import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/design/app_colors.dart';
import '../../core/api/api_endpoints.dart';
import '../../core/navigation/route_names.dart';
import '../../services/app_config_service.dart';
import '../../services/chat_service.dart';
import '../../services/teacher_dashboard_service.dart';
import '../../services/teachers_service.dart';
import '../../services/token_storage_service.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';

/// Chat conversations list – WhatsApp-style, app colors.
/// For both teachers and students.
class ChatConversationsScreen extends StatefulWidget {
  const ChatConversationsScreen({super.key});

  @override
  State<ChatConversationsScreen> createState() =>
      _ChatConversationsScreenState();
}

class _ChatConversationsScreenState extends State<ChatConversationsScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];

  @override
  void initState() {
    super.initState();
    _loadConversations();
  }

  Future<void> _loadConversations() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final res = await ChatService.instance.getConversations();
      final list = res['conversations'] ?? res['data'] ?? res['items'];
      final convs = list is List
          ? list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _conversations = convs;
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceFirst('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = AppThemeExtension.of(context);
    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        title: Text(
          isAr ? 'المحادثات' : 'Chat',
          style: GoogleFonts.readexPro(
            fontWeight: FontWeight.bold,
            color: AppColors.goldPrimary,
          ),
        ),
        backgroundColor: AppColors.navyMid,
        foregroundColor: AppColors.goldPrimary,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded,
              color: AppColors.goldPrimary),
          onPressed: () => context.pop(),
        ),
      ),
      body: _loading
          ? Center(child: CircularProgressIndicator(color: theme.icon))
          : _error != null
              ? _buildError(isAr)
              : _conversations.isEmpty
                  ? _buildEmpty(isAr)
                  : RefreshIndicator(
                      onRefresh: _loadConversations,
                      child: ListView.builder(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        itemCount: _conversations.length,
                        itemBuilder: (_, i) => _buildConversationTile(
                          _conversations[i],
                          isAr,
                        ),
                      ),
                    ),
      floatingActionButton: FloatingActionButton(
        onPressed: _openNewChatSheet,
        backgroundColor: theme.icon,
        child: const Icon(Icons.add_comment_rounded, color: AppColors.navyDeep),
      ),
    );
  }

  /// Opens the "new chat" contact picker. When a conversation is started it
  /// navigates straight into the messages screen, then reloads the list.
  Future<void> _openNewChatSheet() async {
    final result = await showModalBottomSheet<Map<String, dynamic>>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _NewChatPickerSheet(),
    );
    if (!mounted || result == null) return;
    final convId = result['conversationId']?.toString() ?? '';
    if (convId.isEmpty) return;
    await context.push(
      '/chat/$convId',
      extra: {
        'conversationId': convId,
        'otherUser': result['otherUser'],
        'conversation': result['conversation'],
      },
    );
    if (mounted) {
      _loadConversations();
    }
  }

  Widget _buildError(bool isAr) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: AppColors.destructive),
            const SizedBox(height: 16),
            Text(
              _error ?? '',
              textAlign: TextAlign.center,
              style: GoogleFonts.readexPro(
                fontSize: 14,
                color: context.cardMetaText,
              ),
            ),
            const SizedBox(height: 16),
            TextButton.icon(
              onPressed: _loadConversations,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(isAr ? 'إعادة المحاولة' : 'Retry',
                  style: GoogleFonts.readexPro()),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty(bool isAr) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.chat_bubble_outline_rounded,
              size: 64, color: context.appTheme.icon.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            isAr ? 'لا توجد محادثات' : 'No conversations yet',
            style: GoogleFonts.readexPro(
              fontSize: 16,
              color: context.cardMetaText,
            ),
          ),
          const SizedBox(height: 16),
          TextButton.icon(
            onPressed: _openNewChatSheet,
            icon:
                Icon(Icons.add_comment_outlined, color: context.appTheme.icon),
            label: Text(
              isAr ? 'ابدأ محادثة جديدة' : 'Start a new chat',
              style: GoogleFonts.readexPro(
                fontWeight: FontWeight.bold,
                color: context.appTheme.icon,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConversationTile(Map<String, dynamic> conv, bool isAr) {
    final other =
        conv['otherUser'] ?? conv['participant'] ?? conv['user'] ?? {};
    final otherMap =
        other is Map ? Map<String, dynamic>.from(other) : <String, dynamic>{};
    final name = otherMap['name'] ??
        otherMap['userName'] ??
        conv['otherUserName'] ??
        (isAr ? 'مستخدم' : 'User');
    final avatar = otherMap['avatar'];
    final lastMsg = conv['lastMessage'] ?? conv['last_message'];
    final lastBody = lastMsg is Map
        ? (lastMsg['body'] ?? lastMsg['text'] ?? '')
        : lastMsg?.toString() ?? '';
    final lastTime =
        lastMsg is Map ? (lastMsg['createdAt'] ?? lastMsg['created_at']) : null;
    final unread = conv['unreadCount'] ?? conv['unread_count'] ?? 0;
    final unreadNum = unread is num ? unread.toInt() : 0;
    final conversationId = conv['id']?.toString() ?? '';

    return InkWell(
      onTap: () async {
        if (conversationId.isEmpty) return;
        await context.push(
          RouteNames.chatMessages.replaceAll(':conversationId', conversationId),
          extra: {
            'conversationId': conversationId,
            'otherUser': otherMap,
            'conversation': conv,
          },
        );
        if (mounted) {
          _loadConversations();
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
        decoration: BoxDecoration(
          color: context.appTheme.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.appTheme.cardBorder),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: context.appTheme.progressTrack,
              backgroundImage: avatar != null && avatar.toString().isNotEmpty
                  ? NetworkImage(ApiEndpoints.getImageUrl(avatar.toString()))
                  : null,
              child: avatar == null || avatar.toString().isEmpty
                  ? Text(
                      (name.toString().isNotEmpty ? name[0] : '?')
                          .toUpperCase(),
                      style: GoogleFonts.readexPro(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: context.appTheme.icon,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          name.toString(),
                          style: GoogleFonts.readexPro(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: context.appTheme.cardTitle,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (lastTime != null)
                        Text(
                          _formatTime(lastTime.toString()),
                          style: GoogleFonts.readexPro(
                            fontSize: 12,
                            color: context.appTheme.cardMetaText
                                .withValues(alpha: 0.75),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          lastBody.toString(),
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            color: context.appTheme.cardMetaText,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (unreadNum > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: context.appTheme.icon,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            unreadNum > 99 ? '99+' : '$unreadNum',
                            style: GoogleFonts.readexPro(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: AppColors.navyDeep,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatTime(String iso) {
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return iso;
      final now = DateTime.now();
      final diff = now.difference(dt);
      if (diff.inDays == 0) {
        return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
      } else if (diff.inDays == 1) {
        return 'Yesterday';
      } else if (diff.inDays < 7) {
        return '${diff.inDays}d';
      }
      return '${dt.day}/${dt.month}';
    } catch (_) {
      return iso;
    }
  }
}

/// Bottom sheet that lists the people the current user can start a chat with.
/// Students see teachers (/api/teachers); teachers see their enrolled
/// students (aggregated across their courses). Returns
/// `{conversationId, conversation, otherUser}` via Navigator.pop on success.
class _NewChatPickerSheet extends StatefulWidget {
  const _NewChatPickerSheet();

  @override
  State<_NewChatPickerSheet> createState() => _NewChatPickerSheetState();
}

class _NewChatPickerSheetState extends State<_NewChatPickerSheet> {
  bool _loading = true;
  String? _error;
  bool _isTeacher = false;
  List<Map<String, dynamic>> _contacts = [];
  String _query = '';
  String _busyUserId = '';

  /// Backend user id of the support/admin account from app config — when
  /// present a pinned "Contact support" tile is shown above the contacts.
  String _supportUserId = '';

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final role =
          (await TokenStorageService.instance.getUserRole())?.toLowerCase() ??
              'student';
      _isTeacher = role == 'instructor' || role == 'teacher';

      final supportIdFuture = role == 'admin'
          ? Future.value('')
          : AppConfigService.instance
              .getAppConfig()
              .then((c) => c.support.adminUserId)
              .catchError((_) => '');

      final contacts =
          _isTeacher ? await _loadStudents() : await _loadTeachers();
      final supportId = await supportIdFuture;
      if (!mounted) return;
      setState(() {
        _contacts = contacts;
        _supportUserId = supportId;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  /// Contacts the student can chat with — all teachers.
  Future<List<Map<String, dynamic>>> _loadTeachers() async {
    final res = await TeachersService.instance.getTeachers(perPage: 50);
    final data = res['data'];
    final raw = data is Map
        ? (data['teachers'] ?? data['items'] ?? const [])
        : (data is List ? data : const []);
    if (raw is! List) return const [];
    return raw
        .whereType<Map>()
        .map((t) => Map<String, dynamic>.from(t))
        .map((m) => <String, dynamic>{
              'id': (m['id'] ?? m['userId'] ?? m['user_id'])?.toString() ?? '',
              'name':
                  (m['name'] ?? m['fullName'] ?? m['userName'])?.toString() ??
                      '',
              'avatar': m['avatar']?.toString(),
              'subtitle':
                  (m['specialty'] ?? m['subject'] ?? m['title'])?.toString() ??
                      '',
              'raw': m,
            })
        .where((c) => (c['id'] as String).isNotEmpty)
        .toList();
  }

  /// Contacts the teacher can chat with — students enrolled in their courses.
  Future<List<Map<String, dynamic>>> _loadStudents() async {
    final userId = await TokenStorageService.instance.getCurrentUserId();
    final coursesData = await TeacherDashboardService.instance
        .getMyCourses(instructorId: userId, limit: 50);
    final rawCourses =
        coursesData['data'] ?? coursesData['courses'] ?? coursesData;
    final courses = rawCourses is List
        ? rawCourses
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList()
        : <Map<String, dynamic>>[];

    final perCourse = await Future.wait(courses.map((c) async {
      final cid = c['id']?.toString() ?? '';
      if (cid.isEmpty) return <Map<String, dynamic>>[];
      try {
        final det =
            await TeacherDashboardService.instance.getCourseDetails(cid);
        final students = det['students'];
        if (students is! List) return <Map<String, dynamic>>[];
        return students
            .whereType<Map>()
            .map((e) => Map<String, dynamic>.from(e))
            .toList();
      } catch (_) {
        return <Map<String, dynamic>>[];
      }
    }));

    final seen = <String>{};
    final contacts = <Map<String, dynamic>>[];
    for (final students in perCourse) {
      for (final s in students) {
        final user = s['user'] is Map
            ? Map<String, dynamic>.from(s['user'] as Map)
            : <String, dynamic>{};
        final student = s['student'] is Map
            ? Map<String, dynamic>.from(s['student'] as Map)
            : <String, dynamic>{};
        final src = <String, dynamic>{...s, ...student, ...user};
        final id =
            (src['id'] ?? src['userId'] ?? src['user_id'])?.toString() ?? '';
        if (id.isEmpty || !seen.add(id)) continue;
        contacts.add(<String, dynamic>{
          'id': id,
          'name':
              (src['name'] ?? src['fullName'] ?? src['userName'])?.toString() ??
                  '',
          'avatar': src['avatar']?.toString(),
          'subtitle': (src['email'] ?? src['phone'])?.toString() ?? '',
          'raw': src,
        });
      }
    }
    return contacts;
  }

  List<Map<String, dynamic>> get _filtered {
    final q = _query.trim().toLowerCase();
    if (q.isEmpty) return _contacts;
    return _contacts.where((c) {
      return c['name'].toString().toLowerCase().contains(q) ||
          c['subtitle'].toString().toLowerCase().contains(q);
    }).toList();
  }

  Future<void> _startChat(Map<String, dynamic> contact) async {
    final id = contact['id']?.toString() ?? '';
    if (id.isEmpty || _busyUserId.isNotEmpty) return;
    setState(() => _busyUserId = id);
    try {
      final conv = await ChatService.instance.createOrGetConversation(id);
      final convId =
          conv['id']?.toString() ?? conv['conversationId']?.toString();
      if (convId == null || convId.isEmpty) {
        throw Exception('Missing conversation id');
      }
      if (!mounted) return;
      Navigator.of(context).pop({
        'conversationId': convId,
        'conversation': conv,
        'otherUser': contact['raw'] ?? contact,
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _busyUserId = '';
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final theme = AppThemeExtension.of(context);
    final contacts = _filtered;

    return Padding(
      padding:
          EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        height: MediaQuery.of(context).size.height * 0.78,
        decoration: BoxDecoration(
          color: theme.card,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: SafeArea(
          top: false,
          child: Column(
            children: [
              const SizedBox(height: 10),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: theme.cardBorder,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                isAr ? 'محادثة جديدة' : 'New chat',
                style: GoogleFonts.readexPro(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: theme.cardTitle,
                ),
              ),
              const SizedBox(height: 12),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: TextField(
                  onChanged: (v) => setState(() => _query = v),
                  style: GoogleFonts.readexPro(
                    fontSize: 14,
                    color: theme.cardTitle,
                  ),
                  decoration: InputDecoration(
                    hintText: isAr ? 'ابحث بالاسم...' : 'Search by name...',
                    hintStyle: GoogleFonts.readexPro(
                      fontSize: 14,
                      color: theme.cardMetaText,
                    ),
                    prefixIcon: Icon(Icons.search_rounded, color: theme.icon),
                    filled: true,
                    fillColor: theme.cardMuted,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: BorderSide.none,
                    ),
                    contentPadding: const EdgeInsets.symmetric(
                        vertical: 12, horizontal: 16),
                  ),
                ),
              ),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
                  child: Text(
                    _error!,
                    textAlign: TextAlign.center,
                    style: GoogleFonts.readexPro(
                      fontSize: 13,
                      color: AppColors.destructive,
                    ),
                  ),
                ),
              const SizedBox(height: 8),
              Expanded(
                child: Column(
                  children: [
                    if (_supportUserId.isNotEmpty) ...[
                      _buildSupportTile(isAr, theme),
                      Divider(
                        height: 1,
                        indent: 16,
                        endIndent: 16,
                        color: theme.cardBorder,
                      ),
                    ],
                    Expanded(
                      child: _loading
                          ? Center(
                              child:
                                  CircularProgressIndicator(color: theme.icon))
                          : contacts.isEmpty
                              ? Center(
                                  child: Padding(
                                    padding: const EdgeInsets.all(24),
                                    child: Text(
                                      _isTeacher
                                          ? (isAr
                                              ? 'لا يوجد طلاب في كورساتك بعد'
                                              : 'No students in your courses yet')
                                          : (isAr
                                              ? 'لا يوجد مدرسين متاحين'
                                              : 'No teachers available'),
                                      textAlign: TextAlign.center,
                                      style: GoogleFonts.readexPro(
                                        fontSize: 14,
                                        color: theme.cardMetaText,
                                      ),
                                    ),
                                  ),
                                )
                              : ListView.separated(
                                  padding:
                                      const EdgeInsets.fromLTRB(8, 0, 8, 16),
                                  itemCount: contacts.length,
                                  separatorBuilder: (_, __) =>
                                      const SizedBox(height: 4),
                                  itemBuilder: (_, i) {
                                    final c = contacts[i];
                                    final name = c['name'].toString();
                                    final avatar =
                                        c['avatar']?.toString() ?? '';
                                    final busy = _busyUserId == c['id'];
                                    return ListTile(
                                      onTap: () => _startChat(c),
                                      leading: CircleAvatar(
                                        radius: 22,
                                        backgroundColor: theme.progressTrack,
                                        backgroundImage: avatar.isNotEmpty
                                            ? NetworkImage(
                                                ApiEndpoints.getImageUrl(
                                                    avatar))
                                            : null,
                                        child: avatar.isEmpty
                                            ? Text(
                                                name.isNotEmpty
                                                    ? name[0].toUpperCase()
                                                    : '?',
                                                style: GoogleFonts.readexPro(
                                                  fontWeight: FontWeight.bold,
                                                  color: theme.icon,
                                                ),
                                              )
                                            : null,
                                      ),
                                      title: Text(
                                        name.isNotEmpty
                                            ? name
                                            : (isAr ? 'مستخدم' : 'User'),
                                        style: GoogleFonts.readexPro(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w600,
                                          color: theme.cardTitle,
                                        ),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                      subtitle: c['subtitle']
                                              .toString()
                                              .isNotEmpty
                                          ? Text(
                                              c['subtitle'].toString(),
                                              style: GoogleFonts.readexPro(
                                                fontSize: 12,
                                                color: theme.cardMetaText,
                                              ),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            )
                                          : null,
                                      trailing: busy
                                          ? SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(
                                                strokeWidth: 2,
                                                color: theme.icon,
                                              ),
                                            )
                                          : Icon(
                                              Icons.chat_bubble_outline_rounded,
                                              size: 20,
                                              color: theme.icon,
                                            ),
                                    );
                                  },
                                ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Pinned tile for the support/admin account — shown when the backend
  /// exposes `support.admin_user_id` via GET /api/config/app.
  Widget _buildSupportTile(bool isAr, AppThemeExtension theme) {
    final name = isAr ? 'الإدارة / الدعم' : 'Support team';
    final busy = _busyUserId == _supportUserId;
    return ListTile(
      onTap: () => _startChat(<String, dynamic>{
        'id': _supportUserId,
        'raw': <String, dynamic>{'id': _supportUserId, 'name': name},
      }),
      leading: CircleAvatar(
        radius: 22,
        backgroundColor: theme.icon.withValues(alpha: 0.15),
        child: Icon(Icons.support_agent_rounded, color: theme.icon),
      ),
      title: Text(
        name,
        style: GoogleFonts.readexPro(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: theme.cardTitle,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        isAr
            ? 'تواصل مباشر مع فريق الدعم'
            : 'Chat directly with our support team',
        style: GoogleFonts.readexPro(
          fontSize: 12,
          color: theme.cardMetaText,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      trailing: busy
          ? SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: theme.icon,
              ),
            )
          : Icon(
              Icons.chat_bubble_outline_rounded,
              size: 20,
              color: theme.icon,
            ),
    );
  }
}
