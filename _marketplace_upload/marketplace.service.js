import crypto from 'crypto';
import { Prisma } from '@prisma/client';
import prisma from '../../shared/prisma/client.js';
import { AppError } from '../../shared/errors/AppError.js';

const ACTIVE_HOLD = ['requested', 'pending_payment', 'confirmed', 'scheduled', 'live'];
const ALLOWED_SOCIAL = ['website', 'linkedin', 'youtube', 'instagram', 'facebook', 'x', 'tiktok'];

function fail(code, message, status = 400) {
  throw new AppError(message, status, null, { code });
}

function money(value) {
  return new Prisma.Decimal(new Prisma.Decimal(value).toFixed(2));
}

function moneyOut(value) {
  if (value == null) return '0.00';
  return new Prisma.Decimal(value).toFixed(2);
}

function secret() {
  return process.env.JWT_SECRET || 'marketplace-dev-secret';
}

function signSlot(payload) {
  const body = Buffer.from(JSON.stringify(payload)).toString('base64url');
  const sig = crypto.createHmac('sha256', secret()).update(body).digest('base64url');
  return `${body}.${sig}`;
}

function readSlot(token) {
  if (!token || !token.includes('.')) fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.');
  const [body, sig] = token.split('.');
  const expected = crypto.createHmac('sha256', secret()).update(body).digest('base64url');
  const a = Buffer.from(sig);
  const b = Buffer.from(expected);
  if (a.length !== b.length || !crypto.timingSafeEqual(a, b)) {
    fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.');
  }
  try {
    return JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.');
  }
}

function zoneOffsetMs(date, timeZone) {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    hour: '2-digit',
    minute: '2-digit',
    second: '2-digit',
  });
  const map = {};
  for (const part of dtf.formatToParts(date)) map[part.type] = part.value;
  const asUtc = Date.UTC(
    Number(map.year),
    Number(map.month) - 1,
    Number(map.day),
    Number(map.hour) % 24,
    Number(map.minute),
    Number(map.second),
  );
  return asUtc - date.getTime();
}

function zonedToUtc(year, month, day, hour, minute, timeZone) {
  const guess = new Date(Date.UTC(year, month - 1, day, hour, minute, 0));
  const offset = zoneOffsetMs(guess, timeZone);
  const utc = new Date(guess.getTime() - offset);
  const check = zoneOffsetMs(utc, timeZone);
  if (check !== offset) return new Date(guess.getTime() - check);
  return utc;
}

function zonedParts(date, timeZone) {
  const dtf = new Intl.DateTimeFormat('en-US', {
    timeZone,
    hourCycle: 'h23',
    year: 'numeric',
    month: '2-digit',
    day: '2-digit',
    weekday: 'short',
  });
  const map = {};
  for (const part of dtf.formatToParts(date)) map[part.type] = part.value;
  const weekdayMap = { Sun: 0, Mon: 1, Tue: 2, Wed: 3, Thu: 4, Fri: 5, Sat: 6 };
  return {
    year: Number(map.year),
    month: Number(map.month),
    day: Number(map.day),
    weekday: weekdayMap[map.weekday] ?? 0,
    key: `${map.year}-${map.month}-${map.day}`,
  };
}

function addDays(year, month, day, amount) {
  const dt = new Date(Date.UTC(year, month - 1, day));
  dt.setUTCDate(dt.getUTCDate() + amount);
  return { year: dt.getUTCFullYear(), month: dt.getUTCMonth() + 1, day: dt.getUTCDate() };
}

function parseDateKey(value) {
  const match = /^(\d{4})-(\d{2})-(\d{2})$/.exec(String(value || ''));
  if (!match) return null;
  return { year: Number(match[1]), month: Number(match[2]), day: Number(match[3]) };
}

function cleanText(value, max) {
  if (value == null) return null;
  const text = String(value).replace(/<[^>]*>/g, '').trim();
  if (!text) return null;
  return text.slice(0, max);
}

