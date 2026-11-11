import { Router } from 'express';

// Import module routes
import authRoutes from './modules/auth/auth.routes.js';
import usersRoutes from './modules/users/users.routes.js';
import categoriesRoutes from './modules/categories/categories.routes.js';
import countriesRoutes from './modules/countries/countries.routes.js';
import currenciesRoutes from './modules/currencies/currencies.routes.js';
import coursesRoutes from './modules/courses/courses.routes.js';
import curriculumRoutes from './modules/curriculum/curriculum.routes.js';
import examsRoutes from './modules/exams/exams.routes.js';
import databankRoutes from './modules/databank/databank.routes.js';
import liveSessionsRoutes from './modules/liveSessions/liveSessions.routes.js';
import paymentsRoutes from './modules/payments/payments.routes.js';
import certificatesRoutes from './modules/certificates/certificates.routes.js';
import notificationsRoutes from './modules/notifications/notifications.routes.js';
import bannersRoutes from './modules/banners/banners.routes.js';
import slidersRoutes from './modules/sliders/sliders.routes.js';
import homeSpotVideosRoutes from './modules/homeSpotVideos/homeSpotVideos.routes.js';
import dashboardRoutes from './modules/dashboard/dashboard.routes.js';
import reportsRoutes from './modules/reports/reports.routes.js';
import appConfigRoutes from './modules/appConfig/appConfig.routes.js';
import mobileRoutes from './modules/mobile/mobile.routes.js';
import attendanceRoutes from './modules/attendance/attendance.routes.js';
import treasuryRoutes from './modules/treasury/treasury.routes.js';
import teacherSalaryRoutes from './modules/teacherSalary/teacherSalary.routes.js';
import studentDebtsRoutes from './modules/studentDebts/studentDebts.routes.js';
import studentsRoutes from './modules/students/students.routes.js';
import videoCacheRoutes from './modules/videoCache/videoCache.routes.js';
import monthlyReportsRoutes from './modules/monthlyReports/monthlyReports.routes.js';
import lecturesRoutes from './modules/lectures/lectures.routes.js';
import chatRoutes from './modules/chat/chat.routes.js';
import studentTrackingRoutes from './modules/studentTracking/studentTracking.routes.js';
import securityRoutes from './modules/security/security.routes.js';
import adminVideosRoutes from './modules/adminVideos/adminVideos.routes.js';
import blockedAccountsRoutes from './modules/blockedAccounts/blockedAccounts.routes.js';
import securityAlertsRoutes from './modules/securityAlerts/securityAlerts.routes.js';
import enrollmentRequestsRoutes from './modules/enrollmentRequests/enrollmentRequests.routes.js';
import activationCodesRoutes from './modules/activationCodes/activationCodes.routes.js';
import activationCodesStudentRoutes from './modules/activationCodes/activationCodes.student.routes.js';
import adminInboxRoutes from './modules/adminInbox/adminInbox.routes.js';
import marketplaceRoutes from './modules/marketplace/marketplace.routes.js';
import { uploadMixed, handleUploadError } from './shared/middleware/upload.middleware.js';
import path from 'path';
import bannersService from './modules/banners/banners.service.js';
import slidersService from './modules/sliders/sliders.service.js';
import { sendSuccess } from './shared/utils/response.js';
import { asyncHandler } from './shared/errors/errorHandler.js';

const router = Router();

// Generic file upload (for thumbnails, videos, documents, etc.) – must be before other /api routes
// Accepts multipart with field "image" or "file"; returns { success, url, filename }
function uploadHandler(req, res, next) {
  const file = req.files?.image?.[0] || req.files?.file?.[0];
  if (!file) {
    return res.status(400).json({ success: false, message: 'لم يتم تحديد ملف' });
  }
  // Derive URL from multer destination (uploads/images, uploads/videos, uploads/documents)
  let uploadPath = file.path || path.join(file.destination || 'uploads/images', file.filename);
  uploadPath = uploadPath.replace(/\\/g, '/');
  const uploadsIndex = uploadPath.indexOf('uploads/');
  const relativePath = uploadsIndex >= 0 ? uploadPath.substring(uploadsIndex) : `uploads/images/${file.filename}`;
  const url = `/${relativePath}`;
  return res.status(200).json({
    success: true,
    url,
    filename: file.filename,
    message: 'تم رفع الصورة بنجاح',
  });
}

