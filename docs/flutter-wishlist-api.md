# Wishlist API — Flutter (قائمة الرغبات / الكورسات)

توثيق مسارات **قائمة الرغبات** للتطبيق. في النظام الحالي العنصر هو **كورس** (`course`) وليس كتاباً منفصلاً؛ مسار الحذف يزيل الكورس من القائمة.

## Base URL

| البيئة | المسار |
|--------|--------|
| Backend مباشرة | `{BACKEND_URL}/api/...` أو `{BACKEND_URL}/v1/...` |
| عبر نفس دومين الويب (Next proxy) | `https://<your-domain>/api/...` |

الخادم يركّب نفس الـ router على **`/api`** و **`/v1`** — اختر واحداً وثبّته في التطبيق.

## المصادقة (مطلوبة)

كل المسارات أدناه تتطلب مستخدماً مسجّلاً:

```http
Authorization: Bearer <access_token>
```

التوكن نفسه الناتج عن `POST /api/auth/login` أو `POST /api/auth/register` (حقل `data.accessToken` في الاستجابة الناجحة).

---

## 1) جلب قائمة الرغبات (عرض كل العناصر)

**الغرض:** استرجاع كل الكورسات المحفوظة في قائمة رغبات المستخدم (مثل «جلب الكتب/الكورسات من المفضلة»).

| العنصر | القيمة |
|--------|--------|
| Method | `GET` |
| Path | `/wishlist` |
| Full URL (مثال) | `GET {BASE}/api/wishlist` |

**Headers**

- `Authorization: Bearer <token>`
- `Content-Type: application/json` (اختياري لـ GET)

**Body:** لا يوجد.

**استجابة ناجحة (200)**

نفس شكل بقية الـ API:

```json
{
  "success": true,
  "data": []
}
```

- **`data`:** مصفوفة كائنات كورس (بعد تفعيل التخزين في الـ backend). حالياً قد تكون **`[]`** فارغة لأن منطق قائمة الرغبات في الخادم ما زال placeholder (انظر قسم «الوضع الحالي» أدناه).

---

## 2) إزالة كورس من قائمة الرغبات (حذف من المفضلة)

**الغرض:** إزالة كورس واحد من القائمة باستخدام **معرف الكورس**.

| العنصر | القيمة |
|--------|--------|
| Method | `DELETE` |
| Path | `/wishlist/{courseId}` |
| Full URL (مثال) | `DELETE {BASE}/api/wishlist/550e8400-e29b-41d4-a716-446655440000` |

**Path parameter**

| الاسم | النوع | الوصف |
|--------|--------|--------|
| `courseId` | `string` (UUID) | معرف الكورس كما في `GET /courses` أو تفاصيل الكورس |

**Headers**

- `Authorization: Bearer <token>`

**Body:** لا يوجد.

**استجابة ناجحة (200)** — شكل عام:

```json
{
  "success": true,
  "message": "تمت الإزالة من قائمة الرغبات",
  "data": { }
}
```

شكل **`data`** يعتمد على تنفيذ الخادم بعد ربط قاعدة البيانات.

---

## 3) إضافة كورس إلى قائمة الرغبات (مرجع)

| العنصر | القيمة |
|--------|--------|
| Method | `POST` |
| Path | `/wishlist` |

**Body (JSON)**

```json
{
  "course_id": "<uuid-الكورس>"
}
```

**ملاحظة:** اسم الحقل في الطلب هو **`course_id`** (snake_case) كما يقرأه الـ controller من `req.body`.

**Headers**

- `Authorization: Bearer <token>`
- `Content-Type: application/json`

---

## أخطاء شائعة

| HTTP | المعنى المعتاد |
|------|----------------|
| `401` | توكن مفقود أو منتهٍ أو غير صالح |
| `404` | مسار غير موجود (تحقق من `/api` vs `/v1` والـ `courseId`) |
| `429` | تجاوز حد الطلبات (rate limit على `/api/` و `/v1/`) |

رسائل التحقق أو التعارض (مثلاً كورس غير موجود) تعتمد على تنفيذ `mobile.service` بعد إكمال الميزة.

---

## مثال Dart (http)

```dart
import 'dart:convert';
import 'package:http/http.dart' as http;

class WishlistApi {
  WishlistApi({required this.baseUrl, required this.accessToken});

  final String baseUrl; // e.g. https://elsherifacademy.anmka.com/api
  final String accessToken;

  Map<String, String> get _headers => {
        'Authorization': 'Bearer $accessToken',
        'Content-Type': 'application/json',
      };

  /// GET wishlist — list of courses
  Future<Map<String, dynamic>> getWishlist() async {
    final res = await http.get(
      Uri.parse('$baseUrl/wishlist'),
      headers: _headers,
    );
    return _decode(res);
  }

  /// DELETE — remove one course from wishlist
  Future<Map<String, dynamic>> removeFromWishlist(String courseId) async {
    final res = await http.delete(
      Uri.parse('$baseUrl/wishlist/$courseId'),
      headers: _headers,
    );
    return _decode(res);
  }

  /// POST — add course (body: course_id)
  Future<Map<String, dynamic>> addToWishlist(String courseId) async {
    final res = await http.post(
      Uri.parse('$baseUrl/wishlist'),
      headers: _headers,
      body: jsonEncode({'course_id': courseId}),
    );
    return _decode(res);
  }

  Map<String, dynamic> _decode(http.Response res) {
    final body = jsonDecode(res.body) as Map<String, dynamic>;
    if (res.statusCode >= 200 && res.statusCode < 300) {
      return body;
    }
    throw Exception(body['message'] ?? 'Request failed ${res.statusCode}');
  }
}
```

---

## الوضع الحالي في المستودع (تنبيه للمطورين)

في `backend/src/modules/mobile/mobile.service.js` دوال **`getWishlist` / `addToWishlist` / `removeFromWishlist`** ما زالت **placeholder** (تعليق TODO: لا يوجد نموذج Wishlist في Prisma بعد). لذلك:

- **GET** قد يعيد **`data: []`** دائماً.
- **POST / DELETE** قد يعيدان في **`data`** كائنات توضح أن الميزة غير متاحة حتى يُنفَّذ التخزين في قاعدة البيانات.

بعد إضافة جدول/علاقة قائمة الرغبات وربط الخدمة، تبقى عقود الـ **URL** و**المصادقة** و**`course_id` في POST** كما هي أعلاه — يحدّث المطور حقل **`data`** فقط في التوثيق إذا تغيّر شكل الكورس المُعاد.

---

## مراجع في الكود

| الملف | الفائدة |
|--------|---------|
| `backend/src/modules/mobile/mobile.routes.js` | تعريف المسارات |
| `backend/src/modules/mobile/mobile.controller.js` | `getWishlist`, `addToWishlist`, `removeFromWishlist` |
| `backend/src/modules/mobile/mobile.service.js` | منطق البيانات (حالياً placeholder) |
| `lib/api.ts` (ويب) | `getWishlist`, `addToWishlist`, `removeFromWishlist` — نفس المسارات النسبية |

---

**نسخة المستند:** 1.0  
**التاريخ:** 2026-05-04
