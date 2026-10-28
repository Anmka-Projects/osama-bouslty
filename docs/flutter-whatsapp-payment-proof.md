# Flutter — إثبات دفع واتساب (WhatsApp payment proof)

توثيق نقاط النهاية (endpoints) لرفع لقطة شاشة الدفع وربطها بطلب اشتراك في الدورة، حتى تظهر في لوحة الإدارة للموافقة أو الرفض.

---

## العنوان الأساسي (Base URL)

| البيئة | مثال |
|--------|------|
| عبر موقع Next (موصى به للتطبيق) | `https://<DOMAIN>` — المسارات تبدأ بـ `/api/...` |
| اتصال مباشر بخادم Express | `http://<HOST>:<PORT>` — المسارات: `/api/...` أو `/v1/...` (نفس المسارات) |

> على الخادم، الـ Express يُعلّق المسارات تحت `/api` و`/v1` معاً.

---

## المصادقة

جميع الطلبات التالية (ما عدا رفع الملف إن كان مفتوحاً بدون توكن عندكم) تحتاج:

```http
Authorization: Bearer <accessToken>
```

`<accessToken>` يُستخرج عادة من استجابة تسجيل الدخول (مثل `POST /api/auth/login`).

---

## 1) رفع صورة الإثبات

**`POST /api/upload`**

- **Content-Type:** `multipart/form-data`
- **الحقول:** `image` أو `file` (ملف واحد)
- **مصادقة:** حسب إعداد الخادم؛ غالباً يمكن الرفع من التطبيق بنفس الدومين.

**استجابة ناجحة (مثال):**

```json
{
  "success": true,
  "url": "/uploads/images/1730000000000_abc123.png",
  "filename": "1730000000000_abc123.png",
  "message": "تم رفع الصورة بنجاح"
}
```

احفظ قيمة **`url`** لاستخدامها في الخطوة التالية كـ `receipt_image_url`.

---

## 2) إرسال إثبات دفع واتساب (الـ endpoint المخصص)

**`POST /api/courses/{courseId}/whatsapp-payment-proof`**

| العنصر | القيمة |
|--------|--------|
| Method | `POST` |
| Path param | `courseId` — معرف الدورة (UUID) |
| Headers | `Content-Type: application/json`، `Authorization: Bearer ...` |

**Body (JSON):**

| الحقل | النوع | مطلوب | الوصف |
|--------|------|--------|--------|
| `receipt_image_url` | `string` | نعم | مسار الصورة كما عاد من الرفع، مثل `/uploads/images/....` أو رابط `https://...` كامل |
| `message` | `string` | لا | ملاحظة اختيارية للإدارة |

**مثال:**

```json
{
  "receipt_image_url": "/uploads/images/1730000000000_abc123.png",
  "message": "تم التحويل على رقم الواتساب"
}
```

**استجابة ناجحة (شكل عام للـ API):**

```json
{
  "success": true,
  "message": "تم إرسال إثبات الدفع. سيتم مراجعته قريباً",
  "data": {
    "id": "<uuid>",
    "course_id": "<courseId>",
    "status": "pending",
    "payment_method": "whatsapp",
    "message": "...",
    "created_at": "2026-05-03T12:00:00.000Z"
  }
}
```

**أخطاء شائعة (400):**

| رسالة (تقريباً) | السبب |
|-----------------|--------|
| صورة إثبات الدفع مطلوبة | `receipt_image_url` فارغ أو غير مرسل |
| مسار صورة الإيصال يجب أن يبدأ بـ uploads/ أو يكون رابطاً كاملاً | مسار غير صالح |
| أنت مشترك بالفعل في هذه الدورة | الطالب مسجل مسبقاً |
| لديك طلب انضمام قيد المراجعة لهذه الدورة | يوجد طلب `pending` لنفس الدورة |

---

## 3) بديل — طلب اشتراك عام (نفس السجل في قاعدة البيانات)

يمكن بدلاً من المسار أعلاه استخدام:

**`POST /api/enrollment-requests`**

```json
{
  "course_id": "<courseId>",
  "payment_method": "whatsapp",
  "receipt_image_url": "/uploads/images/....",
  "message": "اختياري"
}
```

> المسار المخصص في القسم (2) يفرض وجود صورة الإثبات فقط؛ هذا البديل يسمح بمنطق أوسع إن احتجت لاحقاً.

---

## 4) قائمة طلبات الطالب

**`GET /api/enrollment-requests?page=1&per_page=20&status=pending`**

- Query اختياري: `status` — مثل `pending` / `approved` / `rejected`
- يعيد الطلبات مع `receipt_image_url` و`payment_method` وغيرها حسب تنفيذ الـ API.

---

## تدفق مقترح في Flutter

1. تسجيل الدخول → حفظ `accessToken`.
2. اختيار صورة من المعرض / الكاميرا.
3. `MultipartFile` → `POST /api/upload` (حقل `image` أو `file`).
4. من JSON الناتج: أخذ `url`.
5. `POST /api/courses/{courseId}/whatsapp-payment-proof` مع الهيدر والـ body أعلاه.
6. عرض رسالة النجاح من `message`؛ حالة الطلب تبقى `pending` حتى توافق الإدارة من الداشبورد.

---

## ملاحظات تقنية

- الاستجابة القياسية للمنصة: `{ "success": boolean, "data": ..., "message"?: string }`.
- إن واجهت `401`، حدّث التوكن أو أعد تسجيل الدخول.
- حجم الصورة عبر `/api/upload` للصور محدود (مثلاً حتى ~5MB للصور — راجع سياسة الخادم).

---

## مرجع الملفات في المشروع

| الطبقة | الملف |
|--------|--------|
| Backend (Express) | `backend/src/modules/mobile/mobile.routes.js` — `POST /courses/:id/whatsapp-payment-proof` |
| Backend logic | `backend/src/modules/mobile/mobile.service.js` — `submitWhatsappPaymentProof` |
| Next.js proxy | `app/api/courses/[id]/whatsapp-payment-proof/route.ts` |
| عميل TypeScript (ويب) | `lib/api.ts` — `mobileApi.submitWhatsappPaymentProof` |

---

*آخر تحديث: 2026-05-03*
