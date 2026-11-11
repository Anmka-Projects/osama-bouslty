# Flutter Specification — Trainer Marketplace and Live Booking

> Shared scope: [CLIENT_REQUIREMENTS_IMPLEMENTATION_PLAN.md](./CLIENT_REQUIREMENTS_IMPLEMENTATION_PLAN.md)
>
> Backend contract: [BACKEND_TRAINER_MARKETPLACE_SPEC.md](./BACKEND_TRAINER_MARKETPLACE_SPEC.md)

## 1. Existing Flutter Pieces to Reuse

The repository already contains useful foundations:

- `teachers_service.dart`, `teachers_screen.dart`, and `teacher_details_screen.dart`
- `live_courses_service.dart`, `live_courses_screen.dart`, and `live_lesson_screen.dart`
- `live_session_webview_screen.dart`
- `chat_service.dart`, `chat_websocket_service.dart`, and chat screens
- `payments_service.dart`, `checkout_screen.dart`, and manual-payment flows
- Instructor dashboard, courses, earnings, profile, and session-details screens
- Notifications and live-session reminder services

Extend these features rather than introducing a second parallel architecture.

## 2. Proposed Flutter Structure

```text
lib/
├── models/
│   ├── trainer_profile.dart
│   ├── trainer_offering.dart
│   ├── availability_slot.dart
│   ├── booking.dart
│   ├── booking_quote.dart
│   ├── trainer_review.dart
│   └── payout_request.dart
├── services/
│   ├── trainers_service.dart              # extend existing teachers service or migrate deliberately
│   ├── availability_service.dart
│   ├── bookings_service.dart
│   ├── meeting_join_service.dart
│   └── payouts_service.dart
├── screens/
│   ├── secondary/
│   │   ├── trainers_screen.dart           # may evolve current teachers_screen
│   │   ├── trainer_details_screen.dart
│   │   ├── trainer_availability_screen.dart
│   │   ├── booking_checkout_screen.dart
│   │   ├── my_bookings_screen.dart
│   │   ├── booking_details_screen.dart
│   │   ├── booking_review_screen.dart
│   │   └── live_session_webview_screen.dart
│   └── instructor/
│       ├── instructor_bookings_screen.dart
│       ├── instructor_session_details_screen.dart
│       ├── instructor_availability_screen.dart
│       ├── instructor_profile_editor_screen.dart
│       └── instructor_payouts_screen.dart
└── core/
    ├── bookings/
    │   ├── booking_status.dart
    │   ├── booking_actions.dart
    │   └── booking_error_mapper.dart
    └── live/
        └── meeting_webview_policy.dart
```

Use the project's current state-management and service patterns. Do not add a new state-management dependency only for this feature.

## 3. Student User Flow

### 3.1 Trainer discovery

Screen capabilities:

- Search by trainer name/specialty.
- Filters for specialty, language, rating, price, and availability.
- Pagination/infinite scroll.
- Trainer card: avatar, headline, rating, session/student counts, starting price, and next availability.
- Empty, loading, retry, and offline states.

### 3.2 Trainer details

Sections:

- Intro video or image fallback.
- Trainer identity and verification state.
- Biography, specialties, experience, qualifications, and languages.
- Ratings and reviews.
- Offerings:
  - Single session.
  - Multi-session package.
  - Related course when available.
- Availability preview.
- Sticky actions: **Contact** (only if permitted) and **Book now**.

Do not display raw phone/email fields unless the backend explicitly marks them public.

### 3.3 Select offering and slot

- Select a single session or package.
- Load slots for a bounded date range.
- Display in the device's timezone with the timezone label.
- Refresh availability before proceeding.
- If `SLOT_NO_LONGER_AVAILABLE` is returned, explain the conflict and reload slots.

### 3.4 Quote and checkout

- Request a backend quote before displaying the final payable total.
- Show quote expiry when relevant.
- Use payment-method configuration from `GET /api/config/app`.
- Reuse bank transfer, library receipt, and WhatsApp flows where enabled.
- Submit an `Idempotency-Key` for booking/payment mutations.
- Never calculate the authoritative discount or total only in Flutter.

### 3.5 Booking confirmation and list

`My Bookings` tabs/filters:

- Upcoming
- Live
- Completed
- Cancelled

Booking cards show trainer, date/time, duration, payment state, session state, and the next allowed action.

### 3.6 Booking details actions

Render actions from backend capability flags:

```json
{
  "can_join": true,
  "can_cancel": false,
  "can_reschedule": true,
  "can_review": false
}
```

Do not reproduce cancellation/join policy independently in Flutter. Local checks may improve UX, but the backend response remains authoritative.

## 4. In-App Live Session

### Join sequence

```text
User taps Join
  → POST /bookings/{id}/join
  → receive short-lived join_url
  → request camera/microphone permissions when needed
  → open LiveSessionWebViewScreen
  → monitor navigation/errors
  → show controlled fallback if backend permits it
```

### WebView requirements

- JavaScript, DOM storage, media playback, and required cookies enabled only for allowlisted domains.
- Camera and microphone permissions requested with clear Arabic/English explanations.
- Block or externalize unsupported schemes safely.
- Do not log the join URL or include it in analytics/crash breadcrumbs.
- Clear ephemeral meeting cookies/storage on logout when appropriate.
- Show dedicated states for:
  - Meeting not ready.
  - Join window closed.
  - Provider unavailable.
  - Permission denied.
  - Network disconnected.
- Preserve screen wake state during an active session where platform policy permits.

