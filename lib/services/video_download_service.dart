import 'dart:developer';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:device_info_plus/device_info_plus.dart';
import '../core/api/api_endpoints.dart';
import '../core/services/download_manager.dart';
import '../models/download_model.dart';
import '../services/profile_service.dart';
import '../services/token_storage_service.dart';

/// Sqflite may return `null` for legacy rows or optional columns — never use raw `as String`.
String _sqliteString(Object? v, [String fallback = '']) {
  if (v == null) return fallback;
  return v.toString();
}

int _sqliteInt(Object? v, [int fallback = 0]) {
  if (v == null) return fallback;
  if (v is int) return v;
  if (v is num) return v.toInt();
  return int.tryParse(v.toString()) ?? fallback;
}

DateTime _sqliteDateTime(Object? v) {
  if (v == null) return DateTime.now();
  final s = v.toString();
  if (s.isEmpty) return DateTime.now();
  try {
    return DateTime.parse(s);
  } catch (_) {
    return DateTime.now();
  }
}

class VideoDownloadService {
  static final VideoDownloadService _instance =
      VideoDownloadService._internal();
  factory VideoDownloadService() => _instance;
  VideoDownloadService._internal();

  static Database? _database;
  static String? _activeUserDbKey;
  static const String _tableName = 'downloaded_videos';

  /// Call after logout / session cleared so the next user opens their own DB file.
  Future<void> closeDatabase() async {
    try {
      if (_database != null) {
        await _database!.close();
      }
    } catch (e, st) {
      log('VideoDownloadService.closeDatabase: $e', stackTrace: st);
    } finally {
      _database = null;
      _activeUserDbKey = null;
    }
  }

  static String _storageKeyForUserId(String rawUserId) {
    if (rawUserId.isEmpty) return '_guest';
    final s = rawUserId.replaceAll(RegExp(r'[^a-zA-Z0-9_-]'), '_');
    return s.length > 64 ? s.substring(0, 64) : s;
  }

  /// Prefs first; if missing but token exists, load [/me] and cache id (fixes sessions that never called saveUserId).
  Future<String> _resolveCurrentUserId() async {
    var id = await TokenStorageService.instance.getCurrentUserId();
    if (id.isNotEmpty) return id;
    final loggedIn = await TokenStorageService.instance.isLoggedIn();
    if (!loggedIn) return '';
    try {
      final profile = await ProfileService.instance.getProfile();
      id = profile['id']?.toString() ?? '';
      if (id.isNotEmpty) {
        await TokenStorageService.instance.saveUserId(id);
      }
    } catch (e, st) {
      log('VideoDownloadService: resolve user id failed: $e', stackTrace: st);
    }
    return await TokenStorageService.instance.getCurrentUserId();
  }

  /// One SQLite file per user so offline media cannot leak across accounts on the same device.
  Future<void> _ensureDatabaseForCurrentUser() async {
    final rawId = await _resolveCurrentUserId();
    final key = _storageKeyForUserId(rawId);
    if (_database != null && _activeUserDbKey == key) return;

    await closeDatabase();

    final path = await _prepareDatabasePath(key, rawId);
    _database = await _openDatabaseAtPath(path);
    _activeUserDbKey = key;

    // Normalize legacy rows that still have empty user_id inside this user's DB file.
    if (rawId.isNotEmpty && _database != null) {
      await _database!.rawUpdate(
        'UPDATE $_tableName SET user_id = ? WHERE user_id = \'\' OR user_id IS NULL',
        [rawId],
      );
    }
  }

  /// Moves legacy [downloaded_videos.db] into the logged-in user's file once (first claimant).
  Future<String> _prepareDatabasePath(String storageKey, String rawUserId) async {
    final dir = await getApplicationDocumentsDirectory();
    final newPath = join(dir.path, 'downloaded_videos_$storageKey.db');
    final legacy = File(join(dir.path, 'downloaded_videos.db'));
    final target = File(newPath);
    if (!await target.exists() &&
        await legacy.exists() &&
        rawUserId.isNotEmpty) {
      try {
        await legacy.rename(newPath);
      } catch (_) {
        await legacy.copy(newPath);
        await legacy.delete();
      }
      return newPath;
    }
    return newPath;
  }

