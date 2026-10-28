# Course bundle includes — QA

Tests for **normal courses** where admin selects **which other courses open** when the user buys the parent course.

---

## Admin dashboard

| # | Action | Expected |
|---|--------|----------|
| 1 | Create course **A** (normal) | Saved |
| 2 | Select **B** and **C** as “also unlock” | Links stored |
| 3 | Remove **C**, save | Only **B** linked |
| 4 | View **A** in API | `bundle_includes` matches dashboard |

---

## API

```bash
curl -s -H "Authorization: Bearer TOKEN" \
  "https://YOUR_API/api/courses/PARENT_ID" \
  | jq '.data.bundle_includes, .data.description'
```

| # | Check | Expected |
|---|--------|----------|
| 1 | `bundle_includes` | Matches admin selection |
| 2 | Items have `course_id` + `title` | App can render list |
| 3 | `description` | About tab in app |
| 4 | Enroll/pay **A** (new user) | `enrolled_course_ids` contains A + all includes |
| 5 | Repeat enroll | Idempotent, no error |

---

## Flutter

| # | Action | Expected |
|---|--------|----------|
| 1 | Open **A** details | Banner lists B, C from API |
| 2 | About tab | API `description` |
| 3 | Buy **A** | Access to A, B, C; multi-course message if applicable |
| 4 | **A** with no includes | No bundle banner |
| 5 | Admin changes includes, refresh details | List updates |

---

## Must not happen

| # | Failure |
|---|---------|
| 1 | App enrolls B/C with separate API calls — **server only** |
| 2 | User paid A but only A enrolled — missing bundle logic |
| 3 | Banner shows hardcoded list while API `bundle_includes` is empty — fix API/dashboard |
