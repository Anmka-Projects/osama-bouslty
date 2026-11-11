import crypto from 'crypto';
import prisma from '../../shared/prisma/client.js';
import { NotFoundError, ForbiddenError, BadRequestError, ValidationError } from '../../shared/errors/AppError.js';
import { parsePagination } from '../../shared/utils/pagination.js';

/**
 * Normalize conversation participants so participant1Id < participant2Id for unique lookup
 */
function normalizeParticipantIds(userId1, userId2) {
  return userId1 < userId2 ? [userId1, userId2] : [userId2, userId1];
}

/**
 * Check if current user is allowed to chat with the other user.
 * - Admin can chat with any user (student or instructor).
 * - Instructor can chat with admin (support) or with students enrolled in at least one of their courses.
 * - Student can chat with admin or with instructors of courses they're enrolled in.
 */
async function canChatWith(currentUser, otherUserId) {
  if (currentUser.id === otherUserId) {
    return false;
  }

  const other = await prisma.user.findUnique({
    where: { id: otherUserId },
    select: { id: true, role: true },
  });

  if (!other) {
    return false;
  }

  if (currentUser.role === 'admin') {
    return true;
  }

  if (currentUser.role === 'instructor') {
    // Support/admin account is always reachable (app "الإدارة / الدعم" tile)
    if (other.role === 'admin') return true;
    if (other.role !== 'student') return false;
    const enrollment = await prisma.userCourseEnrollment.findFirst({
      where: {
        userId: otherUserId,
        course: { instructorId: currentUser.id },
      },
    });
    return !!enrollment;
  }

  if (currentUser.role === 'student') {
    if (other.role === 'admin') return true;
    if (other.role === 'instructor') {
      const trainer = await prisma.trainerProfile.findUnique({
        where: { userId: otherUserId },
        select: { verificationStatus: true },
      });
      if (trainer?.verificationStatus === 'approved') return true;
      const enrollment = await prisma.userCourseEnrollment.findFirst({
        where: {
          userId: currentUser.id,
          isActive: true,
          course: { instructorId: otherUserId },
        },
      });
      return !!enrollment;
    }
    return false;
  }

  return false;
}

/**
 * Check if current user is a participant of the conversation
 */
function isParticipant(conversation, userId) {
  return conversation.participant1Id === userId || conversation.participant2Id === userId;
}

/**
 * Get the other participant's user id in a conversation
 */
function getOtherParticipantId(conversation, currentUserId) {
  return conversation.participant1Id === currentUserId
    ? conversation.participant2Id
    : conversation.participant1Id;
}

/**
 * Format a chat message for API responses.
 * Emits both camelCase and snake_case keys — the mobile app parses
 * created_at / sender_id, so snake_case must be present.
 */
function formatMessage(m, senderName) {
  return {
    id: m.id,
    body: m.body,
    attachmentUrl: m.attachmentUrl,
    attachment_url: m.attachmentUrl,
    attachmentType: m.attachmentType,
    attachment_type: m.attachmentType,
    attachmentName: m.attachmentName,
    attachment_name: m.attachmentName,
    attachmentSize: m.attachmentSize,
    attachment_size: m.attachmentSize,
    durationSeconds: m.durationSeconds,
    duration_seconds: m.durationSeconds,
    senderId: m.senderId,
    sender_id: m.senderId,
    ...(senderName !== undefined || m.sender?.name
      ? { senderName: senderName ?? m.sender?.name, sender_name: senderName ?? m.sender?.name }
      : {}),
    ...(m.sender !== undefined ? { sender: m.sender } : {}),
    readAt: m.readAt,
    read_at: m.readAt,
    createdAt: m.createdAt,
    created_at: m.createdAt,
  };
}

/**
 * Chat Service - business logic for admin/teacher–student chat
 */
