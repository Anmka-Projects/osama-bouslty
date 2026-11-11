// Student/Mobile API utility functions
// Base URL for backend API - use Next.js rewrites proxy
// Client-side uses /backend-api (proxied to backend via next.config.mjs rewrites)
const BACKEND_URL = ""
const API_PATH = "/backend-api"

// Types
export interface ApiResponse<T> {
  success: boolean
  data: T
  message?: string
}

export interface PaginatedResponse<T> {
  data: T[]
  total: number
  page: number
  limit: number
  totalPages?: number
}

export interface Course {
  id: string
  title: string
  description: string
  thumbnail?: string
  price: number
  discountPrice?: number
  level: 'beginner' | 'intermediate' | 'advanced'
  categoryId: string
  categoryName?: string
  instructorId: string
  instructorName?: string
  duration: number
  lessonsCount?: number
  studentsCount?: number
  rating?: number
  reviewsCount?: number
  status: string
  isFeatured?: boolean
  createdAt?: string
  updatedAt?: string
  is_enrolled?: boolean
  sections?: Section[]
}

export interface Category {
  id: string
  name: string
  description?: string
  icon?: string
  color?: string
  coursesCount?: number
  order?: number
  isActive?: boolean
}

export interface Instructor {
  id: string
  name: string
  nameEn?: string
  title?: string
  titleEn?: string
  bio?: string
  bioEn?: string
  avatar?: string
  email?: string
  phone?: string
  coursesCount?: number
  studentsCount?: number
  rating?: number
  reviewsCount?: number
  courses?: Course[]
}

export interface Enrollment {
  id: string
  courseId: string
  course: Course
  progress: number
  completedLessons: number
  totalLessons: number
  enrolledAt: string
  lastAccessedAt?: string
  status?: string
}

export interface Lesson {
  id: string
  title: string
  type: 'video' | 'text' | 'quiz'
  duration: number
  isFree: boolean
  order: number
  videoUrl?: string
  content?: string
  isCompleted?: boolean
  progress?: number
  sectionId?: string
}

export interface Section {
  id: string
  title: string
  order: number
  lessons: Lesson[]
}

export interface Curriculum {
  courseId: string
  sections: Section[]
}

export interface User {
  id: string
  name: string
  email: string
  phone?: string
  avatar?: string
  role: 'student' | 'instructor' | 'admin'
  status?: string
  createdAt?: string
}

export interface Certificate {
  id: string
  courseId: string
  courseName: string
  courseTitle?: string
  userId: string
  userName?: string
  issueDate: string
  certificateUrl?: string
  downloadUrl?: string
  completedAt?: string
}

export interface Notification {
  id: string
  title: string
  message: string
  type: string
  isRead: boolean
  createdAt: string
  data?: any
}

export interface Review {
  id: string
  userId: string
  userName: string
  userAvatar?: string
  rating: number
  title?: string
  comment: string
  createdAt: string
}

export interface Progress {
  totalCourses: number
  completedCourses: number
  inProgressCourses: number
  totalLessons: number
  completedLessons: number
  totalHours: number
  completedHours: number
  weeklyProgress?: number[]
  monthlyProgress?: number[]
  recentActivity?: any[]
}

export interface Exam {
  id: string
  title: string
  description?: string
  duration: number
  totalQuestions: number
  passingScore: number
  courseId: string
  questions?: ExamQuestion[]
  attempts?: ExamAttempt[]
  canAttempt?: boolean
}

export interface ExamQuestion {
  id: string
  question: string
  type: 'single' | 'multiple' | 'text'
  options?: { id: string; text: string }[]
  correctAnswer?: string | string[]
}

export interface ExamAttempt {
  id: string
  examId: string
  userId: string
  score: number
  passed: boolean
  answers: any
  startedAt: string
  completedAt?: string
}

