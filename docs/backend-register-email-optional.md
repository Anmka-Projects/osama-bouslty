# Register API — Optional `email` field

Specification for the mobile app **registration** flow: `email` is **optional** on the client. `phone` remains **required**. The backend must accept registration without `email`, and validate `email` only when it is sent.

**Audience:** Backend team  
**Mobile reference:** `lib/screens/auth/register_screen.dart`, `lib/services/auth_service.dart`  
**Version:** 1.0  
**Date:** 2026-05-20

---

## Summary

| Item | Value |
|------|--------|
| Endpoint | `POST /api/auth/register` |
| Field | `email` |
| Required? | **No** — omit or leave empty; user registers with **phone + password** |
| `phone` | **Required** — Egyptian mobile, normalized to E.164 `+20…` |
| Other required fields (app) | `name`, `phone`, `password` (+ terms accepted in UI) |

---

## Request behavior (Flutter)

### Without email (typical)

The app **does not** include `email` in the JSON body when the user leaves the field empty.

```json
{
  "name": "Ahmed Ali",
  "phone": "+201012345678",
  "password": "StrongPass123",
  "role": "student",
  "student_type": "online"
}
```

Optional: `fcm_token`, `platform` (push notifications).

### With email

```json
{
  "name": "Ahmed Ali",
  "email": "ahmed@example.com",
  "phone": "+201012345678",
  "password": "StrongPass123",
  "role": "student",
  "student_type": "online"
}
```

---

## Backend requirements

### 1. Validation rules

| Case | Expected backend behavior |
|------|---------------------------|
| `email` missing | **Allow** registration if `phone` is valid and unique |
| `email` is `null` or `""` | Treat as **not provided** |
| `email` provided | Validate format (RFC-like) and uniqueness |
| `phone` missing | **Reject** — required for this app version |
| Duplicate `email` | Reject only when `email` was sent |

### 2. Phone format (required)

| Input type | Pattern (after trim) | Example input | Sent value |
|------------|----------------------|---------------|------------|
| Local EG | `^01[0125]\d{8}$` (11 digits) | `01012345678` | `+201012345678` |
| International EG | `^\+201[0125]\d{8}$` | `+201012345678` | `+201012345678` |

**Suggested server regex (E.164):** `^\+201[0125]\d{8}$`

### 3. Login consistency

`POST /api/auth/login` supports **email OR phone** + password.

- Accounts registered **without** `email` must log in with **phone + password**.
- Accounts with both `email` and `phone` can use either identifier.

### 4. Database

- `email` column should be **nullable** (or empty = null).
- Unique index on `email` for non-null values only (partial unique index).
- `phone` remains required and unique per your existing rules.

---

## Error responses (recommended)

### Invalid email (when field is sent)

```json
{
  "success": false,
  "message": "البريد الإلكتروني غير صالح",
  "errors": {
    "email": ["The email must be a valid email address."]
  }
}
```

### Email required by old API (should be removed)

If the API returns `"email is required"` on register, update validation so `email` is optional when `phone` is present.

---

## Acceptance checklist

- [ ] Register succeeds with `name`, `phone`, `password` only (no `email` key).
- [ ] Register succeeds with `name`, `email`, `phone`, `password`.
- [ ] Register fails without `phone`.
- [ ] Register fails with invalid `email` when provided.
- [ ] Login with phone works for accounts created without `email`.
- [ ] Login with email works when `email` was provided at registration.

---

## Related docs

- `API_DOCUMENTATION (1).md` — § `POST /api/auth/register`

---

## Questions for backend

1. Can users add `email` later via `PUT /api/auth/profile`?
2. Is `PENDING` admin approval unchanged when `email` is omitted?
3. Password reset by email — how should it work for phone-only accounts?