  Future<Database> _openDatabaseAtPath(String path) async {
    return openDatabase(
      path,
      version: 3,
      onCreate: (db, version) {
        return db.execute(
          '''
          CREATE TABLE $_tableName(
            id TEXT PRIMARY KEY,
            user_id TEXT NOT NULL DEFAULT '',
            lesson_id TEXT,
            course_id TEXT,
            course_title TEXT,
            title TEXT,
            description TEXT,
            video_url TEXT,
            local_path TEXT,
            file_size INTEGER,
            file_size_mb REAL,
            file_type TEXT,
            duration INTEGER,
            duration_text TEXT,
            video_source TEXT,
            downloaded_at TEXT,
            thumbnail_path TEXT,
            asset_type TEXT NOT NULL DEFAULT 'video'
          )
          ''',
        );
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute(
            "ALTER TABLE $_tableName ADD COLUMN asset_type TEXT NOT NULL DEFAULT 'video'",
          );
        }
        if (oldVersion < 3) {
          await db.execute(
            "ALTER TABLE $_tableName ADD COLUMN user_id TEXT NOT NULL DEFAULT ''",
          );
        }
      },
    );
  }

  // Initialize the download service
  Future<void> initialize() async {
    await _ensureDatabaseForCurrentUser();
  }

  String _sanitizeFileName(String input) {
    var sanitized = input.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
    if (sanitized.isEmpty) return 'video';
    // اختصار الاسم الطويل جداً
    if (sanitized.length > 60) {
      sanitized = sanitized.substring(0, 60);
    }
    return sanitized;
  }

  // Request storage permission
  Future<bool> requestPermission() async {
    try {
      if (Platform.isAndroid) {
        final androidInfo = await DeviceInfoPlugin().androidInfo;
        final sdkInt = androidInfo.version.sdkInt;

        if (sdkInt >= 33) {
          // Android 13+ (app-specific storage path doesn't require runtime storage permissions)
          return true;
        } else if (sdkInt >= 30) {
          // Android 11-12
          final storageStatus = await Permission.storage.status;
          if (storageStatus == PermissionStatus.granted) {
            return true;
          }

          final storageStatusAfter = await Permission.storage.request();
          return storageStatusAfter == PermissionStatus.granted;
        } else {
          // Android 10 and below
          final storageStatus = await Permission.storage.status;
          if (storageStatus == PermissionStatus.granted) {
            return true;
          }

          final storageStatusAfter = await Permission.storage.request();
          return storageStatusAfter == PermissionStatus.granted;
        }
      }
      return true; // iOS doesn't need explicit permission for app documents
    } catch (e) {
      print('Error requesting permission: $e');
      return false;
    }
  }

  // Check current permission status
  Future<bool> hasStoragePermission() async {
    if (Platform.isAndroid) {
      final androidInfo = await DeviceInfoPlugin().androidInfo;

      if (androidInfo.version.sdkInt >= 33) {
        // Android 13+ (app-specific storage path doesn't require runtime storage permissions)
        return true;
      } else if (androidInfo.version.sdkInt >= 30) {
        // Android 11-12
        final storageStatus = await Permission.storage.status;
        return storageStatus == PermissionStatus.granted;
      } else {
        // Android 10 and below
        final storageStatus = await Permission.storage.status;
        return storageStatus == PermissionStatus.granted;
      }
    }
    return true; // iOS doesn't need explicit permission for app documents
  }

  /// تحميل فيديو باستخدام DownloadManager
  Future<String?> downloadVideoWithManager({
    required String videoUrl,
    required String lessonId,
    required String courseId,
    required String title,
    String? courseTitle,
    String? description,
    double? fileSizeMb,
    String? durationText,
    String? videoSource,
    Function(int progress)? onProgress,
  }) async {
    try {
      await _ensureDatabaseForCurrentUser();
      print('🎬 Starting video download with DownloadManager');
      print('Video URL: $videoUrl');
      print('Lesson ID: $lessonId');

      // الحصول على token للمصادقة
      final token = await TokenStorageService.instance.getAccessToken();

      // اسم الملف = عنوان الفيديو فقط
      final fileName = '${_sanitizeFileName(title)}.mp4';

      // تحميل الفيديو باستخدام DownloadManager
      String? localPath = await DownloadManager.download(
        videoUrl,
        name: fileName,
        onDownload: (progress) {
          print('Download progress: $progress%');
          // استدعاء callback التقدم إذا كان موجوداً
          if (onProgress != null) {
            onProgress(progress);
          }
        },
        isOpen: false,
        authToken: token,
        acceptHeader: 'video/*, */*',
      );

      if (localPath != null) {
        log(localPath);
        //print('✅ Video downloaded successfully to: $localPath');

        // حفظ معلومات الفيديو في قاعدة البيانات
        String videoId = DateTime.now().millisecondsSinceEpoch.toString();
        final currentUserId = await _resolveCurrentUserId();

        await _database?.insert(
          _tableName,
          {
            'id': videoId,
            'user_id': currentUserId,
            'lesson_id': lessonId,
            'course_id': courseId,
            'course_title': courseTitle ?? 'كورس $courseId',
            'title': title,
            'description': description ?? '',
            'video_url': videoUrl,
            'local_path': localPath,
            'file_size': 0,
            'file_size_mb': fileSizeMb ?? 0.0,
            'file_type': 'video/mp4',
            'duration': 0,
            'duration_text': durationText ?? '',
            'video_source': videoSource ?? 'server',
            'downloaded_at': DateTime.now().toIso8601String(),
            'thumbnail_path': '',
            'asset_type': 'video',
          },
        );

        print('✅ Video info saved to database');
        return videoId;
      } else {
        print('❌ Video download failed');
        return null;
      }
    } catch (e) {
      print('❌ Error downloading video with DownloadManager: $e');
      return null;
    }
  }

  /// تحميل ملف PDF للدرس (نفس مسار التخزين والمصادقة مثل الفيديو).
  Future<String?> downloadPdfWithManager({
    required String pdfUrl,
    required String lessonId,
    required String courseId,
    required String title,
    String? courseTitle,
    String? description,
    Function(int progress)? onProgress,
  }) async {
    try {
      await _ensureDatabaseForCurrentUser();
      print('📄 Starting PDF download with DownloadManager');
      final token = await TokenStorageService.instance.getAccessToken();

      final safeCourseTitle =
          _sanitizeFileName(courseTitle ?? 'course_$courseId');
      final safeLessonTitle = _sanitizeFileName(title);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final fileName = '${safeCourseTitle}_${safeLessonTitle}_$timestamp.pdf';

      String? localPath;
      for (final url in ApiEndpoints.mediaDownloadUrlCandidates(pdfUrl)) {
        localPath = await DownloadManager.download(
          url,
          name: fileName,
          onDownload: (progress) {
            if (onProgress != null) onProgress(progress);
          },
          isOpen: false,
          authToken: token,
          acceptHeader: '*/*',
        );
        if (localPath != null) {
          if (kDebugMode && url != pdfUrl) {
            print('✅ PDF downloaded from alternate URL: $url');
          }
          break;
        }
      }

      if (localPath == null) return null;

      final id = DateTime.now().millisecondsSinceEpoch.toString();
      final currentUserId = await _resolveCurrentUserId();
      await _database?.insert(
        _tableName,
        {
          'id': id,
          'user_id': currentUserId,
          'lesson_id': lessonId,
          'course_id': courseId,
          'course_title': courseTitle ?? 'كورس $courseId',
          'title': title,
          'description': description ?? '',
          'video_url': pdfUrl,
          'local_path': localPath,
          'file_size': 0,
          'file_size_mb': 0.0,
          'file_type': 'application/pdf',
          'duration': 0,
          'duration_text': '',
          'video_source': 'server',
          'downloaded_at': DateTime.now().toIso8601String(),
          'thumbnail_path': '',
          'asset_type': 'pdf',
        },
      );

      print('✅ PDF info saved to database');
      return id;
    } catch (e) {
      print('❌ Error downloading PDF: $e');
      return null;
    }
  }

  /// حفظ فيديو تم تحميله مسبقاً (مثلاً من YouTube) في قاعدة البيانات
  Future<String?> saveDownloadedVideoRecord({
    required String lessonId,
    required String courseId,
    required String title,
    required String videoUrl,
    required String localPath,
    String? courseTitle,
    String? description,
    double? fileSizeMb,
    String? durationText,
    String videoSource = 'server',
    String assetType = 'video',
    String fileType = 'video/mp4',
  }) async {
    try {
      await _ensureDatabaseForCurrentUser();

      final videoId = DateTime.now().millisecondsSinceEpoch.toString();
      final currentUserId = await _resolveCurrentUserId();

      await _database?.insert(
        _tableName,
        {
          'id': videoId,
          'user_id': currentUserId,
          'lesson_id': lessonId,
          'course_id': courseId,
          'course_title': courseTitle ?? 'كورس $courseId',
          'title': title,
          'description': description ?? '',
          'video_url': videoUrl,
          'local_path': localPath,
          'file_size': 0,
          'file_size_mb': fileSizeMb ?? 0.0,
          'file_type': fileType,
          'duration': 0,
          'duration_text': durationText ?? '',
          'video_source': videoSource,
          'downloaded_at': DateTime.now().toIso8601String(),
          'thumbnail_path': '',
          'asset_type': assetType,
        },
      );

      print('✅ External video info saved to database (source: $videoSource)');
      return videoId;
    } catch (e) {
      print('❌ Error saving downloaded video record: $e');
      return null;
    }
  }

  /// الحصول على معلومات التحميل من API
  Future<DownloadData?> getDownloadInfo(String lessonId) async {
    try {
      // TODO: إضافة endpoint للتحميل في API إذا كان موجوداً
      // حالياً سنستخدم lesson content للحصول على معلومات الفيديو
      // يمكن تعديل هذا لاحقاً إذا كان هناك endpoint مخصص للتحميل

      // يمكن إضافة endpoint مثل: ApiEndpoints.downloadLesson(lessonId)
      return null;
    } catch (e) {
      print('❌ Error getting download info: $e');
      return null;
    }
  }

  /// التحقق من وجود ملف محمل مسبقاً
  Future<String?> checkLocalVideoFile(String lessonId) async {
    await _ensureDatabaseForCurrentUser();
    final userId = await _resolveCurrentUserId();
    final result = await _database?.query(
      _tableName,
      where: 'lesson_id = ? AND asset_type = ? AND user_id = ?',
      whereArgs: [lessonId, 'video', userId],
      limit: 1,
    );

    if (result?.isNotEmpty ?? false) {
      final localPath = _sqliteString(result!.first['local_path']);
      if (localPath.isEmpty) return null;

      final file = File(localPath);
      if (await file.exists()) {
        print('✅ Local video file exists: $localPath');
        return localPath;
      } else {
        print('🚫 Local video file not found, cleaning database entry');
        await _database?.delete(
          _tableName,
          where: 'lesson_id = ? AND asset_type = ? AND user_id = ?',
          whereArgs: [lessonId, 'video', userId],
        );
      }
    }

    return null;
  }

  /// الحصول على جميع الفيديوهات المحملة
  Future<List<DownloadedVideoModel>> getDownloadedVideosWithManager() async {
    try {
      print('Getting downloaded videos from database...');

      await _ensureDatabaseForCurrentUser();

      final userId = await _resolveCurrentUserId();
      final results = await _database?.query(
        _tableName,
        where: 'user_id = ?',
        whereArgs: [userId],
      );

      if (results == null || results.isEmpty) {
        print('No downloaded videos found in database');
        return [];
      }

      print('Found ${results.length} videos in database');

      List<DownloadedVideoModel> videos = [];

      for (final row in results) {
        final localPath = _sqliteString(row['local_path']);
        if (localPath.isEmpty) {
          final badId = _sqliteString(row['id']);
          if (badId.isNotEmpty) {
            await _database?.delete(
              _tableName,
              where: 'id = ?',
              whereArgs: [badId],
            );
          }
          continue;
        }
        final file = File(localPath);

        // التحقق من وجود الملف
        if (await file.exists()) {
          print('✅ Video file exists: $localPath');

          // حساب حجم الملف الفعلي
          int fileSize = await file.length();
          double fileSizeMb = fileSize / (1024 * 1024);
          final courseTitleRaw = _sqliteString(row['course_title']);
          final courseIdStr = _sqliteString(row['course_id']);

          videos.add(DownloadedVideoModel(
            id: _sqliteString(row['id']),
            lessonId: _sqliteString(row['lesson_id']),
            courseId: courseIdStr,
            courseTitle: courseTitleRaw.isNotEmpty
                ? courseTitleRaw
                : 'كورس $courseIdStr',
            title: _sqliteString(row['title']),
            description: _sqliteString(row['description']),
            videoUrl: _sqliteString(row['video_url']),
            localPath: localPath,
            fileSize: fileSize,
            fileSizeMb: fileSizeMb,
            fileType: _sqliteString(row['file_type'], 'video/mp4'),
            duration: _sqliteInt(row['duration']),
            durationText: _sqliteString(row['duration_text']),
            videoSource: _sqliteString(row['video_source'], 'server'),
            downloadedAt: _sqliteDateTime(row['downloaded_at']),
            thumbnailPath: _sqliteString(row['thumbnail_path']),
            assetType: _sqliteString(row['asset_type'], 'video'),
          ));
        } else {
          print('🚫 Video file not found, removing from database: $localPath');
          // حذف السجل إذا كان الملف غير موجود
          await _database?.delete(
            _tableName,
            where: 'id = ?',
            whereArgs: [row['id']],
          );
        }
      }

      print('Returning ${videos.length} valid videos');
      return videos;
    } catch (e) {
      print('Error getting downloaded videos: $e');
      return [];
    }
  }

  /// حذف فيديو محمل
  Future<bool> deleteDownloadedVideo(String videoId) async {
    try {
      await _ensureDatabaseForCurrentUser();
      final userId = await _resolveCurrentUserId();
      // الحصول على معلومات الفيديو من قاعدة البيانات
      final result = await _database?.query(
        _tableName,
        where: 'id = ? AND user_id = ?',
        whereArgs: [videoId, userId],
        limit: 1,
      );

      if (result?.isNotEmpty ?? false) {
        final localPath = _sqliteString(result!.first['local_path']);
        if (localPath.isEmpty) return false;
        final fileName = localPath.split('/').last;

        // حذف الملف من التخزين
        await DownloadManager.deleteFile(fileName);

        // حذف السجل من قاعدة البيانات
        await _database?.delete(
          _tableName,
          where: 'id = ? AND user_id = ?',
          whereArgs: [videoId, userId],
        );

        print('✅ Video deleted successfully');
        return true;
      } else {
        print('🚫 Video not found in database');
        return false;
      }
    } catch (e) {
      print('❌ Error deleting video: $e');
      return false;
    }
  }

  /// التحقق من أن الفيديو محمل
  Future<bool> isVideoDownloaded(String lessonId) async {
    await _ensureDatabaseForCurrentUser();
    final userId = await _resolveCurrentUserId();
    final result = await _database?.query(
      _tableName,
      where: 'lesson_id = ? AND asset_type = ? AND user_id = ?',
      whereArgs: [lessonId, 'video', userId],
      limit: 1,
    );

    if (result?.isNotEmpty ?? false) {
      final localPath = _sqliteString(result!.first['local_path']);
      if (localPath.isEmpty) return false;
      final file = File(localPath);
      return await file.exists();
    }

    return false;
  }

  /// نفس الدرس قد يملك أكثر من PDF؛ التمييز بـ [pdfUrl] المخزن في عمود video_url.
  Future<bool> isPdfDownloaded(String lessonId, String pdfUrl) async {
    await _ensureDatabaseForCurrentUser();
    final userId = await _resolveCurrentUserId();
    final result = await _database?.query(
      _tableName,
      where: 'lesson_id = ? AND asset_type = ? AND video_url = ? AND user_id = ?',
      whereArgs: [lessonId, 'pdf', pdfUrl, userId],
      limit: 1,
    );

    if (result?.isNotEmpty ?? false) {
      final localPath = _sqliteString(result!.first['local_path']);
      if (localPath.isEmpty) return false;
      final file = File(localPath);
      return await file.exists();
    }

    return false;
  }
}