export interface LiveSession {
  id: string
  title: string
  description?: string
  instructorId: string
  instructorName?: string
  startTime: string
  endTime?: string
  status: 'upcoming' | 'live' | 'ended'
  meetingUrl?: string
  thumbnail?: string
}

// Helper function to get auth token
function getAuthToken(): string | null {
  if (typeof window === 'undefined') return null
  return localStorage.getItem('accessToken') || localStorage.getItem('studentToken')
}

// Same media-path rule as the Flutter app: /uploads/x -> /api/uploads/x (proxied),
// already-absolute URLs pass through unchanged.
export function mediaUrl(path?: string | null): string {
  if (!path || path.includes('default_avatar')) return ''
  if (path.startsWith('http://') || path.startsWith('https://')) return path
  let clean = path
  if (clean.startsWith('/uploads/')) clean = `/api${clean}`
  else if (!clean.startsWith('/')) clean = `/${clean}`
  if (!clean.startsWith('/api/')) clean = `/api${clean}`
  return clean
}

// Helper function to set auth tokens
export function setAuthTokens(accessToken: string, refreshToken?: string) {
  if (typeof window === 'undefined') return
  localStorage.setItem('accessToken', accessToken)
  if (refreshToken) {
    localStorage.setItem('refreshToken', refreshToken)
  }
}

// Helper function to clear auth tokens
export function clearAuthTokens() {
  if (typeof window === 'undefined') return
  localStorage.removeItem('accessToken')
  localStorage.removeItem('refreshToken')
  localStorage.removeItem('studentToken')
  localStorage.removeItem('user')
}

// Helper function to check if user is authenticated
export function isAuthenticated(): boolean {
  return !!getAuthToken()
}

// Helper function to get stored user
export function getStoredUser(): User | null {
  if (typeof window === 'undefined') return null
  const user = localStorage.getItem('user')
  return user ? JSON.parse(user) : null
}

// Helper function to store user
export function storeUser(user: User) {
  if (typeof window === 'undefined') return
  localStorage.setItem('user', JSON.stringify(user))
}

// Base fetch function
async function fetchApi<T>(
  endpoint: string,
  options: RequestInit = {}
): Promise<ApiResponse<T>> {
  const token = getAuthToken()
  
  const headers: HeadersInit = {
    'Content-Type': 'application/json',
    ...(options.headers || {}),
  }
  
  if (token) {
    headers['Authorization'] = `Bearer ${token}`
  }

  try {
    const response = await fetch(`${API_PATH}${endpoint}`, {
      ...options,
      headers,
    })

    if (!response.ok) {
      const errorData = await response.json().catch(() => ({ message: 'حدث خطأ' }))
      throw new Error(errorData.message || `HTTP error! status: ${response.status}`)
    }

    const data = await response.json()
    return data
  } catch (error) {
    console.error('API Error:', error)
    throw error
  }
}

// ============== PUBLIC APIs ==============

// App Config
export const appConfigApi = {
  get: () => fetchApi<any>('/config/app'),
}

// Home Page
export const homeApi = {
  get: () => fetchApi<{
    featuredCourses: Course[]
    categories: Category[]
    stats: {
      totalCourses: number
      totalStudents: number
      totalInstructors: number
      averageRating: number
    }
    banners?: any[]
  }>('/home'),
}

// Categories
export const categoriesApi = {
  getAll: () => fetchApi<Category[]>('/categories'),
  getCourses: (categoryId: string, params?: {
    page?: number
    perPage?: number
    sort?: string
    level?: string
    price?: string
  }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    if (params?.sort) searchParams.set('sort', params.sort)
    if (params?.level) searchParams.set('level', params.level)
    if (params?.price) searchParams.set('price', params.price)
    
    const query = searchParams.toString()
    return fetchApi<PaginatedResponse<Course>>(`/categories/${categoryId}/courses${query ? `?${query}` : ''}`)
  },
}

