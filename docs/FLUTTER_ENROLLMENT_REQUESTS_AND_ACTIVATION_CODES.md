# Flutter Integration Guide
## طلبات الاشتراك (موافقة الأدمن) + أكواد التفعيل

هذا الملف يوثّق تدفق شراء الدورات بدون بوابة دفع إلكترونية:

1. **طلب اشتراك يدوي** — الطالب يبعت طلب (مع صورة إيصال اختيارية) والأدمن يقبل/يرفض مع سبب الرفض.
2. **كود تفعيل** — كود مربوط بدورة محددة، الطالب يدخله فيفتح الكورس فوراً مجاناً.

---

## Base URL & Auth

```
https://bouslty.anmka.com/api
```

كل endpoints الطالب تحتاج:

```
Authorization: Bearer <access_token>
```

---

## 1) تدفق طلب الاشتراك (موافقة الأدمن)

### 1.1 إنشاء طلب اشتراك

`POST /enrollment-requests`

| الحقل | النوع | إلزامي | الوصف |
|--------|--------|--------|--------|
| `course_id` | string (UUID) | نعم | معرف الدورة |
| `payment_method` | string | لا | `library` = «طلب شراء» (افتراضي) / `bank_transfer` / `whatsapp` |
| `receipt_image_url` | string | نعم لو `whatsapp` | قيمة `url` من `POST /api/upload` (يبدأ `/uploads/...` أو رابط https كامل) |
| `message` | string | لا | ملاحظة للإدارة (رقم التحويل، اسم المحوّل…) |

```json
{
  "course_id": "COURSE_ID",
  "payment_method": "bank_transfer",
  "receipt_image_url": "/uploads/images/abc123.jpg",
  "message": "تحويل إنستاباي رقم 12345"
}
```

**نجاح `200`:**

```json
{
  "success": true,
  "data": {
    "id": "REQUEST_ID",
    "course_id": "COURSE_ID",
    "status": "pending",
    "payment_method": "bank_transfer",
    "message": "تحويل إنستاباي رقم 12345",
    "created_at": "2026-10-22T12:00:00.000Z"
  }
}
```

**أخطاء محتملة (`success: false` + `message`, HTTP 400):**

| الرسالة | المعنى |
|--------|--------|
| `الدورة غير موجودة` | course_id غلط |
| `أنت مشترك بالفعل في هذه الدورة` | عنده enrollment نشط |
| `لديك طلب انضمام قيد المراجعة لهذه الدورة` | عنده طلب pending لنفس الدورة — اعرض حالة الطلب بدل السماح بطلب جديد |
| `مسار صورة الإيصال يجب أن يبدأ بـ uploads/ أو يكون رابطاً كاملاً` | قيمة receipt_image_url غير صالحة |

### 1.2 طلباتي (حالة الطلب + سبب الرفض)

`GET /enrollment-requests?status=pending&page=1&per_page=20`

- `status` اختياري: `pending` / `approved` / `rejected` (بدونه = الكل)

```json
{
  "success": true,
  "data": {
    "requests": [
      {
        "id": "REQUEST_ID",
        "course": {
          "id": "COURSE_ID",
          "title": "اسم الدورة",
          "thumbnail": "https://…",
          "price": 500,
          "instructor_name": "اسم المدرب"
        },
        "status": "rejected",
        "payment_method": "bank_transfer",
        "message": "تحويل إنستاباي رقم 12345",
        "receipt_image_url": "https://…/uploads/images/abc123.jpg",
        "admin_notes": "الإيصال غير واضح، أعد إرسال صورة أوضح",
        "created_at": "2026-10-22T12:00:00.000Z",
        "reviewed_at": "2026-10-22T14:00:00.000Z"
      }
    ],
    "meta": { "total": 1, "page": 1, "per_page": 20, "total_pages": 1 }
  }
}
```

> **`admin_notes` = سبب الرفض/ملاحظة الأدمن** — اعرضها للطالب في شاشة حالة الطلب عندما `status === "rejected"`.

### 1.3 إثبات دفع واتساب

`POST /courses/:courseId/whatsapp-payment-proof`

نفس سجل طلب الاشتراك لكن `payment_method=whatsapp` و**صورة الإيصال إلزامية**:

```json
{
  "receipt_image_url": "/uploads/images/abc123.jpg",
  "message": "اختياري"
}
```

