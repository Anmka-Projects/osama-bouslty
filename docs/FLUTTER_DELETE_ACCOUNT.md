# Delete Account — Flutter ↔ Backend Contract

In-app account deletion for students and instructors. Required for Google Play / App Store account-deletion policies.

**Audience:** Backend + mobile  
**Mobile reference:**
- `lib/services/auth_service.dart` → `deleteAccount()`
- `lib/core/api/api_endpoints.dart` → `deleteAccount`
- `lib/screens/student/student_dashboard_screen.dart`
- `lib/screens/instructor/instructor_profile_screen.dart`

**Version:** 1.0  
**Date:** 2026-09-06

---

## Summary

| Item | Value |
|------|--------|
| Endpoint | `DELETE /api/auth/account` |
| Auth | Bearer access token (**required**) |
| Body | `{ "password": "<current password>" }` (**required** for email/phone accounts) |
| Success | `200` / `204` with `success: true` (or empty body) |
| On success (app) | Clears tokens, closes download DB, navigates to splash/login |

---

## Request

```http
DELETE /api/auth/account
Authorization: Bearer <accessToken>
Content-Type: application/json
Accept: application/json

{
  "password": "UserCurrentPassword123"
}
```

### Rules

| Case | Expected |
|------|----------|
| Missing / invalid token | `401` |
| Password missing (password-based account) | `400` — ask for password |
| Wrong password | `401` or `403` with clear message |
| Social-only account (no password) | Accept omit/`null` password **or** accept a dedicated confirm flag (see optional) |
| Success | Permanently delete (or anonymize) the user and revoke all sessions |

### Optional body for social-only accounts

If the user has no password (Google / Apple only), the app still sends a password from the dialog today. Backend may either:

1. Accept deletion with token alone when `auth_provider != local`, or  
2. Support:

```json
{
  "confirm": true
}
```

Coordinate with mobile if you adopt (2) — UI can be adjusted.

---

## Success response

```json
{
  "success": true,
  "message": "Account deleted successfully"
}
```

Empty body with `200` / `204` is also accepted by the client.

---

## Error responses

### Wrong password

```json
{
  "success": false,
  "message": "Incorrect password"
}
```

### Unauthorized

```json
{
  "success": false,
  "message": "Unauthorized"
}
```

### Generic failure

```json
{
  "success": false,
  "message": "Failed to delete account"
}
```

Prefer Arabic or English messages consistent with other auth endpoints; the app shows `message` to the user.

---

## Backend responsibilities

1. **Authenticate** the caller from the Bearer token; delete **only** that user (never by arbitrary id from the client).
2. **Verify password** for local (email/phone) accounts before deleting.
3. **Revoke** all access + refresh tokens / sessions for that user.
4. **Remove or anonymize** personal data (profile, avatar file, FCM device tokens, chat identity as required by privacy policy).
5. **Cascade / soft-handle** related rows:
   - enrollments, progress, wishlist, certificates, exam attempts
   - enrollment requests, payment proofs (retain anonymized financial records if legally required)
   - instructor-owned content: do **not** hard-delete courses without a product rule — prefer reassign / soft-deactivate instructor and keep course catalog
6. Return a clear error if deletion is blocked (e.g. instructor with active paid students) instead of a silent 500.

### Suggested status codes

| Code | Meaning |
|------|---------|
| `200` / `204` | Deleted |
| `400` | Validation (missing password, etc.) |
| `401` | Invalid token or wrong password |
| `403` | Not allowed to delete (business rule) |
| `409` | Conflict (e.g. pending obligations) |
| `500` | Unexpected server error |

---

## Flutter behavior (implemented)

1. User taps **Delete Account** (student dashboard or instructor profile).
2. Dialog shows warning + **password** field.
3. On confirm → `AuthService.deleteAccount(password: …)` → `DELETE /api/auth/account`.
4. **Only on API success:** clear tokens, close per-user download DB, clear `hasLaunched`, go to splash.
5. On API failure: keep session; show snackbar with server/client error message.

Unlike logout, a failed delete call does **not** clear the local session.

---

## QA checklist

- [ ] Student can delete account with correct password and cannot log in afterward
- [ ] Wrong password keeps account and shows error
- [ ] Empty password blocked in UI
- [ ] After delete, old Bearer token returns `401` on any authenticated route
- [ ] Instructor path works the same from profile screen
- [ ] Re-register with same phone/email is allowed (or blocked with clear message if you soft-delete)
- [ ] FCM / device tokens for that user no longer receive pushes

---

## Related

- `POST /api/auth/logout` — session end only (account remains)
- `docs/backend-single-session-contract.md` — session revocation patterns
- Google Play Data safety / account deletion requirements
