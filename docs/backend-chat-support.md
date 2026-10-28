# Chat API — Support / Admin Conversation (`support.admin_user_id`)

Specification for letting students & teachers start an **in-app chat with the admin/support account** directly from the conversations screen.

**Audience:** Backend team  
**Mobile reference:** `lib/screens/secondary/chat_conversations_screen.dart` (`_NewChatPickerSheet`, `_buildSupportTile`), `lib/models/app_config.dart` (`SupportConfig.adminUserId`), `lib/services/chat_service.dart`  
**Version:** 1.0  
**Date:** 2026-10-27

---

## Summary

| Item | Value |
|------|--------|
| Goal | Every user (student **and** teacher) can open the "New chat" sheet and find a pinned **"الإدارة / الدعم"** entry |
| Required change 1 | Expose the support account's user id in `GET /api/config/app` → `data.support.admin_user_id` |
| Required change 2 | Allow that id as `otherUserId` in `POST /api/chat/conversations` for **any** authenticated role |
| Admin inbox | Admins must be able to list & reply to these conversations (their dashboard) |

---

## 1) `GET /api/config/app` — expose the support user

Add one field inside the existing `support` object:

```json
{
  "success": true,
  "data": {
    "support": {
      "email": "support@thebrand.anmka.com",
      "phone": "+201019108541",
      "whatsapp": "+201019108541",
      "admin_user_id": "usr_admin_01"
    }
  }
}
```

- `admin_user_id` = the `users.id` of the support/admin account that will receive chats.
- If you prefer multiple support agents later, keep this a single "primary" id — the app only needs one entry point.
- If the key is missing or empty, the app simply **hides** the support tile — backwards compatible with this app version either way.

## 2) `POST /api/chat/conversations` — accept the admin id

Current behavior: creates (or returns) the 1:1 conversation between the authenticated user and `otherUserId` — used today for student ↔ teacher.

```json
{ "otherUserId": "usr_admin_01" }
```

**Required rule changes:**

| Case | Expected behavior |
|------|-------------------|
| `otherUserId` = the configured `admin_user_id` | **Allow** for any authenticated role (`student`, `instructor`) — create-or-get as usual |
| Admin user calling with any `otherUserId` | Allow (admin should be able to reply/initiate too) |
| `otherUserId` = the caller's own id | Reject — 422 `cannot chat with yourself` |

If you currently whitelist "student can only chat with a teacher of their enrolled courses" — **exempt the `admin_user_id`** from that rule.

### Response — unchanged

Same conversation shape as today; the app uses `id` (or `conversationId`) to open `/chat/:id`, and treats `otherUser`/`participant` for the display name. For the support conversation, returning `otherUser.name = "الإدارة"` (or `"Support"`) gives a nicer display name than the raw account name.

## 3) Admin inbox — how the admin sees the chats

Pick whichever fits your dashboard:

- **Option A (simplest):** `GET /api/chat/conversations` already returns the caller's conversations — when the caller is the admin account, it naturally contains all support chats. The admin web/mobile panel just needs a chat UI reusing the same endpoints.
- **Option B:** dedicated admin endpoints — `GET /api/admin/chat/conversations`, `GET /api/admin/chat/conversations/:id/messages`, `POST .../messages` — if you want a separate support inbox in the admin panel.

Either way, **Socket.IO** (the existing `chatSocketBaseUrl`) should emit new-message events to the admin's socket room too, so replies arrive in real time.

## 4) (Optional) `POST /api/chat/support` convenience endpoint

If you'd rather not expose the user id in config, an alternative is a dedicated endpoint:

```
POST /api/chat/support        → 200 { "data": { "id": "conv_...", ... } }
```

that creates-or-gets the caller's conversation with the support account. The app currently implements option 1 (`admin_user_id` + regular create-conversation) — if you ship this endpoint instead, tell us and we'll switch the tile to call it.

## 5) Validation & security notes

- `admin_user_id` is not sensitive — it's already discoverable via conversation APIs; exposing it in config is fine.
- Keep `GET /api/chat/conversations` scoped to the caller's own conversations (no cross-user listing) — unchanged.
- The support tile is hidden for users whose own role is `admin` (admin shouldn't chat with "support").

---

## Acceptance checklist

- [ ] `GET /api/config/app` → `data.support.admin_user_id` present.
- [ ] `POST /api/chat/conversations` with `otherUserId = admin_user_id` returns a conversation for both `student` and `instructor` tokens.
- [ ] Calling it twice returns the **same** conversation (create-or-get, no duplicates).
- [ ] Messages sent to that conversation appear in the admin's inbox (`GET /api/chat/conversations` with admin token, or the admin endpoint).
- [ ] Socket.IO new-message events reach the admin in real time.