class ChatService {
  /**
   * Get or create a conversation with another user
   */
  async getOrCreateConversation(currentUserId, currentUserRole, otherUserId) {
    if (currentUserId === otherUserId) {
      throw new ValidationError('cannot chat with yourself', {
        otherUserId: 'cannot chat with yourself',
      });
    }
    const allowed = await canChatWith(
      { id: currentUserId, role: currentUserRole },
      otherUserId
    );
    if (!allowed) {
      throw new ForbiddenError('غير مسموح بفتح محادثة مع هذا المستخدم');
    }

    const [p1, p2] = normalizeParticipantIds(currentUserId, otherUserId);

    let conversation = await prisma.chatConversation.findUnique({
      where: {
        participant1Id_participant2Id: { participant1Id: p1, participant2Id: p2 },
      },
      include: {
        participant1: { select: { id: true, name: true, avatar: true, role: true } },
        participant2: { select: { id: true, name: true, avatar: true, role: true } },
      },
    });

    if (!conversation) {
      conversation = await prisma.chatConversation.create({
        data: { participant1Id: p1, participant2Id: p2 },
        include: {
          participant1: { select: { id: true, name: true, avatar: true, role: true } },
          participant2: { select: { id: true, name: true, avatar: true, role: true } },
        },
      });
    }

    const other =
      conversation.participant1Id === currentUserId
        ? conversation.participant2
        : conversation.participant1;
    const lastMessage = await prisma.chatMessage.findFirst({
      where: { conversationId: conversation.id },
      orderBy: { createdAt: 'desc' },
      include: { sender: { select: { id: true, name: true } } },
    });

    return {
      id: conversation.id,
      otherUser: other,
      lastMessage: lastMessage ? formatMessage(lastMessage) : null,
      createdAt: conversation.createdAt,
      created_at: conversation.createdAt,
    };
  }

  /**
   * List current user's conversations with last message
   */
  async listConversations(currentUserId, query) {
    const { page, limit, skip } = parsePagination(query);

    const where = {
      OR: [{ participant1Id: currentUserId }, { participant2Id: currentUserId }],
    };

    const [conversations, total] = await Promise.all([
      prisma.chatConversation.findMany({
        where,
        orderBy: { updatedAt: 'desc' },
        skip,
        take: limit,
        include: {
          participant1: { select: { id: true, name: true, avatar: true, role: true } },
          participant2: { select: { id: true, name: true, avatar: true, role: true } },
        },
      }),
      prisma.chatConversation.count({ where }),
    ]);

    const list = await Promise.all(
      conversations.map(async (c) => {
        const other =
          c.participant1Id === currentUserId ? c.participant2 : c.participant1;
        const lastMessage = await prisma.chatMessage.findFirst({
          where: { conversationId: c.id },
          orderBy: { createdAt: 'desc' },
          include: { sender: { select: { id: true, name: true } } },
        });
        const unreadCount = await prisma.chatMessage.count({
          where: {
            conversationId: c.id,
            senderId: { not: currentUserId },
            readAt: null,
          },
        });
        return {
          id: c.id,
          otherUser: other,
          lastMessage: lastMessage ? formatMessage(lastMessage) : null,
          unreadCount,
          unread_count: unreadCount,
          updatedAt: c.updatedAt,
          updated_at: c.updatedAt,
        };
      })
    );

    return { data: list, total, page, limit };
  }

  /**
   * Get messages for a conversation (paginated, newest first)
   */
  async getMessages(currentUserId, conversationId, query) {
    const conversation = await prisma.chatConversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundError('المحادثة غير موجودة');
    }
    if (!isParticipant(conversation, currentUserId)) {
      throw new ForbiddenError('ليس لديك صلاحية الوصول لهذه المحادثة');
    }

    const { page, limit, skip } = parsePagination(query);

    const [messages, total] = await Promise.all([
      prisma.chatMessage.findMany({
        where: { conversationId },
        orderBy: { createdAt: 'desc' },
        skip,
        take: limit,
        include: {
          sender: { select: { id: true, name: true, avatar: true } },
        },
      }),
      prisma.chatMessage.count({ where: { conversationId } }),
    ]);

    const formatted = messages.map((m) => formatMessage(m));

