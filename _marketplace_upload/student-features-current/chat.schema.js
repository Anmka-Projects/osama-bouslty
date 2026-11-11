import Joi from 'joi';
import { uuidSchema, paginationSchema } from '../../shared/validation/common.schema.js';

/**
 * Chat validation schemas
 */
export const getOrCreateConversationSchema = {
  body: Joi.object({
    otherUserId: uuidSchema.required().messages({
      'any.required': 'معرف المستخدم الآخر مطلوب',
    }),
  }),
};

export const listConversationsSchema = {
  query: paginationSchema.unknown(true),
};

export const getMessagesSchema = {
  params: Joi.object({
    conversationId: uuidSchema.required(),
  }),
  query: paginationSchema.unknown(true),
};

export const sendMessageSchema = {
  params: Joi.object({
    conversationId: uuidSchema.required(),
  }),
  body: Joi.object({
    body: Joi.string().allow('').max(10000).default('').messages({
      'string.min': 'نص الرسالة مطلوب',
      'string.max': 'الرسالة طويلة جداً',
    }),
    attachment_url: Joi.string().uri({ allowRelative: true }).max(2000).allow(null, ''),
    attachment_type: Joi.string().valid('image', 'video', 'audio').allow(null, ''),
    attachment_name: Joi.string().max(255).allow(null, ''),
    attachment_size: Joi.number().integer().min(0).max(2147483647).allow(null),
    duration_seconds: Joi.number().integer().min(0).max(3600).allow(null),
  }).custom((value, helpers) => {
    if (!String(value.body || '').trim() && !String(value.attachment_url || '').trim()) {
      return helpers.error('any.custom', { message: 'نص الرسالة أو المرفق مطلوب' });
    }
    if (value.attachment_url && !value.attachment_type) {
      return helpers.error('any.custom', { message: 'نوع المرفق مطلوب' });
    }
    return value;
  }),
};

export const markReadSchema = {
  params: Joi.object({
    messageId: uuidSchema.required(),
  }),
};

export default {
  getOrCreateConversationSchema,
  listConversationsSchema,
  getMessagesSchema,
  sendMessageSchema,
  markReadSchema,
};