function introVideoUrl(value, current = null) {
  if (value === '') return null;
  const raw = String(value || '').trim();
  if (!raw) return current;
  if (/^https:\/\//i.test(raw)) return raw.slice(0, 1000);
  if (/^\/?uploads\//i.test(raw) || /^\/?api\/uploads\//i.test(raw)) {
    const apiBase = (process.env.PUBLIC_API_URL || 'https://bouslty.anmka.com/api').replace(/\/$/, '');
    const clean = raw.replace(/^\/?api\//i, '').replace(/^\//, '');
    return `${apiBase}/${clean}`.slice(0, 1000);
  }
  return current;
}

function effectivePrice(offering) {
  if (offering.discountPrice != null && new Prisma.Decimal(offering.discountPrice).lt(offering.price)) {
    return offering.discountPrice;
  }
  return offering.price;
}

async function settings() {
  return prisma.marketplaceSetting.upsert({
    where: { id: 'default' },
    update: {},
    create: { id: 'default' },
  });
}

function configuredPriceOptions(cfg) {
  try {
    const values = JSON.parse(cfg.priceOptionsUsd || '[]');
    if (!Array.isArray(values)) return [];
    return [...new Set(values
      .map((value) => Number(value))
      .filter((value) => Number.isFinite(value) && value > 0))]
      .sort((a, b) => a - b)
      .slice(0, 50);
  } catch {
    return [];
  }
}

async function audit(bookingId, actorId, action, metadata = null) {
  await prisma.bookingAuditEvent.create({
    data: { bookingId, actorId: actorId || null, action, metadata: metadata || undefined },
  });
}

async function notifyUser(userId, title, body, bookingId) {
  try {
    await prisma.notification.create({
      data: {
        title,
        body,
        targetAudience: 'specific',
        targetUserIds: JSON.stringify([userId]),
        deepLink: `booking:${bookingId}`,
        status: 'sent',
        sentAt: new Date(),
        recipients: { create: { userId } },
      },
    });
  } catch (error) {
    console.error('marketplace notify failed', error.message);
  }
  try {
    const fcm = await import('../../shared/services/fcm.service.js');
    const send = fcm.sendToUser || fcm.default?.sendToUser || fcm.notifyUser;
    if (typeof send === 'function') {
      await send(userId, { title, body, data: { deep_link: `booking:${bookingId}`, booking_id: bookingId } });
    }
  } catch {
    // Push is best-effort. The in-app notification row is the durable record.
  }
}

async function ensureConversation(studentId, trainerUserId) {
  const existing = await prisma.chatConversation.findFirst({
    where: {
      OR: [
        { participant1Id: studentId, participant2Id: trainerUserId },
        { participant1Id: trainerUserId, participant2Id: studentId },
      ],
    },
  });
  if (existing) return existing.id;
  const created = await prisma.chatConversation.create({
    data: { participant1Id: studentId, participant2Id: trainerUserId },
  });
  return created.id;
}

export async function syncInstructorProfiles() {
  const instructors = await prisma.user.findMany({
    where: { role: 'instructor', status: 'active' },
    select: { id: true, name: true, title: true, bio: true, avatar: true },
  });
  for (const user of instructors) {
    const exists = await prisma.trainerProfile.findUnique({ where: { userId: user.id } });
    if (exists) continue;
    await prisma.trainerProfile.create({
      data: {
        userId: user.id,
        displayName: user.name,
        headline: user.title || 'مدرب',
        bio: user.bio,
        avatarUrl: user.avatar,
        languages: ['ar'],
        verificationStatus: 'pending',
        isAcceptingBookings: true,
        offerings: {
          create: [
            {
              type: 'single_session',
              title: 'جلسة فردية',
              description: 'جلسة مباشرة واحدة مع المدرب داخل التطبيق.',
              durationMinutes: 60,
              sessionCount: 1,
              price: money(250),
              currency: 'EGP',
              isActive: true,
            },
            {
              type: 'package',
              title: 'باقة 4 جلسات',
              description: 'أربع جلسات مباشرة بسعر أقل من الحجز المنفرد.',
              durationMinutes: 60,
              sessionCount: 4,
              price: money(1000),
              discountPrice: money(880),
              currency: 'EGP',
              isActive: true,
            },
          ],
        },
        availabilityRules: {
          create: [6, 0, 1, 2, 3, 4].map((weekday) => ({
            weekday,
            startMinute: 16 * 60,
            endMinute: 21 * 60,
          })),
        },
      },
    });
  }
}

function publicCard(profile) {
  const active = (profile.offerings || []).filter((item) => item.isActive);
  const prices = active.map((item) => new Prisma.Decimal(effectivePrice(item)));
  const starting = prices.length ? prices.reduce((min, value) => (value.lt(min) ? value : min)) : null;
  return {
    id: profile.userId,
    profile_id: profile.id,
    display_name: profile.displayName,
    headline: profile.headline,
    avatar_url: profile.avatarUrl && !profile.avatarUrl.includes('default_avatar')
      ? profile.avatarUrl
      : null,
    intro_video_url: profile.introVideoUrl,
    rating_average: Number(profile.ratingAverage),
    rating_count: profile.ratingCount,
    completed_sessions_count: profile.completedSessionsCount,
    students_count: profile.studentsCount,
    starting_price: starting ? moneyOut(starting) : null,
    currency: active[0]?.currency || 'EGP',
    specialties: (profile.specialties || []).map((item) => ({ id: item.id, name: item.name })),
    languages: Array.isArray(profile.languages) ? profile.languages : [],
    is_accepting_bookings: profile.isAcceptingBookings && profile.verificationStatus === 'approved',
    verification_status: profile.verificationStatus,
    years_experience: profile.yearsExperience,
    category_id: profile.categoryId || null,
    subcategory_id: profile.subcategoryId || null,
  };
}

export async function listTrainers(query) {
  await syncInstructorProfiles();
  const page = Math.max(1, Number(query.page) || 1);
  const perPage = Math.min(50, Math.max(1, Number(query.per_page) || 20));
  const q = String(query.q || '').trim();
  const where = {
    verificationStatus: 'approved',
    ...(query.accepting === '0' ? {} : { isAcceptingBookings: true }),
  };
  if (q) {
    where.OR = [
      { displayName: { contains: q } },
      { headline: { contains: q } },
      { specialties: { some: { name: { contains: q } } } },
    ];
  }
  if (query.min_rating) {
    where.ratingAverage = { gte: Number(query.min_rating) };
  }
  if (query.category_id) where.categoryId = String(query.category_id);
  if (query.subcategory_id) where.subcategoryId = String(query.subcategory_id);
  const [total, rows, completed] = await Promise.all([
    prisma.trainerProfile.count({ where }),
    prisma.trainerProfile.findMany({
      where,
      include: { specialties: true, offerings: { where: { isActive: true } } },
      orderBy: [{ ratingAverage: 'desc' }, { completedSessionsCount: 'desc' }],
      skip: (page - 1) * perPage,
      take: perPage,
    }),
    prisma.sessionBooking.count({ where: { status: 'completed' } }),
  ]);
  let cards = rows.map(publicCard);
  if (query.language) {
    const language = String(query.language).toLowerCase();
    cards = cards.filter((card) => (card.languages || []).map((item) => String(item).toLowerCase()).includes(language));
  }
  if (query.max_price) {
    const max = Number(query.max_price);
    cards = cards.filter((card) => card.starting_price != null && Number(card.starting_price) <= max);
  }
  return {
    trainers: cards,
    pagination: { page, per_page: perPage, total },
    platform: { trainers: total, completed_sessions: completed },
    server_time: new Date().toISOString(),
  };
}

const profileInclude = {
  specialties: true,
  qualifications: true,
  offerings: { where: { isActive: true }, orderBy: { price: 'asc' } },
  user: { select: { id: true, name: true, avatar: true, title: true } },
  availabilityRules: true,
};

export async function getTrainer(userId) {
  await syncInstructorProfiles();
  const profile = await prisma.trainerProfile.findUnique({
    where: { userId },
    include: profileInclude,
  });
  if (!profile || profile.verificationStatus !== 'approved') {
    fail('NOT_FOUND', 'Trainer not found', 404);
  }
  let reviews = [];
  let slots = [];
  try {
    reviews = await prisma.bookingReview.findMany({
      where: { trainerUserId: userId, isHidden: false },
      orderBy: { createdAt: 'desc' },
      take: 8,
      include: { student: { select: { name: true, avatar: true } } },
    });
  } catch (error) {
    console.error('[marketplace] trainer reviews unavailable', { userId, error });
  }
  try {
    slots = await buildSlots(profile, 7);
  } catch (error) {
    // A profile must stay viewable even if its schedule is incomplete. The
    // dedicated availability endpoint can still report the scheduling error.
    console.error('[marketplace] trainer preview slots unavailable', { userId, error });
  }
  return {
    ...publicCard(profile),
    bio: profile.bio,
    qualifications: profile.qualifications.map((item) => ({
      id: item.id,
      title: item.title,
      issuer: item.issuer,
      year: item.year,
    })),
    social_links: profile.socialLinks || {},
    offerings: profile.offerings.map(offeringDto),
    next_slots: slots.filter((slot) => slot.available).slice(0, 6),
    reviews: reviews.map((review) => ({
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      created_at: review.createdAt.toISOString(),
      student_name: review.student?.name || '',
      student_avatar: review.student?.avatar || null,
    })),
    server_time: new Date().toISOString(),
  };
}

function offeringDto(offering) {
  return {
    id: offering.id,
    type: offering.type,
    title: offering.title,
    description: offering.description,
    duration_minutes: offering.durationMinutes,
    session_count: offering.sessionCount,
    price: moneyOut(offering.price),
    discount_price: offering.discountPrice == null ? null : moneyOut(offering.discountPrice),
    payable: moneyOut(effectivePrice(offering)),
    currency: offering.currency,
    is_active: offering.isActive,
    course_id: offering.courseId,
  };
}

async function buildSlots(profile, days) {
  const cfg = await settings();
  const timeZone = profile.timezone || 'Africa/Cairo';
  const now = new Date();
  const start = zonedParts(now, timeZone);
  const exceptions = await prisma.trainerAvailabilityException.findMany({
    where: { profileId: profile.id },
  });
  const blocked = new Set(
    exceptions.filter((item) => item.isBlocked).map((item) => {
      const date = new Date(item.date);
      const y = date.getUTCFullYear();
      const m = String(date.getUTCMonth() + 1).padStart(2, '0');
      const d = String(date.getUTCDate()).padStart(2, '0');
      return `${y}-${m}-${d}`;
    }),
  );
  const rangeStart = now;
  const rangeEnd = new Date(now.getTime() + (days + 1) * 86400000);
  const holds = await prisma.sessionBooking.findMany({
    where: {
      trainerUserId: profile.userId,
      status: { in: ACTIVE_HOLD },
      endsAt: { gt: rangeStart },
      scheduledAt: { lt: rangeEnd },
    },
    select: { scheduledAt: true, endsAt: true, status: true, createdAt: true },
  });
  const slots = [];
  let cursor = start;
  for (let i = 0; i < days; i += 1) {
    const key = `${cursor.year}-${String(cursor.month).padStart(2, '0')}-${String(cursor.day).padStart(2, '0')}`;
    const rules = blocked.has(key)
      ? []
      : (profile.availabilityRules || []).filter((rule) => rule.weekday === cursor.weekday);
    for (const rule of rules) {
      const step = profile.slotDurationMinutes + profile.bufferMinutes;
      for (let minute = rule.startMinute; minute + profile.slotDurationMinutes <= rule.endMinute; minute += step) {
        const startsAt = zonedToUtc(cursor.year, cursor.month, cursor.day, Math.floor(minute / 60), minute % 60, timeZone);
        const endsAt = new Date(startsAt.getTime() + profile.slotDurationMinutes * 60000);
        if (startsAt.getTime() < now.getTime() + 30 * 60000) continue;
        const taken = holds.some((hold) => {
          if (hold.status === 'pending_payment' && now.getTime() - hold.createdAt.getTime() > 48 * 3600000) return false;
          return startsAt < hold.endsAt && endsAt > hold.scheduledAt;
        });
        slots.push({
          slot_id: signSlot({
            trainerUserId: profile.userId,
            startsAt: startsAt.toISOString(),
            endsAt: endsAt.toISOString(),
          }),
          starts_at: startsAt.toISOString(),
          ends_at: endsAt.toISOString(),
          available: !taken,
        });
      }
    }
    const next = addDays(cursor.year, cursor.month, cursor.day, 1);
    cursor = { ...cursor, ...next, weekday: (cursor.weekday + 1) % 7 };
  }
  return slots;
}

export async function getAvailability(userId, query) {
  const profile = await prisma.trainerProfile.findUnique({
    where: { userId },
    include: { availabilityRules: true },
  });
  if (!profile) fail('NOT_FOUND', 'Trainer not found', 404);
  const from = parseDateKey(query.from);
  const to = parseDateKey(query.to);
  let days = 14;
  if (from && to) {
    const a = Date.UTC(from.year, from.month - 1, from.day);
    const b = Date.UTC(to.year, to.month - 1, to.day);
    days = Math.min(31, Math.max(1, Math.round((b - a) / 86400000) + 1));
  }
  const slots = await buildSlots(profile, days);
  return {
    trainer_id: profile.userId,
    timezone: profile.timezone,
    server_time: new Date().toISOString(),
    slots,
  };
}

async function loadOffering(offeringId) {
  const offering = await prisma.trainerOffering.findUnique({
    where: { id: offeringId },
    include: { profile: true },
  });
  if (!offering || !offering.isActive) fail('NOT_FOUND', 'Offering not found', 404);
  if (!offering.profile.isAcceptingBookings || offering.profile.verificationStatus !== 'approved') {
    fail('BOOKING_NOT_JOINABLE', 'This trainer is not accepting bookings.', 409);
  }
  return offering;
}

async function applyCoupon(code, subtotal) {
  if (!code) return { discount: money(0), coupon: null };
  const coupon = await prisma.coupon.findUnique({ where: { code: String(code).trim() } });
  if (!coupon || !coupon.isActive) fail('QUOTE_EXPIRED', 'Coupon is not valid.');
  if (coupon.expiresAt && coupon.expiresAt < new Date()) fail('QUOTE_EXPIRED', 'Coupon is not valid.');
  if (coupon.maxUses != null && coupon.usedCount >= coupon.maxUses) fail('QUOTE_EXPIRED', 'Coupon is not valid.');
  if (new Prisma.Decimal(subtotal).lt(coupon.minPurchase)) fail('QUOTE_EXPIRED', 'Coupon minimum was not reached.');
  let discount = money(0);
  if (coupon.type === 'percentage') {
    discount = money(new Prisma.Decimal(subtotal).mul(coupon.value).div(100));
  } else {
    discount = money(coupon.value);
  }
  if (new Prisma.Decimal(discount).gt(subtotal)) discount = money(subtotal);
  return { discount, coupon };
}

export async function createQuote(user, body, idempotencyKey) {
  return withIdempotency(user.id, 'quote', idempotencyKey, async () => {
    const offering = await loadOffering(body.offering_id);
    const slot = readSlot(body.slot_id);
    if (slot.trainerUserId !== offering.profile.userId) {
      fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.');
    }
    const startsAt = new Date(slot.startsAt);
    const endsAt = new Date(slot.endsAt);
    const minutes = (endsAt - startsAt) / 60000;
    if (minutes !== offering.durationMinutes) {
      fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time does not match this session length.');
    }
    const fresh = await getAvailability(offering.profile.userId, {});
    const still = fresh.slots.find((item) => item.starts_at === startsAt.toISOString() && item.available);
    if (!still) fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.');
    const subtotal = money(effectivePrice(offering));
    const { discount } = await applyCoupon(body.coupon_code, subtotal);
    const total = money(new Prisma.Decimal(subtotal).minus(discount));
    const quote = await prisma.bookingQuote.create({
      data: {
        studentId: user.id,
        offeringId: offering.id,
        startsAt,
        endsAt,
        subtotal,
        discount,
        total,
        currency: offering.currency,
        couponCode: body.coupon_code || null,
        expiresAt: new Date(Date.now() + 15 * 60000),
        idempotencyKey: idempotencyKey || null,
      },
    });
    return quoteDto(quote);
  });
}

function quoteDto(quote) {
  return {
    quote_id: quote.id,
    expires_at: quote.expiresAt.toISOString(),
    subtotal: moneyOut(quote.subtotal),
    discount: moneyOut(quote.discount),
    total: moneyOut(quote.total),
    currency: quote.currency,
    server_time: new Date().toISOString(),
  };
}

async function withIdempotency(userId, scope, key, producer) {
  if (!key) return producer();
  const existing = await prisma.idempotencyRecord.findUnique({
    where: { userId_scope_key: { userId, scope, key } },
  });
  if (existing) return JSON.parse(existing.responseJson);
  const result = await producer();
  try {
    await prisma.idempotencyRecord.create({
      data: { userId, scope, key, responseJson: JSON.stringify(result) },
    });
  } catch (error) {
    if (error.code === 'P2002') {
      const again = await prisma.idempotencyRecord.findUnique({
        where: { userId_scope_key: { userId, scope, key } },
      });
      if (again) return JSON.parse(again.responseJson);
    }
  }
  return result;
}

async function attachMeeting(tx, booking, profile) {
  if (!profile.defaultJoinUrl) return booking.status;
  await tx.meetingSession.create({
    data: {
      bookingId: booking.id,
      provider: profile.defaultMeetingProvider || 'custom_web',
      joinUrl: profile.defaultJoinUrl,
      hostUrl: profile.defaultJoinUrl,
    },
  });
  return 'scheduled';
}

export async function createBooking(user, body, idempotencyKey) {
  if (user.role === 'instructor') {
    fail('BOOKING_NOT_JOINABLE', 'Instructors book from a student account.', 403);
  }
  return withIdempotency(user.id, 'booking', idempotencyKey, async () => {
    if (body.package_purchase_id) return redeemPackage(user, body);
    if (!body.quote_id) fail('QUOTE_EXPIRED', 'A price quote is required.');
    const quote = await prisma.bookingQuote.findUnique({
      where: { id: body.quote_id },
      include: { offering: { include: { profile: true } } },
    });
    if (!quote || quote.studentId !== user.id) fail('QUOTE_EXPIRED', 'The price quote has expired.');
    if (quote.consumedAt || quote.expiresAt < new Date()) fail('QUOTE_EXPIRED', 'The price quote has expired.');
    const total = new Prisma.Decimal(quote.total);
    const needsPayment = total.gt(0);
    const method = body.payment_method || (needsPayment ? 'bank_transfer' : 'free');
    const conversationId = await ensureConversation(user.id, quote.offering.profile.userId);
    let booking;
    try {
      booking = await prisma.$transaction(async (tx) => {
        const created = await tx.sessionBooking.create({
          data: {
            studentId: user.id,
            trainerUserId: quote.offering.profile.userId,
            profileId: quote.offering.profileId,
            offeringId: quote.offeringId,
            scheduledAt: quote.startsAt,
            endsAt: quote.endsAt,
            status: 'requested',
            paymentStatus: needsPayment ? 'unpaid' : 'paid',
            paymentMethod: method,
            priceSnapshot: quote.total,
            currency: quote.currency,
            studentNotes: cleanText(body.student_notes, 1000),
            receiptUrl: body.receipt_url || null,
            conversationId,
          },
        });
        await tx.trainerSlotLock.create({
          data: {
            trainerUserId: quote.offering.profile.userId,
            startsAt: quote.startsAt,
            bookingId: created.id,
          },
        });
        if (quote.offering.type === 'package') {
          const purchase = await tx.packagePurchase.create({
            data: {
              studentId: user.id,
              offeringId: quote.offeringId,
              sessionsTotal: quote.offering.sessionCount,
              sessionsUsed: 1,
              status: 'pending_payment',
            },
          });
          await tx.sessionBooking.update({
            where: { id: created.id },
            data: { packagePurchaseId: purchase.id },
          });
        }
        await tx.bookingQuote.update({ where: { id: quote.id }, data: { consumedAt: new Date() } });
        if (quote.couponCode) {
          await tx.coupon.updateMany({
            where: { code: quote.couponCode },
            data: { usedCount: { increment: 1 } },
          });
        }
        await tx.bookingAuditEvent.create({
          data: { bookingId: created.id, actorId: user.id, action: 'booking_created', metadata: { method, total: moneyOut(quote.total) } },
        });
        return tx.sessionBooking.findUnique({ where: { id: created.id }, include: bookingInclude });
      });
    } catch (error) {
      if (error.code === 'P2002') fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.', 409);
      throw error;
    }
    await notifyUser(booking.trainerUserId, 'حجز جديد', `${user.name} حجز جلسة.`, booking.id);
    return bookingDto(booking, user);
  });
}

async function redeemPackage(user, body) {
  const purchase = await prisma.packagePurchase.findUnique({
    where: { id: body.package_purchase_id },
    include: { offering: { include: { profile: true } } },
  });
  if (!purchase || purchase.studentId !== user.id) fail('PAYMENT_REQUIRED', 'Package not found.', 404);
  if (purchase.status !== 'active' || purchase.sessionsUsed >= purchase.sessionsTotal) {
    fail('PAYMENT_REQUIRED', 'This package has no remaining sessions.');
  }
  const slot = readSlot(body.slot_id);
  const startsAt = new Date(slot.startsAt);
  const endsAt = new Date(slot.endsAt);
  const conversationId = await ensureConversation(user.id, purchase.offering.profile.userId);
  try {
    const booking = await prisma.$transaction(async (tx) => {
      const created = await tx.sessionBooking.create({
        data: {
          studentId: user.id,
          trainerUserId: purchase.offering.profile.userId,
          profileId: purchase.offering.profileId,
          offeringId: purchase.offeringId,
          packagePurchaseId: purchase.id,
          scheduledAt: startsAt,
          endsAt,
          status: 'confirmed',
          paymentStatus: 'paid',
          paymentMethod: 'package',
          priceSnapshot: money(0),
          currency: purchase.offering.currency,
          studentNotes: cleanText(body.student_notes, 1000),
          conversationId,
        },
      });
      await tx.trainerSlotLock.create({
        data: { trainerUserId: purchase.offering.profile.userId, startsAt, bookingId: created.id },
      });
      const status = await attachMeeting(tx, created, purchase.offering.profile);
      await tx.packagePurchase.update({
        where: { id: purchase.id },
        data: { sessionsUsed: { increment: 1 } },
      });
      if (status !== 'confirmed') {
        await tx.sessionBooking.update({ where: { id: created.id }, data: { status } });
      }
      return tx.sessionBooking.findUnique({ where: { id: created.id }, include: bookingInclude });
    });
    return bookingDto(booking, user);
  } catch (error) {
    if (error.code === 'P2002') fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.', 409);
    throw error;
  }
}

const bookingInclude = {
  offering: true,
  student: { select: { id: true, name: true, avatar: true } },
  trainer: { select: { id: true, name: true, avatar: true } },
  profile: { select: { displayName: true, headline: true, avatarUrl: true, timezone: true } },
  meeting: { select: { provider: true, id: true } },
  review: { select: { id: true } },
  packagePurchase: { select: { id: true, sessionsTotal: true, sessionsUsed: true, status: true } },
};

function bookingDto(booking, viewer) {
  const cfgWindow = booking._window;
  const now = new Date();
  const isStudent = viewer?.id === booking.studentId;
  const isTrainer = viewer?.role === 'admin' || viewer?.id === booking.trainerUserId;
  const paid = booking.paymentStatus === 'paid';
  const joinableStatus = booking.status === 'scheduled' || booking.status === 'live';
  const before = (cfgWindow?.joinBeforeMinutes ?? 15) * 60000;
  const after = (cfgWindow?.joinAfterMinutes ?? 15) * 60000;
  const windowOpen = now.getTime() >= booking.scheduledAt.getTime() - before
    && now.getTime() <= booking.endsAt.getTime() + after;
  const canJoin = Boolean(isStudent || isTrainer) && paid && joinableStatus && windowOpen && Boolean(booking.meeting);
  let joinBlock = null;
  if (!paid) joinBlock = 'PAYMENT_REQUIRED';
  else if (!booking.meeting) joinBlock = 'MEETING_NOT_READY';
  else if (!joinableStatus) joinBlock = 'BOOKING_NOT_JOINABLE';
  else if (!windowOpen) joinBlock = 'JOIN_WINDOW_CLOSED';
  const hours = cfgWindow?.cancelBeforeHours ?? 12;
  const beforeDeadline = booking.scheduledAt.getTime() - now.getTime() > hours * 3600000;
  const mutable = ['requested', 'pending_payment', 'confirmed', 'scheduled'].includes(booking.status);
  return {
    id: booking.id,
    status: booking.status,
    payment_status: booking.paymentStatus,
    payment_method: booking.paymentMethod,
    package_purchase_id: booking.packagePurchaseId,
    scheduled_at: booking.scheduledAt.toISOString(),
    ends_at: booking.endsAt.toISOString(),
    amount: moneyOut(booking.priceSnapshot),
    currency: booking.currency,
    schedule_version: booking.scheduleVersion,
    student_notes: booking.studentNotes,
    receipt_url: booking.receiptUrl,
    conversation_id: booking.conversationId,
    cancellation_reason: booking.cancellationReason,
    offering: {
      id: booking.offering.id,
      type: booking.offering.type,
      title: booking.offering.title,
      duration_minutes: booking.offering.durationMinutes,
      session_count: booking.offering.sessionCount,
    },
    student_summary: isTrainer || isStudent ? {
      id: booking.student.id,
      name: booking.student.name,
      avatar_url: booking.student.avatar,
    } : undefined,
    trainer_summary: {
      id: booking.trainer.id,
      display_name: booking.profile?.displayName || booking.trainer.name,
      headline: booking.profile?.headline,
      avatar_url: booking.profile?.avatarUrl || booking.trainer.avatar,
      timezone: booking.profile?.timezone || 'Africa/Cairo',
    },
    meeting_provider: booking.meeting?.provider || null,
    can_join: canJoin,
    can_cancel: mutable && (viewer?.role === 'admin' || booking.status === 'pending_payment' || beforeDeadline),
    can_reschedule: mutable && booking.status !== 'pending_payment' && (viewer?.role === 'admin' || beforeDeadline),
    can_review: isStudent && booking.status === 'completed' && !booking.review,
    join_block_reason: canJoin ? null : joinBlock,
    server_time: now.toISOString(),
    payment: booking.paymentStatus === 'pending' ? { next_action: 'upload_receipt' } : { next_action: null },
    package_purchase: booking.packagePurchase ? {
      id: booking.packagePurchase.id,
      sessions_total: booking.packagePurchase.sessionsTotal,
      sessions_used: booking.packagePurchase.sessionsUsed,
      sessions_remaining: Math.max(0, booking.packagePurchase.sessionsTotal - booking.packagePurchase.sessionsUsed),
      status: booking.packagePurchase.status,
    } : null,
  };
}

async function settlePastBookings() {
  const cfg = await settings();
  const cutoff = new Date(Date.now() - cfg.joinAfterMinutes * 60000);
  const due = await prisma.sessionBooking.findMany({
    where: { status: { in: ['scheduled', 'live'] }, endsAt: { lt: cutoff }, paymentStatus: 'paid' },
    include: { trainer: { select: { commissionType: true, commissionValue: true } } },
  });
  for (const booking of due) {
    await prisma.sessionBooking.update({ where: { id: booking.id }, data: { status: 'completed' } });
    const already = await prisma.trainerEarningLedger.findFirst({
      where: { bookingId: booking.id, type: 'credit' },
    });
    if (!already) {
      let net = new Prisma.Decimal(booking.priceSnapshot);
      if (booking.trainer.commissionType === 'percentage' && booking.trainer.commissionValue) {
        const fee = net.mul(booking.trainer.commissionValue).div(100);
        net = net.minus(fee);
      } else if (['per_sale', 'per_student'].includes(booking.trainer.commissionType) && booking.trainer.commissionValue) {
        net = Prisma.Decimal.max(money(0), net.minus(booking.trainer.commissionValue));
      }
      if (net.gt(0)) {
        await prisma.trainerEarningLedger.create({
          data: {
            trainerUserId: booking.trainerUserId,
            bookingId: booking.id,
            type: 'credit',
            amount: money(net),
            currency: booking.currency,
            note: 'completed_session',
          },
        });
      }
    }
    await prisma.trainerProfile.update({
      where: { id: booking.profileId },
      data: { completedSessionsCount: { increment: 1 } },
    });
    await notifyUser(booking.studentId, 'انتهت الجلسة', 'يمكنك تقييم الجلسة الآن.', booking.id);
  }
}

async function loadBookingFor(user, id) {
  await settlePastBookings();
  const booking = await prisma.sessionBooking.findUnique({ where: { id }, include: bookingInclude });
  if (!booking) fail('NOT_FOUND', 'Booking not found', 404);
  const allowed = user.role === 'admin' || user.id === booking.studentId || user.id === booking.trainerUserId;
  if (!allowed) fail('BOOKING_NOT_JOINABLE', 'You cannot access this booking.', 403);
  const cfg = await settings();
  booking._window = cfg;
  return booking;
}

export async function respondBooking(user, id, body) {
  const booking = await prisma.sessionBooking.findUnique({
    where: { id },
    include: { offering: { include: { profile: true } } },
  });
  if (!booking || (booking.trainerUserId !== user.id && user.role !== 'admin')) {
    fail('NOT_FOUND', 'Booking not found', 404);
  }
  if (booking.status !== 'requested') fail('BOOKING_NOT_JOINABLE', 'This request was already handled.');
  if (body.accept === false) {
    await prisma.$transaction(async (tx) => {
      await tx.sessionBooking.update({
        where: { id },
        data: { status: 'cancelled', cancellationReason: cleanText(body.reason, 500) || 'rejected by tutor' },
      });
      await tx.trainerSlotLock.deleteMany({ where: { bookingId: id } });
      if (booking.packagePurchaseId) {
        await tx.packagePurchase.update({ where: { id: booking.packagePurchaseId }, data: { status: 'cancelled' } });
      }
    });
    return getBooking(user, id);
  }
  const needsPayment = new Prisma.Decimal(booking.priceSnapshot).gt(0) && booking.paymentStatus !== 'paid';
  await prisma.$transaction(async (tx) => {
    let status = needsPayment ? 'pending_payment' : 'confirmed';
    if (!needsPayment) {
      const next = await attachMeeting(tx, booking, booking.offering.profile);
      if (next === 'scheduled') status = 'scheduled';
    }
    await tx.sessionBooking.update({
      where: { id },
      data: { status, paymentStatus: needsPayment ? 'pending' : 'paid' },
    });
    if (booking.packagePurchaseId && !needsPayment) {
      await tx.packagePurchase.update({ where: { id: booking.packagePurchaseId }, data: { status: 'active' } });
    }
  });
  return getBooking(user, id);
}

export async function listBookings(user, query) {
  await settlePastBookings();
  const page = Math.max(1, Number(query.page) || 1);
  const perPage = Math.min(50, Math.max(1, Number(query.per_page) || 20));
  const where = {};
  const role = query.role;
  if (user.role === 'admin' && role === 'admin') {
    // full list
  } else if ((user.role === 'instructor' || user.role === 'admin') && role === 'instructor') {
    where.trainerUserId = user.role === 'admin' && query.trainer_id ? query.trainer_id : user.id;
  } else {
    where.studentId = user.id;
  }
  if (query.status) where.status = query.status;
  if (query.payment_status) where.paymentStatus = query.payment_status;
  const [total, rows] = await Promise.all([
    prisma.sessionBooking.count({ where }),
    prisma.sessionBooking.findMany({
      where,
      include: bookingInclude,
      orderBy: { scheduledAt: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
    }),
  ]);
  const cfg = await settings();
  return {
    bookings: rows.map((row) => bookingDto({ ...row, _window: cfg }, user)),
    pagination: { page, per_page: perPage, total },
    server_time: new Date().toISOString(),
  };
}

export async function getBooking(user, id) {
  const booking = await loadBookingFor(user, id);
  return bookingDto(booking, user);
}

export async function uploadReceipt(user, id, receiptUrl) {
  const booking = await loadBookingFor(user, id);
  if (user.id !== booking.studentId && user.role !== 'admin') fail('PAYMENT_REQUIRED', 'Only the student can upload a receipt.', 403);
  const updated = await prisma.sessionBooking.update({
    where: { id },
    data: { receiptUrl, paymentStatus: 'pending' },
    include: bookingInclude,
  });
  updated._window = booking._window;
  await audit(id, user.id, 'receipt_uploaded', null);
  return bookingDto(updated, user);
}

export async function approvePayment(admin, id, approve) {
  const booking = await loadBookingFor(admin, id);
  if (!approve) {
    await releaseBooking(id, admin.id, 'payment_rejected');
    const updated = await prisma.sessionBooking.update({
      where: { id },
      data: { status: 'cancelled', paymentStatus: 'failed', cancelledById: admin.id, cancellationReason: 'payment_rejected' },
      include: bookingInclude,
    });
    updated._window = booking._window;
    await notifyUser(booking.studentId, 'تم رفض الإيصال', 'لم يتم تأكيد الدفع. اختر موعداً آخر.', id);
    return bookingDto(updated, admin);
  }
  const profile = await prisma.trainerProfile.findUnique({ where: { id: booking.profileId } });
  const updated = await prisma.$transaction(async (tx) => {
    let status = 'confirmed';
    const existingMeeting = await tx.meetingSession.findUnique({ where: { bookingId: id } });
    if (!existingMeeting && profile?.defaultJoinUrl) {
      await tx.meetingSession.create({
        data: {
          bookingId: id,
          provider: profile.defaultMeetingProvider || 'custom_web',
          joinUrl: profile.defaultJoinUrl,
          hostUrl: profile.defaultJoinUrl,
        },
      });
      status = 'scheduled';
    } else if (existingMeeting) status = 'scheduled';
    await tx.packagePurchase.updateMany({
      where: { studentId: booking.studentId, offeringId: booking.offeringId, status: 'pending_payment' },
      data: { status: 'active' },
    });
    return tx.sessionBooking.update({
      where: { id },
      data: { paymentStatus: 'paid', status },
      include: bookingInclude,
    });
  });
  updated._window = booking._window;
  await audit(id, admin.id, 'payment_approved', null);
  await notifyUser(booking.studentId, 'تم تأكيد الحجز', 'دفعتك اتأكدت والجلسة اتسجلت.', id);
  await notifyUser(booking.trainerUserId, 'دفعة مؤكدة', 'في حجز مدفوع على جدولك.', id);
  return bookingDto(updated, admin);
}

async function releaseBooking(id, actorId, reason) {
  await prisma.trainerSlotLock.deleteMany({ where: { bookingId: id } });
  await audit(id, actorId, 'slot_released', { reason });
}

export async function cancelBooking(user, id, reason) {
  const booking = await loadBookingFor(user, id);
  const dto = bookingDto(booking, user);
  if (!dto.can_cancel) fail('CANCELLATION_NOT_ALLOWED', 'This booking can no longer be cancelled.');
  await releaseBooking(id, user.id, reason || 'cancelled');
  if (booking.paymentStatus === 'paid' && new Prisma.Decimal(booking.priceSnapshot).gt(0)) {
    await prisma.trainerEarningLedger.create({
      data: {
        trainerUserId: booking.trainerUserId,
        bookingId: id,
        type: 'refund',
        amount: booking.priceSnapshot,
        currency: booking.currency,
        note: 'cancellation',
      },
    });
  }
  const updated = await prisma.sessionBooking.update({
    where: { id },
    data: {
      status: 'cancelled',
      paymentStatus: booking.paymentStatus === 'paid' ? 'refunded' : booking.paymentStatus,
      cancelledById: user.id,
      cancellationReason: cleanText(reason, 500),
    },
    include: bookingInclude,
  });
  updated._window = booking._window;
  const other = user.id === booking.studentId ? booking.trainerUserId : booking.studentId;
  await notifyUser(other, 'تم إلغاء الجلسة', cleanText(reason, 180) || 'تم إلغاء الحجز.', id);
  return bookingDto(updated, user);
}

export async function rescheduleBooking(user, id, body) {
  const booking = await loadBookingFor(user, id);
  const dto = bookingDto(booking, user);
  if (!dto.can_reschedule) fail('RESCHEDULE_CONFLICT', 'This booking cannot be rescheduled.');
  if (Number(body.expected_schedule_version) !== booking.scheduleVersion) {
    fail('RESCHEDULE_CONFLICT', 'The booking changed. Refresh and try again.', 409);
  }
  const slot = readSlot(body.slot_id);
  if (slot.trainerUserId !== booking.trainerUserId) fail('SLOT_NO_LONGER_AVAILABLE', 'The selected time is no longer available.');
  const startsAt = new Date(slot.startsAt);
  const endsAt = new Date(slot.endsAt);
  try {
    const updated = await prisma.$transaction(async (tx) => {
      await tx.trainerSlotLock.deleteMany({ where: { bookingId: id } });
      await tx.trainerSlotLock.create({
        data: { trainerUserId: booking.trainerUserId, startsAt, bookingId: id },
      });
      const result = await tx.sessionBooking.updateMany({
        where: { id, scheduleVersion: booking.scheduleVersion },
        data: {
          scheduledAt: startsAt,
          endsAt,
          scheduleVersion: { increment: 1 },
          status: booking.meeting ? 'scheduled' : booking.status,
        },
      });
      if (result.count !== 1) throw Object.assign(new Error('conflict'), { code: 'RESCHEDULE' });
      await tx.bookingAuditEvent.create({
        data: { bookingId: id, actorId: user.id, action: 'rescheduled', metadata: { startsAt: startsAt.toISOString(), reason: body.reason || null } },
      });
      return tx.sessionBooking.findUnique({ where: { id }, include: bookingInclude });
    });
    updated._window = booking._window;
    await notifyUser(booking.studentId, 'تم تغيير موعد الجلسة', 'راجع الموعد الجديد من حجوزاتي.', id);
    await notifyUser(booking.trainerUserId, 'تم تغيير موعد الجلسة', 'فيه حجز اتغير ميعاده.', id);
    return bookingDto(updated, user);
  } catch (error) {
    if (error.code === 'P2002' || error.code === 'RESCHEDULE') {
      fail('RESCHEDULE_CONFLICT', 'That time is no longer available.', 409);
    }
    throw error;
  }
}

export async function publishMeeting(user, id, body) {
  const booking = await loadBookingFor(user, id);
  if (user.id !== booking.trainerUserId && user.role !== 'admin') {
    fail('MEETING_NOT_READY', 'Only the trainer can publish the meeting link.', 403);
  }
  const joinUrl = String(body.join_url || '').trim();
  if (!/^https:\/\//i.test(joinUrl)) fail('MEETING_NOT_READY', 'A valid https meeting link is required.');
  const provider = ['teams', 'zoom', 'jitsi', 'custom_web'].includes(body.provider) ? body.provider : 'custom_web';
  await prisma.meetingSession.upsert({
    where: { bookingId: id },
    update: { joinUrl, hostUrl: body.host_url || joinUrl, provider },
    create: { bookingId: id, joinUrl, hostUrl: body.host_url || joinUrl, provider },
  });
  const updated = await prisma.sessionBooking.update({
    where: { id },
    data: { status: booking.paymentStatus === 'paid' ? 'scheduled' : booking.status },
    include: bookingInclude,
  });
  updated._window = booking._window;
  await audit(id, user.id, 'meeting_published', { provider });
  await notifyUser(booking.studentId, 'رابط الجلسة جاهز', 'تقدر تدخل الجلسة من التطبيق في ميعادها.', id);
  return bookingDto(updated, user);
}

export async function joinBooking(user, id) {
  const booking = await loadBookingFor(user, id);
  const dto = bookingDto(booking, user);
  if (!dto.can_join) fail(dto.join_block_reason || 'BOOKING_NOT_JOINABLE', 'This session cannot be joined right now.', 409);
  const meeting = await prisma.meetingSession.findUnique({ where: { bookingId: id } });
  if (!meeting?.joinUrl) fail('MEETING_NOT_READY', 'The meeting link is not ready yet.', 409);
  if (booking.status === 'scheduled') {
    await prisma.sessionBooking.update({ where: { id }, data: { status: 'live' } });
  }
  const token = crypto.randomBytes(24).toString('base64url');
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const expiresAt = new Date(Date.now() + 10 * 60000);
  await prisma.joinGrant.create({ data: { bookingId: id, userId: user.id, tokenHash, expiresAt } });
  await audit(id, user.id, 'join_token_created', null);
  const base = process.env.PUBLIC_API_URL || 'https://bouslty.anmka.com/api';
  return {
    join_token: token,
    join_url: `${base.replace(/\/$/, '')}/live/join/${token}`,
    expires_at: expiresAt.toISOString(),
    open_mode: 'in_app_webview',
    fallback_allowed: true,
    server_time: new Date().toISOString(),
  };
}

export async function consumeJoinToken(token) {
  const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
  const grant = await prisma.joinGrant.findUnique({ where: { tokenHash } });
  if (!grant || grant.expiresAt < new Date()) fail('JOIN_WINDOW_CLOSED', 'This join link has expired.', 410);
  const meeting = await prisma.meetingSession.findUnique({ where: { bookingId: grant.bookingId } });
  if (!meeting?.joinUrl) fail('MEETING_NOT_READY', 'The meeting link is not ready yet.', 409);
  await prisma.joinGrant.delete({ where: { id: grant.id } });
  return meeting.joinUrl;
}

export async function addReview(user, id, body) {
  const booking = await loadBookingFor(user, id);
  const dto = bookingDto(booking, user);
  if (!dto.can_review) fail('REVIEW_NOT_ALLOWED', 'This booking cannot be reviewed.');
  const rating = Number(body.rating);
  if (!Number.isInteger(rating) || rating < 1 || rating > 5) fail('REVIEW_NOT_ALLOWED', 'Rating must be from 1 to 5.');
  const review = await prisma.bookingReview.create({
    data: {
      bookingId: id,
      studentId: user.id,
      trainerUserId: booking.trainerUserId,
      rating,
      comment: cleanText(body.comment, 1000),
    },
  });
  const agg = await prisma.bookingReview.aggregate({
    where: { trainerUserId: booking.trainerUserId, isHidden: false },
    _avg: { rating: true },
    _count: { rating: true },
  });
  await prisma.trainerProfile.update({
    where: { userId: booking.trainerUserId },
    data: {
      ratingAverage: money(agg._avg.rating || 0),
      ratingCount: agg._count.rating,
    },
  });
  await audit(id, user.id, 'reviewed', { rating });
  return { id: review.id, rating: review.rating, comment: review.comment };
}

export async function listReviews(userId, query) {
  const page = Math.max(1, Number(query.page) || 1);
  const perPage = 20;
  const where = { trainerUserId: userId, isHidden: false };
  const [total, rows] = await Promise.all([
    prisma.bookingReview.count({ where }),
    prisma.bookingReview.findMany({
      where,
      orderBy: { createdAt: 'desc' },
      skip: (page - 1) * perPage,
      take: perPage,
      include: { student: { select: { name: true } } },
    }),
  ]);
  return {
    reviews: rows.map((review) => ({
      id: review.id,
      rating: review.rating,
      comment: review.comment,
      created_at: review.createdAt.toISOString(),
      student_name: review.student?.name || '',
    })),
    pagination: { page, per_page: perPage, total },
  };
}

function profileOwner(user) {
  return prisma.trainerProfile.findUnique({
    where: { userId: user.id },
    include: { specialties: true, qualifications: true, offerings: true, availabilityRules: true, availabilityExceptions: true },
  });
}

export async function getMyTrainerProfile(user) {
  await syncInstructorProfiles();
  const [profile, cfg] = await Promise.all([profileOwner(user), settings()]);
  if (!profile) fail('NOT_FOUND', 'Trainer profile not found', 404);
  return {
    ...publicCard(profile),
    bio: profile.bio,
    social_links: profile.socialLinks || {},
    qualifications: profile.qualifications,
    offerings: profile.offerings.map(offeringDto),
    default_meeting_provider: profile.defaultMeetingProvider,
    default_join_url: profile.defaultJoinUrl || '',
    has_default_join_url: Boolean(profile.defaultJoinUrl),
    rejection_note: profile.rejectionNote,
    timezone: profile.timezone,
    slot_duration_minutes: profile.slotDurationMinutes,
    buffer_minutes: profile.bufferMinutes,
    price_options_usd: configuredPriceOptions(cfg),
  };
}

export async function updateMyTrainerProfile(user, body) {
  const [profile, cfg] = await Promise.all([profileOwner(user), settings()]);
  if (!profile) fail('NOT_FOUND', 'Trainer profile not found', 404);
  const has = (key) => Object.prototype.hasOwnProperty.call(body, key);
  const social = {};
  if (body.social_links && typeof body.social_links === 'object') {
    for (const key of ALLOWED_SOCIAL) {
      const value = body.social_links[key];
      if (typeof value === 'string' && /^https:\/\//i.test(value)) social[key] = value.slice(0, 300);
    }
  }
  // PUT is intentionally patch-like: the offerings screen sends no profile
  // fields and must never blank the trainer's headline or biography.
  const data = {};
  if (has('display_name')) data.displayName = cleanText(body.display_name, 255) || profile.displayName;
  if (has('headline')) data.headline = cleanText(body.headline, 255);
  if (has('bio')) data.bio = cleanText(body.bio, 4000);
  if (has('intro_video_url')) {
    data.introVideoUrl = introVideoUrl(body.intro_video_url, profile.introVideoUrl);
  }
  if (has('avatar_url')) data.avatarUrl = body.avatar_url || null;
  if (has('years_experience')) data.yearsExperience = body.years_experience == null ? null : Math.max(0, Number(body.years_experience) || 0);
  if (has('languages') && Array.isArray(body.languages)) data.languages = body.languages.map((item) => String(item).slice(0, 8)).slice(0, 8);
  if (has('social_links')) data.socialLinks = social;
  if (has('is_accepting_bookings')) {
    data.isAcceptingBookings = profile.verificationStatus === 'approved'
      ? Boolean(body.is_accepting_bookings)
      : false;
  }
  if (has('timezone') && body.timezone) data.timezone = body.timezone;
  if (has('category_id')) data.categoryId = body.category_id || null;
  if (has('subcategory_id')) data.subcategoryId = body.subcategory_id || null;
  if (body.default_join_url === '') data.defaultJoinUrl = null;
  else if (body.default_join_url && /^https:\/\//i.test(body.default_join_url)) data.defaultJoinUrl = body.default_join_url;
  if (body.default_meeting_provider) data.defaultMeetingProvider = body.default_meeting_provider;
  await prisma.$transaction(async (tx) => {
    await tx.trainerProfile.update({ where: { id: profile.id }, data });
    if (Array.isArray(body.specialties)) {
      await tx.trainerSpecialty.deleteMany({ where: { profileId: profile.id } });
      await tx.trainerSpecialty.createMany({
        data: body.specialties.slice(0, 12).map((name) => ({ profileId: profile.id, name: String(name).slice(0, 120) })),
      });
    }
    if (Array.isArray(body.qualifications)) {
      await tx.trainerQualification.deleteMany({ where: { profileId: profile.id } });
      await tx.trainerQualification.createMany({
        data: body.qualifications.slice(0, 12).map((item) => ({
          profileId: profile.id,
          title: String(item.title || '').slice(0, 255),
          issuer: item.issuer ? String(item.issuer).slice(0, 255) : null,
          year: item.year ? Number(item.year) : null,
        })).filter((item) => item.title),
      });
    }
    if (Array.isArray(body.offerings)) {
      const allowedPrices = configuredPriceOptions(cfg);
      if (!allowedPrices.length) {
        fail('PRICE_NOT_ALLOWED', 'Admin has not configured session prices yet.');
      }
      for (const offering of body.offerings.slice(0, 8)) {
        const price = money(offering.price);
        const discount = offering.discount_price == null || offering.discount_price === ''
          ? null
          : money(offering.discount_price);
        const priceAllowed = allowedPrices.some((value) => new Prisma.Decimal(value).eq(price));
        const discountAllowed = discount == null
          || allowedPrices.some((value) => new Prisma.Decimal(value).eq(discount));
        if (!priceAllowed || !discountAllowed) {
          fail('PRICE_NOT_ALLOWED', 'Choose a price configured by the admin.');
        }
        if (discount && new Prisma.Decimal(discount).gte(price)) fail('PAYOUT_NOT_ALLOWED', 'Discount must be less than the price.');
        const payload = {
          type: ['single_session', 'package', 'course'].includes(offering.type) ? offering.type : 'single_session',
          title: String(offering.title || 'جلسة').slice(0, 255),
          description: cleanText(offering.description, 2000),
          durationMinutes: Math.max(15, Number(offering.duration_minutes) || 60),
          sessionCount: Math.max(1, Number(offering.session_count) || 1),
          price,
          discountPrice: discount,
          currency: 'USD',
          isActive: offering.is_active !== false,
          courseId: offering.course_id || null,
        };
        if (offering.id) {
          await tx.trainerOffering.updateMany({ where: { id: offering.id, profileId: profile.id }, data: payload });
        } else {
          await tx.trainerOffering.create({ data: { ...payload, profileId: profile.id } });
        }
      }
    }
    if (Array.isArray(body.deleted_offering_ids) && body.deleted_offering_ids.length) {
      // Preserve booking history while removing these items from students.
      await tx.trainerOffering.updateMany({
        where: {
          profileId: profile.id,
          id: { in: body.deleted_offering_ids.map(String).slice(0, 8) },
        },
        data: { isActive: false },
      });
    }
  });
  return getMyTrainerProfile(user);
}

export async function getMyAvailability(user) {
  const profile = await profileOwner(user);
  if (!profile) fail('NOT_FOUND', 'Trainer profile not found', 404);
  return {
    timezone: profile.timezone,
    slot_duration_minutes: profile.slotDurationMinutes,
    buffer_minutes: profile.bufferMinutes,
    rules: profile.availabilityRules.map((rule) => ({
      id: rule.id,
      weekday: rule.weekday,
      start_minute: rule.startMinute,
      end_minute: rule.endMinute,
    })),
    exceptions: profile.availabilityExceptions.map((item) => ({
      id: item.id,
      date: item.date.toISOString().slice(0, 10),
      is_blocked: item.isBlocked,
      note: item.note,
    })),
  };
}

export async function putMyAvailability(user, body) {
  const profile = await profileOwner(user);
  if (!profile) fail('NOT_FOUND', 'Trainer profile not found', 404);
  const rules = Array.isArray(body.rules) ? body.rules : [];
  for (const rule of rules) {
    if (rule.weekday < 0 || rule.weekday > 6) fail('RESCHEDULE_CONFLICT', 'Weekday must be 0-6.');
    if (rule.start_minute < 0 || rule.end_minute > 1440 || rule.start_minute >= rule.end_minute) {
      fail('RESCHEDULE_CONFLICT', 'Availability interval is invalid.');
    }
  }
  const sameDay = rules.filter((left, index) => rules.some((right, other) => other !== index && left.weekday === right.weekday
    && left.start_minute < right.end_minute && right.start_minute < left.end_minute));
  if (sameDay.length) fail('RESCHEDULE_CONFLICT', 'Availability intervals overlap.');
  await prisma.$transaction(async (tx) => {
    await tx.trainerProfile.update({
      where: { id: profile.id },
      data: {
        timezone: body.timezone || profile.timezone,
        slotDurationMinutes: Math.max(15, Number(body.slot_duration_minutes) || profile.slotDurationMinutes),
        bufferMinutes: Math.max(0, Number(body.buffer_minutes) || 0),
      },
    });
    await tx.trainerAvailabilityRule.deleteMany({ where: { profileId: profile.id } });
    await tx.trainerAvailabilityRule.createMany({
      data: rules.map((rule) => ({
        profileId: profile.id,
        weekday: Number(rule.weekday),
        startMinute: Number(rule.start_minute),
        endMinute: Number(rule.end_minute),
      })),
    });
  });
  return getMyAvailability(user);
}

export async function addException(user, body) {
  const profile = await profileOwner(user);
  if (!profile) fail('NOT_FOUND', 'Trainer profile not found', 404);
  const date = parseDateKey(body.date);
  if (!date) fail('RESCHEDULE_CONFLICT', 'Date is required.');
  const created = await prisma.trainerAvailabilityException.create({
    data: {
      profileId: profile.id,
      date: new Date(Date.UTC(date.year, date.month - 1, date.day)),
      isBlocked: body.is_blocked !== false,
      note: cleanText(body.note, 255),
    },
  });
  return { id: created.id, date: body.date, is_blocked: created.isBlocked, note: created.note };
}

export async function deleteException(user, id) {
  const profile = await profileOwner(user);
  if (!profile) fail('NOT_FOUND', 'Trainer profile not found', 404);
  await prisma.trainerAvailabilityException.deleteMany({ where: { id, profileId: profile.id } });
  return { deleted: true };
}

export async function earnings(user, query) {
  const from = query.from ? new Date(query.from) : new Date(Date.now() - 30 * 86400000);
  const to = query.to ? new Date(query.to) : new Date();
  const rows = await prisma.trainerEarningLedger.findMany({
    where: { trainerUserId: user.id, createdAt: { gte: from, lte: to } },
    orderBy: { createdAt: 'desc' },
  });
  const all = await prisma.trainerEarningLedger.findMany({ where: { trainerUserId: user.id } });
  const payouts = await prisma.payoutRequest.findMany({ where: { trainerUserId: user.id, status: { in: ['pending', 'approved'] } } });
  const sum = (list, type) => list.filter((row) => row.type === type).reduce((acc, row) => acc.plus(row.amount), new Prisma.Decimal(0));
  const net = sum(all, 'credit').minus(sum(all, 'debit')).minus(sum(all, 'refund'));
  const reserved = payouts.reduce((acc, row) => acc.plus(row.amount), new Prisma.Decimal(0));
  return {
    currency: rows[0]?.currency || 'EGP',
    available: moneyOut(Prisma.Decimal.max(money(0), net.minus(reserved))),
    pending: moneyOut(reserved),
    paid: moneyOut(sum(all, 'debit')),
    entries: rows.map((row) => ({
      id: row.id,
      booking_id: row.bookingId,
      type: row.type,
      amount: moneyOut(row.amount),
      currency: row.currency,
      note: row.note,
      created_at: row.createdAt.toISOString(),
    })),
  };
}

export async function requestPayout(user, body) {
  const summary = await earnings(user, {});
  const amount = money(body.amount);
  if (new Prisma.Decimal(amount).lte(0) || new Prisma.Decimal(amount).gt(summary.available)) {
    fail('PAYOUT_NOT_ALLOWED', 'Payout amount is above the available balance.');
  }
  const created = await prisma.payoutRequest.create({
    data: {
      trainerUserId: user.id,
      amount,
      currency: body.currency || summary.currency || 'EGP',
      note: cleanText(body.note, 500),
    },
  });
  return payoutDto(created);
}

export async function listPayouts(user) {
  const rows = await prisma.payoutRequest.findMany({
    where: { trainerUserId: user.id },
    orderBy: { createdAt: 'desc' },
  });
  return { payouts: rows.map(payoutDto) };
}

function payoutDto(row) {
  return {
    id: row.id,
    amount: moneyOut(row.amount),
    currency: row.currency,
    status: row.status,
    note: row.note,
    admin_note: row.adminNote,
    created_at: row.createdAt.toISOString(),
  };
}

export async function adminListTrainers(query) {
  const where = {};
  if (query.status && query.status !== 'all') where.verificationStatus = String(query.status);
  const q = String(query.q || '').trim();
  if (q) {
    where.OR = [
      { displayName: { contains: q } },
      { headline: { contains: q } },
      { user: { email: { contains: q } } },
      { user: { phone: { contains: q } } },
    ];
  }
  const rows = await prisma.trainerProfile.findMany({
    where,
    include: profileInclude,
    orderBy: { updatedAt: 'desc' },
    take: 100,
  });
  return {
    trainers: rows.map((row) => ({
      ...publicCard(row),
      offerings_count: row.offerings.length,
      active_offerings_count: row.offerings.filter((item) => item.isActive).length,
    })),
  };
}

export async function adminGetTrainer(userId) {
  const [profile, availability] = await Promise.all([
    getMyTrainerProfile({ id: userId }),
    getMyAvailability({ id: userId }),
  ]);
  const user = await prisma.user.findUnique({
    where: { id: userId },
    select: { email: true, phone: true, status: true },
  });
  return { ...profile, availability, user };
}

export async function adminUpdateTrainer(userId, body) {
  await updateMyTrainerProfile({ id: userId }, body);
  return adminGetTrainer(userId);
}

export async function adminUpdateTrainerAvailability(userId, body) {
  await putMyAvailability({ id: userId }, body);
  return adminGetTrainer(userId);
}

export async function adminListBookings(query) {
  return listBookings({ id: 'admin', role: 'admin' }, { ...query, role: 'admin' });
}

export async function adminSetVerification(userId, body) {
  const status = body.verification_status;
  if (!['draft', 'pending', 'approved', 'rejected', 'suspended'].includes(status)) {
    fail('PAYOUT_NOT_ALLOWED', 'Unknown verification status.');
  }
  await prisma.trainerProfile.update({
    where: { userId },
    data: {
      verificationStatus: status,
      rejectionNote: cleanText(body.note, 1000),
      isAcceptingBookings: status === 'approved',
    },
  });
  return getTrainer(userId);
}

export async function adminDecidePayout(id, body) {
  const payout = await prisma.payoutRequest.findUnique({ where: { id } });
  if (!payout || payout.status !== 'pending') fail('PAYOUT_NOT_ALLOWED', 'Payout cannot be changed.');
  if (body.status === 'rejected') {
    const updated = await prisma.payoutRequest.update({
      where: { id },
      data: { status: 'rejected', adminNote: cleanText(body.note, 500) },
    });
    return payoutDto(updated);
  }
  const updated = await prisma.$transaction(async (tx) => {
    await tx.trainerEarningLedger.create({
      data: {
        trainerUserId: payout.trainerUserId,
        type: 'debit',
        amount: payout.amount,
        currency: payout.currency,
        note: `payout:${payout.id}`,
      },
    });
    return tx.payoutRequest.update({
      where: { id },
      data: { status: 'paid', adminNote: cleanText(body.note, 500) },
    });
  });
  return payoutDto(updated);
}

export async function adminUpdateSettings(body) {
  const update = {};
  if (body.join_before_minutes != null) update.joinBeforeMinutes = Number(body.join_before_minutes) || 15;
  if (body.join_after_minutes != null) update.joinAfterMinutes = Number(body.join_after_minutes) || 15;
  if (body.cancel_before_hours != null) update.cancelBeforeHours = Number(body.cancel_before_hours) || 12;
  if (body.default_currency != null) update.defaultCurrency = String(body.default_currency).slice(0, 3);
  if (Array.isArray(body.price_options_usd)) {
    const prices = [...new Set(body.price_options_usd
      .map((value) => Number(value))
      .filter((value) => Number.isFinite(value) && value > 0))]
      .sort((a, b) => a - b)
      .slice(0, 50);
    update.priceOptionsUsd = JSON.stringify(prices);
    update.defaultCurrency = 'USD';
  }
  if (Array.isArray(body.paths)) {
    update.paths = JSON.stringify(
      body.paths.map((p) => String(p).trim()).filter(Boolean).slice(0, 40),
    );
  }
  return prisma.marketplaceSetting.upsert({
    where: { id: 'default' },
    update,
    create: { id: 'default' },
  });
}

export async function adminGetSettings() {
  const cfg = await settings();
  return {
    join_before_minutes: cfg.joinBeforeMinutes,
    join_after_minutes: cfg.joinAfterMinutes,
    cancel_before_hours: cfg.cancelBeforeHours,
    default_currency: 'USD',
    price_options_usd: configuredPriceOptions(cfg),
  };
}

/** Public discover paths controlled by admin marketplace settings. */
export async function publicPaths() {
  const cfg = await settings();
  let paths = [];
  try {
    paths = JSON.parse(cfg.paths || '[]');
  } catch {
    paths = [];
  }
  if (!Array.isArray(paths)) paths = [];
  return { paths: paths.map((p) => String(p)).filter(Boolean) };
}

export async function adminListPayouts() {
  const rows = await prisma.payoutRequest.findMany({
    orderBy: { createdAt: 'desc' },
    take: 100,
    include: { trainer: { select: { name: true } } },
  });
  return rows.map((row) => ({ ...payoutDto(row), trainer_name: row.trainer?.name }));
}