router.post('/upload', (req, res, next) => {
  const multerUpload = uploadMixed.fields([{ name: 'image', maxCount: 1 }, { name: 'file', maxCount: 1 }]);
  multerUpload(req, res, (err) => {
    if (err) return handleUploadError(err, req, res, next);
    uploadHandler(req, res, next);
  });
});

router.post('/uploads/upload', (req, res, next) => {
  const multerUpload = uploadMixed.fields([{ name: 'image', maxCount: 1 }, { name: 'file', maxCount: 1 }]);
  multerUpload(req, res, (err) => {
    if (err) return handleUploadError(err, req, res, next);
    uploadHandler(req, res, next);
  });
});

// Auth routes (public)
router.use('/auth', authRoutes);

// Public banners (active only, no auth required)
router.get('/banners', asyncHandler(async (req, res) => {
  const banners = await bannersService.getBanners(true);
  sendSuccess(res, banners);
}));

// Public app sliders — المفعّل فقط يُرسَل للتطبيق (بدون عناصر معطّلة وبدون حقل isActive)
router.get('/sliders', asyncHandler(async (req, res) => {
  const sliders = await slidersService.getPublicSlidersForApp();
  sendSuccess(res, sliders);
}));

// Mobile/Student API routes (public + protected)
router.use('/', mobileRoutes);

// Student tracking & security
router.use('/', studentTrackingRoutes);
router.use('/', securityRoutes);

// Activation codes (student redeem: POST /api/activation-codes/redeem)
router.use('/activation-codes', activationCodesStudentRoutes);

// Admin routes (protected)
router.use('/admin/dashboard', dashboardRoutes);
router.use('/admin/inbox', adminInboxRoutes);
router.use('/admin/users', usersRoutes);
router.use('/admin/categories', categoriesRoutes);
router.use('/admin/countries', countriesRoutes);
router.use('/admin/currencies', currenciesRoutes);
router.use('/admin/courses', coursesRoutes);
router.use('/admin/courses/:courseId/lectures', lecturesRoutes);
router.use('/admin/curriculum', curriculumRoutes);
router.use('/admin/exams', examsRoutes);
router.use('/admin/databank', databankRoutes);
router.use('/admin/live-sessions', liveSessionsRoutes);
router.use('/admin/payments', paymentsRoutes);
router.use('/admin/certificates', certificatesRoutes);
router.use('/admin/certificate-templates', certificatesRoutes);
router.use('/admin/notifications', notificationsRoutes);
router.use('/admin/banners', bannersRoutes);
router.use('/admin/sliders', slidersRoutes);
router.use('/admin/home-spot-videos', homeSpotVideosRoutes);
router.use('/admin/reports', reportsRoutes);
router.use('/admin/app-config', appConfigRoutes);
router.use('/admin/treasury', treasuryRoutes);
router.use('/admin/teachers', teacherSalaryRoutes);
router.use('/admin/students/debts', studentDebtsRoutes);
router.use('/admin/students', studentsRoutes);
router.use('/admin/videos', adminVideosRoutes);
router.use('/admin/blocked-accounts', blockedAccountsRoutes);
router.use('/admin/security-alerts', securityAlertsRoutes);
router.use('/admin/enrollment-requests', enrollmentRequestsRoutes);
router.use('/admin/activation-codes', activationCodesRoutes);
router.use('/admin/attendance', attendanceRoutes);
router.use('/attendance', attendanceRoutes);

// Video Cache routes (for both admin and students)
router.use('/videos/cache', videoCacheRoutes);

// Chat (admin/teacher ↔ student) - authenticated users only
router.use('/chat', chatRoutes);

// Monthly Reports routes (both paths for compatibility)
router.use('/admin/monthly-reports', monthlyReportsRoutes);
router.use('/admin/monthly-notifications-reports', monthlyReportsRoutes);

router.use(marketplaceRoutes);

// API info endpoint
router.get('/', (req, res) => {
  res.json({
    name: 'UR The Brand API',
    version: '1.0.0',
    documentation: '/api/docs',
    health: '/health',
  });
});

export default router;






