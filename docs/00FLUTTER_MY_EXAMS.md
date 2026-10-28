# امتحانات الطالب — تكامل Flutter

**مسار الملف في المشروع:** `public_html/FLUTTER_MY_EXAMS.md` — انسخ الملف أو أرسل الرابط من الريبو لفريق Flutter.

## الملخص

- **`GET /my-exams`** يعيد **قائمة واحدة** بكل الامتحانات النشطة للدورات التي الطالب **مشترك فيها** (مناسب لشاشة «امتحاناتي»).
- **`GET /courses/{courseId}/exams`** يعيد نفس شكل العنصر لكن **لدورة واحدة** فقط.
- **بدء الامتحان** و**التسليم** يحتاجان توكناً صالحاً؛ الطالب يجب أن يكون مسجّلاً في الدورة.
- خيارات الإجابة في بدء الامتحان تُعاد كـ `{ id: "opt_0", text: "..." }` — عند **التسليم** أرسل **فهرس الاختيار** (`"0"`, `"1"`, …) أو نفس شكل `opt_0` (السيرفر يوحّد المقارنة).

---

## المسارات الأساسية (نفس الـ router)

**القاعدة:** استبدل `{BASE_URL}` بعنوان الـ API (مثال: `https://elsherifacademy.anmka.com`).

- `{BASE_URL}/api/...`
- `{BASE_URL}/v1/...` (نفس المسارات تحت بادئة `v1`)

---

## 1) كل امتحاناتي (عبر كل الدورات المسجّل بها)

**الطريقة:** `GET`  
**المسار:** `/api/my-exams` أو `/v1/my-exams`

**المصادقة:** **مطلوبة** — `Authorization: Bearer <access_token>`

**مثال:**

```http
GET /api/my-exams
Authorization: Bearer <access_token>
```

**الاستجابة:**

```json
{
  "success": true,
  "data": [
    {
      "id": "uuid",
      "title": "عنوان الامتحان",
      "description": "وصف أو null",
      "course_id": "uuid",
      "course_name": "اسم الدورة",
      "questions_count": 10,
      "duration_minutes": 60,
      "passing_score": 70,
      "max_attempts": 3,
      "attempts_used": 0,
      "best_score": null,
      "best_percentage": null,
      "correct_answers": null,
      "wrong_answers": null,
      "is_passed": false,
      "can_start": true,
      "created_at": "2026-01-01T00:00:00.000Z"
    }
  ]
}
```

| الحقل | النوع | الوصف |
|--------|--------|--------|
| `attempts_used` | `int` | عدد صفوف المحاولات (المسجّلة) لهذا الامتحان |
| `best_score` | `number` \| `null` | أعلى **درجة نقاط** بين المحاولات (حسب `score` المخزّن) |
| `best_percentage` | `number` \| `null` | نسبة **أفضل محاولة مكتملة** (أعلى `percentage` ثم `score` ثم الأحدث) |
| `correct_answers` | `int` \| `null` | عدد الأسئلة الصحيحة في تلك **أفضل محاولة مكتملة** |
| `wrong_answers` | `int` \| `null` | عدد الأسئلة الخاطئة/غير الصحيحة فيها (يشمل غير المُجاب عنها كخطأ) |
| `questions_count` | `int` | إجمالي أسئلة الامتحان (`correct_answers + wrong_answers` يطابقها بعد التسليم) |
| `is_passed` | `bool` | هل نجح في أي محاولة مكتملة |
| `can_start` | `bool` | `true` إذا `attempts_used < max_attempts` |

> **`correct_answers` / `wrong_answers`**: تُملأ من السيرفر بعد **التسليم** فقط (محاولات قديمة قبل التحديث قد ترجع `null`). إجمالي الأسئلة المرصود في المحاولة = `correct_answers + wrong_answers` (= `questions_count` إذا أجاب عن كل السؤال).

إذا الطالب **غير مشترك في أي دورة**، `data` تكون `[]`.

---

## 2) امتحانات دورة واحدة

**الطريقة:** `GET`  
**المسار:** `/api/courses/{courseId}/exams`

**المصادقة:** اختيارية — مع التوكن تُحسب `attempts_used` و`can_start` و`best_score` بدقة.

**مثال:**

```http
GET /api/courses/550e8400-e29b-41d4-a716-446655440000/exams
Authorization: Bearer <access_token>   # مُفضّل
```

**شكل `data`:** نفس جدول العناصر في القسم (1) — لكن كل العناصر لها نفس `course_id`.

---

## 3) تفاصيل امتحان (أسئلة بدون إجابة نموذجية)

