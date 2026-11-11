import { Router } from 'express';
import chatController from './chat.controller.js';
import { authMiddleware } from '../../shared/middleware/auth.middleware.js';
import { validate } from '../../shared/middleware/validate.middleware.js';
import {
  getOrCreateConversationSchema,
  listConversationsSchema,
  getMessagesSchema,
  sendMessageSchema,
  markReadSchema,
} from './chat.schema.js';

const router = Router();

router.use(authMiddleware);

router.get('/moderation-alerts', chatController.listModerationAlerts);
router.post('/moderation-alerts/:id/read', chatController.markModerationAlert);

// GET /api/chat/conversations - list my conversations
router.get(
  '/conversations',
  validate(listConversationsSchema),
  chatController.listConversations
);

// POST /api/chat/conversations - get or create conversation with another user
router.post(
  '/conversations',
  validate(getOrCreateConversationSchema),
  chatController.getOrCreateConversation
);

// GET /api/chat/conversations/:conversationId/messages - get messages (paginated)
router.get(
  '/conversations/:conversationId/messages',
  validate(getMessagesSchema),
  chatController.getMessages
);

// POST /api/chat/conversations/:conversationId/messages - send message
router.post(
  '/conversations/:conversationId/messages',
  validate(sendMessageSchema),
  chatController.sendMessage
);

// PATCH /api/chat/messages/:messageId/read - mark message as read
router.patch(
  '/messages/:messageId/read',
  validate(markReadSchema),
  chatController.markMessageRead
);

export default router;
