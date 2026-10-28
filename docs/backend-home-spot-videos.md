# Home spot videos API — Student home screen

Specification for **two dashboard-controlled videos** on the student home screen. They replace the previous **Enrolled courses** and **Learning hours** stat cards.

**Audience:** Backend team  
**Mobile reference:** `lib/screens/student/home_screen.dart`, `lib/services/home_service.dart`, `lib/widgets/home_spot_videos_row.dart`  
**Version:** 1.0  
**Date:** 2026-05-20

---

## Summary

| Item | Value |
|------|--------|
| Student read | `GET /api/home` → `data.home_spot_videos` (max **2** active items) |
| Admin control | CRUD from **admin dashboard** (suggested routes below) |
| Slots | `slot`: **1** (left) and **2** (right) — same row as old stat cards |
| Video source | **YouTube** (`youtube_id` or YouTube URL) **or** hosted file (`video_url`) |
| Thumbnail | Required for good UX (`thumbnail` image URL) |
| Auth (read) | Same as existing home: `Authorization: Bearer <token>` (app uses `requireAuth: true`) |

---

## Student API — extend `GET /api/home`

### Response shape

Add array `home_spot_videos` inside existing `data` object:

```json
{
  "success": true,
  "data": {
    "user_summary": { "...": "..." },
    "featured_courses": [],
    "popular_courses": [],
    "continue_learning": [],
    "categories": [],
    "home_spot_videos": [
      {
        "id": 1,
        "slot": 1,
        "sort_order": 0,
        "title": "مرحباً بك في المنصة",
        "description": "شاهد فيديو الترحيب وتعرف على المنصة",
        "thumbnail": "/uploads/home-spot/thumb-1.jpg",
        "youtube_id": "dQw4w9WgXcQ",
        "video_url": null,
        "link_url": null,
        "is_active": true
      },
      {
        "id": 2,
        "slot": 2,
        "sort_order": 0,
        "title": "كيف تبدأ التعلم",
        "description": "خطوات سريعة لبدء أول دورة",
        "thumbnail": "/uploads/home-spot/thumb-2.jpg",
        "youtube_id": null,
        "video_url": "/uploads/home-spot/intro.mp4",
        "link_url": "https://bouslty.anmka.com/courses",
        "is_active": true
      }
    ]
  }
}
```

### Field rules

| Field | Type | Required | Notes |
|-------|------|----------|--------|
| `id` | int/string | yes | Stable id for admin CRUD |
| `slot` | int | yes | **1** or **2** — position on home row |
| `sort_order` | int | no | Tie-breaker when multiple rows share slot (default `0`) |
| `title` | string | no | Short label **on** the video tile (bottom overlay, max ~40 chars) |
| `description` | string | no | Text **above** the video tile on home (max ~120 chars, 3 lines in app) |
| `thumbnail` | string | yes* | Relative `/uploads/...` or absolute URL |
| `youtube_id` | string | no* | YouTube video id (11 chars) |
| `video_url` | string | no* | MP4/HLS URL on your CDN/storage |
| `link_url` | string | no | Optional deep link (reserved; app opens player on tap today) |
| `is_active` | bool | yes | `false` → hidden on mobile |

\* At least one playable source: `youtube_id` **or** `video_url` (or YouTube URL inside `video_url`).  
If both missing, tile shows but play is disabled.

### Mobile processing

- Paths under `/uploads/` are prefixed with `https://bouslty.anmka.com/api/uploads/...` (same as sliders/courses).
- Items with `is_active: false` are filtered out.
- Sorted by `slot` asc, then `sort_order` asc.
- **Maximum 2** items returned to UI.

### Empty / not ready

If `home_spot_videos` is missing, `[]`, or all inactive → mobile **hides** the row (no placeholder cards).

---

## Admin dashboard — suggested API

Protect with admin auth (same as sliders/categories admin).

### List

`GET /api/admin/home-spot-videos`

```json
{
  "success": true,
  "data": [
    {
      "id": 1,
      "slot": 1,
      "sort_order": 0,
      "title": "مرحباً بك",
      "description": "شاهد فيديو الترحيب",
      "thumbnail": "/uploads/home-spot/thumb-1.jpg",
      "youtube_id": "abc123",
      "video_url": null,
      "link_url": null,
      "is_active": true,
      "created_at": "2026-05-20T10:00:00Z",
      "updated_at": "2026-05-20T10:00:00Z"
    }
  ]
}
```

### Create

`POST /api/admin/home-spot-videos`  
`Content-Type: multipart/form-data` **or** `application/json`

| Part / field | Required | Notes |
|--------------|----------|--------|
| `slot` | yes | Must be `1` or `2` |
| `title` | no | On-video overlay |
| `description` | no | Shown above video on home |
| `thumbnail` | yes (create) | Image file or URL |
| `youtube_id` | no | |
| `video_url` | no | Uploaded file or external URL |
| `link_url` | no | |
| `is_active` | no | Default `true` |

**Validation:** Only one **active** record per `slot` (recommended). Reject duplicate active `slot` with `422`.

### Update

`PUT /api/admin/home-spot-videos/{id}` or `PATCH` — same fields, all optional.

### Delete

`DELETE /api/admin/home-spot-videos/{id}`

### Reorder / toggle (optional shortcuts)

- `PATCH /api/admin/home-spot-videos/{id}/toggle` → flip `is_active`
- `POST /api/admin/home-spot-videos/reorder` → body `{ "items": [{ "id": 1, "slot": 1, "sort_order": 0 }, ...] }`

---

## Database suggestion

Table: `home_spot_videos`

| Column | Type |
|--------|------|
| id | PK |
| slot | tinyint (1 or 2) |
| sort_order | int default 0 |
| title | varchar nullable |
| description | text nullable |
| thumbnail | varchar |
| youtube_id | varchar nullable |
| video_url | varchar nullable |
| link_url | varchar nullable |
| is_active | boolean default true |
| created_at / updated_at | timestamps |

Unique index (recommended): `(slot)` WHERE `is_active = 1` (partial unique per DB).

---

## Dashboard UI checklist

- [ ] Screen: **Home videos** (or under **App content** next to Sliders)
- [ ] Two slots labeled **Left (1)** and **Right (2)**
- [ ] Optional **description** field (text above video on home)
- [ ] Upload thumbnail + set YouTube ID **or** upload MP4
- [ ] Active toggle per slot
- [ ] Preview thumbnail in list

---

## Mobile QA (after backend deploy)

| # | Case | Expected |
|---|------|----------|
| 1 | Two active videos in slots 1 & 2 | Two tiles under promo slider |
| 2 | Only slot 1 active | One tile, left side |
| 3 | `is_active: false` for both | Row hidden |
| 4 | Tap tile with `youtube_id` | Bottom sheet player plays YouTube |
| 5 | Tap tile with `video_url` (mp4) | Network player with auth token query if needed |
| 6 | Invalid/missing video source | Tile visible, play disabled |
| 7 | `description` set | Text appears above video; omitted if empty |

---

## Changelog (mobile)

- Removed enrolled courses / learning hours stat cards from `home_screen.dart`.
- Added `home_spot_videos` consumption and inline video tiles.

**Contact:** Flutter team for field renames; keep snake_case to match existing API (`featured_courses`, `user_summary`, etc.).
