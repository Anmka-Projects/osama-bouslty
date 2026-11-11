import { Router } from 'express';
import rateLimit from 'express-rate-limit';
import { asyncHandler } from '../../shared/errors/errorHandler.js';
import { authMiddleware, adminMiddleware, instructorMiddleware } from '../../shared/middleware/auth.middleware.js';
import { sendSuccess } from '../../shared/utils/response.js';
import * as marketplace from './marketplace.service.js';

const router = Router();

const quoteLimit = rateLimit({ windowMs: 60 * 1000, max: 30, standardHeaders: true, legacyHeaders: false });
const joinLimit = rateLimit({ windowMs: 60 * 1000, max: 20, standardHeaders: true, legacyHeaders: false });
const reviewLimit = rateLimit({ windowMs: 60 * 1000, max: 10, standardHeaders: true, legacyHeaders: false });

function idempotencyKey(req) {
  return req.get('Idempotency-Key') || req.get('idempotency-key') || null;
}

router.get('/paths', asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.publicPaths());
}));

router.get('/trainers', asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.listTrainers(req.query));
}));

router.get('/trainers/:trainerId/availability', asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.getAvailability(req.params.trainerId, req.query));
}));

router.get('/trainers/:trainerId/reviews', asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.listReviews(req.params.trainerId, req.query));
}));

router.get('/trainers/:trainerId', asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.getTrainer(req.params.trainerId));
}));

router.post('/booking-quotes', authMiddleware, quoteLimit, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.createQuote(req.user, req.body || {}, idempotencyKey(req)), null, 201);
}));

router.post('/bookings', authMiddleware, quoteLimit, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.createBooking(req.user, req.body || {}, idempotencyKey(req)), null, 201);
}));

router.get('/bookings', authMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.listBookings(req.user, req.query));
}));

router.get('/bookings/:bookingId', authMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.getBooking(req.user, req.params.bookingId));
}));

router.post('/bookings/:bookingId/receipt', authMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.uploadReceipt(req.user, req.params.bookingId, req.body?.receipt_url));
}));

router.post('/bookings/:bookingId/cancel', authMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.cancelBooking(req.user, req.params.bookingId, req.body?.reason));
}));

router.post('/bookings/:bookingId/reschedule', authMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.rescheduleBooking(req.user, req.params.bookingId, req.body || {}));
}));

router.post('/bookings/:bookingId/join', authMiddleware, joinLimit, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.joinBooking(req.user, req.params.bookingId));
}));

router.post('/bookings/:bookingId/review', authMiddleware, reviewLimit, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.addReview(req.user, req.params.bookingId, req.body || {}), null, 201);
}));

router.get('/live/join/:token', asyncHandler(async (req, res) => {
  const target = await marketplace.consumeJoinToken(req.params.token);
  res.set('Cache-Control', 'no-store');
  res.redirect(302, target);
}));

router.get('/instructor/trainer-profile', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.getMyTrainerProfile(req.user));
}));

router.put('/instructor/trainer-profile', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.updateMyTrainerProfile(req.user, req.body || {}));
}));

router.get('/instructor/availability', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.getMyAvailability(req.user));
}));

router.put('/instructor/availability', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.putMyAvailability(req.user, req.body || {}));
}));

router.post('/instructor/availability/exceptions', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.addException(req.user, req.body || {}), null, 201);
}));

router.delete('/instructor/availability/exceptions/:id', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.deleteException(req.user, req.params.id));
}));

router.post('/instructor/bookings/:bookingId/meeting', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.publishMeeting(req.user, req.params.bookingId, req.body || {}));
}));

router.get('/instructor/earnings', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.earnings(req.user, req.query));
}));

router.get('/instructor/payouts', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.listPayouts(req.user));
}));

router.post('/instructor/payouts', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.requestPayout(req.user, req.body || {}), null, 201);
}));

router.post('/instructor/bookings/:bookingId/respond', authMiddleware, instructorMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.respondBooking(req.user, req.params.bookingId, req.body || {}));
}));

router.get('/admin/marketplace/trainers', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminListTrainers(req.query));
}));

router.get('/admin/marketplace/trainers/:trainerId', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminGetTrainer(req.params.trainerId));
}));

router.put('/admin/marketplace/trainers/:trainerId', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminUpdateTrainer(req.params.trainerId, req.body || {}));
}));

router.put('/admin/marketplace/trainers/:trainerId/availability', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminUpdateTrainerAvailability(req.params.trainerId, req.body || {}));
}));

router.get('/admin/marketplace/bookings', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminListBookings(req.query));
}));

router.post('/admin/marketplace/bookings/:bookingId/payment', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.approvePayment(req.user, req.params.bookingId, req.body?.approve !== false));
}));

router.post('/admin/marketplace/bookings/:bookingId/cancel', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.cancelBooking(req.user, req.params.bookingId, req.body?.reason || 'admin'));
}));

router.put('/admin/marketplace/trainers/:trainerId/verification', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminSetVerification(req.params.trainerId, req.body || {}));
}));

router.get('/admin/marketplace/payouts', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, { payouts: await marketplace.adminListPayouts() });
}));

router.post('/admin/marketplace/payouts/:id', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminDecidePayout(req.params.id, req.body || {}));
}));

router.put('/admin/marketplace/settings', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminUpdateSettings(req.body || {}));
}));

router.get('/admin/marketplace/settings', authMiddleware, adminMiddleware, asyncHandler(async (req, res) => {
  sendSuccess(res, await marketplace.adminGetSettings());
}));

export default router;
