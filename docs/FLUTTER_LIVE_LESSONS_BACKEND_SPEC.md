# مواصفة الباك إند — الدروس كجلسات لايف فقط + شراء درس منفرد

هذا الملف يوضح المطلوب من الباك إند بعد تحويل دروس الكورس إلى **جلسات لايف فقط** (مفيش فيديو مسجل)، مع:

- كل درس/جلسة ليها **سعر خاص**.
- الكورس ليه **سعر خاص** منفصل.
- الطالب يقدر يشتري **درس واحد** أو **الكورس كله**.
- لينك الجلسة بيتفتح جوه التطبيق في **WebView**.
- التطبيق بيعرض **كونتر (عدّاد تنازلي)** لوقت الجلسة وبيظبط **تذكيرات محلية** قبل البداية.

---

## 1) موديل البيانات — Live Session / Lesson

الجلسة (الدرس) المطلوب إنها ترجع في تفاصيل الكورس داخل `live_sessions` و/أو `lessons` بنفس الشكل:

```json
{
  "id": 55,
  "course_id": 12,
  "title": "الجلسة الأولى — مقدمة",
  "description": "نبذة عن الجلسة",
  "platform": "zoom",
  "platform_link": "https://zoom.us/j/123456789",
  "scheduled_at": "2025-02-10T18:00:00Z",
  "duration_minutes": 60,
  "price": 150,
  "currency": "EGP",
  "status": "scheduled",
  "capacity": 30,
  "enrolled_count": 12,
  "is_purchased": false,
  "has_access": false,
  "is_free": false,
  "instructor": {
    "id": 7,
    "name": "أ. محمد أحمد",
    "avatar": "..."
  }
}
```

### أهم الحقول

| الحقل | النوع | ملاحظات |
|---|---|---|
| `id` | int | مطلوب — بيتبعت في الشراء كـ `lesson_id` |
| `platform_link` / `join_url` / `meeting_url` | string | لينك الجلسة — واحد منهم على الأقل لازم يكون موجود |
| `scheduled_at` | ISO 8601 | **UTC مع timezone** — التطبيق بيحوّله للوقت المحلي ويبني عليه الكونتر والتذكير |
| `duration_minutes` | int | مدة الجلسة — بيتحسب منها وقت الانتهاء |
| `price` | number | سعر الدرس منفرد — `0` أو `null` = مجاني |
| `status` | enum | `scheduled` \| `live` \| `completed` \| `cancelled` |
| `is_purchased` / `has_access` | bool | هل الطالب الحالي شاري الدرس ده — **مهم جدًا** يكون per-student |
| `is_free` | bool | اختياري — بديل عن `price: 0` |

> لو الحقل مش موجود التطبيق بيقبل أسماء بديلة (`join_url`, `meeting_url`, `zoom_link`, `starts_at`, `start_at`, `scheduledAt`, `session_status`)، لكن الأفضل نثبت على الأسماء اللي فوق.

---

## 2) أسعار الكورس والدروس

- `course.price` / `discount_price` → سعر الكورس كامل (زي ما هو حاليًا).
- `live_sessions[].price` → سعر الدرس الواحد.
- شراء الكورس **يفتح كل الدروس** → في الريسبونس لازم `is_purchased`/`has_access` لكل جلسة تبقى `true` لما الطالب مشترك في الكورس.
- شراء درس واحد **يفتح الدرس ده بس** → باقي الجلسات تفضل مقفولة بزرار شراء.

---

## 3) الشراء — Checkout / Payments

### 3.1 الطلب (Request)

التطبيق بيبعت للـ checkout/payment:

```json
{
  "item_type": "course",
  "course_id": 12,
  "payment_method": "vodafone_cash"
}
```

أو لدرس منفرد:

```json
{
  "item_type": "lesson",
  "course_id": 12,
  "lesson_id": 55,
  "payment_method": "vodafone_cash"
}
```

> `item_type` أحد القيم: `course` \| `lesson` (أو `live_session` — نثبت على `lesson`). لما يكون `lesson` لازم `lesson_id` يكون موجود، و`course_id` مفيد للسياق/التقرير.

### 3.2 طلبات التفعيل اليدوية (Enrollment Requests)

نفس الفكرة في `POST /api/enrollment-requests` (تحويل بنكي / مكتبة / إثبات واتساب):

