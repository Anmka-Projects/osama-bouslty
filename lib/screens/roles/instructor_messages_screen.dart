import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../core/api/api_endpoints.dart';
import '../../core/design/app_colors.dart';
import '../../core/navigation/route_names.dart';
import '../../services/chat_service.dart';
import '../../widgets/tutor_top_nav.dart';

/// Tutor "الرسائل" tab — reference design conversation list.
class InstructorMessagesScreen extends StatefulWidget {
  const InstructorMessagesScreen({super.key});

  @override
  State<InstructorMessagesScreen> createState() =>
      _InstructorMessagesScreenState();
}

class _InstructorMessagesScreenState
    extends State<InstructorMessagesScreen> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _conversations = [];

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
      final res = await ChatService.instance.getConversations();
      final list = res['conversations'] ?? res['data'] ?? res['items'];
      if (!mounted) return;
      setState(() {
        _conversations = list is List
            ? list
                .whereType<Map>()
                .map((e) => Map<String, dynamic>.from(e))
                .toList()
            : [];
        _loading = false;
      });
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
    return Scaffold(
      backgroundColor: AppColors.brandSand,
      body: Column(
        children: [
          const TutorTopNav(activeTab: 'messages'),
          Expanded(
            child: _loading
                ? const Center(
                    child: CircularProgressIndicator(strokeWidth: 2))
                : _error != null
                    ? _errorView()
                    : _conversations.isEmpty
                        ? _emptyView()
                        : RefreshIndicator(
                            onRefresh: _load,
                            child: ListView(
                              padding: const EdgeInsets.fromLTRB(
                                  18, 20, 18, 32),
                              children: [
                                _title(),
                                const SizedBox(height: 16),
                                ..._conversations.map(_tile),
                              ],
                            ),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _title() => Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('الرسائل',
                    style: GoogleFonts.readexPro(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink)),
                const SizedBox(height: 2),
                Text('محادثاتك مع الطلاب',
                    style: GoogleFonts.readexPro(
                        fontSize: 12, color: AppColors.inkMuted)),
              ],
            ),
          ),
          Icon(Icons.chat_bubble_outline_rounded,
              size: 20, color: AppColors.brandTeal),
        ],
      );

  Widget _tile(Map<String, dynamic> conv) {
    final other =
        conv['otherUser'] ?? conv['participant'] ?? conv['user'] ?? {};
    final otherMap =
        other is Map ? Map<String, dynamic>.from(other) : <String, dynamic>{};
    final name = (otherMap['name'] ??
            otherMap['userName'] ??
            conv['otherUserName'] ??
            'طالب')
        .toString();
    final avatar = otherMap['avatar'];
    final lastMsg = conv['lastMessage'] ?? conv['last_message'];
    final lastBody = (lastMsg is Map
            ? (lastMsg['body'] ?? lastMsg['text'] ?? '')
            : lastMsg?.toString() ?? '')
        .toString();
    final lastTime =
        lastMsg is Map ? (lastMsg['createdAt'] ?? lastMsg['created_at']) : null;
    final unreadRaw = conv['unreadCount'] ?? conv['unread_count'] ?? 0;
    final unread = unreadRaw is num ? unreadRaw.toInt() : 0;
    final conversationId = conv['id']?.toString() ?? '';

    return InkWell(
      onTap: () async {
        if (conversationId.isEmpty) return;
        await context.push(
          RouteNames.chatMessages
              .replaceAll(':conversationId', conversationId),
          extra: {
            'conversationId': conversationId,
            'otherUser': otherMap,
            'conversation': conv,
          },
        );
        if (mounted) _load();
      },
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 13),
        child: Row(
          children: [
            // chevron + time + unread badge (left in RTL = end side)
            Icon(Icons.chevron_left_rounded,
                size: 20, color: AppColors.inkSubtle),
            const SizedBox(width: 6),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (lastTime != null)
                  Text(
                    _formatTime(lastTime.toString()),
                    style: GoogleFonts.readexPro(
                        fontSize: 11, color: AppColors.inkMuted),
                  ),
                const SizedBox(height: 4),
                if (unread > 0)
                  Container(
                    width: 20,
                    height: 20,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: AppColors.brandSaffron,
                      shape: BoxShape.circle,
                    ),
                    child: Text(
                      unread > 99 ? '99' : '$unread',
                      style: GoogleFonts.readexPro(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white),
                    ),
                  )
                else
                  const SizedBox(height: 20),
              ],
            ),
            const SizedBox(width: 10),
            // name + last message
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    name,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.readexPro(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.ink),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    lastBody,
                    textAlign: TextAlign.end,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.readexPro(
                        fontSize: 12.5, color: AppColors.inkMuted),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            CircleAvatar(
              radius: 24,
              backgroundColor: AppColors.primarySoft,
              backgroundImage:
                  avatar != null && avatar.toString().isNotEmpty
                      ? NetworkImage(
                          ApiEndpoints.getImageUrl(avatar.toString()))
                      : null,
              child: avatar == null || avatar.toString().isEmpty
                  ? Icon(Icons.person_rounded,
                      size: 22, color: AppColors.brandTeal)
                  : null,
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptyView() => Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.chat_bubble_outline_rounded,
                size: 56,
                color: AppColors.inkSubtle.withValues(alpha: 0.4)),
            const SizedBox(height: 12),
            Text('لا توجد محادثات',
                style: GoogleFonts.readexPro(
                    fontSize: 15, color: AppColors.inkMuted)),
          ],
        ),
      );

  Widget _errorView() => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded,
                  size: 44, color: AppColors.destructive),
              const SizedBox(height: 12),
              Text(_error ?? '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.readexPro(
                      fontSize: 13, color: AppColors.inkMuted)),
              const SizedBox(height: 12),
              TextButton.icon(
                onPressed: _load,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text('إعادة المحاولة',
                    style: GoogleFonts.readexPro(fontSize: 13)),
              ),
            ],
          ),
        ),
      );

  String _formatTime(String iso) {
    try {
      final dt = DateTime.tryParse(iso);
      if (dt == null) return '';
      final local = dt.toLocal();
      final now = DateTime.now();
      final diff = now.difference(local);
      if (diff.inDays == 0) return DateFormat('HH:mm').format(local);
      if (diff.inDays == 1) return 'أمس';
      if (diff.inDays < 7) return DateFormat('EEEE', 'ar').format(local);
      return DateFormat('d/M').format(local);
    } catch (_) {
      return '';
    }
  }
}