// Courses
export const coursesApi = {
  getAll: (params?: {
    page?: number
    limit?: number
    categoryId?: string
    level?: string
    search?: string
    sort?: string
    price?: string
  }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.limit) searchParams.set('per_page', params.limit.toString())
    if (params?.categoryId) searchParams.set('category_id', params.categoryId)
    if (params?.level && params.level !== 'all') searchParams.set('level', params.level)
    if (params?.search) searchParams.set('search', params.search)
    if (params?.sort) searchParams.set('sort', params.sort)
    if (params?.price && params.price !== 'all') searchParams.set('price', params.price)
    
    const query = searchParams.toString()
    return fetchApi<PaginatedResponse<Course>>(`/courses${query ? `?${query}` : ''}`)
  },
  getById: (id: string) => fetchApi<Course>(`/courses/${id}`),
  getReviews: (id: string, params?: { page?: number; perPage?: number; rating?: number }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    if (params?.rating) searchParams.set('rating', params.rating.toString())
    
    const query = searchParams.toString()
    return fetchApi<PaginatedResponse<Review>>(`/courses/${id}/reviews${query ? `?${query}` : ''}`)
  },
  search: (query: string, params?: { type?: string; page?: number; perPage?: number }) => {
    const searchParams = new URLSearchParams()
    searchParams.set('q', query)
    if (params?.type) searchParams.set('type', params.type)
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    
    return fetchApi<{ courses: Course[]; teachers: Instructor[]; total: number }>(`/search?${searchParams.toString()}`)
  },
}

// Instructors/Teachers
export const instructorsApi = {
  getAll: (params?: { page?: number; perPage?: number; search?: string; sort?: string }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    if (params?.search) searchParams.set('search', params.search)
    if (params?.sort) searchParams.set('sort', params.sort)
    
    const query = searchParams.toString()
    return fetchApi<PaginatedResponse<Instructor>>(`/teachers${query ? `?${query}` : ''}`)
  },
  getById: (id: string) => fetchApi<Instructor>(`/teachers/${id}`),
  getCourses: (id: string, params?: { page?: number; perPage?: number }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    
    const query = searchParams.toString()
    return fetchApi<PaginatedResponse<Course>>(`/teachers/${id}/courses${query ? `?${query}` : ''}`)
  },
}

// Live Sessions
export const liveSessionsApi = {
  getAll: () => fetchApi<LiveSession[]>('/live-courses'),
}

// ============== AUTH APIs ==============

