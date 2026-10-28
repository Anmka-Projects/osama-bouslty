import 'dart:async';
import 'dart:developer';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart' as http;
import 'package:path_provider/path_provider.dart';
import 'package:pod_player/pod_player.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/localization/localization_helper.dart';
import '../../core/courses/lesson_duration_utils.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../l10n/app_localizations.dart';
import '../../services/courses_service.dart';
import '../../services/token_storage_service.dart';
import '../../services/video_download_service.dart';
import '../../services/youtube_video_service.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';

/// Lesson Viewer Screen - Modern & Eye-Friendly Design
class LessonViewerScreen extends StatefulWidget {
  final Map<String, dynamic>? lesson;
  final String? courseId;

  /// Ordered lessons in the course curriculum — used for previous/next
  /// lesson navigation.
  final List<Map<String, dynamic>>? lessons;

  const LessonViewerScreen({
    super.key,
    this.lesson,
    this.courseId,
    this.lessons,
  });

  @override
  State<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends State<LessonViewerScreen> {
  AppThemeExtension get _theme => AppThemeExtension.of(context);

  PodPlayerController? _controller;
  WebViewController? _webViewController;
  bool _isVideoLoading = true;
  bool _isLoadingContent = true;
  bool _useWebViewFallback = false;
  Map<String, dynamic>? _lessonContent;
  File? _tempVideoFile;
  final VideoDownloadService _downloadService = VideoDownloadService();
  bool _isDownloading = false;
  int _downloadProgress = 0;
  bool _isDownloaded = false;
  bool _allowOfflineDownload = false;

  /// Normalized PDF URLs → downloaded locally (lesson may have several PDFs).
  Map<String, bool> _pdfDownloadedByUrl = {};
  String? _pdfDownloadingUrl;
  int _pdfDownloadProgress = 0;

  Timer? _progressTimer;
  int _lastReportedSeconds = 0;
  bool _progressReporting = false;
  int _watchProgressPercent = 0;

  @override
  void initState() {
    super.initState();
    _initializeDownloadService();
    _loadCoursePermissions();
    _enrichDurationFromYoutubeIfNeeded();
    _loadLessonContent().then((_) {
      // Initialize video after content is loaded (or failed)
      // This ensures we can use video data from the API response
      _initializeVideo();
      _checkIfDownloaded();
      _refreshPdfDownloadStates();
    });
  }

  Future<void> _enrichDurationFromYoutubeIfNeeded() async {
    final lesson = widget.lesson;
    if (lesson == null) return;
    if (LessonDurationUtils.hasDurationSet(lesson)) return;

    final url = (lesson['video_url'] ?? lesson['videoUrl'])?.toString().trim();
    if (url == null || url.isEmpty) return;
    if (!url.contains('youtube.com') && !url.contains('youtu.be')) return;

    final minutes =
        await YoutubeVideoService.instance.getVideoDurationMinutes(url);
    if (minutes == null || minutes <= 0 || !mounted) return;
    setState(() {
      LessonDurationUtils.applyYoutubeMinutes(lesson, minutes);
    });
  }

  Map<String, dynamic> _mergedLessonData() {
    final lesson = widget.lesson;
    if (lesson == null) return {};
    final merged = Map<String, dynamic>.from(lesson);
    if (_lessonContent != null) {
      LessonDurationUtils.mergeDurationFields(merged, _lessonContent!);
    }
    return merged;
  }

  int _lessonTotalSeconds() {
    final meta = LessonDurationUtils.resolveTotalSeconds(_mergedLessonData());
    if (meta > 0) return meta;
    // Fallback: the player itself knows the real duration once initialised —
    // keeps progress sync working for lessons missing duration metadata.
    if (_controller != null && _controller!.isInitialised) {
      return _controller!.totalVideoLength.inSeconds;
    }
    return 0;
  }

  int _currentWatchedSeconds() {
    if (_controller != null && _controller!.isInitialised) {
      return _controller!.currentVideoPosition.inSeconds;
    }
    return LessonDurationUtils.watchedSeconds(_mergedLessonData());
  }

  void _refreshWatchProgressPercent() {
    final total = _lessonTotalSeconds();
    if (total <= 0) return;
    final watched = _currentWatchedSeconds();
    final pct = ((watched / total) * 100).round().clamp(0, 100);
    if (pct != _watchProgressPercent && mounted) {
      setState(() => _watchProgressPercent = pct);
    }
  }

  void _startProgressTracking() {
    _progressTimer?.cancel();
    _refreshWatchProgressPercent();
    _progressTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      _syncLessonProgress();
      _refreshWatchProgressPercent();
    });
  }

  /// Local SharedPreferences key for the last watched position of this
  /// lesson — resume must work even if the API doesn't echo `progress` back.
  String? _lessonWatchKey() {
    final lessonId = widget.lesson?['id']?.toString();
    if (lessonId == null || lessonId.isEmpty) return null;
    final courseId = _resolveCourseId() ?? 'nocourse';
    return 'lesson_watch_${courseId}_$lessonId';
  }

  Future<void> _persistLocalPosition() async {
    final key = _lessonWatchKey();
    final watched = _currentWatchedSeconds();
    if (key == null || watched <= 0) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt(key, watched);
    } catch (_) {}
  }

  Future<int> _loadLocalPosition() async {
    final key = _lessonWatchKey();
    if (key == null) return 0;
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getInt(key) ?? 0;
    } catch (_) {
      return 0;
    }
  }

  Future<void> _syncLessonProgress({bool force = false}) async {
    // Always persist locally first — even if a server sync is in flight,
    // the lesson has no duration metadata, or the API call fails later.
    _persistLocalPosition();
    if (_progressReporting) return;
    final lesson = widget.lesson;
    final courseId = _resolveCourseId();
    if (lesson == null || courseId == null) return;

    final lessonId = lesson['id']?.toString();
    if (lessonId == null || lessonId.isEmpty) return;

    final total = _lessonTotalSeconds();
    if (total <= 0) return;

    final watched = _currentWatchedSeconds().clamp(0, total);
    if (!force && (watched - _lastReportedSeconds).abs() < 5) return;

    final isCompleted = watched >= total - 3;

    _progressReporting = true;
    try {
      await CoursesService.instance.updateLessonProgress(
        courseId,
        lessonId,
        watchedSeconds: watched,
        isCompleted: isCompleted,
      );
      _lastReportedSeconds = watched;
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Failed to sync lesson progress: $e');
      }
    } finally {
      _progressReporting = false;
    }
  }

  Future<void> _resumeFromSavedProgress() async {
    // Prefer the fresher of the server-reported and locally saved positions.
    final apiWatched = LessonDurationUtils.watchedSeconds(_mergedLessonData());
    final localWatched = await _loadLocalPosition();
    final watched = apiWatched > localWatched ? apiWatched : localWatched;
    if (watched <= 0 || _controller == null || !_controller!.isInitialised) {
      return;
    }
    try {
      await _controller!.videoSeekTo(Duration(seconds: watched));
      _lastReportedSeconds = watched;
      _refreshWatchProgressPercent();
    } catch (e) {
      if (kDebugMode) {
        print('⚠️ Could not seek to saved progress: $e');
      }
    }
  }

  void _onVideoReady() {
    if (!mounted) return;
    setState(() => _isVideoLoading = false);
    _resumeFromSavedProgress();
    _startProgressTracking();
  }

  Future<void> _initializeDownloadService() async {
    await _downloadService.initialize();
  }

  Future<void> _checkIfDownloaded() async {
    final lesson = widget.lesson;
    if (lesson == null) return;

    final lessonId = lesson['id']?.toString();
    if (lessonId == null || lessonId.isEmpty) return;

    final isDownloaded = await _downloadService.isVideoDownloaded(lessonId);
    if (mounted) {
      setState(() {
        _isDownloaded = isDownloaded;
      });
    }
  }

  Future<void> _refreshPdfDownloadStates() async {
    final lesson = widget.lesson;
    if (lesson == null) return;
    final lessonId = lesson['id']?.toString();
    if (lessonId == null || lessonId.isEmpty) return;
    if (_lessonContent == null) return;

    final urls = <String>[];
    final contentPdf = _lessonContent?['content_pdf']?.toString();
    if (contentPdf != null && contentPdf.isNotEmpty) {
      final c = _cleanVideoUrl(contentPdf);
      if (c != null) urls.add(c);
    }
    final resources = _lessonContent?['resources'] as List?;
    if (resources != null) {
      for (final resource in resources) {
        if (resource is! Map<String, dynamic>) continue;
        final url =
            resource['url']?.toString() ?? resource['file']?.toString() ?? '';
        final type = (resource['type']?.toString() ??
                resource['file_type']?.toString() ??
                '')
            .toLowerCase();
        final isPdfRes =
            type.contains('pdf') || url.toLowerCase().contains('.pdf');
        if (!isPdfRes) continue;
        final c = _cleanVideoUrl(url);
        if (c != null) urls.add(c);
      }
    }

    final next = <String, bool>{};
    for (final u in urls) {
      next[u] = await _downloadService.isPdfDownloaded(lessonId, u);
    }
    if (mounted) setState(() => _pdfDownloadedByUrl = next);
  }

  String? _resolveCourseId() {
    String? courseId = widget.courseId;
    final lesson = widget.lesson;
    if ((courseId == null || courseId.isEmpty) && lesson != null) {
      courseId =
          lesson['course_id']?.toString() ?? lesson['courseId']?.toString();
    }
    if (courseId == null || courseId.isEmpty) return null;
    return courseId;
  }

  int _currentLessonIndex() {
    final lessons = widget.lessons;
    final lessonId = widget.lesson?['id']?.toString();
    if (lessons == null || lessonId == null || lessonId.isEmpty) return -1;
    for (var i = 0; i < lessons.length; i++) {
      if (lessons[i]['id']?.toString() == lessonId) return i;
    }
    return -1;
  }

  /// Lesson at [offset] from the current one in the ordered curriculum list
  /// (`-1` previous / `+1` next). Returns null when out of bounds or when the
  /// list isn't available.
  Map<String, dynamic>? _lessonAtOffset(int offset) {
    final lessons = widget.lessons;
    final index = _currentLessonIndex();
    if (lessons == null || index < 0) return null;
    final target = index + offset;
    if (target < 0 || target >= lessons.length) return null;
    return lessons[target];
  }

  void _navigateToAdjacentLesson(int offset) {
    final target = _lessonAtOffset(offset);
    if (target == null) {
      // At the course edge — go back to the curriculum list.
      context.pop();
      return;
    }
    context.pushReplacement(RouteNames.lessonViewer, extra: {
      'lesson': target,
      'courseId': _resolveCourseId(),
      'lessons': widget.lessons,
    });
  }

  Future<void> _loadCoursePermissions() async {
    final courseId = _resolveCourseId();
    if (courseId == null) return;
    try {
      final course = await CoursesService.instance.getCourseDetails(courseId);
      final allow = course['allow_offline_download'] == true;
      if (!mounted) return;
      setState(() => _allowOfflineDownload = allow);
    } catch (_) {
      // Keep default false if unavailable
    }
  }

  Future<void> _loadLessonContent() async {
    final lesson = widget.lesson;
    if (lesson == null) {
      setState(() {
        _isLoadingContent = false;
      });
      return;
    }

    // Get courseId from widget or extract from lesson
    String? courseId = widget.courseId;
    if (courseId == null || courseId.isEmpty) {
      courseId =
          lesson['course_id']?.toString() ?? lesson['courseId']?.toString();
    }

    final lessonId = lesson['id']?.toString();

    if (courseId == null ||
        courseId.isEmpty ||
        lessonId == null ||
        lessonId.isEmpty) {
      setState(() {
        _isLoadingContent = false;
      });
      return;
    }

    try {
      final content = await CoursesService.instance.getLessonContent(
        courseId,
        lessonId,
      );

      if (mounted) {
        setState(() {
          _lessonContent = content;
          _isLoadingContent = false;
          LessonDurationUtils.mergeDurationFields(lesson, content);
          _watchProgressPercent =
              LessonDurationUtils.progressPercentage(content);
          _lastReportedSeconds = LessonDurationUtils.watchedSeconds(content);
        });
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error loading lesson content: $e');
      }
      if (mounted) {
        setState(() {
          _isLoadingContent = false;
        });
      }
    }
  }

  String _lessonDurationLabel(Map? lesson) {
    return context.lessonDurationLabel(lesson);
  }

  /// Clean and normalize video URL
  String? _cleanVideoUrl(String? url) {
    if (url == null || url.isEmpty) return null;

    // Remove any blob: prefix if present at the start
    url = url.replaceFirst(RegExp(r'^blob:'), '').trim();

    // Fix URLs that have blob: in the middle (like "https://domain.com/blob:https://...")
    if (url.contains('blob:')) {
      final blobIndex = url.indexOf('blob:');
      if (blobIndex != -1) {
        final afterBlob =
            url.substring(blobIndex + 5).trim(); // 5 is length of "blob:"
        // If the part after blob: starts with http/https, use it directly
        if (afterBlob.startsWith('http://') ||
            afterBlob.startsWith('https://')) {
          url = afterBlob;
        } else {
          // Otherwise, remove the blob: part and keep everything before and after
          url = url.substring(0, blobIndex).trim() + afterBlob;
        }
      }
    }

    // Protocol-relative URLs
    if (url.startsWith('//')) {
      url = 'https:$url';
    }

    // Relative API/media paths → full URL (avoids broken absolute URLs)
    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      if (url.startsWith('/')) {
        final resolved = ApiEndpoints.getImageUrl(url);
        if (resolved.isNotEmpty) {
          url = resolved;
        } else {
          if (kDebugMode) {
            print('⚠️ Could not resolve video URL: $url');
          }
          return null;
        }
      } else {
        if (kDebugMode) {
          print('⚠️ Invalid video URL format: $url');
        }
        return null;
      }
    }

    return url.trim();
  }

  Future<void> _initializeVideo() async {
    final lesson = widget.lesson;
    if (lesson == null) {
      setState(() => _isVideoLoading = false);
      return;
    }

    // Wait for content to load, then use it for video
    // If content is already loaded, use it; otherwise use lesson data
    final videoData = _lessonContent?['video'] ?? lesson['video'];

    // Extract video ID from lesson content or lesson - try all possible fields
    String? videoId;
    String? videoUrl;

    // 1. Try video_url field directly from lesson (highest priority)
    videoUrl = _cleanVideoUrl(lesson['video_url']?.toString());

    // 2. Try video object with youtube_id from content
    if (videoUrl == null && videoData is Map) {
      videoId = videoData['youtube_id']?.toString();
      videoUrl = _cleanVideoUrl(videoData['url']?.toString());
    }

    // 3. Try video object with youtube_id from lesson
    if (videoUrl == null && lesson['video'] is Map) {
      videoId = lesson['video']?['youtube_id']?.toString();
      videoUrl = _cleanVideoUrl(lesson['video']?['url']?.toString());
    }

    // 4. Try direct youtube_id field
    videoId = videoId ?? lesson['youtube_id']?.toString();

    // 5. Try youtubeVideoId field
    videoId = videoId ?? lesson['youtubeVideoId']?.toString();

    // 6. If no video object, use lesson id as video id
    if (videoId == null || videoId.isEmpty) {
      videoId = lesson['id']?.toString();
    }

    videoId = videoId ?? '';

    if (kDebugMode) {
      print('═══════════════════════════════════════════════════════════');
      print('🎥 INITIALIZING VIDEO IN LESSON VIEWER');
      print('═══════════════════════════════════════════════════════════');
      print('Video ID: $videoId');
      print('Video URL (cleaned): $videoUrl');
      print('Lesson ID: ${lesson['id']}');
      print('Lesson Title: ${lesson['title']}');
      print('Video Object: $videoData');
      print('Raw video_url: ${lesson['video_url']}');
      print('All Lesson Keys: ${lesson.keys.toList()}');
      print('═══════════════════════════════════════════════════════════');
    }

    try {
      // Use video URL if available, otherwise use YouTube ID
      if (videoUrl != null && videoUrl.isNotEmpty) {
        // Check if it's a YouTube URL
        if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
          if (kDebugMode) {
            print('📺 Using YouTube URL: $videoUrl');
          }
          _controller = PodPlayerController(
            playVideoFrom: PlayVideoFrom.youtube(videoUrl),
            podPlayerConfig: const PodPlayerConfig(
              autoPlay: false,
              isLooping: false,
            ),
          )..initialise().then((_) {
              _onVideoReady();
            }).catchError((error) {
              if (kDebugMode) {
                print('❌ Error initializing YouTube video: $error');
              }
              if (mounted) {
                setState(() => _isVideoLoading = false);
              }
            });
        } else {
          // Direct video URL from server - use pod_player with network
          if (kDebugMode) {
            print('📹 Using pod_player for direct video URL: $videoUrl');
          }
          _initializeDirectVideo(videoUrl);
        }
      } else if (videoId.isNotEmpty) {
        // Fallback to YouTube ID
        if (kDebugMode) {
          print('📺 Using YouTube ID fallback: $videoId');
        }
        final youtubeUrl = 'https://www.youtube.com/watch?v=$videoId';
        _controller = PodPlayerController(
          playVideoFrom: PlayVideoFrom.youtube(youtubeUrl),
          podPlayerConfig: const PodPlayerConfig(
            autoPlay: false,
            isLooping: false,
          ),
        )..initialise().then((_) {
            _onVideoReady();
          }).catchError((error) {
            if (kDebugMode) {
              print('❌ Error initializing YouTube video by ID: $error');
            }
            if (mounted) {
              setState(() => _isVideoLoading = false);
            }
          });
      } else {
        // No valid video source
        if (kDebugMode) {
          print('⚠️ No valid video source found');
        }
        if (mounted) {
          setState(() => _isVideoLoading = false);
        }
      }
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing video: $e');
      }
      if (mounted) {
        setState(() => _isVideoLoading = false);
      }
    }
  }

  /// Initialize direct video playback using pod_player
  Future<void> _initializeDirectVideo(String videoUrl) async {
    try {
      if (kDebugMode) {
        print('📹 Initializing direct video with pod_player: $videoUrl');
      }

      // Get authorization token for video access
      final token = await TokenStorageService.instance.getAccessToken();

      // Add token as query parameter if available
      String videoUrlWithToken = videoUrl;
      if (token != null && token.isNotEmpty) {
        final uri = Uri.parse(videoUrl);
        videoUrlWithToken = uri.replace(queryParameters: {
          ...uri.queryParameters,
          'token': token,
        }).toString();

        if (kDebugMode) {
          print('🔑 Added token to video URL');
        }
      }

      // Use pod_player with PlayVideoFrom.network()
      _controller = PodPlayerController(
        playVideoFrom: PlayVideoFrom.network(videoUrlWithToken),
        podPlayerConfig: const PodPlayerConfig(
          autoPlay: false,
          isLooping: false,
        ),
      )..initialise().then((_) {
          if (mounted) {
            setState(() {
              _isVideoLoading = false;
              _useWebViewFallback = false;
            });
            _onVideoReady();
          }
        }).catchError((error) {
          if (kDebugMode) {
            print('❌ Error initializing direct video with pod_player: $error');
            print('   Falling back to WebView...');
          }
          // Fallback to WebView if pod_player fails
          if (mounted) {
            _initializeWebView(videoUrl);
          }
        });
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error in _initializeDirectVideo: $e');
        print('   Falling back to WebView...');
      }
      // Fallback to WebView if there's an error
      if (mounted) {
        _initializeWebView(videoUrl);
      }
    }
  }

  /// Initialize WebView for direct video playback (fallback method)
  Future<void> _initializeWebView(String videoUrl) async {
    try {
      if (kDebugMode) {
        print('🌐 Initializing WebView for video playback: $videoUrl');
      }

      // Get authorization token for video access
      final token = await TokenStorageService.instance.getAccessToken();

      setState(() {
        _useWebViewFallback = true;
      });

      // Try to load video via Flutter HTTP request first (to bypass CORS)
      // Then pass it to WebView as blob URL
      try {
        if (kDebugMode) {
          print('📥 Loading video via Flutter HTTP request...');
        }

        final headers = <String, String>{};
        if (token != null && token.isNotEmpty) {
          headers['Authorization'] = 'Bearer $token';
        }

        // Load video and save to temporary file
        final response = await http
            .get(
              Uri.parse(videoUrl),
              headers: headers,
            )
            .timeout(const Duration(seconds: 60));

        if (response.statusCode == 200) {
          if (kDebugMode) {
            print(
                '✅ Video loaded successfully via HTTP (${response.bodyBytes.length} bytes)');
          }

          // Save to temporary file
          final tempDir = await getTemporaryDirectory();
          final fileName = videoUrl.split('/').last.split('?').first;
          final fileExtension = fileName.split('.').last;
          final tempFile = File(
              '${tempDir.path}/video_${DateTime.now().millisecondsSinceEpoch}.$fileExtension');

          await tempFile.writeAsBytes(response.bodyBytes);

          if (kDebugMode) {
            print('💾 Video saved to temporary file: ${tempFile.path}');
          }

          // Use file:// URL for WebView
          final fileUrl = tempFile.path;
          _createWebViewWithFileUrl(fileUrl);

          // Store reference to temp file for cleanup
          setState(() {
            _tempVideoFile = tempFile;
          });

          return;
        } else {
          if (kDebugMode) {
            print('❌ HTTP request failed with status: ${response.statusCode}');
          }
        }
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Failed to load video via HTTP: $e');
          print('   Falling back to direct WebView method...');
        }
      }

      // Fallback: Try direct WebView method

      _createWebViewWithDirectUrl(videoUrl, token);
    } catch (e) {
      if (kDebugMode) {
        print('❌ Error initializing WebView: $e');
      }
      if (mounted) {
        setState(() {
          _isVideoLoading = false;
        });
      }
    }
  }

  /// Create WebView with file URL (from temporary file)
  void _createWebViewWithFileUrl(String filePath) {
    // Convert file path to file:// URL
    final fileUrl =
        Platform.isAndroid ? 'file://$filePath' : 'file://$filePath';

    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    html, body {
      width: 100%;
      height: 100%;
      background-color: #000;
      overflow: hidden;
    }
    video {
      width: 100%;
      height: 100%;
      object-fit: contain;
      background-color: #000;
    }
  </style>
</head>
<body>
  <video id="videoPlayer" controls autoplay playsinline webkit-playsinline>
    <source src="$fileUrl" type="video/mp4">
    Your browser does not support the video tag.
  </video>
  <script>
    var video = document.getElementById('videoPlayer');
    video.addEventListener('loadeddata', function() {
      console.log('Video loaded successfully from file URL');
    });
    video.addEventListener('error', function(e) {
      console.error('Video error:', e);
      var error = video.error;
      if (error) {
        console.error('Error code:', error.code, 'Message:', error.message);
      }
    });
  </script>
</body>
</html>
''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (String url) {
            if (kDebugMode) {
              print('✅ WebView page finished: $url');
            }
            if (mounted) {
              setState(() {
                _isVideoLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print('❌ WebView resource error: ${error.description}');
            }
            if (mounted) {
              setState(() {
                _isVideoLoading = false;
              });
            }
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
          });
        }
      });
    }
  }

  /// Create WebView with direct URL (fallback method)
  void _createWebViewWithDirectUrl(String videoUrl, String? token) {
    // Build video URL with token as query parameter (fallback method)
    String videoUrlWithToken = videoUrl;
    if (token != null && token.isNotEmpty) {
      final uri = Uri.parse(videoUrl);
      videoUrlWithToken = uri.replace(queryParameters: {
        ...uri.queryParameters,
        'token': token,
      }).toString();
    }

    // Create HTML5 video player with multiple fallback methods
    final htmlContent = '''
<!DOCTYPE html>
<html>
<head>
  <meta name="viewport" content="width=device-width, initial-scale=1.0, maximum-scale=1.0, user-scalable=no">
  <style>
    * {
      margin: 0;
      padding: 0;
      box-sizing: border-box;
    }
    html, body {
      width: 100%;
      height: 100%;
      background-color: #000;
      overflow: hidden;
    }
    video {
      width: 100%;
      height: 100%;
      object-fit: contain;
      background-color: #000;
    }
    .loading {
      position: absolute;
      top: 50%;
      left: 50%;
      transform: translate(-50%, -50%);
      color: white;
      font-family: Arial, sans-serif;
      text-align: center;
    }
    .error {
      color: #ff6b6b;
    }
  </style>
</head>
<body>
  <div class="loading" id="loading">جاري تحميل الفيديو...</div>
  <video id="videoPlayer" controls autoplay playsinline webkit-playsinline style="display: none;">
    Your browser does not support the video tag.
  </video>
  <script>
    var video = document.getElementById('videoPlayer');
    var loading = document.getElementById('loading');
    var videoUrl = '$videoUrl';
    var videoUrlWithToken = '$videoUrlWithToken';
    ${token != null ? "var token = '$token';" : 'var token = null;'}
    var currentMethod = 0;
    var methods = ['direct', 'no-cors', 'token-param'];
    
    function showVideo() {
      video.style.display = 'block';
      loading.style.display = 'none';
    }
    
    function showError(message) {
      loading.textContent = message;
      loading.className = 'loading error';
    }
    
    // Method 1: Try direct video source first (simplest, may work if server allows)
    function tryDirectVideo() {
      console.log('Trying method 1: Direct video source');
      video.src = videoUrl;
      video.load();
      
      var timeout = setTimeout(function() {
        if (video.readyState === 0) {
          console.log('Direct method failed, trying next method');
          tryNoCorsFetch();
        }
      }, 3000);
      
      video.addEventListener('loadeddata', function() {
        clearTimeout(timeout);
        console.log('Direct method succeeded');
        showVideo();
      }, { once: true });
      
      video.addEventListener('error', function(e) {
        clearTimeout(timeout);
        console.log('Direct method failed:', e);
        tryNoCorsFetch();
      }, { once: true });
    }
    
    // Method 2: Try fetch with no-cors mode
    async function tryNoCorsFetch() {
      console.log('Trying method 2: Fetch with no-cors mode');
      try {
        var response = await fetch(videoUrl, {
          method: 'GET',
          mode: 'no-cors',
          cache: 'default'
        });
        
        // With no-cors, we can't read the response, but we can try to use it
        // Try to create a blob URL anyway
        if (response.type === 'opaque') {
          // Opaque response - try to use video tag with the URL directly
          console.log('Got opaque response, trying direct video');
          video.src = videoUrl;
          video.load();
          
          video.addEventListener('loadeddata', function() {
            console.log('Video loaded after no-cors fetch');
            showVideo();
          }, { once: true });
          
          video.addEventListener('error', function(e) {
            console.log('No-cors method failed:', e);
            tryTokenParam();
          }, { once: true });
        }
      } catch (error) {
        console.log('No-cors fetch failed:', error);
        tryTokenParam();
      }
    }
    
    // Method 3: Try with token as query parameter
    function tryTokenParam() {
      if (!token) {
        showError('لا يمكن تحميل الفيديو');
        return;
      }
      
      console.log('Trying method 3: Token as query parameter');
      video.src = videoUrlWithToken;
      video.load();
      
      video.addEventListener('loadeddata', function() {
        console.log('Token param method succeeded');
        showVideo();
      }, { once: true });
      
      video.addEventListener('error', function(e) {
        console.log('Token param method failed:', e);
        showError('فشل تحميل الفيديو. يرجى التحقق من الاتصال بالإنترنت.');
      }, { once: true });
    }
    
    // Add error handlers
    video.addEventListener('error', function(e) {
      var error = video.error;
      if (error) {
        console.error('Video error code:', error.code, 'Message:', error.message);
        if (error.code === 4) {
          // MEDIA_ELEMENT_ERROR: Format error
          showError('تنسيق الفيديو غير مدعوم');
        } else if (error.code === 3) {
          // MEDIA_ELEMENT_ERROR: Decode error
          showError('خطأ في فك تشفير الفيديو');
        } else if (error.code === 2) {
          // MEDIA_ELEMENT_ERROR: Network error
          showError('خطأ في الاتصال بالشبكة');
        } else {
          showError('خطأ في تحميل الفيديو');
        }
      }
    });
    
    // Start loading
    if (document.readyState === 'loading') {
      document.addEventListener('DOMContentLoaded', tryDirectVideo);
    } else {
      tryDirectVideo();
    }
  </script>
</body>
</html>
''';

    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (String url) {
            if (kDebugMode) {
              print('🌐 WebView page started: $url');
            }
          },
          onPageFinished: (String url) {
            if (kDebugMode) {
              print('✅ WebView page finished: $url');
            }
            if (mounted) {
              setState(() {
                _isVideoLoading = false;
              });
            }
          },
          onWebResourceError: (WebResourceError error) {
            if (kDebugMode) {
              print('❌ WebView resource error: ${error.description}');
              print('   Error code: ${error.errorCode}');
              print('   Error type: ${error.errorType}');
              print('   Failed URL: ${error.url}');

              // Log specific error types
              if (error.errorCode == -1) {
                print(
                    '   ⚠️ CORS or ORB (Opaque Response Blocking) error detected');
                print(
                    '   💡 This is expected - JavaScript will handle fallback methods');
              }
            }
            // Don't set loading to false immediately - let JavaScript try fallback methods
            // Only set to false if it's a critical error
            if (error.errorType == WebResourceErrorType.hostLookup ||
                error.errorType == WebResourceErrorType.timeout) {
              if (mounted) {
                setState(() {
                  _isVideoLoading = false;
                });
              }
            }
          },
        ),
      )
      ..loadHtmlString(htmlContent);

    if (mounted) {
      Future.delayed(const Duration(milliseconds: 500), () {
        if (mounted) {
          setState(() {
            _isVideoLoading = false;
          });
        }
      });
    }
  }

  @override
  void dispose() {
    _progressTimer?.cancel();
    _syncLessonProgress(force: true);
    _controller?.dispose();
    // Clean up temporary video file
    if (_tempVideoFile != null) {
      try {
        _tempVideoFile!.deleteSync();
      } catch (e) {
        if (kDebugMode) {
          print('⚠️ Error deleting temp video file: $e');
        }
      }
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    SystemChrome.setSystemUIOverlayStyle(
      const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.dark,
      ),
    );

    final lesson = widget.lesson;
    if (lesson == null) {
      return Scaffold(
        backgroundColor: AppColors.navyDeep,
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.error_outline, size: 64, color: AppColors.goldPrimary),
              const SizedBox(height: 16),
              Text(
                l10n.noLessonsAvailable,
                style: GoogleFonts.readexPro(
                  color: AppColors.goldPrimary,
                  fontSize: 18,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: context.appTheme.scaffoldBackground,
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            // Video Player Section
            _buildVideoSection(lesson),

            // Lesson Info Section
            Expanded(
              child: _buildLessonInfo(lesson),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildVideoSection(Map<String, dynamic> lesson) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      color: Colors.black,
      child: Column(
        children: [
          // Header
          Container(
            padding: EdgeInsets.only(
              top: MediaQuery.of(context).padding.top + 8,
              left: 16,
              right: 16,
              bottom: 8,
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.pop(),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.arrow_back_ios_new_rounded,
                        color: Colors.white, size: 18),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        lesson['title'] as String? ?? l10n.lesson,
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        _lessonDurationLabel(_mergedLessonData()),
                        style: GoogleFonts.readexPro(
                          fontSize: 12,
                          color: Colors.white60,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Video Player
          SizedBox(
            height: 220,
            child: _isVideoLoading
                ? Container(
                    color: Colors.black,
                    child: Center(
                      child: CircularProgressIndicator(
                        color: _theme.icon,
                      ),
                    ),
                  )
                : _controller != null
                    ? PodVideoPlayer(
                        controller: _controller!,
                        videoAspectRatio: 16 / 9,
                        podProgressBarConfig: PodProgressBarConfig(
                          playingBarColor: _theme.icon,
                          circleHandlerColor: _theme.icon,
                          bufferedBarColor: Colors.white30,
                        ),
                      )
                    : _useWebViewFallback && _webViewController != null
                        ? WebViewWidget(controller: _webViewController!)
                        : Container(
                            color: Colors.black,
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.error_outline,
                                      color: Colors.white54, size: 48),
                                  const SizedBox(height: 12),
                                  Text(
                                    isAr
                                        ? 'لا يمكن تحميل الفيديو'
                                        : 'Unable to load video',
                                    style: GoogleFonts.readexPro(
                                      color: Colors.white54,
                                      fontSize: 14,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _buildLessonInfo(Map<String, dynamic> lesson) {
    final l10n = AppLocalizations.of(context)!;
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    return Container(
      decoration: BoxDecoration(
        color: _theme.card,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
        border: Border(top: BorderSide(color: _theme.cardBorder)),
      ),
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Drag Handle
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: _theme.progressTrack,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Lesson Title & Stats
            Text(
              lesson['title'] as String? ?? l10n.lesson,
              style: GoogleFonts.readexPro(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: _theme.cardTitle,
              ),
            ),
            const SizedBox(height: 12),

            // Stats Row
            Row(
              children: [
                _buildStatBadge(Icons.access_time_rounded,
                    _lessonDurationLabel(_mergedLessonData())),
                if (_watchProgressPercent > 0) ...[
                  const SizedBox(width: 12),
                  _buildStatBadge(
                    Icons.play_circle_outline_rounded,
                    isAr
                        ? '$_watchProgressPercent%'
                        : '$_watchProgressPercent%',
                  ),
                ],
              ],
            ),
            const SizedBox(height: 24),

            // Description Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _theme.cardMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _theme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: _theme.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _theme.progressTrack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _theme.cardAccentText.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.description_rounded,
                          color: _theme.icon,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isAr ? 'وصف الدرس' : 'Lesson Description',
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _theme.cardTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isLoadingContent
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: _theme.icon,
                            ),
                          ),
                        )
                      : Text(
                          _lessonContent?['description'] as String? ??
                              (isAr
                                  ? 'لا يوجد وصف متاح'
                                  : 'No description available'),
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            color: _theme.cardMetaText,
                            height: 1.7,
                          ),
                        ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            if (_allowOfflineDownload) ...[
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: _theme.cardMuted,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _theme.cardBorder),
                  boxShadow: [
                    BoxShadow(
                      color: _theme.shadow,
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: _theme.progressTrack,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color:
                                  _theme.cardAccentText.withValues(alpha: 0.35),
                            ),
                          ),
                          child: Icon(
                            Icons.download_rounded,
                            color: _theme.icon,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          l10n.watchOffline,
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: _theme.cardTitle,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    if (_isDownloading)
                      Column(
                        children: [
                          LinearProgressIndicator(
                            value: _downloadProgress / 100,
                            backgroundColor: _theme.progressTrack,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              _theme.icon,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            '${l10n.downloading} $_downloadProgress%',
                            style: GoogleFonts.readexPro(
                              fontSize: 14,
                              color: _theme.cardMetaText,
                            ),
                          ),
                        ],
                      )
                    else if (_isDownloaded)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.goldPrimary.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _theme.cardAccentText.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.check_circle,
                              color: _theme.icon,
                              size: 20,
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                l10n.downloadLinkObtained,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.readexPro(
                                  fontSize: 14,
                                  color: _theme.cardAccentText,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
                      )
                    else
                      ElevatedButton.icon(
                        onPressed: _handleDownload,
                        icon: const Icon(
                          Icons.download,
                          color: AppColors.navyDeep,
                        ),
                        label: Text(
                          l10n.download,
                          style: GoogleFonts.readexPro(
                            color: AppColors.navyDeep,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _theme.icon,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 24,
                            vertical: 12,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],

            // Resources Card
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: _theme.cardMuted,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _theme.cardBorder),
                boxShadow: [
                  BoxShadow(
                    color: _theme.shadow,
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: _theme.progressTrack,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                _theme.cardAccentText.withValues(alpha: 0.35),
                          ),
                        ),
                        child: Icon(
                          Icons.folder_rounded,
                          color: _theme.icon,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        isAr ? 'ملفات الدرس' : 'Lesson Files',
                        style: GoogleFonts.readexPro(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: _theme.cardTitle,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _isLoadingContent
                      ? Center(
                          child: Padding(
                            padding: const EdgeInsets.all(20.0),
                            child: CircularProgressIndicator(
                              color: _theme.icon,
                            ),
                          ),
                        )
                      : _buildResourcesList(),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Navigation Buttons
            Row(
              children: [
                Expanded(
                  child: _buildNavButton(
                    l10n.previousLesson,
                    Icons.arrow_forward_rounded,
                    false,
                    () => _navigateToAdjacentLesson(-1),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 1,
                  child: _buildNavButton(
                    l10n.nextLesson,
                    Icons.arrow_back_rounded,
                    true,
                    () => _navigateToAdjacentLesson(1),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildStatBadge(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _theme.progressTrack,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _theme.cardBorder),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: _theme.icon),
          const SizedBox(width: 6),
          Text(
            text,
            style: GoogleFonts.readexPro(
              fontSize: 12,
              color: _theme.cardMetaText,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResourcesList() {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final resources = _lessonContent?['resources'] as List?;
    final contentPdf = _lessonContent?['content_pdf'] as String?;

    // Build list of resources
    final List<Map<String, dynamic>> resourceList = [];

    // Add PDF if available
    if (contentPdf != null && contentPdf.isNotEmpty) {
      resourceList.add({
        'title': isAr ? 'ملف PDF - ملخص الدرس' : 'PDF File - Lesson Summary',
        'url': contentPdf,
        'type': 'pdf',
        'icon': Icons.picture_as_pdf,
        'isPdf': true,
      });
    }

    // Add resources from API
    if (resources != null && resources.isNotEmpty) {
      for (var resource in resources) {
        if (resource is Map<String, dynamic>) {
          final title = resource['title']?.toString() ??
              resource['name']?.toString() ??
              'ملف مرفق';
          final url =
              resource['url']?.toString() ?? resource['file']?.toString() ?? '';
          final type = (resource['type']?.toString() ??
                  resource['file_type']?.toString() ??
                  '')
              .toLowerCase();

          IconData icon = Icons.insert_drive_file;
          if (type.contains('pdf')) {
            icon = Icons.picture_as_pdf;
          } else if (type.contains('zip') || type.contains('rar')) {
            icon = Icons.folder_zip;
          } else if (type.contains('image')) {
            icon = Icons.image;
          } else if (type.contains('video')) {
            icon = Icons.video_file;
          }

          final isPdfRes = type.contains('pdf') ||
              url.toLowerCase().contains('.pdf') ||
              icon == Icons.picture_as_pdf;

          resourceList.add({
            'title': title,
            'url': url,
            'type': type,
            'icon': icon,
            'size': resource['size']?.toString() ?? '',
            'isPdf': isPdfRes,
          });
        }
      }
    }

    if (resourceList.isEmpty) {
      return Padding(
        padding: const EdgeInsets.all(20.0),
        child: Center(
          child: Text(
            'لا توجد ملفات متاحة',
            style: GoogleFonts.readexPro(
              fontSize: 14,
              color: _theme.cardMetaText,
            ),
          ),
        ),
      );
    }

    return Column(
      children: resourceList.asMap().entries.map((entry) {
        final index = entry.key;
        final resource = entry.value;
        return Column(
          children: [
            _buildResourceItem(
              resource['title'] as String,
              resource['size'] as String? ?? '',
              resource['icon'] as IconData,
              resource['url'] as String? ?? '',
              isPdf: resource['isPdf'] == true,
            ),
            if (index < resourceList.length - 1) const SizedBox(height: 10),
          ],
        );
      }).toList(),
    );
  }

  Future<void> _handleDownload() async {
    if (!_allowOfflineDownload) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.downloadLinkUnavailable,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }
    final lesson = widget.lesson;
    if (lesson == null) return;

    final lessonId = lesson['id']?.toString();
    final courseId = widget.courseId ?? lesson['course_id']?.toString();
    final title = lesson['title']?.toString() ?? 'فيديو';
    final description = lesson['description']?.toString() ?? '';

    if (lessonId == null || courseId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن تحميل هذا الفيديو',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    // التحقق من الصلاحيات
    final hasPermission = await _downloadService.hasStoragePermission();
    if (!hasPermission) {
      final granted = await _downloadService.requestPermission();
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يجب منح صلاحيات التخزين لتحميل الفيديوهات',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }

    // الحصول على رابط الفيديو (نفس منطق التشغيل، مع تنظيف الرابط)
    String? rawVideoUrl = _lessonContent?['video']?['url']?.toString() ??
        lesson['video_url']?.toString() ??
        lesson['video']?['url']?.toString();

    final videoUrl = _cleanVideoUrl(rawVideoUrl);

    if (videoUrl == null || videoUrl.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رابط فيديو للتحميل',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() {
      _isDownloading = true;
      _downloadProgress = 0;
    });

    try {
      // الحصول على عنوان الكورس
      String? courseTitle;
      try {
        final courseDetails =
            await CoursesService.instance.getCourseDetails(courseId);
        courseTitle = courseDetails['title']?.toString();
      } catch (e) {
        print('Error getting course title: $e');
      }
      if (videoUrl.contains('youtube.com') || videoUrl.contains('youtu.be')) {
        // File name = video title only
        final safeTitle = title.replaceAll(RegExp(r'[\\/:*?"<>|]'), '_').trim();
        final fileName = '${safeTitle.isEmpty ? 'video' : safeTitle}.mp4';

        final localPath =
            await YoutubeVideoService.instance.downloadYoutubeVideo(
          videoUrl,
          fileName: fileName,
          onProgress: (progress) {
            if (mounted) {
              setState(() => _downloadProgress = progress);
            }
          },
        );

        if (localPath != null) {
          // Save to database so it appears in Downloads screen (like server downloads)
          // title = lecture title (main display), courseTitle = course for grouping
          final videoId = await _downloadService.saveDownloadedVideoRecord(
            lessonId: lessonId,
            courseId: courseId,
            title: title,
            videoUrl: videoUrl,
            localPath: localPath,
            courseTitle: courseTitle ?? 'كورس $courseId',
            description: description.isNotEmpty ? description : title,
            durationText: _lessonDurationLabel(lesson),
            videoSource: 'youtube',
          );

          if (kDebugMode && videoId != null) {
            log('YouTube video saved to database: $videoId');
          }

          if (mounted) {
            setState(() {
              _isDownloading = false;
              _isDownloaded = true;
              _downloadProgress = 0;
            });

            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'تم تحميل الفيديو بنجاح',
                  style: GoogleFonts.readexPro(),
                ),
                backgroundColor: Colors.green,
              ),
            );
          }
        } else {
          if (mounted) {
            setState(() {
              _isDownloading = false;
              _downloadProgress = 0;
            });
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'فشل تحميل الفيديو',
                  style: GoogleFonts.readexPro(),
                ),
                backgroundColor: Colors.red,
              ),
            );
          }
        }
        return;
      }

      final videoId = await _downloadService.downloadVideoWithManager(
        videoUrl: videoUrl,
        lessonId: lessonId,
        courseId: courseId,
        title: title,
        courseTitle: courseTitle,
        description: description,
        onProgress: (progress) {
          if (mounted) {
            setState(() {
              _downloadProgress = progress;
            });
          }
        },
      );

      if (videoId != null) {
        if (mounted) {
          setState(() {
            _isDownloading = false;
            _isDownloaded = true;
            _downloadProgress = 0;
          });

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'تم تحميل الفيديو بنجاح',
                style: GoogleFonts.readexPro(),
              ),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else {
        throw Exception('فشل تحميل الفيديو');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isDownloading = false;
          _downloadProgress = 0;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في تحميل الفيديو: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _handlePdfDownload(String rawUrl, String displayTitle) async {
    if (!_allowOfflineDownload) {
      if (mounted) {
        final l10n = AppLocalizations.of(context)!;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              l10n.downloadLinkUnavailable,
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
      }
      return;
    }

    final lesson = widget.lesson;
    if (lesson == null) return;
    final lessonId = lesson['id']?.toString();
    final courseId = widget.courseId ?? lesson['course_id']?.toString();
    final description = lesson['description']?.toString() ?? '';

    if (lessonId == null || courseId == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يمكن تحميل هذا الملف',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final pdfUrl = _cleanVideoUrl(rawUrl);
    if (pdfUrl == null || pdfUrl.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'لا يوجد رابط صالح لتحميل الملف',
            style: GoogleFonts.readexPro(),
          ),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    final hasPermission = await _downloadService.hasStoragePermission();
    if (!mounted) return;
    if (!hasPermission) {
      final granted = await _downloadService.requestPermission();
      if (!mounted) return;
      if (!granted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'يجب منح صلاحيات التخزين لتحميل الملفات',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
    }
    if (!mounted) return;

    setState(() {
      _pdfDownloadingUrl = pdfUrl;
      _pdfDownloadProgress = 0;
    });

    try {
      String? courseTitle;
      try {
        final courseDetails =
            await CoursesService.instance.getCourseDetails(courseId);
        courseTitle = courseDetails['title']?.toString();
      } catch (e) {
        print('Error getting course title: $e');
      }

      if (!mounted) return;

      final id = await _downloadService.downloadPdfWithManager(
        pdfUrl: pdfUrl,
        lessonId: lessonId,
        courseId: courseId,
        title: displayTitle,
        courseTitle: courseTitle,
        description: description.isNotEmpty ? description : displayTitle,
        onProgress: (p) {
          if (mounted) {
            setState(() => _pdfDownloadProgress = p);
          }
        },
      );

      if (mounted) {
        setState(() {
          _pdfDownloadingUrl = null;
          _pdfDownloadProgress = 0;
        });
      }

      if (id != null && mounted) {
        setState(() {
          _pdfDownloadedByUrl = {..._pdfDownloadedByUrl, pdfUrl: true};
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'تم تحميل ملف PDF بنجاح',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'فشل تحميل الملف',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _pdfDownloadingUrl = null;
          _pdfDownloadProgress = 0;
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'خطأ في التحميل: ${e.toString().replaceFirst('Exception: ', '')}',
              style: GoogleFonts.readexPro(),
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Widget _buildResourceItem(
    String title,
    String size,
    IconData icon,
    String url, {
    bool isPdf = false,
  }) {
    final normalizedUrl = url.isNotEmpty ? (_cleanVideoUrl(url) ?? url) : '';
    final effectivePdf = isPdf && normalizedUrl.isNotEmpty;
    final pdfSaved =
        effectivePdf && (_pdfDownloadedByUrl[normalizedUrl] == true);
    final pdfBusy = effectivePdf && _pdfDownloadingUrl == normalizedUrl;

    void openPdf() {
      final openUrl = _cleanVideoUrl(url) ?? url;
      if (openUrl.isEmpty) return;
      context.push(
        RouteNames.pdfViewer,
        extra: {
          'pdfUrl': openUrl,
          'title': title,
        },
      );
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _theme.card,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _theme.cardBorder),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: InkWell(
              onTap: url.isEmpty
                  ? null
                  : () {
                      if (kDebugMode) {
                        print('Opening resource: $url');
                      }
                      if (effectivePdf) {
                        openPdf();
                      }
                    },
              borderRadius: BorderRadius.circular(10),
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: effectivePdf
                            ? AppColors.goldPrimary.withValues(alpha: 0.12)
                            : _theme.progressTrack,
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: effectivePdf
                              ? _theme.cardAccentText.withValues(alpha: 0.3)
                              : _theme.cardBorder,
                        ),
                      ),
                      child: Icon(
                        icon,
                        color: effectivePdf ? _theme.icon : _theme.iconMuted,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.readexPro(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: _theme.cardTitle,
                            ),
                          ),
                          if (size.isNotEmpty && !pdfBusy)
                            Text(
                              size,
                              style: GoogleFonts.readexPro(
                                fontSize: 11,
                                color: _theme.cardMetaText,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (effectivePdf && _allowOfflineDownload) ...[
            const SizedBox(width: 8),
            if (pdfBusy)
              SizedBox(
                width: 36,
                height: 36,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  value: _pdfDownloadProgress / 100,
                  color: _theme.icon,
                ),
              )
            else if (pdfSaved)
              Icon(Icons.check_circle_rounded, color: _theme.icon, size: 28)
            else
              IconButton(
                tooltip: 'تحميل',
                onPressed: () => _handlePdfDownload(url, title),
                icon: const Icon(Icons.download_rounded),
                color: _theme.icon,
              ),
          ] else if (effectivePdf) ...[
            const SizedBox(width: 8),
            Icon(Icons.preview_rounded, color: _theme.icon, size: 22),
          ],
        ],
      ),
    );
  }

  Widget _buildNavButton(
      String text, IconData icon, bool isPrimary, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          gradient: isPrimary
              ? const LinearGradient(
                  colors: [AppColors.goldLight, AppColors.goldPrimary],
                )
              : null,
          color: isPrimary ? null : _theme.card,
          borderRadius: BorderRadius.circular(16),
          border: isPrimary ? null : Border.all(color: _theme.cardBorder),
          boxShadow: isPrimary
              ? [
                  BoxShadow(
                    color: _theme.shadow,
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!isPrimary) Icon(icon, size: 18, color: _theme.icon),
            if (!isPrimary) const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isPrimary ? AppColors.navyDeep : _theme.cardTitle,
              ),
            ),
            if (isPrimary) const SizedBox(width: 8),
            if (isPrimary) Icon(icon, size: 18, color: AppColors.navyDeep),
          ],
        ),
      ),
    );
  }
}
