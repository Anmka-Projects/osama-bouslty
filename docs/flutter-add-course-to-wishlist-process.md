# Add Course To Wishlist Process (Flutter)

هذا المستند يشرح مسار **إضافة كورس إلى قائمة الرغبات** من تطبيق Flutter بشكل عملي (من الزر حتى استجابة الـ API).

## الهدف

عند ضغط المستخدم على زر الـ bookmark في الكورس:

1. التطبيق يرسل طلب `POST` إلى مسار الـ wishlist.
2. الخادم يتحقق من التوكن.
3. الخادم يستقبل `course_id` ويستدعي خدمة الإضافة.
4. التطبيق يحدّث حالة الزر (bookmarked / unbookmarked) بناءً على النتيجة.

---

## 1) Endpoint المستخدم للإضافة

| العنصر   | القيمة                                                |
| -------- | ----------------------------------------------------- |
| Method   | `POST`                                                |
| Path     | `/wishlist`                                           |
| Full URL | `{BASE_URL}/api/wishlist` أو `{BASE_URL}/v1/wishlist` |
| Auth     | مطلوب `Bearer` token                                  |

**Headers**

```http
Authorization: Bearer <access_token>
Content-Type: application/json
```

**Body**

```json
{
  "course_id": "550e8400-e29b-41d4-a716-446655440000"
}
```

> ملاحظة: اسم الحقل المطلوب في الـ backend هو `course_id` (snake_case).

---

## 2) التسلسل الكامل (Flutter -> API -> Backend)

1. المستخدم يضغط زر الـ bookmark في UI.
2. Flutter يستدعي دالة الإضافة (مثلا `addToWishlist(courseId)`).
3. الطلب يذهب إلى `/api/wishlist` (Next proxy إن كنت تستخدم نفس الدومين).
4. proxy يمرر الطلب إلى backend route `/api/wishlist`.
5. في backend:
   - route: `router.post('/wishlist', authMiddleware, mobileController.addToWishlist)`
   - `authMiddleware` يقرأ التوكن ويحدد `req.user.id`.
   - `mobileController.addToWishlist` يقرأ `course_id` من body.
   - يستدعي `mobileService.addToWishlist(userId, course_id)`.
6. backend يرجع payload موحد بصيغة `{ success, data, message? }`.
7. Flutter:
   - لو النجاح: يغيّر icon state إلى bookmarked.
   - لو الفشل: يعرض رسالة خطأ ويترك الحالة كما هي (أو يعمل rollback لو optimistic update).

---

## 3) الاستجابة المتوقعة

### نجاح عام (شكل موحد)

```json
{
  "success": true,
  "message": "تمت الإضافة إلى قائمة الرغبات",
  "data": {}
}
```

### أخطاء شائعة

| HTTP  | السبب                             |
| ----- | --------------------------------- |
| `401` | التوكن ناقص/منتهي/غير صالح        |
| `404` | المسار خطأ أو `BASE_URL` غير صحيح |
| `429` | تجاوز rate limit                  |

---

## 4) ملاحظة مهمة عن الوضع الحالي في هذا المشروع

في الكود الحالي، خدمة wishlist في backend ما زالت placeholder:

- `getWishlist` ترجع `[]`
- `addToWishlist` ترجع كائن يفيد أن الميزة غير متاحة حاليا
- لا يوجد Wishlist model في Prisma حاليا

بالتالي في بيئة هذا المستودع الآن:

- الطلب قد يرجع `success: true` من طبقة `sendSuccess`
- لكن `data` نفسها قد تحتوي `{ success: false, message: "قائمة الرغبات غير متاحة حالياً" }`

لذلك في Flutter مؤقتا:

1. افحص `response.success`.
2. افحص أيضا `response.data.success` إذا كانت موجودة.
3. لا تغيّر حالة الزر إلى bookmarked نهائيا إلا إذا كانت النتيجة الفعلية ناجحة.

---

## 5) Example Dart (إضافة كورس)

```dart
Future<bool> addCourseToWishlist({
  required String baseUrl,
  required String token,
  required String courseId,
}) async {
  final res = await http.post(
    Uri.parse('$baseUrl/wishlist'),
    headers: {
      'Authorization': 'Bearer $token',
      'Content-Type': 'application/json',
    },
    body: jsonEncode({'course_id': courseId}),
  );

  final body = jsonDecode(res.body) as Map<String, dynamic>;
  if (res.statusCode < 200 || res.statusCode >= 300) return false;

  // مستوى API العام
  final apiSuccess = body['success'] == true;

  // مستوى data الداخلي (الوضع الحالي للـ placeholder)
  final nested = body['data'];
  final nestedSuccess = nested is Map<String, dynamic>
      ? (nested['success'] != false) // false explicit means fail
      : true;

  return apiSuccess && nestedSuccess;
}
```

---

## 6) ربط زر bookmark (Best Practice)

- عند الضغط:
  - عطّل الزر (`isLoading`).
  - نفّذ `addToWishlist(courseId)`.
  - عند النجاح: غيّر `isBookmarked = true`.
  - عند الفشل: اعرض toast/snackbar بالخطأ.
- عند فتح الشاشة:
  - حمّل wishlist (`GET /wishlist`) وحدد `isBookmarked` لكل كورس.
- عند الإزالة:
  - استدع `DELETE /wishlist/{courseId}` ثم حدث الحالة إلى `false`.

---

## 7) مراجع الكود في المشروع

- `backend/src/modules/mobile/mobile.routes.js`
- `backend/src/modules/mobile/mobile.controller.js`
- `backend/src/modules/mobile/mobile.service.js`
- `app/api/wishlist/route.ts`
- `app/api/wishlist/[courseId]/route.ts`
- `lib/api.ts` (`mobileApi.addToWishlist`)

---

**Version:** 1.0  
**Date:** 2026-05-04
