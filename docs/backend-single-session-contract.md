# Single Session Enforcement Contract (Frontend -> Backend)

## Goal
When the same user logs in on a new device, the previous device must be invalidated and forced to logout.

## Current Frontend Behavior (Implemented)
- If any authenticated API call returns `401` with a message indicating "logged in from another device", the app:
  - clears cached tokens
  - redirects user to `login`
  - shows blocking alert: "Your account was logged in on another device. Please log in again."
- Detection keywords currently include English and Arabic variants (e.g. `another device`, `تم تسجيل الدخول من جهاز آخر`).

## What Backend Should Return
For requests made with an invalidated token (because user logged in elsewhere), return:

- **HTTP Status:** `401`
- **JSON body shape:**

```json
{
  "success": false,
  "code": "SESSION_REVOKED_BY_NEW_LOGIN",
  "message": "You have been logged in from another device"
}
```

## Required Backend Rules
- Enforce one active session per user (or per role if business requires).
- On new login:
  - revoke/blacklist previous access token(s) and refresh token(s) for that user
  - issue fresh tokens for the new device
- For revoked token usage:
  - always return the same deterministic `code` + `message` above
  - do not return generic validation text in this case

## Optional (Recommended) Enhancements
- Include metadata in the response for audit/debug:

```json
{
  "success": false,
  "code": "SESSION_REVOKED_BY_NEW_LOGIN",
  "message": "You have been logged in from another device",
  "meta": {
    "new_login_at": "2026-04-29T12:00:00Z",
    "new_device_platform": "android"
  }
}
```

- Add dedicated websocket/event push for real-time forced logout (faster UX than waiting for next API call).

## Notes
- Frontend is already compatible with message-based detection.
- Best practice is to rely on `code` (`SESSION_REVOKED_BY_NEW_LOGIN`) to avoid localization/message drift.
