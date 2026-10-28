# Wishlist Endpoints Update (Flutter)

## هل تم تغيير الـ endpoints؟

لا، **الـ endpoints لم تتغير**.  
الذي تغيّر هو **المنطق الداخلي في الـ backend** فقط (تم تفعيل التخزين الفعلي بدل placeholder).

---

## المسارات المعتمدة (كما هي)

| العملية | Method | Path |
|--------|--------|------|
| جلب قائمة الرغبات | `GET` | `/wishlist` |
| إضافة كورس للرغبات | `POST` | `/wishlist` |
| إزالة كورس من الرغبات | `DELETE` | `/wishlist/{courseId}` |

تقدر تستخدمها عبر:

- `https://elsherifacademy.anmka.com/api/...`
- أو `https://elsherifacademy.anmka.com/v1/...`

---

## Auth (مطلوب)

```http
Authorization: Bearer <access_token>
Content-Type: application/json
Accept: application/json
```

---

## 1) Add to wishlist

### Request

```http
POST /api/wishlist
```

```json
{
  "course_id": "39bc3972-6198-4744-b241-937770dc750e"
}
```

> مهم: اسم الحقل في البودي هو `course_id` (snake_case).

### Success response (expected)

```json
{
  "success": true,
  "message": "تمت الإضافة إلى قائمة الرغبات",
  "data": {
    "success": true,
    "wishlist_id": "uuid",
    "user_id": "uuid",
    "course_id": "uuid",
    "created_at": "2026-05-04T..."
  }
}
```

---

## 2) Get wishlist

### Request

```http
GET /api/wishlist
```

### Success response (expected)

```json
{
  "success": true,
  "data": [
    {
      "id": "course-id",
      "title": "Course title",
      "thumbnail": "https://...",
      "is_wishlisted": true,
      "wishlist_id": "wishlist-id",
      "wishlisted_at": "2026-05-04T..."
    }
  ]
}
```

---

## 3) Remove from wishlist

### Request

```http
DELETE /api/wishlist/{courseId}
```

### Success response (expected)

```json
{
  "success": true,
  "message": "تمت الإزالة من قائمة الرغبات",
  "data": {
    "success": true,
    "course_id": "uuid",
    "removed": true
  }
}
```

---

## Flutter handling recommendation

بسبب هيكل الاستجابة الحالي، افحص مستويين:

1. `response.success == true`
2. وإذا `response.data.success` موجودة، لازم تكون `!= false`

مثال:

```dart
final okTop = body['success'] == true;
final data = body['data'];
final okData = data is Map<String, dynamic> ? (data['success'] != false) : true;
final isSuccess = okTop && okData;
```

---

## ملاحظة تشغيل مهمة

الكود تم تحديثه، لكن لازم جدول `wishlists` يكون موجود في قاعدة البيانات (Prisma update).  
لو لم يتم تطبيق تحديث DB في البيئة، endpoints ستفشل runtime.

---

**Version:** 1.0  
**Date:** 2026-05-04
