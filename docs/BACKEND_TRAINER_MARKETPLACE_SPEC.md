# Backend Specification — Trainer Marketplace and Live Booking

> Shared scope and priorities: [CLIENT_REQUIREMENTS_IMPLEMENTATION_PLAN.md](./CLIENT_REQUIREMENTS_IMPLEMENTATION_PLAN.md)
>
> This document extends the existing course/live-session APIs. Existing course purchases must remain backward-compatible.

## 1. Backend Principles

- Backend owns prices, discounts, access, booking state, meeting credentials, and payout calculations.
- All mutation endpoints use authentication, authorization, validation, and audit logging.
- Payment and booking creation must be idempotent.
- Store timestamps in UTC.
- Never expose meeting-provider host credentials to students.
- Return stable canonical fields; do not require Flutter to parse multiple historical aliases for new endpoints.

## 2. Recommended Data Model

### `trainer_profiles`

| Field | Type | Notes |
|---|---|---|
| `user_id` | FK | Unique instructor user. |
| `display_name` | string | Public name. |
| `headline` | string | Short specialization headline. |
| `bio` | text | Public biography. |
| `intro_video_url` | string nullable | Validated media URL. |
| `avatar_url` | string nullable | Public image. |
| `years_experience` | integer nullable | Non-negative. |
| `languages` | JSON/related table | Language codes. |
| `specialties` | related table | Searchable taxonomy. |
| `qualifications` | related table | Degree/certificate metadata. |
| `social_links` | JSON | Allowlisted providers/URLs. |
| `verification_status` | enum | `draft`, `pending`, `approved`, `rejected`, `suspended`. |
| `is_accepting_bookings` | boolean | Admin/trainer controlled. |

Public aggregate fields such as `rating_average`, `rating_count`, `completed_sessions_count`, and `students_count` may be materialized but must be derived from canonical records.

### `trainer_offerings`

Represents something a student can buy/book.

| Field | Type | Notes |
|---|---|---|
| `id` | ID | |
| `trainer_id` | FK | |
| `type` | enum | `single_session`, `package`, `course`. |
| `title` | string | |
| `description` | text nullable | |
| `duration_minutes` | integer | Per session. |
| `session_count` | integer | `1` for a single session. |
| `price` | decimal | Never trust client totals. |
| `discount_price` | decimal nullable | Must be less than `price`. |
| `currency` | ISO 4217 | Example: `EGP`, `SAR`. |
| `is_active` | boolean | |

### `trainer_availability_rules`

- Weekly recurring intervals in the trainer's IANA timezone.
- Effective date range.
- Slot duration and buffer time.
- Exceptions/blocked dates stored separately.

### `bookings`

| Field | Type | Notes |
|---|---|---|
| `id` | ID/UUID | Public opaque ID preferred. |
| `student_id` | FK | |
| `trainer_id` | FK | |
| `offering_id` | FK | |
| `package_purchase_id` | FK nullable | For package redemption. |
| `scheduled_at` | UTC timestamp | |
| `ends_at` | UTC timestamp | Derived and stored. |
| `status` | enum | Canonical lifecycle enum. |
| `payment_status` | enum | `unpaid`, `pending`, `paid`, `failed`, `refunded`, `partially_refunded`. |
| `price_snapshot` | decimal | Immutable booked price. |
| `currency` | string | Immutable currency. |
| `schedule_version` | integer | Increment on reschedule. |
| `student_notes` | text nullable | Length-limited/sanitized. |
| `cancelled_by` | FK nullable | |
| `cancellation_reason` | text nullable | |

Prevent double booking with a database constraint/transaction, not only an application-level check.

### `meeting_sessions`

| Field | Type | Notes |
|---|---|---|
| `booking_id` | FK unique | One active meeting per booking initially. |
| `provider` | enum | `teams`, `zoom`, `jitsi`, `custom_web`. |
| `provider_meeting_id` | encrypted string | Internal only. |
| `host_url` | encrypted text | Trainer/admin only. |
| `join_url` | encrypted text | Do not return directly from booking list. |
| `provider_metadata` | encrypted JSON | No secrets in logs. |

Return a short-lived redirect/token from the join endpoint rather than persisting the provider URL in Flutter.

### Supporting records

- `package_purchases` and `package_credits`
- `payments` and immutable `payment_events`
- `booking_reviews`
- `conversations` and `messages`
- `trainer_earnings_ledger`
- `payout_requests`
- `booking_audit_events`

## 3. API Contract

