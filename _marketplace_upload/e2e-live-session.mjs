import crypto from 'crypto'
import jwt from 'jsonwebtoken'
import 'dotenv/config'
import { PrismaClient } from '@prisma/client'

const prisma = new PrismaClient()
const base = 'http://127.0.0.1:16821/api'

async function request(path, { token, method = 'GET', body, idempotency } = {}) {
  const response = await fetch(`${base}${path}`, {
    method,
    headers: {
      ...(token ? { Authorization: `Bearer ${token}` } : {}),
      ...(body ? { 'Content-Type': 'application/json' } : {}),
      ...(idempotency ? { 'Idempotency-Key': idempotency } : {}),
    },
    body: body ? JSON.stringify(body) : undefined,
  })
  const payload = await response.json()
  if (!response.ok) throw new Error(`${path}: ${payload.message || response.status}`)
  return payload.data
}

async function login(email, password) {
  return request('/auth/login', { method: 'POST', body: { email, password } })
}

let originalSettings
try {
  const student = await login(process.env.E2E_STUDENT_EMAIL, process.env.E2E_STUDENT_PASSWORD)
  const teacher = await login(process.env.E2E_TEACHER_EMAIL, process.env.E2E_TEACHER_PASSWORD)
  const studentToken = student.accessToken
  const teacherToken = teacher.accessToken

  const meetingUrl = `https://meet.jit.si/bouslty-${Date.now()}`
  await request('/instructor/trainer-profile', {
    token: teacherToken,
    method: 'PUT',
    body: {
      default_meeting_provider: 'jitsi',
      default_join_url: meetingUrl,
      is_accepting_bookings: true,
    },
  })

  const profile = await request(`/trainers/${teacher.user.id}`)
  const offering = profile.offerings.find((item) => item.type === 'single_session' && item.is_active)
    || profile.offerings.find((item) => item.is_active)
  if (!offering) throw new Error('No active offering')

  const availability = await request(`/trainers/${teacher.user.id}/availability`)
  const slot = availability.slots.find((item) => item.available)
  if (!slot) throw new Error('No available slot')

  const quote = await request('/booking-quotes', {
    token: studentToken,
    method: 'POST',
    idempotency: crypto.randomUUID(),
    body: { offering_id: offering.id, slot_id: slot.slot_id },
  })
  const created = await request('/bookings', {
    token: studentToken,
    method: 'POST',
    idempotency: crypto.randomUUID(),
    body: {
      quote_id: quote.quote_id,
      payment_method: 'bank_transfer',
      student_notes: 'اختبار جلسة مباشرة كامل بين الطالب والمعلم',
    },
  })
  const accepted = await request(`/instructor/bookings/${created.id}/respond`, {
    token: teacherToken,
    method: 'POST',
    body: { accept: true },
  })

  const admin = await prisma.user.findFirst({ where: { role: 'admin', status: 'active' } })
  if (!admin) throw new Error('No active admin')
  const adminToken = jwt.sign(
    { userId: admin.id, role: admin.role, email: admin.email },
    process.env.JWT_SECRET,
    { expiresIn: '10m' },
  )
  originalSettings = await prisma.marketplaceSetting.findUnique({ where: { id: 'default' } })
  await request('/admin/marketplace/settings', {
    token: adminToken,
    method: 'PUT',
    body: {
      join_before_minutes: 60 * 24 * 31,
      join_after_minutes: originalSettings?.joinAfterMinutes || 15,
      cancel_before_hours: originalSettings?.cancelBeforeHours || 12,
      default_currency: originalSettings?.defaultCurrency || 'EGP',
    },
  })
  const paid = await request(`/admin/marketplace/bookings/${created.id}/payment`, {
    token: adminToken,
    method: 'POST',
    body: { approve: true },
  })

  const studentView = await request(`/bookings/${created.id}`, { token: studentToken })
  const teacherView = await request(`/bookings/${created.id}`, { token: teacherToken })
  const studentJoin = await request(`/bookings/${created.id}/join`, { token: studentToken, method: 'POST', body: {} })
  const teacherJoin = await request(`/bookings/${created.id}/join`, { token: teacherToken, method: 'POST', body: {} })

  console.log(JSON.stringify({
    booking_id: created.id,
    offering: offering.title,
    scheduled_at: paid.scheduled_at,
    amount: `${paid.amount} ${paid.currency}`,
    created_status: created.status,
    teacher_accept_status: accepted.status,
    final_status: paid.status,
    payment_status: paid.payment_status,
    meeting_provider: paid.meeting_provider,
    conversation_created: Boolean(paid.conversation_id),
    student_can_join: studentView.can_join,
    teacher_can_join: teacherView.can_join,
    student_join_granted: Boolean(studentJoin.join_url),
    teacher_join_granted: Boolean(teacherJoin.join_url),
    same_meeting_configured: Boolean(meetingUrl),
  }, null, 2))
} finally {
  if (originalSettings) {
    await prisma.marketplaceSetting.update({
      where: { id: 'default' },
      data: {
        joinBeforeMinutes: originalSettings.joinBeforeMinutes,
        joinAfterMinutes: originalSettings.joinAfterMinutes,
        cancelBeforeHours: originalSettings.cancelBeforeHours,
        defaultCurrency: originalSettings.defaultCurrency,
      },
    })
  }
  await prisma.$disconnect()
}