export const authApi = {
  // App parity: single identifier field — backend accepts either email or phone
  login: (identifier: string, password: string) => {
    const isEmail = /^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(identifier.trim())
    const body: Record<string, string> = { password }
    if (isEmail) body.email = identifier.trim()
    else body.phone = identifier.trim()
    return fetchApi<{ user: User; accessToken: string; refreshToken: string }>('/auth/login', {
      method: 'POST',
      body: JSON.stringify(body),
    })
  },
  register: (data: {
    name: string
    email?: string
    phone: string
    password: string
    password_confirmation?: string
    category_id?: string
    subcategory_id?: string
    accept_terms?: boolean
    role?: string
    student_type?: string
  }) =>
    fetchApi<{ user: User; accessToken: string; refreshToken: string }>('/auth/register', {
      method: 'POST',
      body: JSON.stringify({ role: 'student', ...data }),
    }),
  refreshToken: (refreshToken: string) =>
    fetchApi<{ accessToken: string; refreshToken: string }>('/auth/refresh', {
      method: 'POST',
      body: JSON.stringify({ refreshToken }),
    }),
  forgotPassword: (email: string) =>
    fetchApi<{ message: string }>('/auth/forgot-password', {
      method: 'POST',
      body: JSON.stringify({ email }),
    }),
  logout: () =>
    fetchApi<void>('/auth/logout', {
      method: 'POST',
    }),
  getCurrentUser: () => fetchApi<User>('/auth/me'),
  changePassword: (data: { oldPassword: string; newPassword: string }) =>
    fetchApi<void>('/auth/change-password', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  updateProfile: (data: Partial<User>) =>
    fetchApi<User>('/auth/profile', {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
}

// ============== PROTECTED APIs (Require Auth) ==============

// Enrollments
export const enrollmentsApi = {
  getMyEnrollments: (params?: { status?: string; page?: number; perPage?: number }) => {
    const searchParams = new URLSearchParams()
    if (params?.status && params.status !== 'all') searchParams.set('status', params.status)
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    
    const query = searchParams.toString()
    return fetchApi<PaginatedResponse<Enrollment>>(`/enrollments${query ? `?${query}` : ''}`)
  },
  enroll: (courseId: string) =>
    fetchApi<Enrollment>(`/courses/${courseId}/enroll`, {
      method: 'POST',
    }),
}

// Lessons
export const lessonsApi = {
  getLesson: (courseId: string, lessonId: string) =>
    fetchApi<Lesson>(`/courses/${courseId}/lessons/${lessonId}`),
  getLessonContent: (courseId: string, lessonId: string) =>
    fetchApi<{ content: string; videoUrl?: string; resources?: any[] }>(`/courses/${courseId}/lessons/${lessonId}/content`),
  updateProgress: (courseId: string, lessonId: string, data: { watched_seconds: number; is_completed: boolean }) =>
    fetchApi<{
      lesson_progress: { watched_seconds: number; is_completed: boolean }
      course_progress: { completed_lessons: number; total_lessons: number; percentage: number }
    }>(`/courses/${courseId}/lessons/${lessonId}/progress`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
}

// Profile
export const profileApi = {
  get: () => fetchApi<User>('/profile'),
  update: (data: Partial<User>) =>
    fetchApi<User>('/auth/profile', {
      method: 'PUT',
      body: JSON.stringify(data),
    }),
}

// Certificates
export const certificatesApi = {
  getMyCertificates: () => fetchApi<Certificate[]>('/certificates'),
  download: (certificateId: string) => fetchApi<{ downloadUrl: string }>(`/certificates/${certificateId}/download`),
}

// Notifications
export const notificationsApi = {
  getMyNotifications: (params?: { page?: number; perPage?: number; unreadOnly?: boolean }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    if (params?.unreadOnly) searchParams.set('unread_only', 'true')
    
    const query = searchParams.toString()
    return fetchApi<{ notifications: Notification[]; unreadCount: number; total: number }>(`/notifications${query ? `?${query}` : ''}`)
  },
  markAsRead: (id: string) =>
    fetchApi<void>(`/notifications/${id}/read`, {
      method: 'POST',
    }),
  markAllAsRead: () =>
    fetchApi<void>('/notifications/read-all', {
      method: 'POST',
    }),
}

// Wishlist
export const wishlistApi = {
  get: () => fetchApi<Course[]>('/wishlist'),
  add: (courseId: string) =>
    fetchApi<void>('/wishlist', {
      method: 'POST',
      body: JSON.stringify({ course_id: courseId }),
    }),
  remove: (courseId: string) =>
    fetchApi<void>(`/wishlist/${courseId}`, {
      method: 'DELETE',
    }),
}

// Reviews
export const reviewsApi = {
  add: (courseId: string, data: { rating: number; title?: string; comment: string }) =>
    fetchApi<Review>(`/courses/${courseId}/reviews`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
}

// Exams
export const examsApi = {
  getCourseExams: (courseId: string) => fetchApi<Exam[]>(`/courses/${courseId}/exams`),
  getExamDetails: (courseId: string, examId: string) =>
    fetchApi<Exam>(`/courses/${courseId}/exams/${examId}`),
  startExam: (courseId: string, examId: string) =>
    fetchApi<{ attemptId: string; exam: Exam; startedAt: string }>(`/courses/${courseId}/exams/${examId}/start`, {
      method: 'POST',
    }),
  submitExam: (courseId: string, examId: string, data: { attempt_id: string; answers: Record<string, any> }) =>
    fetchApi<{
      score: number
      passed: boolean
      correctAnswers: number
      totalQuestions: number
      results: any[]
    }>(`/courses/${courseId}/exams/${examId}/submit`, {
      method: 'POST',
      body: JSON.stringify(data),
    }),
}

// Progress
export const progressApi = {
  get: (period?: 'weekly' | 'monthly') => {
    const searchParams = new URLSearchParams()
    if (period) searchParams.set('period', period)
    
    const query = searchParams.toString()
    return fetchApi<Progress>(`/progress${query ? `?${query}` : ''}`)
  },
}

// Coupons
export const couponsApi = {
  validate: (code: string, courseId: string) =>
    fetchApi<{
      is_valid: boolean
      discount_type: 'percentage' | 'fixed'
      discount_value: number
      final_price: number
      message?: string
    }>('/coupons/validate', {
      method: 'POST',
      body: JSON.stringify({ code, course_id: courseId }),
    }),
}

// QR Code
export const qrCodeApi = {
  getMyQRCode: () => fetchApi<{ qr_code: string; user_id: string; expires_at: string }>('/my-qr-code'),
}// Payments (for checkout)
export const paymentsApi = {
  createPayment: (data: {
    courseId: string
    paymentMethod: string
    couponCode?: string
  }) =>
    fetchApi<{
      paymentId: string
      redirectUrl?: string
      status: string
    }>('/payments', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
  verifyPayment: (paymentId: string) =>
    fetchApi<{
      status: string
      enrollment?: Enrollment
    }>(`/payments/${paymentId}/verify`),
}

// ============== APP-PARITY APIs (ported from the Flutter app) ==============

// Sliders (public — home hero carousel)
export interface Slider {
  id: string
  title?: string
  subtitle?: string
  image?: string
  imageUrl?: string
  linkUrl?: string
  courseId?: string
}
export const slidersApi = {
  getAll: () => fetchApi<Slider[]>('/sliders'),
}

// Skill-track ladder (tiers + bundles)
export const skillTrackApi = {
  get: () => fetchApi<any>('/skill-track'),
}

// Activation codes — POST /activation-codes/redeem (single-course bound)
export const activationCodesApi = {
  redeem: (code: string) =>
    fetchApi<{ message?: string; course?: Course; enrollment?: Enrollment }>(
      '/activation-codes/redeem',
      { method: 'POST', body: JSON.stringify({ code }) }
    ),
}

// Enrollment requests (student's own: pending/approved/rejected + admin notes)
export interface EnrollmentRequest {
  id: string
  courseId?: string
  course?: Course
  courseTitle?: string
  status: 'pending' | 'approved' | 'rejected' | string
  adminNote?: string
  admin_note?: string
  paymentMethod?: string
  payment_method?: string
  receiptUrl?: string
  createdAt?: string
  created_at?: string
  updatedAt?: string
}
export const enrollmentRequestsApi = {
  getMine: (params?: { page?: number; perPage?: number }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    const query = searchParams.toString()
    return fetchApi<{ requests: EnrollmentRequest[]; meta?: { total: number; page: number } } | EnrollmentRequest[]>(
      `/enrollment-requests${query ? `?${query}` : ''}`
    )
  },
  create: (data: { course_id: string; payment_method?: string; receipt_url?: string; note?: string }) =>
    fetchApi<EnrollmentRequest>('/enrollment-requests', {
      method: 'POST',
      body: JSON.stringify(data),
    }),
}

// My exams — available exams across enrolled courses
export const myExamsApi = {
  getAvailable: () => fetchApi<{ exams: any[] } | any[]>('/my-exams'),
  getResults: () =>
    fetchApi<{ attempts: any[]; stats?: { totalAttempts: number; passed: number; failed: number; averageScore: number } }>(
      '/my-exam-results'
    ),
}

// Live sessions register
export const liveApi = {
  getAll: () => fetchApi<LiveSession[]>('/live-courses'),
  register: (sessionId: string) =>
    fetchApi<any>(`/admin/live-sessions/${sessionId}`, { method: 'POST' }),
}

// Chat (teacher-student)
export interface ChatConversation {
  id: string
  otherUser?: { id: string; name: string; avatar?: string; role?: string }
  other_user?: { id: string; name: string; avatar?: string; role?: string }
  lastMessage?: ChatMessage
  last_message?: ChatMessage
  unreadCount?: number
  unread_count?: number
  updatedAt?: string
}
export interface ChatMessage {
  id: string
  conversationId?: string
  senderId?: string
  sender_id?: string
  body: string
  attachmentUrl?: string
  attachment_url?: string
  attachmentType?: 'image' | 'video' | 'audio'
  attachment_type?: 'image' | 'video' | 'audio'
  attachmentName?: string
  attachment_name?: string
  attachmentSize?: number
  attachment_size?: number
  durationSeconds?: number
  duration_seconds?: number
  isRead?: boolean
  is_read?: boolean
  createdAt?: string
  created_at?: string
}
export const chatApi = {
  getConversations: (params?: { page?: number; perPage?: number }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    const query = searchParams.toString()
    return fetchApi<{ conversations: ChatConversation[] } | ChatConversation[]>(
      `/chat/conversations${query ? `?${query}` : ''}`
    )
  },
  createConversation: (otherUserId: string) =>
    fetchApi<ChatConversation>('/chat/conversations', {
      method: 'POST',
      body: JSON.stringify({ otherUserId }),
    }),
  getMessages: (conversationId: string, params?: { page?: number; perPage?: number }) => {
    const searchParams = new URLSearchParams()
    if (params?.page) searchParams.set('page', params.page.toString())
    if (params?.perPage) searchParams.set('per_page', params.perPage.toString())
    const query = searchParams.toString()
    return fetchApi<{ messages: ChatMessage[]; meta?: { total: number; page: number; totalPages?: number } } | ChatMessage[]>(
      `/chat/conversations/${conversationId}/messages${query ? `?${query}` : ''}`
    )
  },
  sendMessage: (conversationId: string, body: string, attachment?: {
    url: string
    type: 'image' | 'video' | 'audio'
    name?: string
    size?: number
    durationSeconds?: number
  }) =>
    fetchApi<ChatMessage>(`/chat/conversations/${conversationId}/messages`, {
      method: 'POST',
      body: JSON.stringify({
        body,
        ...(attachment ? {
          attachment_url: attachment.url,
          attachment_type: attachment.type,
          attachment_name: attachment.name,
          attachment_size: attachment.size,
          duration_seconds: attachment.durationSeconds,
        } : {}),
      }),
    }),
  markMessageRead: (messageId: string) =>
    fetchApi<void>(`/chat/messages/${messageId}/read`, { method: 'PATCH', body: '{}' }),
}

// Attendance / QR
export const attendanceApi = {
  getMyQrCode: () =>
    fetchApi<{ qr_code: string; user_id?: string; expires_at?: string } | { qrCode: string }>(
      '/attendance/my-qr-code'
    ),
  getMyAttendance: () => fetchApi<{ records: any[] } | any[]>('/attendance/my-attendance'),
}

// Upload (multipart — returns url)
export const uploadApi = {
  upload: async (file: File): Promise<string> => {
    const token = getAuthToken()
    const form = new FormData()
    form.append('file', file)
    const res = await fetch(`${API_PATH}/upload`, {
      method: 'POST',
      headers: token ? { Authorization: `Bearer ${token}` } : {},
      body: form,
    })
    const data = await res.json().catch(() => ({}))
    if (!res.ok) throw new Error(data.message || 'فشل رفع الملف')
    return data?.data?.url || data?.url || ''
  },
}

// Account deletion — DELETE /auth/account
export const accountApi = {
  delete: () => fetchApi<void>('/auth/account', { method: 'DELETE' }),
}