All examples omit the common envelope where the current API already uses one. Keep one consistent envelope across new endpoints.

### 3.1 Trainer discovery

```http
GET /api/trainers?q=motion&specialty_id=3&language=ar&min_rating=4&available_from=2026-11-05T00:00:00Z&page=1&per_page=20
```

```json
{
  "data": [
    {
      "id": 7,
      "display_name": "أحمد محمد",
      "headline": "مدرب موشن جرافيك",
      "avatar_url": "https://...",
      "intro_video_thumbnail_url": "https://...",
      "rating_average": 4.9,
      "rating_count": 33,
      "completed_sessions_count": 417,
      "students_count": 150,
      "starting_price": 230,
      "currency": "SAR",
      "specialties": [{"id": 3, "name": "Motion Graphics"}],
      "is_accepting_bookings": true
    }
  ],
  "pagination": {"page": 1, "per_page": 20, "total": 1}
}
```

### 3.2 Trainer profile

```http
GET /api/trainers/{trainer_id}
```

Return public profile fields, aggregates, active offerings, next available slot summary, and recent approved reviews. Do not return private contact details unless product rules explicitly allow them.

### 3.3 Availability

```http
GET /api/trainers/{trainer_id}/availability?from=2026-11-05&to=2026-11-19&timezone=Africa/Cairo
```

```json
{
  "trainer_id": 7,
  "timezone": "Africa/Cairo",
  "server_time": "2026-11-04T14:00:00Z",
  "slots": [
    {
      "slot_id": "slot_opaque_token",
      "starts_at": "2026-11-05T16:00:00Z",
      "ends_at": "2026-11-05T17:00:00Z",
      "available": true
    }
  ]
}
```

`slot_id` must be signed or validated server-side. A displayed slot is not guaranteed until booking is committed.

### 3.4 Price quote

```http
POST /api/booking-quotes
Idempotency-Key: <uuid>
```

```json
{
  "offering_id": 91,
  "slot_id": "slot_opaque_token",
  "coupon_code": null
}
```

```json
{
  "quote_id": "quote_uuid",
  "expires_at": "2026-11-04T14:15:00Z",
  "subtotal": 230,
  "discount": 0,
  "total": 230,
  "currency": "SAR"
}
```

### 3.5 Create booking/payment

```http
POST /api/bookings
Idempotency-Key: <uuid>
```

```json
{
  "quote_id": "quote_uuid",
  "payment_method": "bank_transfer",
  "student_notes": "أحتاج مراجعة ملف المشروع"
}
```

```json
{
  "id": "booking_uuid",
  "status": "pending_payment",
  "payment_status": "pending",
  "scheduled_at": "2026-11-05T16:00:00Z",
  "ends_at": "2026-11-05T17:00:00Z",
  "amount": 230,
  "currency": "SAR",
  "payment": {
    "id": "payment_uuid",
    "next_action": "upload_receipt"
  }
}
```

For manual methods, reuse the configured payment methods in `GET /api/config/app` and the current enrollment-request/proof-upload infrastructure where practical.

### 3.6 Booking lists/details

```http
GET /api/bookings?role=student&status=scheduled&page=1
GET /api/bookings?role=instructor&status=scheduled&page=1
GET /api/bookings/{booking_id}
```

The backend derives the role from the authenticated user. `role` selects a permitted view; it does not grant authorization.

Booking details should include:

- Trainer/student public summary as appropriate.
- Offering and immutable price snapshot.
- Schedule and status.
- Payment/access status.
- `can_join`, `can_cancel`, `can_reschedule`, `can_review`, and reason codes.
- Chat conversation ID when available.
- No raw meeting URL.

### 3.7 Join session

```http
POST /api/bookings/{booking_id}/join
```

```json
{
  "join_token": "short_lived_opaque_token",
  "join_url": "https://api.example.com/api/live/join/<token>",
  "expires_at": "2026-11-05T16:10:00Z",
  "open_mode": "in_app_webview",
  "fallback_allowed": true
}
```

The endpoint must verify ownership, access, status, and join window on every call. The redirect endpoint revalidates the token before redirecting or rendering the provider join page.

### 3.8 Reschedule/cancel

```http
POST /api/bookings/{booking_id}/reschedule
POST /api/bookings/{booking_id}/cancel
```

Use `expected_schedule_version` to prevent overwriting concurrent changes.

```json
{
  "slot_id": "new_slot_token",
  "expected_schedule_version": 2,
  "reason": "طلب الطالب"
}
```

### 3.9 Reviews