The existing `live_session_webview_screen.dart` should be extended and tested instead of creating a duplicate WebView implementation.

## 5. Trainer Flow

### Trainer profile editor

- Avatar and introduction video.
- Display name/headline/biography.
- Specialties and languages.
- Qualifications/certificates.
- Experience.
- Social links.
- Booking availability toggle.
- Verification status and rejection notes.

### Availability management

- Trainer timezone selection.
- Weekly recurring intervals.
- Slot duration and buffer.
- Blocked dates/exceptions.
- Validation for overlaps.
- Warning when edits affect an existing booking.

### Booking/session management

- Filter by date/status/student.
- Booking details and student notes.
- Confirm/manage meeting readiness if the backend requires trainer action.
- Join as trainer using the appropriate host flow.
- Reschedule/cancel with reason.
- Open booking-scoped chat.
- Marking completion should normally be server/provider-driven; do not rely only on a trainer button.

### Earnings and payouts

- Available, pending, and paid balances.
- Earnings history by booking/course.
- Payout request form.
- Payout status history.
- Reuse the existing instructor earnings screen and service conventions.

## 6. Models and Parsing Rules

- Use typed enums with an `unknown` fallback for forward compatibility.
- Parse money as decimal-safe minor units or the project's established money representation; avoid binary floating-point calculations for totals.
- Parse API timestamps as UTC and convert only for presentation.
- Preserve `schedule_version` for reschedule mutations.
- Do not silently map unknown booking/payment states to `completed` or paid.

Example booking model fields:

```text
id
studentSummary
trainerSummary
offeringSummary
scheduledAtUtc
endsAtUtc
status
paymentStatus
amount
currency
scheduleVersion
canJoin
canCancel
canReschedule
canReview
conversationId
```

## 7. Navigation

Recommended named routes:

```text
/trainers
/trainers/:id
/trainers/:id/availability
/booking/checkout
/bookings
/bookings/:id
/bookings/:id/review
/live-session/:bookingId
/instructor/bookings
/instructor/availability
/instructor/payouts
```

Protect routes by role and authentication through the existing router/session invalidation mechanisms.

Push notifications should deep-link to booking details first. Booking details then requests the current server state before exposing actions.

## 8. Error UX

Map stable backend codes to localized messages and recovery actions:

| Code | Flutter action |
|---|---|
| `SLOT_NO_LONGER_AVAILABLE` | Reload calendar and ask user to choose another slot. |
| `QUOTE_EXPIRED` | Request a fresh quote and refresh total. |
| `PAYMENT_REQUIRED` | Return to payment status/details. |
| `BOOKING_NOT_JOINABLE` | Refresh booking and show server reason. |
| `JOIN_WINDOW_CLOSED` | Show scheduled time and reminder option. |
| `MEETING_NOT_READY` | Retry with bounded polling/manual refresh. |
| `RESCHEDULE_CONFLICT` | Reload booking/availability. |
| `CANCELLATION_NOT_ALLOWED` | Show policy reason. |
| `REVIEW_NOT_ALLOWED` | Refresh booking and hide review action. |

Use `request_id` in support/debug UI, but do not expose tokens or sensitive payloads.

## 9. Notifications and Refresh

- Schedule local reminders when a confirmed/scheduled booking is loaded.
- Cancel/recreate reminders when `schedule_version` changes.
- Handle FCM events for confirmation, reschedule, cancellation, live state, and messages.
- On app resume, refresh active/upcoming bookings.
- Avoid aggressive background polling; prefer push plus user-initiated refresh.

## 10. Localization and Accessibility

- Full Arabic RTL and English support using ARB files.
- Localize statuses, errors, payment labels, date/time, and provider-neutral meeting terminology.
- Do not hard-code “Zoom” when the provider is not part of required user-facing copy.
- All actionable controls require semantic labels and adequate touch targets.
- Verify contrast, dynamic text sizing, and screen-reader ordering.

## 11. Flutter Test Checklist

### Unit tests

- [ ] Booking/payment enum parsing including unknown values.
- [ ] UTC/local time and daylight-saving conversions.
- [ ] Capability/action mapping.
- [ ] Quote expiry and money formatting.
- [ ] Backend error-code mapping.
- [ ] Reminder rescheduling by `schedule_version`.

### Widget tests

- [ ] Trainer list loading/empty/error/data states.
- [ ] Trainer details with missing optional media.
- [ ] Slot conflict recovery.
- [ ] Checkout for each enabled payment method.
- [ ] Booking actions for every status/capability combination.
- [ ] Arabic RTL layouts and large text.

### Integration tests

- [ ] Discover → slot → quote → payment → confirmed booking.
- [ ] Manual receipt upload → pending → approved access.
- [ ] Reschedule updates both UI and reminders.
- [ ] Join endpoint → WebView → meeting page.
- [ ] Camera/microphone denied and later granted.
- [ ] WebView provider failure and approved fallback.
- [ ] Student/trainer chat authorization.
- [ ] Completed booking → submit one review.

## 12. Flutter Definition of Done

- No duplicated booking/live-session architecture is introduced.
- All new API calls use the existing authenticated API client and session invalidation behavior.
- No meeting tokens or full join URLs are written to logs.
- Every screen has loading, empty, error, retry, and offline-aware behavior.
- Android and iOS live-session flows are tested on real devices.
- Backend staging contract tests and Flutter integration tests use the same canonical enums/fields.
- Client-open decisions in the shared plan are resolved or explicitly feature-flagged before production.

