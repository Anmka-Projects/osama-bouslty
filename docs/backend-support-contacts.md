# App Config — Support Contacts (Phone & WhatsApp) Fully Backend-Driven

Specification for making **all** contact numbers shown in the app come from `GET /api/config/app` — the client manages them from the admin panel, and the mobile app must not contain any hardcoded phone numbers.

**Audience:** Backend team  
**Mobile reference:** `lib/screens/secondary/help_support_screen.dart`, `lib/models/app_config.dart` (`SupportConfig`, `SocialLinksConfig`), `lib/core/config/course_payment_methods_ui.dart`, `lib/widgets/global_whatsapp_support_fab.dart`  
**Version:** 1.0  
**Date:** 2026-10-28

---

## Summary

| Item | Value |
|------|--------|
| Goal | Zero hardcoded phone/WhatsApp numbers in the app — every contact number comes from `GET /api/config/app` |
| Admin panel | The client must be able to edit: support phone(s), support WhatsApp number(s), support email, and the payment WhatsApp number |
| Multiple numbers | Both `support.phone` and `support.whatsapp` accept **several numbers** in one string, separated by commas, spaces, slashes, semicolons or dashes |
| App-side change | `help_support_screen.dart` no longer ships fallback numbers — when config is empty it shows "Contact numbers are not available right now." |

---

## 1) `GET /api/config/app` → `data.support`

These are the fields the app reads (all already in the response — they just need to be **editable from the admin panel** and filled with **Bouslty's real values**):

```json
{
  "data": {
    "support": {
      "phone": "+201XXXXXXXXX, +201YYYYYYYYY",
      "whatsapp": "+201ZZZZZZZZZ",
      "email": "support@bouslty.anmka.com",
      "admin_user_id": "usr_admin_01"
    },
    "payment_whatsapp_number": "+201ZZZZZZZZZ",
    "course_payment_methods": {
      "bank_transfer_enabled": true,
      "library_receipt_enabled": true,
      "whatsapp_enabled": true,
      "whatsapp_number_e164": "+201ZZZZZZZZZ"
    },
    "social_links": {
      "whatsapp": "+201ZZZZZZZZZ"
    }
  }
}
```

### Field rules

| Field | Type | Rules |
|-------|------|-------|
| `support.phone` | string | One or more voice-call numbers. Multiple values separated by `,` `;` `/` whitespace or `-`. Each becomes a **Call** tile on Help & Support. |
| `support.whatsapp` | string | One or more WhatsApp numbers (same separators). Each becomes a **WhatsApp** tile. Local `01xxxxxxxxx` is auto-converted to `20xxxxxxxxxx` by the app — but prefer storing full international format `+20xxxxxxxxxx`. |
| `support.email` | string | Support email address shown/used for mail contact. |
| `payment_whatsapp_number` | string | Fallback WhatsApp number for **payment coordination** (checkout flow). |
| `course_payment_methods.whatsapp_number_e164` | string \| null | **Primary** WhatsApp number for the checkout payment option. When set it wins over all fallbacks. |
| `course_payment_methods.whatsapp_enabled` | bool | Shows/hides the "WhatsApp" payment method in checkout. Currently `false` — the client decides. |
| `social_links.whatsapp` | string | Last-resort fallback WhatsApp number. |

## 2) WhatsApp number resolution chain (app behavior)

For payment coordination and the floating WhatsApp button, the app picks the **first non-empty** value:

```
1. course_payment_methods.whatsapp_number_e164
2. payment_whatsapp_number
3. support.whatsapp
4. social_links.whatsapp
```

Set `whatsapp_number_e164` explicitly if payments should go to a **different** number than general support; leave it `null` to reuse `payment_whatsapp_number` / `support.whatsapp`.

## 3) Where each number appears in the app

| UI | Source |
|----|--------|
| Help & Support → Call tiles | `support.phone` (all numbers listed) |
| Help & Support → WhatsApp tiles | `support.whatsapp` (all numbers listed) |
| Floating WhatsApp FAB (all main screens + auth screens) | resolution chain above → `wa.me/<number>` |
| Checkout → "WhatsApp" payment method | `whatsapp_enabled` flag + resolution chain |
| Register/login screens WhatsApp button | same FAB |

## 4) Current problem (same as `backend-legal-urls.md`)

The config currently returns **`thebrand.anmka.com` values** — `support.email` is `support@thebrand.anmka.com` and the numbers belong to that deployment. After fixing the config source, verify:

- `support.phone` / `support.whatsapp` = Bouslty's real numbers
- `support.email` = `@bouslty.anmka.com` (or the client's real support email)

## 5) Admin panel requirements

- Editable text fields for each of: `support.phone`, `support.whatsapp`, `support.email`, `payment_whatsapp_number`, `course_payment_methods.whatsapp_number_e164`
- A toggle for `course_payment_methods.whatsapp_enabled`
- Accept multiple numbers in `support.phone` / `support.whatsapp` separated by commas (the app splits them)
- Validate E.164-ish format loosely (`+` then digits) — the app strips non-digits anyway

---

## Acceptance checklist

- [ ] Admin can edit all contact fields above and changes appear in `GET /api/config/app` within cache TTL
- [ ] Help & Support lists every number in `support.phone` as a Call tile and every number in `support.whatsapp` as a WhatsApp tile — no fixed numbers appear
- [ ] With all fields empty, Help & Support shows the "not available" message (no crash, no stale numbers)
- [ ] Floating WhatsApp FAB opens `wa.me/` for `whatsapp_number_e164` when set; otherwise the first non-empty fallback
- [ ] `whatsapp_enabled: true` makes the WhatsApp payment option visible in checkout
- [ ] No number in the app comes from the client bundle — everything reflects `data.support` / `data.payment_whatsapp_number`