```http
POST /api/bookings/{booking_id}/review
GET /api/trainers/{trainer_id}/reviews?page=1
```

Rules:

- Booking must belong to the student.
- Booking must be completed.
- One active review per booking.
- Rating integer from 1 to 5.
- Admin moderation may hide abusive text without changing the immutable audit trail.

### 3.10 Trainer availability management

```http
GET  /api/instructor/availability
PUT  /api/instructor/availability
POST /api/instructor/availability/exceptions
DELETE /api/instructor/availability/exceptions/{id}
```

Validate overlapping rules, timezone, buffers, and existing confirmed bookings.

### 3.11 Earnings and payouts

```http
GET  /api/instructor/earnings?from=2026-11-01&to=2026-11-30
GET  /api/instructor/payouts
POST /api/instructor/payouts
```

Use an immutable ledger. Never calculate payout eligibility only by summing mutable booking rows at request time.

## 4. Meeting Provider Interface

Recommended server interface:

```ts
interface MeetingProvider {
  createMeeting(input: CreateMeetingInput): Promise<MeetingRecord>;
  getStudentJoinTarget(meeting: MeetingRecord, user: User): Promise<JoinTarget>;
  getTrainerHostTarget(meeting: MeetingRecord, user: User): Promise<JoinTarget>;
  updateMeeting(meeting: MeetingRecord, input: UpdateMeetingInput): Promise<void>;
  cancelMeeting(meeting: MeetingRecord): Promise<void>;
}
```

Provider jobs must be retryable. Store provider request IDs and make creation idempotent so retries do not create duplicate meetings.

## 5. Realtime Chat and Notifications

- Create or activate a booking conversation only for authorized participants.
- Reuse the existing chat service/WebSocket conventions where possible.
- Push events:
  - `booking_confirmed`
  - `booking_rescheduled`
  - `booking_cancelled`
  - `session_starting`
  - `session_live`
  - `new_message`
  - `review_requested`
- Flutter should also schedule local reminders from `scheduled_at`; server push is the cross-device correction mechanism.

## 6. Admin Requirements

- Search/filter bookings by trainer, student, date, status, and payment status.
- Approve/reject manual payment proof.
- Cancel/reschedule with reason and audit entry.
- View provider creation/join failures without exposing secrets.
- Approve/suspend trainer profiles.
- Review disputes/refunds.
- Approve/reject payout requests.
- Configure join window and supported meeting provider.

## 7. Security and Reliability

- Rate-limit quote, payment, join-token, chat, and review endpoints.
- Encrypt provider tokens/URLs at rest.
- Redact tokens and meeting URLs from logs/analytics.
- Verify payment webhooks cryptographically and process idempotently.
- Use row-level authorization for every booking/message/review lookup.
- Reject client-supplied prices, trainer IDs derived from offerings, and arbitrary meeting URLs.
- Audit booking status, payment approval, join-token creation, refunds, and payouts.
- Define cleanup/retention for chat attachments and meeting metadata.

## 8. Contract Error Shape

Use stable machine-readable codes:

```json
{
  "error": {
    "code": "SLOT_NO_LONGER_AVAILABLE",
    "message": "The selected time is no longer available.",
    "details": null,
    "request_id": "req_uuid"
  }
}
```

Minimum codes:

```text
SLOT_NO_LONGER_AVAILABLE
QUOTE_EXPIRED
PAYMENT_REQUIRED
BOOKING_NOT_JOINABLE
JOIN_WINDOW_CLOSED
MEETING_NOT_READY
RESCHEDULE_CONFLICT
CANCELLATION_NOT_ALLOWED
REVIEW_NOT_ALLOWED
PAYOUT_NOT_ALLOWED
```

## 9. Backend Test Checklist

- [ ] Concurrent booking attempts cannot reserve the same trainer slot.
- [ ] Idempotent retries return the original quote/booking/payment result.
- [ ] Manual payment approval grants access to only the correct booking/item.
- [ ] Unpaid and unrelated users cannot join.
- [ ] Join tokens expire and cannot be reused outside policy.
- [ ] Reschedule releases the old slot and reserves the new slot atomically.
- [ ] Cancellation/refund rules are applied consistently.
- [ ] Only completed bookings can be reviewed, once.
- [ ] Chat access is limited to booking participants/admin support.
- [ ] Earnings ledger matches completed/refunded booking events.
- [ ] Provider webhook/retry handling does not duplicate meetings.
- [ ] All timestamps and DST conversions are covered by tests.

