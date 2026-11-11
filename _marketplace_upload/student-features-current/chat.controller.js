import chatService from './chat.service.js';
import { ForbiddenError } from '../../shared/errors/AppError.js';
import { sendSuccess, sendCreated, sendPaginatedResponse } from '../../shared/utils/response.js';
import { asyncHandler } from '../../shared/errors/errorHandler.js';
import { getSocketIo } from '../../shared/socket.js';

/**
 * Chat Controller - real-time chat between admin/teacher and student
 */
class ChatController {
  getOrCreateConversation = asyncHandler(async (req, res) => {
    const conversation = await chatService.getOrCreateConversation(
      req.user.id,
      req.user.role,
      req.body.otherUserId
    );
    sendSuccess(res, conversation);
  });

  listConversations = asyncHandler(async (req, res) => {
    const result = await chatService.listConversations(req.user.id, req.query);
    sendPaginatedResponse(res, result);
  });

  getMessages = asyncHandler(async (req, res) => {
    const result = await chatService.getMessages(
      req.user.id,
      req.params.conversationId,
      req.query
    );
    sendPaginatedResponse(res, result);
  });

  sendMessage = asyncHandler(async (req, res) => {
    const { message, recipientId, moderation_note: moderationNote } = await chatService.sendMessage(
      req.user.id,
      req.params.conversationId,
      req.body
    );
    const io = getSocketIo();
    if (io && recipientId) {
      io.to(`user:${recipientId}`).emit('chat:message', {
        conversationId: req.params.conversationId,
        message,
      });
    }
    sendCreated(res, { ...message, moderation_note: moderationNote || null }, 'تم إرسال الرسالة');
  });

  listModerationAlerts = asyncHandler(async (req, res) => {
    if (req.user.role !== 'admin') throw new ForbiddenError('غير مسموح');
    sendSuccess(res, await chatService.listModerationAlerts());
  });

  markModerationAlert = asyncHandler(async (req, res) => {
    if (req.user.role !== 'admin') throw new ForbiddenError('غير مسموح');
    sendSuccess(res, await chatService.markModerationAlert(req.params.id));
  });

  markMessageRead = asyncHandler(async (req, res) => {
    const result = await chatService.markMessageRead(req.user.id, req.params.messageId);
    sendSuccess(res, result);
  });
}

export default new ChatController();