```json
{
  "item_type": "lesson",
  "course_id": 12,
  "lesson_id": 55,
  "payment_method": "bank_transfer",
  "transaction_reference": "TRX-123",
  "attachment": "<file>"
}
```

لازم الداشبورد/الأدمن يقدر يوافق على طلب **درس واحد** من غير ما يفتح الكورس كله.

### 3.3 الاستجابة بعد الشراء/الموافقة

بعد نجاح الدفع (أو موافقة الأدمن)، ريكوئست تفاصيل الكورس لازم يرجع:

```json
{
  "live_sessions": [
    { "id": 55, "is_purchased": true, "has_access": true, "...": "..." },
    { "id": 56, "is_purchased": false, "has_access": false, "...": "..." }
  ],
  "is_enrolled": false
}
```

- `is_enrolled: true` (شراء الكورس) → كل الجلسات `has_access: true`.
- شراء درس → الجلسة دي بس `is_purchased: true`.

---

## 4) قواعد الوصول (Access Rules)

التطبيق بيسمح بالانضمام للجلسة لو:

```
is_enrolled(course) OR live_sessions[].is_purchased OR has_access OR price == 0 / is_free
```

غير كده زرار الجلسة بيبقى **"اشترك الآن"** وبيفتح شيت شراء الدرس. الأفضل الباك يرجع `has_access` محسوبة جاهزة (مشترك في الكورس **أو** شاري الدرس **أو** مجاني) عشان المنطق يكون في مكان واحد.

---

## 5) فتح الجلسة — WebView

- التطبيق بيفتح `platform_link`/`join_url` جوه **WebView** داخلي.
- لو اللينك HTTP/HTTPS → بيفتح جوه التطبيق مباشرة.
- لو لينك تطبيق خارجي (`zoommtg://`, `tel:`, `mailto:`) → التطبيق بيحوّله للنظام — يعني الباك يقدر يبعت deep links برضه.
- الأفضل اللينك يكون **join URL جاهز بدون صفحة لوجين** (signed join link / tokenized) عشان الطالب ميحتاجش يسجل دخول تاني جوه الويب فيو.

---

## 6) الحالة والكونتر والتذكيرات

- الكونتر بيتحسب من `scheduled_at` ناقص الوقت الحالي، وبيوقف عند `scheduled_at + duration_minutes`.
- `status: live` → زرار **"انضم الآن"**.
- `status: scheduled` والوقت لسه جاي → زرار **"ذكّرني"** (تذكير محلي قبل البداية بساعة وربع ساعة).
- `status: completed` / `cancelled` → زرار معطّل.
- التذكيرات **محلية** على الجهاز — مش محتاجة API. لو الباك عايز يبعت Push Notification قبل الجلسة (مثلًا قبلها بـ 15 دقيقة) ده إضافة كويسة بس مش شرط.

> مهم: لو الجلسة اتأجلت، الباك يحدّث `scheduled_at` و`status` يرجع `scheduled` — التطبيق هيعيد حساب الكونتر والتذكير تلقائيًا.

---

## 7) إندبوينت تفاصيل الكورس (موجود — يحتاج تأكيد الحقول)

`GET /api/courses/{id}` لازم يرجع داخل الريسبونس:

```json
{
  "id": 12,
  "title": "كورس التسويق",
  "price": 1200,
  "is_enrolled": false,
  "live_sessions": [
    {
      "id": 55,
      "title": "الجلسة الأولى",
      "platform": "zoom",
      "platform_link": "https://zoom.us/j/123",
      "scheduled_at": "2025-02-10T18:00:00Z",
      "duration_minutes": 60,
      "price": 150,
      "status": "scheduled",
      "is_purchased": false,
      "has_access": false
    }
  ]
}
```

## 8) ملخص المطلوب من الباك

1. إضافة/تثبيت حقل **`price` + `is_purchased`/`has_access`** لكل عنصر في `live_sessions` (per-student).
2. قبول **`item_type: "lesson"` + `lesson_id`** في إندبوينت الدفع/checkout وطلبات التفعيل اليدوية.
3. شراء الدرس يفتح الدرس بس؛ شراء الكورس يفتح الكل.
4. التأكد إن `platform_link`/`join_url` و`scheduled_at` (UTC ISO8601) و`status` بيرجعوا دايمًا.
5. اختياري: Push Notification من السيرفر قبل بدء الجلسة.