**الطريقة:** `GET`  
**المسار:** `/api/courses/{courseId}/exams/{examId}`

**المصادقة:** اختيارية.

**مثال:**

```http
GET /api/courses/{courseId}/exams/{examId}
Authorization: Bearer <access_token>   # مُفضّل
```

يُرجع تفاصيل الامتحان + قائمة أسئلة (بدون `correctAnswer` للطالب).

---

## 4) بدء محاولة

**الطريقة:** `POST`  
**المسار:** `/api/courses/{courseId}/exams/{examId}/start`

**المصادقة:** **مطلوبة**

**مثال:**

```http
POST /api/courses/{courseId}/exams/{examId}/start
Authorization: Bearer <access_token>
Content-Type: application/json

{}
```

**الاستجابة (مختصرة):**

| الحقل | الوصف |
|--------|--------|
| `attempt_id` | معرف المحاولة — يُستخدم عند التسليم |
| `ends_at` | نهاية الوقت المسموح (ISO) |
| `duration_minutes` | مدة الامتحان |
| `questions` | أسئلة مع خيارات؛ كل خيار `id` مثل `opt_0`, `opt_1` |

---

## 5) تسليم الإجابات

**الطريقة:** `POST`  
**المسار:** `/api/courses/{courseId}/exams/{examId}/submit`

**المصادقة:** **مطلوبة**

**Body (JSON):**

```json
{
  "attempt_id": "uuid-المحاولة",
  "answers": [
    {
      "question_id": "uuid-السؤال",
      "selected_options": "0"
    }
  ]
}
```

- **اختيار واحد (MCQ / صح وخطأ):** `selected_options` نص: `"0"` أو `"1"` … (يُفضّل الفهرس كما في قاعدة البيانات).
- **يمكن** إرسال `"opt_0"` بدل `"0"` — السيرفر يوحّد.
- **نص حر:** استخدم `answer` بدل `selected_options` إن وُجد نمط نصي في الـ API لديكم (السيرفر يقبل `answer` أو `selected_options`).

**مفاتيح بديلة مقبولة في كل عنصر:** `questionId` (camelCase) بدل `question_id`.

**الاستجابة (مختصرة — snake_case):**

| الحقل | الوصف |
|--------|--------|
| `score` | مجموع نقاط الأسئلة الصحيحة |
| `percentage` | النسبة المئوية من إجمالي النقاط |
| `is_passed` | تجاوز `passing_score` |
| `correct_answers` | عدد الأسئلة الصحيحة |
| `wrong_answers` | عدد الأسئلة الخاطئة أو غير الصحيحة |
| `total_questions` | عدد أسئلة الامتحان في التصحيح |
| `passing_score` | من إعدادات الامتحان (في بعض الردود) |
| `time_taken_minutes` | مدة المحاولة بالدقائق |

---

## 6) سجل نتائجي (محاولات مكتملة فقط)

**الطريقة:** `GET`  
**المسار:** `/api/my-exam-results`

**المصادقة:** **مطلوبة**

**Query (اختياري):**

| المعامل | مثال | الوصف |
|---------|------|--------|
| `page` | `1` | رقم الصفحة |
| `per_page` | `20` | حجم الصفحة |
| `course_id` | uuid | تصفية حسب الدورة |
| `is_passed` | `true` / `false` | نجاح / عدم نجاح |

**مثال:**

```http
GET /api/my-exam-results?page=1&per_page=20
Authorization: Bearer <access_token>
```

**الاستجابة:** `data.attempts` + `data.meta` + `data.stats` (إحصائيات سريعة).

---

## أخطاء شائعة

| الحالة | السبب المحتمل |
|--------|------------------|
| 401 | توكن منتهٍ أو مفقود |
| 400 عند `start` / `submit` | الطالب غير مسجّل في الدورة، أو انتهى الوقت، أو تجاوز `max_attempts` |
| 404 على `exams` للدورة | `courseId` خاطئ أو لا يوجد امتحانات نشطة |

---

## تدفق مقترح في Flutter

1. شاشة «امتحاناتي»: `GET /api/my-exams`.
2. عند الضغط على امتحان: `GET /api/courses/{course_id}/exams/{examId}` (أو الاعتماد على بيانات القائمة إن كافية).
3. «ابدأ»: `POST .../start` → خزّن `attempt_id` و`ends_at`.
4. بعد الإجابة: `POST .../submit` مع `attempt_id` و`answers`.
5. تاريخ النتائج: `GET /api/my-exam-results`.

---

*آخر تحديث: يناير 2026 — يتماشى مع `backend/src/modules/mobile/mobile.routes.js`.*
