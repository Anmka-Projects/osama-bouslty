# Client Requirements — Backend + Flutter Implementation Plan

> Source: `E:\drOsama.mp4` (client meeting, reviewed 2026-11-04)
>
> Purpose: one shared delivery plan for backend and Flutter teams.
>
> Related existing specifications:
> - [FLUTTER_LIVE_LESSONS_BACKEND_SPEC.md](./FLUTTER_LIVE_LESSONS_BACKEND_SPEC.md)
> - [TEACHER_FEATURE_ARCHITECTURE.md](./TEACHER_FEATURE_ARCHITECTURE.md)
> - [FLUTTER_COURSE_PAYMENT_METHODS.md](./FLUTTER_COURSE_PAYMENT_METHODS.md)
> - [backend-chat-support.md](./backend-chat-support.md)

## 1. Product Goal

Extend Bouslty from a course catalog into a trainer marketplace where a student can:

1. Discover a trainer or course.
2. Inspect the trainer profile, experience, ratings, pricing, and availability.
3. Buy a single live session, a session package, or a whole course.
4. Book an available time.
5. Join the live class from inside the Flutter application.
6. Chat with the trainer and review the completed session.

The trainer must be able to manage the profile, availability, bookings, lessons, chat, earnings, and payout requests.

## 2. Confidence Levels

### Confirmed in the meeting

- Booking/payment must lead to a live-session join flow.
- The student should join from inside the Flutter application.
- The student should not be forced to install a separate meeting application.
- The trainer may host using an external meeting provider.
- Microsoft Teams and Zoom were discussed; Teams should be investigated.
- Zoom's free-session time limit was raised as a concern.
- Trainer profiles, availability, lessons/bookings, chat, and payments were demonstrated as core flows.

### Demonstrated as product references

These appeared in the Modarby reference application/site. Treat them as planned scope, but confirm exact UX and copy with the client:

- Trainer introduction video.
- Trainer qualifications, biography, specialties, and experience.
- Ratings, review count, student count, and completed-session count.
- Single sessions plus discounted multi-session packages.
- Available-times calendar.
- Guided trainer-matching wizard.
- Testimonials, partner logos, and public platform statistics.
- Persistent WhatsApp/support entry point.

## 3. Scope and Priorities

### P0 — Required for the first usable release

- Trainer discovery and profile.
- Trainer availability.
- Single-session booking.
- Payment/access validation.
- Student booking list and booking details.
- Trainer booking/session management.
- In-app live-session join page.
- Chat between the booked student and trainer.
- Session states: scheduled, live, completed, cancelled.
- Admin visibility and intervention for bookings/payments.

### P1 — Required after the P0 booking flow is stable

- Session packages/bundles.
- Reviews and ratings after completion.
- Trainer earnings and payout requests.
- Reschedule/cancellation workflow.
- Push reminders and meeting status notifications.
- Trainer CV, certificates, and social links.

### P2 — Marketing and discovery enhancements

- Guided trainer-matching wizard.
- Public statistics.
- Partner/customer logos.
- Testimonials and marketing sections.

## 4. Shared Domain Rules

### Roles

| Role | Responsibilities |
|---|---|
| `student` | Discover, buy, book, join, chat, and review. |
| `instructor` | Maintain trainer profile, availability, sessions, chat, and earnings. |
| `admin` | Approve trainers/manual payments, manage bookings, refunds, disputes, and payouts. |

### Booking lifecycle

```text
pending_payment
      │ payment succeeds / manual payment approved
      ▼
confirmed
      │ trainer/admin publishes join access
      ▼
scheduled ──────► live ──────► completed
    │               │
    ├───────────────┴──────► cancelled
    └──────────────────────► rescheduled (then scheduled again)
```

Canonical API status values:

```text
pending_payment | confirmed | scheduled | live | completed | cancelled
```

Rescheduling should update `scheduled_at` and increment a `schedule_version`; it should not introduce a permanent terminal `rescheduled` state.

### Access rule

A student can join only when all are true:

```text
authenticated
AND booking belongs to student
AND payment/access is approved
AND booking status is scheduled or live
AND current time is within configured join window
```

The backend is authoritative. Flutter must not infer paid access only from locally cached payment data.

### Time handling

- Backend stores and returns timestamps as ISO 8601 UTC.
- Flutter converts UTC to device-local time.
- Backend returns `server_time` in time-sensitive responses.
- Default join window proposal: 15 minutes before start until session end plus 15 minutes.
- Join-window values must be server-configurable.

