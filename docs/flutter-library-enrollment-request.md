# Flutter — الدفع في المكتبة: طلب اشتراك بدون صورة

> **ملخص للفلاتر:** طلب المكتبة يُقبل **من غير صورة ومن غير `receipt_image_url`**. أرسلوا فقط `course_id` ويفضّل `payment_method: "library"`. الـ API يردّ `200` و`success: true` مثل أي طلب صالح.

التوثيق التفصيلي أدناه. مسار **واتساب** مختلف (صورة إثبات مطلوبة) — راجع `docs/flutter-whatsapp-payment-proof.md`.

---

## مقارنة سريعة

| قناة الدفع | حقل `receipt_image_url` | Endpoint الطلب |
|------------|-------------------------|------------------|
| **مكتبة** | **غير مطلوب** — اتركوه غير مُرسل أو `null` | `POST /api/enrollment-requests` |
| واتساب | **مطلوب** (أو استخدم المسار المخصص الذي يفرض الصورة) | `POST /api/enrollment-requests` أو `POST /api/courses/{id}/whatsapp-payment-proof` |
| تحويل بنكي | اختياري حسب سياسة التطبيق | `POST /api/enrollment-requests` |

---

## العنوان الأساسي (Base URL)

| البيئة | مثال |
|--------|------|
| عبر الدومين (Next + proxy) | `https://<DOMAIN>/api/...` |
| Express مباشرة | `https://<HOST>/api/...` أو `/v1/...` |

---

## المصادقة

```http
Authorization: Bearer <accessToken>
Content-Type: application/json
Accept: application/json
```

---

## إنشاء الطلب — بدون صورة (المسار المعتاد)

**`POST /api/enrollment-requests`**

### الحقول

| الحقل | مطلوب | ملاحظة |
|--------|--------|---------|
| `course_id` | **نعم** | UUID الدورة |
| `payment_method` | لا | الافتراضي في الخادم إن حُذف غالباً `library`؛ للوضوح أرسلوا `"library"` |
| `message` | لا | نص للإدارة (اختياري) |
| `receipt_image_url` | **لا** | **لا ترسلوا الحقل** إن لم تكن لديكم صورة؛ لا حاجة لقيمة فارغة |

### أدنى مثال (بدون صورة وبدون رسالة)

```json
{
  "course_id": "e0c32adb-93f6-4bbe-a1e6-ba207fcb052b",
  "payment_method": "library"
}
```

### مثال مع رسالة فقط (بدون صورة)

```json
{
  "course_id": "e0c32adb-93f6-4bbe-a1e6-ba207fcb052b",
  "payment_method": "library",
  "message": "طلب اشتراك — الدفع في المكتبة."
}
```

### إن أردتم إرفاق صورة لاحقاً (اختياري)

1. `POST /api/upload` — `multipart/form-data`، حقل `image` أو `file`.
2. من الاستجابة خذوا `url` وأضيفوا:

```json
{
  "course_id": "<courseId>",
  "payment_method": "library",
  "receipt_image_url": "/uploads/images/....",
  "message": "..."
}
```

> **تنبيه:** لا يوجد تعديل لطلب قائم لإضافة صورة لاحقاً عبر API؛ الطلب يُنشأ مرة واحدة مع أو بدون صورة.

---

## استجابة ناجحة (مثال)

```json
{
  "success": true,
  "message": "تم إرسال طلب الانضمام بنجاح",
  "data": {
    "id": "1a681f5c-6296-4464-9a05-4ac9315672eb",
    "course_id": "e0c32adb-93f6-4bbe-a1e6-ba207fcb052b",
    "status": "pending",
    "payment_method": "library",
    "message": null,
    "created_at": "2026-05-03T19:44:16.765Z"
  }
}
```

---

## أخطاء شائعة (400)

| رسالة (عربي) | السبب |
|----------------|--------|
| معرف الدورة مطلوب | ناقص `course_id` |
| الدورة غير موجودة | `course_id` خاطئ |
| أنت مشترك بالفعل في هذه الدورة | الطالب مسجّل بالفعل |
| لديك طلب انضمام قيد المراجعة لهذه الدورة | يوجد `pending` لنفس الدورة |
| مسار صورة الإيصال يجب أن يبدأ بـ uploads/... | ظهرت **فقط** إذا أرسلتم `receipt_image_url` بقيمة غير صالحة |

---

## عرض طلبات الطالب

**`GET /api/enrollment-requests?page=1&per_page=20&status=pending`**

---

## لوحة الإدارة

- فلتر **المكتبة** أو **كل القنوات** لعرض الطلبات.
- بدون صورة: لا يظهر قسم «صورة إثبات»؛ الموافقة حسب عملكم الداخلي.

---

## مراجع الكود

| المكوّن | الملف |
|---------|--------|
| المنطق | `backend/src/modules/mobile/mobile.service.js` — `createEnrollmentRequest` |
| Controller | `backend/src/modules/mobile/mobile.controller.js` — `createEnrollmentRequest` |
| Route | `backend/src/modules/mobile/mobile.routes.js` — `POST /enrollment-requests` |

---

## روابط ذات صلة

- **واتساب (صورة إلزامية):** `docs/flutter-whatsapp-payment-proof.md`

---

*آخر تحديث: 2026-05-03 — توضيح «بدون صورة» للفلاتر.*
