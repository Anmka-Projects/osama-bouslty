import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:record/record.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/design/app_colors.dart';
import '../../core/api/api_endpoints.dart';
import '../../services/chat_service.dart';
import '../../services/chat_websocket_service.dart';
import '../../services/profile_service.dart';
import '../../services/upload_service.dart';
import '../../core/design/app_theme_context.dart';
import '../../core/design/app_theme_extension.dart';

/// Chat messages screen – WhatsApp-style bubbles, app colors.
class ChatMessagesScreen extends StatefulWidget {
  final String conversationId;
  final Map<String, dynamic>? otherUser;
  final Map<String, dynamic>? conversation;

  const ChatMessagesScreen({
    super.key,
    required this.conversationId,
    this.otherUser,
    this.conversation,
  });

  @override
  State<ChatMessagesScreen> createState() => _ChatMessagesScreenState();
}

class _ChatMessagesScreenState extends State<ChatMessagesScreen> {
  final _controller = TextEditingController();
  final _scrollController = ScrollController();
  bool _loading = true;
  bool _sending = false;
  bool _uploading = false;
  bool _recording = false;
  DateTime? _recordingStartedAt;
  final _recorder = AudioRecorder();
  final _picker = ImagePicker();
  List<Map<String, dynamic>> _messages = [];
  String? _currentUserId;
  StreamSubscription<Map<String, dynamic>>? _wsSubscription;
  Timer? _pollTimer;

  @override
  void initState() {
    super.initState();
    _bootstrap();
  }

  /// Load profile first so [_currentUserId] is set before [_markIncomingMessagesAsRead] runs.
  Future<void> _bootstrap() async {
    await _loadUserId();
    if (!mounted) return;
    await _loadMessages();
    if (!mounted) return;
    _connectWebSocket();
    _startPolling();
  }

  void _connectWebSocket() {
    ChatWebSocketService.instance.connect(widget.conversationId);
    _wsSubscription = ChatWebSocketService.instance.onMessage.listen(
      (msg) {
        if (!mounted) return;
        final id = msg['id']?.toString();
        if (id == null || id.isEmpty) return;
        final exists = _messages.any((m) => m['id']?.toString() == id);
        if (exists) return;
        setState(() => _messages.add(msg));
        _scrollToBottom();
      },
      onError: (e) {
        // Connection/socket errors – avoid unhandled exceptions
      },
      cancelOnError: false,
    );
  }

  @override
  void dispose() {
    _pollTimer?.cancel();
    _wsSubscription?.cancel();
    ChatWebSocketService.instance.disconnect();
    _controller.dispose();
    _scrollController.dispose();
    _recorder.dispose();
    super.dispose();
  }

  Future<void> _pickAttachment(String type) async {
    if (_uploading || _recording) return;
    XFile? picked;
    if (type == 'image') {
      picked = await _picker.pickImage(
          source: ImageSource.gallery, imageQuality: 88);
    } else if (type == 'video') {
      picked = await _picker.pickVideo(
          source: ImageSource.gallery,
          maxDuration: const Duration(minutes: 10));
    }
    if (picked == null) return;
    await _sendAttachment(File(picked.path), type);
  }