## 5. Live-Meeting Decision

The implementation must use a provider abstraction. Do not hard-code Zoom or Teams across the domain model.

```text
MeetingProvider
├── teams
├── zoom
├── jitsi (optional investigation)
└── custom_web
```

Required behavior:

- The student taps **Join session** in Flutter.
- Flutter requests a short-lived join URL from the backend.
- The URL opens in the existing in-app live-session WebView.
- External-app installation must not be required for the primary student flow.
- If the provider blocks embedded WebView use, Flutter shows a controlled fallback to the system browser. This fallback must be validated with the client before release.
- Trainer host credentials, provider secrets, and raw start URLs never go to the student client.

Provider selection remains an open decision. Run a technical spike before final implementation:

1. Test Teams browser join on supported Android/iOS WebViews.
2. Test Zoom browser join and current plan duration limits.
3. Verify authentication requirements for guests.
4. Verify microphone/camera permissions and iOS WebKit behavior.
5. Record the supported fallback behavior.

## 6. Backend ↔ Flutter Ownership Matrix

| Feature | Backend | Flutter |
|---|---|---|
| Trainer search/filter | Query, pagination, ranking fields | Search/filter UI and pagination |
| Trainer profile | Canonical profile and public stats | Profile presentation and media player |
| Availability | Rules, conflicts, timezone normalization | Calendar/slot selection |
| Pricing/packages | Authoritative totals and discounts | Selection and price presentation |
| Checkout | Payment creation, verification, idempotency | Payment method UX and polling/result handling |
| Booking | State machine and permissions | Booking screens and state-specific actions |
| Join session | Access check and short-lived URL | WebView, permissions, fallback handling |
| Chat | Authorization, persistence, realtime delivery | Conversation/message UI |
| Reviews | Eligibility and aggregation | Rating/review form and display |
| Earnings/payouts | Ledger and payout state | Trainer earnings/payout screens |
| Notifications | Push events and templates | FCM handling and local reminders |

## 7. Delivery Sequence

### Phase 0 — Decisions and contract freeze

- [ ] Select meeting provider after WebView spike.
- [ ] Confirm payment methods and currencies.
- [ ] Confirm one-to-one versus group-session scope.
- [ ] Confirm cancellation, refund, and reschedule rules.
- [ ] Freeze OpenAPI schema and enums.

### Phase 1 — Trainer marketplace read flow

- [ ] Backend trainer profile/search endpoints.
- [ ] Flutter trainer list/profile screens.
- [ ] Availability read endpoint and slot calendar.

### Phase 2 — Booking and payment

- [ ] Backend price quote, payment, and booking creation.
- [ ] Flutter checkout and booking confirmation.
- [ ] Admin support for manual-payment approval.

### Phase 3 — Session lifecycle

- [ ] Trainer accepts/manages bookings and publishes meeting access.
- [ ] Student and trainer booking lists/details.
- [ ] In-app join flow and reminders.

### Phase 4 — Communication and trust

- [ ] Booking-scoped chat.
- [ ] Reviews after completion.
- [ ] Trainer earnings and payout requests.

### Phase 5 — Packages and marketing

- [ ] Multi-session packages and package usage tracking.
- [ ] Guided matching wizard and public marketing sections.

## 8. Release Definition of Done

- A student can discover a trainer, select a valid slot, pay, and receive a confirmed booking.
- A trainer can see the booking and the correct student/session details.
- The same slot cannot be double-booked under concurrency.
- An unpaid or unrelated student cannot obtain a join URL.
- The booked student can join inside the app on supported Android and iOS versions.
- Cancellation/reschedule changes appear on both student and trainer devices.
- Chat is limited to authorized booking participants/support staff.
- Completed sessions can be reviewed once.
- Payment, booking, join-token, and payout mutations are audited.
- Backend contract tests and Flutter integration tests pass against the same staging environment.

## 9. Open Client Decisions

- [ ] Final meeting provider.
- [ ] Whether an external-browser fallback is acceptable.
- [ ] One-to-one only, group sessions, or both.
- [ ] Exact session/package durations and discount rules.
- [ ] Supported currencies and electronic payment gateways.
- [ ] Cancellation deadline and refund percentages.
- [ ] Whether trainer payouts are automatic or require admin approval.
- [ ] Whether every reference-site marketing section is required.
- [ ] Whether students may contact trainers before booking.