    return {
      data: formatted.reverse(), // chronological for display
      total,
      page,
      limit,
    };
  }

  /**
   * Send a message and return it (caller can emit via socket)
   */
  async sendMessage(currentUserId, conversationId, payload) {
    const conversation = await prisma.chatConversation.findUnique({
      where: { id: conversationId },
    });

    if (!conversation) {
      throw new NotFoundError('المحادثة غير موجودة');
    }
    if (!isParticipant(conversation, currentUserId)) {
      throw new ForbiddenError('ليس لديك صلاحية الإرسال في هذه المحادثة');
    }

    const trimmedBody = String(payload?.body || '').trim();
    const attachmentUrl = String(payload?.attachment_url || '').trim();
    const attachmentType = String(payload?.attachment_type || '').trim();
    if (!trimmedBody && !attachmentUrl) throw new BadRequestError('نص الرسالة أو المرفق مطلوب');
    if (attachmentUrl && !['image', 'video', 'audio'].includes(attachmentType)) {
      throw new BadRequestError('نوع المرفق غير مدعوم');
    }

    const cleanedBody = trimmedBody
      .replace(/(^|\s)@[A-Za-z0-9_.-]{2,32}/g, ' ')
      .replace(/(?:\+|00)?\d[\d\s().-]{6,}\d/g, ' ')
      .replace(/\s{2,}/g, ' ')
      .trim();
    if (cleanedBody !== trimmedBody) {
      try {
        await prisma.chatModerationAlert.create({
          data: {
            id: crypto.randomUUID(),
            conversationId,
            senderId: currentUserId,
            originalBody: trimmedBody,
            cleanedBody: cleanedBody || null,
          },
        });
        const admins = await prisma.user.findMany({
          where: { role: 'admin', status: 'active' },
          select: { id: true },
          take: 20,
        });
        if (admins.length) {
          await prisma.notification.create({
            data: {
              title: 'تنبيه شات',
              body: 'اتمسحت أرقام أو اسم يبدأ بـ @ من رسالة، وده النص الأصلي محفوظ في تنبيهات الشات.',
              targetAudience: 'specific',
              targetUserIds: JSON.stringify(admins.map((item) => item.id)),
              deepLink: `chat-alert:${conversationId}`,
              status: 'sent',
              sentAt: new Date(),
              recipients: { create: admins.map((item) => ({ userId: item.id })) },
            },
          });
        }
      } catch (error) {
        console.error('chat moderation alert failed', error.message);
      }
    }
    if (!cleanedBody && !attachmentUrl) {
      throw new BadRequestError('الرسالة اتمسحت لأنها رقم أو اسم مستخدم، والإدارة اتبلغت');
    }

    const message = await prisma.chatMessage.create({
      data: {
        conversationId,
        senderId: currentUserId,
        body: cleanedBody,
        attachmentUrl: attachmentUrl || null,
        attachmentType: attachmentUrl ? attachmentType : null,
        attachmentName: attachmentUrl ? String(payload?.attachment_name || '').trim().slice(0, 255) || null : null,
        attachmentSize: attachmentUrl && Number.isFinite(Number(payload?.attachment_size)) ? Math.max(0, Math.floor(Number(payload.attachment_size))) : null,
        durationSeconds: attachmentUrl && Number.isFinite(Number(payload?.duration_seconds)) ? Math.max(0, Math.floor(Number(payload.duration_seconds))) : null,
      },
      include: {
        sender: { select: { id: true, name: true, avatar: true } },
      },
    });

    const recipientId = getOtherParticipantId(conversation, currentUserId);

    return {
      message: formatMessage(message),
      recipientId,
      recipient_id: recipientId,
      moderation_note: cleanedBody !== trimmedBody ? 'اتمسحت أرقام أو اسم مستخدم من الرسالة' : null,
    };
  }

  async listModerationAlerts() {
    const alerts = await prisma.chatModerationAlert.findMany({
      orderBy: { createdAt: 'desc' },
      take: 80,
    });
    const senderIds = [...new Set(alerts.map((item) => item.senderId))];
    const senders = senderIds.length
      ? await prisma.user.findMany({ where: { id: { in: senderIds } }, select: { id: true, name: true } })
      : [];
    const names = Object.fromEntries(senders.map((item) => [item.id, item.name]));
    return {
      alerts: alerts.map((item) => ({
        id: item.id,
        conversation_id: item.conversationId,
        sender_id: item.senderId,
        sender_name: names[item.senderId] || '',
        original_body: item.originalBody,
        cleaned_body: item.cleanedBody,
        is_read: item.isRead,
        created_at: item.createdAt,
      })),
    };
  }

  async markModerationAlert(id) {
    await prisma.chatModerationAlert.update({ where: { id }, data: { isRead: true } });
    return { id, is_read: true };
  }

  /**
   * Mark a message as read
   */
  async markMessageRead(currentUserId, messageId) {
    const message = await prisma.chatMessage.findUnique({
      where: { id: messageId },
      include: { conversation: true },
    });

    if (!message) {
      throw new NotFoundError('الرسالة غير موجودة');
    }
    if (!isParticipant(message.conversation, currentUserId)) {
      throw new ForbiddenError('ليس لديك صلاحية الوصول لهذه الرسالة');
    }
    if (message.senderId === currentUserId) {
      return { message: null }; // sender doesn't "read" their own
    }
    if (message.readAt) {
      return { message: { id: message.id, readAt: message.readAt } };
    }

    const updated = await prisma.chatMessage.update({
      where: { id: messageId },
      data: { readAt: new Date() },
    });

    return { message: { id: updated.id, readAt: updated.readAt, read_at: updated.readAt } };
  }
}

export default new ChatService();