  Future<void> _toggleVoiceRecording() async {
    if (_uploading) return;
    if (_recording) {
      final path = await _recorder.stop();
      final started = _recordingStartedAt;
      if (mounted) setState(() => _recording = false);
      if (path != null && path.isNotEmpty) {
        final seconds = started == null
            ? null
            : DateTime.now().difference(started).inSeconds.clamp(1, 3600);
        await _sendAttachment(File(path), 'audio', durationSeconds: seconds);
      }
      return;
    }
    if (!await _recorder.hasPermission()) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('اسمح باستخدام الميكروفون لإرسال تسجيل صوتي')),
        );
      }
      return;
    }
    final directory = await getTemporaryDirectory();
    final path =
        '${directory.path}/voice-${DateTime.now().millisecondsSinceEpoch}.m4a';
    await _recorder.start(const RecordConfig(encoder: AudioEncoder.aacLc),
        path: path);
    if (mounted) {
      setState(() {
        _recording = true;
        _recordingStartedAt = DateTime.now();
      });
    }
  }

  Future<void> _sendAttachment(File file, String type,
      {int? durationSeconds}) async {
    if (!mounted) return;
    setState(() => _uploading = true);
    try {
      final url = await UploadService.instance.uploadChatAttachment(file);
      final sent = await ChatService.instance.sendMessage(
        widget.conversationId,
        attachmentUrl: url,
        attachmentType: type,
        attachmentName: file.path.split(Platform.pathSeparator).last,
        attachmentSize: await file.length(),
        durationSeconds: durationSeconds,
      );
      if (!mounted) return;
      setState(() => _messages.add(sent));
      _scrollToBottom();
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  'تعذر إرسال المرفق: ${error.toString().replaceFirst('Exception: ', '')}')),
        );
      }
    } finally {
      if (mounted) setState(() => _uploading = false);
    }
  }

  void _showImagePreview(String imageUrl) {
    showDialog<void>(
      context: context,
      barrierColor: Colors.black,
      builder: (dialogContext) => Dialog.fullscreen(
        backgroundColor: Colors.black,
        child: Stack(
          children: [
            Positioned.fill(
              child: InteractiveViewer(
                minScale: 0.8,
                maxScale: 5,
                child: Center(
                  child: Image.network(
                    imageUrl,
                    fit: BoxFit.contain,
                    errorBuilder: (_, __, ___) => const Icon(
                      Icons.broken_image_outlined,
                      color: Colors.white70,
                      size: 56,
                    ),
                  ),
                ),
              ),
            ),
            SafeArea(
              child: Align(
                alignment: AlignmentDirectional.topStart,
                child: Padding(
                  padding: const EdgeInsets.all(8),
                  child: IconButton.filled(
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white,
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.black54,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showAttachmentPicker(bool isAr) {
    showModalBottomSheet<void>(
      context: context,
      builder: (sheetContext) => SafeArea(
        child: Wrap(
          children: [
            ListTile(
              leading: const Icon(Icons.image_outlined),
              title: Text(isAr ? 'إرسال صورة' : 'Send image'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment('image');
              },
            ),
            ListTile(
              leading: const Icon(Icons.video_library_outlined),
              title: Text(isAr ? 'إرسال فيديو' : 'Send video'),
              onTap: () {
                Navigator.pop(sheetContext);
                _pickAttachment('video');
              },
            ),
          ],
        ),
      ),
    );
  }

  /// Background refresh every 5 seconds – merges new messages without user notice.
  void _startPolling() {
    _pollTimer?.cancel();
    _pollTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      _refreshMessagesInBackground();
    });
  }

  Future<void> _refreshMessagesInBackground() async {
    if (_loading) return; // Skip during initial load
    try {
      final res = await ChatService.instance.getMessages(
        widget.conversationId,
        page: 1,
        limit: 100,
      );
      final raw = res['messages'] ?? res['data'] ?? res['items'] ?? [];
      final list = raw is List
          ? raw
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (!mounted) return;
      final existingIds =
          _messages.map((m) => m['id']?.toString()).whereType<String>().toSet();
      final newMessages = list.where((m) {
        final id = m['id']?.toString();
        return id != null && id.isNotEmpty && !existingIds.contains(id);
      }).toList();
      if (newMessages.isEmpty) return;
      // Merge: append new messages and sort by createdAt to preserve order
      final merged = [..._messages];
      for (final m in newMessages) {
        merged.add(m);
        existingIds.add(m['id']?.toString() ?? '');
      }
      merged.sort((a, b) {
        final aAt = a['createdAt'] ?? a['created_at'] ?? '';
        final bAt = b['createdAt'] ?? b['created_at'] ?? '';
        return (aAt.toString()).compareTo(bAt.toString());
      });
      if (mounted) {
        setState(() => _messages = merged);
        _markIncomingMessagesAsRead(newMessages);
      }
    } catch (_) {
      // Silent – user doesn't need to know about background refresh failures
    }
  }

  Future<void> _loadUserId() async {
    try {
      final profile = await ProfileService.instance.getProfile();
      final id = profile['id']?.toString() ??
          (profile['user'] as Map?)?['id']?.toString();
      if (mounted) {
        setState(() => _currentUserId = id);
        if (_messages.isNotEmpty) {
          _markIncomingMessagesAsRead(_messages);
        }
      }
    } catch (_) {}
  }

  Future<void> _loadMessages() async {
    setState(() => _loading = true);
    try {
      final res = await ChatService.instance.getMessages(widget.conversationId);
      final list = res['messages'] ?? res['data'] ?? res['items'] ?? [];
      final msgs = list is List
          ? list
              .whereType<Map>()
              .map((e) => Map<String, dynamic>.from(e))
              .toList()
          : <Map<String, dynamic>>[];
      if (mounted) {
        setState(() {
          _messages = msgs;
          _loading = false;
        });
        _scrollToBottom();
        _markIncomingMessagesAsRead(msgs);
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
      }
    }
  }

  String? _senderIdFromMessage(Map<String, dynamic> m) {
    final direct = m['senderId'] ?? m['sender_id'];
    if (direct != null) return direct.toString().trim();
    final sender = m['sender'];
    if (sender is Map) {
      return sender['id']?.toString().trim() ??
          sender['userId']?.toString().trim();
    }
    return null;
  }

  /// PATCH …/messages/:id/read – marks messages from the other participant as read (clears unread on server).
  void _markIncomingMessagesAsRead(List<Map<String, dynamic>> messages) {
    final myId = _currentUserId?.trim();
    if (myId == null || myId.isEmpty) return;
    final toMark = messages
        .where((m) {
          final sid = _senderIdFromMessage(m);
          if (sid == null || sid.isEmpty) return false;
          return sid != myId;
        })
        .map((m) => m['id']?.toString())
        .whereType<String>()
        .where((id) => id.isNotEmpty)
        .toList();
    if (toMark.isEmpty) return;
    // Limit to last 30 to avoid too many requests
    final ids =
        toMark.length > 30 ? toMark.sublist(toMark.length - 30) : toMark;
    for (final id in ids) {
      ChatService.instance.markMessageRead(id).catchError((_) {});
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Future<void> _sendMessage() async {
    final body = _controller.text.trim();
    if (body.isEmpty) return;
    _controller.clear();
    setState(() => _sending = true);

    final tempMsg = {
      'id': 'temp-${DateTime.now().millisecondsSinceEpoch}',
      'body': body,
      'senderId': _currentUserId,
      'createdAt': DateTime.now().toIso8601String(),
      'isSent': true,
    };
    setState(() {
      _messages.add(tempMsg);
      _sending = false;
    });
    _scrollToBottom();

    try {
      final sent = await ChatService.instance.sendMessage(
        widget.conversationId,
        body: body,
      );
      if (mounted) {
        final idx = _messages.indexWhere((m) => m['id'] == tempMsg['id']);
        if (idx >= 0) {
          setState(() {
            _messages[idx] = {
              ..._messages[idx],
              ...sent,
              'body': sent['body'] ?? _messages[idx]['body'],
              'id': sent['id'] ?? tempMsg['id'],
            };
          });
        }
        final note = sent['moderation_note']?.toString();
        if (note != null && note.isNotEmpty) {
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(note)));
        }
      }
    } catch (e) {
      if (mounted) {
        final idx = _messages.indexWhere((m) => m['id'] == tempMsg['id']);
        if (idx >= 0) {
          setState(() => _messages[idx]['failed'] = true);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = AppThemeExtension.of(context);
    final isAr = Localizations.localeOf(context).languageCode == 'ar';
    final other = widget.otherUser ?? {};
    final name =
        other['name'] ?? other['userName'] ?? (isAr ? 'مستخدم' : 'User');
    final avatar = other['avatar'];

    return Scaffold(
      backgroundColor: theme.scaffoldBackground,
      appBar: AppBar(
        title: Row(
          children: [
            CircleAvatar(
              radius: 18,
              backgroundColor: AppColors.goldPrimary.withValues(alpha: 0.2),
              backgroundImage: avatar != null && avatar.toString().isNotEmpty
                  ? NetworkImage(ApiEndpoints.getImageUrl(avatar.toString()))
                  : null,
              child: avatar == null || avatar.toString().isEmpty
                  ? Text(
                      (name.toString().isNotEmpty ? name[0] : '?')
                          .toUpperCase(),
                      style: GoogleFonts.readexPro(
                        fontWeight: FontWeight.bold,
                        color: AppColors.goldPrimary,
                      ),
                    )
                  : null,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                name.toString(),
                style: GoogleFonts.readexPro(
                  fontWeight: FontWeight.bold,
                  fontSize: 18,
                  color: AppColors.goldPrimary,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
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
      body: Column(
        children: [
          Expanded(
            child: _loading
                ? Center(child: CircularProgressIndicator(color: theme.icon))
                : _messages.isEmpty
                    ? Center(
                        child: Text(
                          isAr ? 'لا توجد رسائل بعد' : 'No messages yet',
                          style: GoogleFonts.readexPro(
                            fontSize: 14,
                            color: context.cardMetaText,
                          ),
                        ),
                      )
                    : ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(12),
                        itemCount: _messages.length,
                        itemBuilder: (_, i) =>
                            _buildMessageBubble(_messages[i], isAr),
                      ),
          ),
          _buildInputBar(isAr),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg, bool isAr) {
    final theme = AppThemeExtension.of(context);
    final body = msg['body']?.toString() ?? '';
    final senderId =
        msg['senderId']?.toString() ?? msg['sender_id']?.toString();
    final isMe = senderId == _currentUserId;
    final createdAt = msg['createdAt'] ?? msg['created_at'];
    final failed = msg['failed'] == true;
    final attachmentUrl =
        (msg['attachment_url'] ?? msg['attachmentUrl'])?.toString() ?? '';
    final attachmentType =
        (msg['attachment_type'] ?? msg['attachmentType'])?.toString() ?? '';
    final mediaUrl =
        attachmentUrl.isEmpty ? '' : ApiEndpoints.getImageUrl(attachmentUrl);

    return Align(
      alignment: isMe
          ? (isAr ? Alignment.centerRight : Alignment.centerRight)
          : (isAr ? Alignment.centerLeft : Alignment.centerLeft),
      child: Container(
        margin: EdgeInsets.only(
          bottom: 8,
          left: isMe ? 64 : 0,
          right: isMe ? 0 : 64,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMe ? theme.icon : theme.card,
          border: isMe ? null : Border.all(color: theme.cardBorder),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(16),
            topRight: const Radius.circular(16),
            bottomLeft: Radius.circular(isMe ? 16 : 4),
            bottomRight: Radius.circular(isMe ? 4 : 16),
          ),
          boxShadow: [
            BoxShadow(
              color: theme.shadow,
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (attachmentUrl.isNotEmpty) ...[
              if (attachmentType == 'image')
                GestureDetector(
                  onTap: () => _showImagePreview(mediaUrl),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Image.network(mediaUrl,
                        width: 220, height: 180, fit: BoxFit.cover),
                  ),
                )
              else
                InkWell(
                  onTap: () => launchUrl(Uri.parse(mediaUrl),
                      mode: LaunchMode.externalApplication),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    constraints: const BoxConstraints(minWidth: 190),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: (isMe ? AppColors.navyDeep : theme.icon)
                          .withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(mainAxisSize: MainAxisSize.min, children: [
                      Icon(
                          attachmentType == 'audio'
                              ? Icons.play_circle_fill_rounded
                              : Icons.play_arrow_rounded,
                          color: isMe ? AppColors.navyDeep : theme.icon),
                      const SizedBox(width: 8),
                      Text(attachmentType == 'audio'
                          ? (isAr ? 'تسجيل صوتي' : 'Voice message')
                          : (isAr ? 'فيديو' : 'Video')),
                    ]),
                  ),
                ),
              if (body.isNotEmpty) const SizedBox(height: 8),
            ],
            if (body.isNotEmpty)
              Text(
                body,
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  color: isMe ? AppColors.navyDeep : theme.cardTitle,
                  height: 1.4,
                ),
              ),
            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (createdAt != null)
                  Text(
                    _formatTime(createdAt.toString()),
                    style: GoogleFonts.readexPro(
                      fontSize: 11,
                      color: isMe
                          ? AppColors.navyDeep.withValues(alpha: 0.7)
                          : theme.cardMetaText.withValues(alpha: 0.75),
                    ),
                  ),
                if (isMe && failed) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.error_outline_rounded,
                    size: 14,
                    color: AppColors.navyDeep.withValues(alpha: 0.85),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInputBar(bool isAr) {
    final theme = AppThemeExtension.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: theme.sheetBackground,
        border: Border(top: BorderSide(color: theme.cardBorder)),
      ),
      child: SafeArea(
        child: Row(
          children: [
            IconButton(
              tooltip: isAr ? 'صورة أو فيديو' : 'Image or video',
              onPressed: _uploading || _recording
                  ? null
                  : () => _showAttachmentPicker(isAr),
              icon: _uploading
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add_circle_outline_rounded),
            ),
            Expanded(
              child: TextField(
                controller: _controller,
                decoration: InputDecoration(
                  hintText: isAr ? 'اكتب رسالة...' : 'Type a message...',
                  hintStyle: GoogleFonts.readexPro(
                    color: theme.mutedForeground,
                    fontSize: 14,
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(24),
                    borderSide: BorderSide.none,
                  ),
                  filled: true,
                  fillColor: theme.card,
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 20,
                    vertical: 12,
                  ),
                ),
                style: GoogleFonts.readexPro(
                  fontSize: 15,
                  color: theme.cardTitle,
                ),
                maxLines: 4,
                minLines: 1,
                textInputAction: TextInputAction.send,
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
            const SizedBox(width: 8),
            IconButton(
              tooltip: _recording
                  ? (isAr ? 'إيقاف وإرسال' : 'Stop and send')
                  : (isAr ? 'تسجيل صوتي' : 'Voice message'),
              onPressed: _sending || _uploading ? null : _toggleVoiceRecording,
              icon: Icon(
                  _recording ? Icons.stop_circle_rounded : Icons.mic_rounded,
                  color: _recording ? Colors.red : theme.icon),
            ),
            Material(
              color: context.appTheme.icon,
              borderRadius: BorderRadius.circular(24),
              child: InkWell(
                onTap: _sending ? null : _sendMessage,
                borderRadius: BorderRadius.circular(24),
                child: const Padding(
                  padding: EdgeInsets.all(12),
                  child: Icon(
                    Icons.send_rounded,
                    color: AppColors.navyDeep,
                    size: 24,
                  ),
                ),
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
      if (dt == null) return '';
      return '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return '';
    }
  }
}
