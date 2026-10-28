# إعدادات طرق دفع اشتراك الدورات — تطبيق Flutter

يتحكم المشرف في **أي طرق دفع تظهر للطالب** من:

- **صفحة مخصصة (مُفضّلة):** `https://elsherifacademy.anmka.com/admin/settings/payment-methods`
- أو **ضمن إعدادات التطبيق:** `https://elsherifacademy.anmka.com/admin/settings` (نفس البطاقة + زر للصفحة المخصصة)

من السايدبار: **إعدادات التطبيق** → **طرق دفع الدورات**.

الطرق المعنونة:

1. **تحويل بنكي** — عرض تعليمات التحويل للحساب البنكي.  
2. **المكتبة (إيصال)** — الطالب يدفع في المكتبة ويرفع صورة الوصل من التطبيق؛ الموافقة من الأدمن (مسار الإيصالات الحالي في النظام إن وُجد).  
3. **واتساب** — إظهار التواصل على رقم واتساب لإتمام الدفع يدويًا.

---

## جلب الإعدادات للتطبيق

**الطريقة:** `GET`  
**مسار API (عبر نفس نطاق الويب):**

```text
https://elsherifacademy.anmka.com/api/config/app
```

(البروكسي يوجّه إلى الخلفية: `/api/config/app`.)

**مصادقة:** عادة **بدون توكن** للإعدادات العامة (تحقق من سياسة النشر عندكم؛ إن طُلب JWT استخدمه كما باقي موبايل API).

### جزء الاستجابة المهم (`course_payment_methods`)

ضمن جسم JSON الرئيسي للكونفيغ يوجد الكائن التالي (مع باقي الحقول القديمة مثل `theme`, `features`, إلخ):

```json
{
  "success": true,
  "data": {
    "course_payment_methods": {
      "bank_transfer_enabled": true,
      "library_receipt_enabled": true,
      "whatsapp_enabled": false,
      "whatsapp_number_e164": "+201234567890"
    }
  }
}
```

| الحقل | النوع | المعنى |
|--------|--------|--------|
| `bank_transfer_enabled` | `bool` | إذا `false` **لا** تعرض خيار التحويل البنكي في شاشة شراء/دفع الدورة. |
| `library_receipt_enabled` | `bool` | إذا `false` **لا** تعرض خيار الدفع في المكتبة + رفع الإيصال. |
| `whatsapp_enabled` | `bool` | إذا `false` **لا** تعرض التنسيق عبر واتساب. |
| `whatsapp_number_e164` | `string \| null` | يظهر **فقط منطقيًا** عندما `whatsapp_enabled === true`. صيغة دولية تبدأ بـ `+`. إذا كان `null` رغم التفعيل، عالج كخطأ إعداد أو استخدم احتياطيًا رقم `payment_whatsapp_number` أو `support.whatsapp` من نفس الاستجابة إن وُجد. |

> **ملاحظة:** الإدارة قد تترك حقل رقم واتساب «دفع الدورات» فارغًا؛ وقتها الخادم يعبّئ الرقم من إعدادات واتساب العامة. بعد التفعيل، تأكد أن `whatsapp_number_e164` غير فارغ قبل عرض زر واتساب.

---

## سلوك مقترح في Flutter

1. عند فتح شاشة الدفع لدورة، استدعِ `GET /api/config/app` (أو استخدم كاشًا مع TTL معقول).
2. ابنِ قائمة الخيارات المعروضة من الثلاث booleans:
   - تحويل بنكي ← `bank_transfer_enabled`
   - مكتبة + رفع إيصال ← `library_receipt_enabled`
   - واتساب ← `whatsapp_enabled` + رابط `https://wa.me/<digits>` بعد إزالة الرموز غير الرقمية من `whatsapp_number_e164` أو استخدام حزمة `url_launcher`.
3. إذا **كل** الطرق المعروضة معطّلة ولا توجد بوابة إلكترونية أخرى في التطبيق، اعرض رسالة توضيحية («لا تتوفر طرق دفع حاليًا») وتنسيق مع الدعم.

---

## لوحة التحكم (حقول تُحفظ في السيرفر)

| المعنى | مفتاح في استجابة الأدمن `/admin/app-config` |
|--------|-----------------------------------------------|
| تفعيل التحويل البنكي | `coursePaymentBankEnabled` |
| تفعيل المكتبة والإيصال | `coursePaymentLibraryEnabled` |
| تفعيل واتساب للدفع | `coursePaymentWhatsappEnabled` |
| رقم واتساب خاص بالدفع (اختياري) | `coursePaymentWhatsappNumber` |

تحديث الإعدادات: `PUT /api/admin/app-config` مع الجسم JSON والتوكن الإداري (كما باقي الإعدادات).

---

## طلب الاشتراك بالدفع في المكتبة (صورة إيصال) — Mobile API

**المسار (عبر نفس النطاق + بروكسي الـ API):**  
`POST /api/enrollment-requests`  
**التوثيق:** `Authorization: Bearer <JWT للطالب>` (نفس توكن بقية موبايل API).

### جسم الطلب (JSON)

| الحقل | النوع | إلزامي | الوصف |
|--------|--------|--------|--------|
| `course_id` | string (UUID) | نعم | معرف الدورة. |
| `payment_method` | string | يُفضّل | القيم: `library` (افتراضي)، `bank_transfer`، `whatsapp`. |
| `receipt_image_url` | string | **نعم عند `library`** | مسار الملف كما يعيده رفع الصورة (انظر أدناه)، أو رابط `https` كاملاً. |
| `message` | string | لا | ملاحظة للإدارة (اختياري). |

عند `payment_method: "library"` **يجب** إرسال `receipt_image_url` وإلا يُرجع الخادم `400` برسالة توضح أن صورة الإيصال مطلوبة.

### الخطوات المقترحة في Flutter

1. الطالب يختار صورة الإيصال من الجهاز.
2. **رفع الملف:**  
   `POST https://elsherifacademy.anmka.com/api/upload`  
   - الطلب: `multipart/form-data` مع الحقل **`image`** أو **`file`** (ملف الصورة).  
   - نفس الترويسة `Authorization: Bearer …` إن طلب الخادم ذلك (تحقق من إعداداتكم).  
   - الاستجابة الناجحة تحتوي على **`url`** مثل `/uploads/images/xxxxx.jpg`.
3. ثم استدعاء `POST /api/enrollment-requests` بـ JSON، مثال:

```json
{
  "course_id": "uuid-الدورة",
  "payment_method": "library",
  "receipt_image_url": "/uploads/images/abc123.jpg",
  "message": "دفع في فرع المكتبة"
}
```

4. الاستجابة الناجحة تتضمن من بين الحقول:  
   `id`, `course_id`, `status`, `payment_method`, **`receipt_image_url`** (رابطاً كاملاً جاهزاً للعرض)، `created_at`.

### لوحة التحكم

بعد نجاح الطلب يظهر الطلب تحت:  
**لوحة التحكم → طلبات الدفع من المكتبة** (`/admin/enrollment-requests`) مع **معاينة صورة الإيصال** وروابط الموافقة/الرفض (كما هو مُهيأ في المشروع).

### رفع الملف: ملاحظة

`receipt_image_url` يجب أن يطابق نمط المسار من السيرفر: يبدأ بـ `uploads/...` (بعد إزالة `/` الابتدائية) أو يكون `https://...`. أي مسار آخر يُرفض برسالة خطأ توضيحية.

---

*آخر تحديث يتوافق مع جدول `app_config`، مسار `GET /api/config/app`، وحقل `receipt_image_url` في جدول `enrollment_requests`.*
