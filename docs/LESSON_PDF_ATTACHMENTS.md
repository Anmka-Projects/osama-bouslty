# Lesson PDF attachments (up to 3 with video)

## Instructor app (Flutter)

When editing a lesson with type **video** or **file**, the form allows up to **3 PDF** uploads per lesson.

Saved on the lesson object:

```json
{
  "type": "video",
  "videoUrl": "https://youtube.com/...",
  "fileUrl": "https://.../first.pdf",
  "content_pdf": "https://.../first.pdf",
  "resources": [
    { "title": "ملخص 1", "url": "https://.../a.pdf", "type": "pdf", "file_type": "application/pdf" },
    { "title": "ملخص 2", "url": "https://.../b.pdf", "type": "pdf", "file_type": "application/pdf" },
    { "title": "ملخص 3", "url": "https://.../c.pdf", "type": "pdf", "file_type": "application/pdf" }
  ]
}
```

API calls: `POST/PUT .../lessons` and full curriculum `PUT` must **persist** `resources` (and return them on `GET .../lessons/:id/content`).

## Student app

`lesson_viewer_screen` already lists `content_pdf` + all PDF entries in `resources`.

## Backend checklist

- [ ] Accept `resources` array on lesson create/update and curriculum bulk save
- [ ] Return `resources` + `content_pdf` from `GET /api/courses/:courseId/lessons/:lessonId/content`
