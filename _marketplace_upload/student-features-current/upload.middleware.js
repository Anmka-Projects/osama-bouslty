import multer from 'multer';
import fs from 'fs';
import path from 'path';
import { v4 as uuidv4 } from 'uuid';
import { BadRequestError } from '../errors/AppError.js';

// Allowed file types (mobile often sends HEIC; some clients send octet-stream + filename)
const ALLOWED_IMAGE_TYPES = [
  'image/jpeg',
  'image/jpg',
  'image/png',
  'image/gif',
  'image/webp',
  'image/heic',
  'image/heif',
  'image/heic-sequence',
  'image/bmp',
  'image/tiff',
  'image/x-png',
];
const ALLOWED_VIDEO_TYPES = ['video/mp4', 'video/webm', 'video/quicktime', 'video/x-matroska'];
const ALLOWED_AUDIO_TYPES = ['audio/mpeg', 'audio/mp4', 'audio/aac', 'audio/wav', 'audio/x-wav', 'audio/ogg', 'audio/webm', 'audio/3gpp'];
const ALLOWED_DOCUMENT_TYPES = [
  'application/pdf',
  'application/msword',
  'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
];

const IMAGE_EXT_RE = /\.(jpe?g|png|gif|webp|heic|heif|bmp|tif|tiff)$/i;
const VIDEO_EXT_RE = /\.(mp4|webm|mov|m4v|mkv)$/i;
const AUDIO_EXT_RE = /\.(mp3|m4a|aac|wav|ogg|oga|webm|3gp)$/i;
const DOC_EXT_RE = /\.(pdf|doc|docx)$/i;

const MIXED_ALLOWED = [...ALLOWED_IMAGE_TYPES, ...ALLOWED_VIDEO_TYPES, ...ALLOWED_AUDIO_TYPES, ...ALLOWED_DOCUMENT_TYPES];

/**
 * Accept file when MIME is allowed, or when client sends wrong MIME (common on Flutter/Android/iOS).
 */
function mixedFileFilter(req, file, cb) {
  if (MIXED_ALLOWED.includes(file.mimetype)) {
    cb(null, true);
    return;
  }
  // Any image/* (some devices use non-standard subtypes)
  if (file.mimetype && file.mimetype.startsWith('image/')) {
    cb(null, true);
    return;
  }
  if (file.mimetype && file.mimetype.startsWith('video/')) {
    cb(null, true);
    return;
  }
  const name = file.originalname || '';
  if (
    file.mimetype === 'application/octet-stream' ||
    file.mimetype === 'binary/octet-stream' ||
    !file.mimetype
  ) {
    if (IMAGE_EXT_RE.test(name) || VIDEO_EXT_RE.test(name) || AUDIO_EXT_RE.test(name) || DOC_EXT_RE.test(name)) {
      cb(null, true);
      return;
    }
  }
  cb(
    new BadRequestError(`نوع الملف غير مدعوم. الأنواع المسموحة: ${MIXED_ALLOWED.join(', ')}`),
    false,
  );
}

// File size limits
const MAX_IMAGE_SIZE = 5 * 1024 * 1024; // 5MB
const MAX_VIDEO_SIZE = 2 * 1024 * 1024 * 1024; // 2GB
const MAX_DOCUMENT_SIZE = 20 * 1024 * 1024; // 20MB

/**
 * Configure storage for multer
 */
const storage = multer.diskStorage({
  destination: (req, file, cb) => {
    let uploadPath = 'uploads/';
    const ext = path.extname(file.originalname || '').toLowerCase();
    const mime = file.mimetype || '';

    const isImage =
      ALLOWED_IMAGE_TYPES.includes(mime) ||
      mime.startsWith('image/') ||
      IMAGE_EXT_RE.test(file.originalname || '');
    const isVideo =
      !isImage &&
      (ALLOWED_VIDEO_TYPES.includes(mime) ||
        mime.startsWith('video/') ||
        VIDEO_EXT_RE.test(file.originalname || ''));
    const isAudio =
      !isImage &&
      !isVideo &&
      (ALLOWED_AUDIO_TYPES.includes(mime) ||
        mime.startsWith('audio/') ||
        AUDIO_EXT_RE.test(file.originalname || ''));
    const isDoc =
      !isImage &&
      !isVideo &&
      !isAudio &&
      (ALLOWED_DOCUMENT_TYPES.includes(mime) ||
        mime === 'application/octet-stream' ||
        DOC_EXT_RE.test(file.originalname || ''));

    if (isImage) {
      uploadPath += 'images/';
    } else if (isVideo) {
      uploadPath += 'videos/';
    } else if (isAudio) {
      uploadPath += 'audio/';
    } else if (isDoc) {
      uploadPath += 'documents/';
    } else if (IMAGE_EXT_RE.test(ext)) {
      uploadPath += 'images/';
    } else if (VIDEO_EXT_RE.test(ext)) {
      uploadPath += 'videos/';
    } else if (AUDIO_EXT_RE.test(ext)) {
      uploadPath += 'audio/';
    } else if (DOC_EXT_RE.test(ext)) {
      uploadPath += 'documents/';
    } else {
      uploadPath += 'images/';
    }

    // Audio is a newer attachment type, so its directory may not exist yet on
    // an older installation. Multer does not create dynamic destinations.
    fs.mkdirSync(uploadPath, { recursive: true });
    cb(null, uploadPath);
  },
  filename: (req, file, cb) => {
    const ext = path.extname(file.originalname);
    const filename = `${uuidv4()}${ext}`;
    cb(null, filename);
  },
});

/**
 * File filter function
 */
const fileFilter = (allowedTypes) => (req, file, cb) => {
  if (allowedTypes.includes(file.mimetype)) {
    cb(null, true);
  } else {
    cb(new BadRequestError(`نوع الملف غير مدعوم. الأنواع المسموحة: ${allowedTypes.join(', ')}`), false);
  }
};

/**
 * Image upload middleware
 */
export const uploadImage = multer({
  storage,
  fileFilter: fileFilter(ALLOWED_IMAGE_TYPES),
  limits: {
    fileSize: MAX_IMAGE_SIZE,
  },
});

/**
 * Video upload middleware
 */
export const uploadVideo = multer({
  storage,
  fileFilter: fileFilter(ALLOWED_VIDEO_TYPES),
  limits: {
    fileSize: MAX_VIDEO_SIZE,
  },
});

/**
 * Document upload middleware
 */
export const uploadDocument = multer({
  storage,
  fileFilter: fileFilter(ALLOWED_DOCUMENT_TYPES),
  limits: {
    fileSize: MAX_DOCUMENT_SIZE,
  },
});

/**
 * Mixed upload middleware (images, videos, and documents)
 * Used for generic /upload endpoint that should accept any lesson/media files.
 */
export const uploadMixed = multer({
  storage,
  fileFilter: mixedFileFilter,
  limits: {
    // Use the largest limit so large videos are allowed
    fileSize: MAX_VIDEO_SIZE,
  },
});

/**
 * Handle multer errors
 */
export const handleUploadError = (err, req, res, next) => {
  if (err instanceof multer.MulterError) {
    if (err.code === 'LIMIT_FILE_SIZE') {
      return next(new BadRequestError('حجم الملف كبير جداً'));
    }
    if (err.code === 'LIMIT_UNEXPECTED_FILE') {
      return next(new BadRequestError('عدد الملفات كبير جداً'));
    }
    return next(new BadRequestError(err.message));
  }
  next(err);
};

export default {
  uploadImage,
  uploadVideo,
  uploadDocument,
  uploadMixed,
  handleUploadError,
};