### 1.4 رفع صورة الإيصال

`POST /upload` — `multipart/form-data` بالحقل `image` أو `file` → الاستجابة `{ "success": true, "url": "/uploads/images/xxx.jpg" }`. استخدم قيمة `url` كما هي في `receipt_image_url`.

### 1.5 الإشعارات (Push + In-App + Email)

| حدث | `data.type` في FCM | ملاحظة |
|------|--------------------|--------|
| موافقة الأدمن | `enrollment_approved` | يتضمن `course_id` — افتح الدورة |
| رفض الأدمن | `enrollment_rejected` | جسم الإشعار يتضمن سبب الرفض — اعرضه + زر إعادة المحاولة |
| تفعيل بكود | `course_activated` | انظر القسم 2 |

---

## 2) أكواد التفعيل (فتح فوري مجاني)

كود التفعيل مربوط **بدورة واحدة محددة** (تولّده الإدارة من لوحة التحكم → أكواد التفعيل). الطالب يدخله من شاشة الدورة فيفتح فوراً بدون مراجعة.

### 2.1 تفعيل الكود

`POST /activation-codes/redeem`

```json
{
  "code": "ABC12345",
  "course_id": "COURSE_ID"
}
```

**نجاح `200`:**

```json
{
  "success": true,
  "data": {
    "course_id": "COURSE_ID",
    "course_title": "اسم الدورة",
    "enrolled_course_ids": ["COURSE_ID", "BUNDLED_COURSE_ID"],
    "message": "تم الاشتراك في الدورة بنجاح."
  },
  "message": "تم تفعيل الدورة بنجاح"
}
```

> `enrolled_course_ids` قد يحتوي أكثر من دورة لو الكورس جزء من bundle — كلها اتفتحت على حساب الطالب. حدّث الكاش المحلي للاشتراكات أو أعد استدعاء `GET /enrollments`.

**أخطاء (`success: false` + message):**

| الرسالة | المعنى |
|--------|--------|
| `كود التفعيل مطلوب` / `معرف الدورة مطلوب` | حقل ناقص |
| `كود التفعيل غير صحيح` | الكود مش موجود **أو** مش تابع لهذه الدورة |
| `كود التفعيل غير مفعّل` | الأدمن عطّل الكود |
| `كود التفعيل منتهي الصلاحية` | expiresAt فاتت |
| `لقد استخدمت هذا الكود من قبل` | نفس المستخدم استخدم نفس الكود |
| `تم استخدام هذا الكود بالكامل` | استنفد maxUses |
| `أنت مشترك بالفعل في هذه الدورة` | عنده enrollment نشط — وجّهه لشاشة المشاهدة مباشرة |

### 2.2 سلوك مقترح في شاشة الشراء

- بجانب خيارات الدفع اليدوية اعرض حقل «لديك كود تفعيل؟».
- بعد `redeem` ناجح: حدّث حالة `is_enrolled` في `GET /courses/:id` أو أعد جلبها، وانقل لشاشة المشاهدة.
- نجاح التفعيل يبعت إشعار push (`type: course_activated`).

---

## 3) إعدادات طرق الدفع (موجودة مسبقاً)

`GET /config/app` → `data.course_payment_methods`:

```json
{
  "bank_transfer_enabled": true,
  "library_receipt_enabled": true,
  "whatsapp_enabled": false,
  "whatsapp_number_e164": "+201xxxxxxxxx"
}
```

اعرض فقط الطرق المفعّلة في شاشة طلب الاشتراك. التفاصيل الكاملة في `FLUTTER_COURSE_PAYMENT_METHODS.md`.

---

## 4) ملاحظات

- عند **موافقة** الأدمن على الطلب يُسجَّل تلقائياً سجل `Payment` في النظام (يظهر في تقارير الإيرادات) — لا يحتاج التطبيق أي إجراء إضافي.
- دورة مجانية (`is_free` أو السعر 0): استخدم `POST /courses/:id/enroll` مباشرة بدون طلب.
- `GET /courses/:id` يعيد `is_enrolled: true` للمستخدم المسجّل — استخدمها لإخفاء زر الشراء.

*آخر تحديث: 2026-10-22 — يتوافق مع `enrollment_requests`, `activation_codes`, `activation_code_redemptions`.*
