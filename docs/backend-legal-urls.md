# App Config — Legal URLs Pointing to the Wrong Domain

Specification for fixing `legal.privacy_url` / `legal.terms_url` (and related branding fields) returned by `GET /api/config/app` — they currently point to **`thebrand.anmka.com`** instead of **`bouslty.anmka.com`**.

**Audience:** Backend team  
**Mobile reference:** `lib/core/legal/legal_urls.dart`, `lib/models/app_config.dart` (`LegalConfig`), `lib/screens/auth/register_screen.dart`, `lib/screens/secondary/settings_screen.dart`  
**Version:** 1.0  
**Date:** 2026-10-28

---

## Summary

| Item | Value |
|------|--------|
| Problem | `GET /api/config/app` → `data.legal` returns URLs on the **`thebrand.anmka.com`** domain — a different product on the same infra |
| Impact | Tapping "الشروط والأحكام" (register) or "Privacy & Security" (settings) sends users to the wrong site — and the privacy page itself **times out / never loads** |
| Required change | Point `legal.*` (and verify `app_name` / `support.*`) to the **bouslty** deployment |
| Fallback behavior | The app only uses its built-in fallback (`https://bouslty.anmka.com/privacy`) when the backend value is **empty** — a wrong non-empty value always wins, so the fix must be server-side |

---

## 1) Current response (broken)

`GET /api/config/app` currently returns:

```json
{
  "data": {
    "app_name": "UR The Brand",
    "app_name_ar": "UR The Brand",
    "legal": {
      "terms_url": "https://thebrand.anmka.com/terms",
      "privacy_url": "https://thebrand.anmka.com/privacy"
    }
  }
}
```

Live checks (2026-10-28):

| URL | Result |
|-----|--------|
| `https://thebrand.anmka.com/privacy` | ❌ **times out** (no response) |
| `https://thebrand.anmka.com/terms` | ✅ 200 |
| `https://bouslty.anmka.com/privacy` | ✅ 200 — **the correct page exists** |
| `https://bouslty.anmka.com/terms` | expected 200 — verify |

So the config likely belongs to a different deployment ("UR The Brand") sharing the same backend, or the legal URLs were hardcoded to the wrong host.

## 2) Required response

```json
{
  "data": {
    "app_name": "Bouslty Academy",
    "app_name_ar": "بوسلتي أكاديمي",
    "legal": {
      "terms_url": "https://bouslty.anmka.com/terms",
      "privacy_url": "https://bouslty.anmka.com/privacy"
    }
  }
}
```

Also verify these fields don't leak the other brand's values:

- `app_name`, `app_name_ar`, `tagline`
- `support.email` / `support.phone` / `support.whatsapp` (currently returning `support@thebrand.anmka.com`-style values — confirm they belong to Bouslty)
- `social_links.*` if configured

## 3) Where the app uses these URLs

| Screen | Entry point | Opens |
|--------|-------------|-------|
| `register_screen.dart` | «الشروط والأحكام» link in the terms checkbox | `legal.privacy_url` |
| `settings_screen.dart` | "Privacy & Security" card | `legal.privacy_url` |

Both go through `LegalUrls.openPrivacy()` / `openTerms()` → `AppConfigService.getAppConfig()` → `launchUrl(externalApplication)` — the link opens in the device browser, so the domain is fully visible to users.

## 4) App-side fallback (for awareness only — no backend action needed)

```dart
// lib/core/legal/legal_urls.dart
static const String fallbackPrivacyUrl = 'https://bouslty.anmka.com/privacy';
static const String fallbackTermsUrl   = 'https://bouslty.anmka.com/terms';
```

The fallback applies **only when the backend returns an empty/missing value** — it cannot override a wrong non-empty value. If you prefer the backend to stay silent on these fields, simply **remove/empty `legal.*`** and the app will use the correct bouslty URLs automatically.

## 5) Validation checklist for the fix

- Both URLs must return **200** in a plain mobile browser **without login**
- Pages must be served over HTTPS on `bouslty.anmka.com`
- Arabic content primary (see `docs/PRIVACY_TERMS_WEBSITE.md` for the full page copy)
- No redirect chains to another domain

---

## Acceptance checklist

- [ ] `GET /api/config/app` → `data.legal.privacy_url` = `https://bouslty.anmka.com/privacy`
- [ ] `GET /api/config/app` → `data.legal.terms_url` = `https://bouslty.anmka.com/terms`
- [ ] `https://bouslty.anmka.com/privacy` loads in a mobile browser without auth
- [ ] `data.app_name` / `support.*` no longer reference "UR The Brand" / `thebrand.anmka.com`
- [ ] Opening «الشروط والأحكام» from Register lands on the Bouslty privacy page
- [ ] Opening "Privacy & Security" from Settings lands on the Bouslty privacy page
