# Register API — Student Educational Stage & Grade (`category_id` / `subcategory_id`)

Specification for the mobile app **registration** flow: the student picks an **educational stage** (top-level category — e.g. ابتدائي / إعدادي / ثانوي / جامعة) and, when that stage has children, a **grade** (subcategory — e.g. الصف الأول الابتدائي). Both are sent to the backend on register.

**Audience:** Backend team  
**Mobile reference:** `lib/screens/auth/register_screen.dart`, `lib/services/auth_service.dart`, `lib/services/courses_service.dart`, `lib/core/categories/category_utils.dart`  
**Version:** 1.0  
**Date:** 2026-10-27

---

## Summary

| Item | Value |
|------|--------|
| Endpoint | `POST /api/auth/register` |
| New fields | `category_id`, `subcategory_id` |
| Required? | `category_id` — **required** when categories exist (see validation rules); `subcategory_id` — required only when the chosen category has children |
| Applies to | `role = "student"` only — instructors may omit both |
| Data source | `GET /api/categories` (**must stay public — called before login**) |

---

## 1) `GET /api/categories` — keep it public

The register screen fetches categories **before the user has a token**, so this endpoint must work **without** an `Authorization` header.

The app accepts both response shapes (already implemented):

- **Nested** (preferred): each parent has `children` (also accepted: `subcategories`, `sub_categories`, `subCategories`).
- **Flat**: every item has `parent_id` (`null` or `0`/`"0"` → top-level).

```json
{
  "success": true,
  "data": [
    {
      "id": "cat-primary",
      "name": "ابتدائي",
      "name_ar": "ابتدائي",
      "name_en": "Primary",
      "parent_id": null,
      "children": [
        { "id": "cat-p1", "name_ar": "الصف الأول الابتدائي", "parent_id": "cat-primary" },
        { "id": "cat-p2", "name_ar": "الصف الثاني الابتدائي", "parent_id": "cat-primary" }
      ]
    },
    { "id": "cat-prep",   "name_ar": "إعدادي", "parent_id": null, "children": [] },
    { "id": "cat-sec",    "name_ar": "ثانوي",  "parent_id": null, "children": [] },
    { "id": "cat-uni",    "name_ar": "جامعة",  "parent_id": null, "children": [] }
  ]
}
```

**Rules the UI depends on:**

- Top-level items = the stages shown first (المرحلة الدراسية).
- `children` of the selected stage = the grades shown in the second dropdown (الصف الدراسي).
- Only **2 levels** are needed (stage → grade). Deeper nesting works but is unnecessary.
- Only return `is_active = true` categories.
- Categories with **no children** are valid — the student selects the stage only.

## 2) `POST /api/auth/register` — accept the new fields

### Request body (student)

```json
{
  "name": "Ahmed Ali",
  "phone": "+201012345678",
  "password": "StrongPass123",
  "role": "student",
  "student_type": "online",
  "category_id": "cat-primary",
  "subcategory_id": "cat-p1"
}
```

- `subcategory_id` is sent **only** when the chosen stage has children and the user picked one.
- When the stage has no children, the app sends `category_id` alone.
- If `GET /api/categories` fails or returns an empty list, the app **hides the pickers** and sends neither field — the backend must still allow registration (see backwards compatibility).

### Validation rules

| Case | Expected backend behavior |
|------|---------------------------|
| `category_id` missing for `role=student` | **Recommended:** accept (back-compat with older app builds). Optionally reject with 422 once enforcement is confirmed |
| `category_id` does not exist / is a child itself | Reject — 422 |
| `subcategory_id` sent without `category_id` | Reject — 422 |
| `subcategory_id.parent_id != category_id` | Reject — 422 (must belong to the selected stage) |
| Stage has children but `subcategory_id` missing | **Recommended:** reject — 422, or default to `null` grade |
| `role=instructor` | Ignore both fields (or accept and store as `null`) |

### Error responses (recommended)

```json
{
  "success": false,
  "message": "الصف الدراسي لا يتبع المرحلة المختارة",
  "errors": {
    "subcategory_id": ["The selected subcategory does not belong to the category."]
  }
}
```

## 3) Storage

Add two nullable columns on `users` (or a student profile table — your choice):

```
users.category_id     → FK categories.id, NULL allowed
users.subcategory_id  → FK categories.id, NULL allowed
```

- `category_id` = the stage (المرحلة).
- `subcategory_id` = the grade (الصف).
- `ON DELETE SET NULL` on both FKs — deleting a category must not delete students.

## 4) Return the fields

Include both in user payloads so the app can display/edit the student's stage & grade:

- `POST /api/auth/register` → `data.user`
- `GET /api/auth/me`
- `POST /api/auth/login` → `data.user`

```json
{
  "id": "uuid",
  "name": "Ahmed Ali",
  "phone": "+201012345678",
  "role": "student",
  "student_type": "online",
  "category_id": "cat-primary",
  "subcategory_id": "cat-p1"
}
```

Optionally embed the resolved objects (`category`, `subcategory`) for display names — nice-to-have, not required.

## 5) Profile update

`PUT /api/auth/profile` should also accept `category_id` / `subcategory_id` with the same validation, so a student can fix or change their stage/grade later.

## 6) Admin setup required

Before release, create the stage structure from the admin panel (`POST /api/admin/categories`):

- 4 root categories: `ابتدائي`, `إعدادي`, `ثانوي`, `جامعة` (`parent_id = null`)
- The grades under each stage (`parent_id = <stage id>`)

> Note: the current categories ("البرمجة", "التصميم", "الأعمال", "اللغات") will also appear as selectable stages in the register dropdown — **everything** in `/api/categories` shows up. If these should NOT be selectable during registration, either remove them, mark them `is_active = false`, or add a flag (e.g. `is_enrollment_stage: true`) the app can filter on.

---

## Acceptance checklist

- [ ] `GET /api/categories` returns 200 with **no** `Authorization` header.
- [ ] Register succeeds with `category_id` only (stage without children).
- [ ] Register succeeds with `category_id` + `subcategory_id`.
- [ ] Register fails (422) when `subcategory_id` doesn't belong to `category_id`.
- [ ] Register still succeeds when neither field is sent (old app builds / empty categories).
- [ ] `category_id` / `subcategory_id` appear in `/api/auth/me` and register/login user payloads.
- [ ] `PUT /api/auth/profile` accepts both fields with the same validation.
