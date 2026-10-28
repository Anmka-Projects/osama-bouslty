# جلسات مباشرة على مستوى الدورة — تكامل Flutter

## الملخص

- كل **جلسة مباشرة** مرتبطة بـ **دورة** (`courseId` في قاعدة البيانات).
- عند جلب **تفاصيل الدورة** من الـ API، يُرجع الحقل **`live_sessions`**: مصفوفة جلسات تخص **نفس الدورة** فقط (باستثناء الحالة `cancelled`).
- يمكن للمستخدم عرض القائمة داخل شاشة تفاصيل الدورة دون طلب إضافي (أو يمكن الاعتماد على نفس الـ response فقط).

---

## 1) تفاصيل الدورة (المصدر الرئيسي)

**الطريقة:** `GET`  
**المسارات المدعومة من الباكند** (نفس الـ router):

- `{BASE_URL}/api/courses/{courseId}`
- `{BASE_URL}/v1/courses/{courseId}`

**المصادقة:** اختيارية (`optionalAuthMiddleware`). إن وُجد التوكن، تُحسب `is_enrolled` و`progress` بدقة.

**مثال:**

```http
GET /api/courses/550e8400-e29b-41d4-a716-446655440000
Authorization: Bearer <access_token>   # اختياري
```

**الاستجابة (مختصرة):** نفس أشكال المشروع الحالي لـ `title`, `curriculum`, `exams`, … مع:

| الحقل            | النوع    | الوصف |
|------------------|----------|--------|
| `live_sessions`  | `array`  | جلسات مباشرة مرتبطة بهذه الدورة (غير الملغاة)، مرتبة حسب `scheduled_at` تصاعدياً |

### شكل عنصر `live_sessions[i]`

| الحقل | النوع | الوصف |
|--------|--------|--------|
| `id` | `string` (UUID) | معرف الجلسة |
| `title` | `string` | عنوان الجلسة |
| `description` | `string` | وصف (قد يكون فارغاً) |
| `platform` | `string` | `zoom` \| `meet` \| `teams` |
| `platform_link` | `string` | رابط الانضمام (Zoom/Meet/Teams) |
| `scheduled_at` | `string` | ISO 8601 — موعد الجلسة |
| `duration_minutes` | `int` | المدة بالدقائق |
| `capacity` | `int` | السعة القصوى |
| `enrolled_count` | `int` | عدد المسجلين |
| `price` | `number` | السعر (رقم عشري) |
| `status` | `string` | `scheduled` \| `live` \| `completed` \| `cancelled` — **في هذه القائمة لا يُعاد `cancelled`** |
| `instructor` | `object` | `{ id, name, avatar }` — `avatar` رابط كامل جاهز للعرض |

**ملاحظة:** إذا لم توجد جلسات للدورة، يُرجع `live_sessions: []`.

---

## 2) قائمة عامة للجلسات (اختياري — الشاشة الرئيسية / البحث)

**الطريقة:** `GET`  
**المسار:** `{BASE_URL}/api/live-courses` (أو `/v1/live-courses`)

يُستخدم للعرض العام (مجموعات `upcoming`, `live_now`, `past`).  
تمت إضافة حقول اختيارية لربط الجلسة بالدورة:

| الحقل | الوصف |
|--------|--------|
| `course_id` | معرف الدورة أو `null` للجلسات القديمة قبل الربط |
| `course_title` | عنوان الدورة أو `null` |

---

## 3) إعداد التطبيق (`config`)

من **`GET /api/config/app`** (أو ما يعادله في التطبيق):

- `live_courses_enabled`: إن كان `false` يمكن إخفاء أقسام الجلسات المباشرة في الواجهة (اختياري).

---

## 4) توصيات واجهة Flutter داخل شاشة الدورة

1. بعد تحميل تفاصيل الدورة، اقرأ `live_sessions` من نفس الـ JSON.
2. اعرض قائمة (Cards) بعنوان، التاريخ من `scheduled_at`، المدة، زر يفتح `platform_link` في المتصفح / التطبيق المناسب.
3. للجلسة `status == live` يمكن تمييزها بصرياً (بث جارٍ).
4. احترم المنطقة الزمنية عند عرض `scheduled_at` (تحويل من UTC إلى محلية الجهاز إن لزم).

---

## 5) لوحة الإدارة (مرجع للبيانات)

- إنشاء جلسة من الأدمن يتطلب اختيار **الدورة** والمدرب والباقي كما هو.
- تصفية القائمة حسب الدورة (إن لزم): من الويب يمكن استخدام query على واجهة الإدارة الداخلية؛ للتطبيق الطالب يكفي `live_sessions` من تفاصيل الدورة.

---

## 6) مثال JSON مقطوع (`live_sessions`)

```json
"live_sessions": [
  {
    "id": "a1b2c3d4-e5f6-7890-abcd-ef1234567890",
    "title": "مراجعة الوحدة الأولى",
    "description": "",
    "platform": "zoom",
    "platform_link": "https://zoom.us/j/123456789",
    "scheduled_at": "2026-05-10T18:00:00.000Z",
    "duration_minutes": 60,
    "capacity": 100,
    "enrolled_count": 12,
    "price": 0,
    "status": "scheduled",
    "instructor": {
      "id": "...",
      "name": "أحمد المدرس",
      "avatar": "https://example.com/uploads/..."
    }
  }
]
```

---

**آخر تحديث:** يتوافق مع الباكند بعد ربط `LiveSession.courseId` وتضمين `live_sessions` في `getCourseDetails`.
