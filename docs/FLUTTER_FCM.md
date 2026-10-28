# إشعارات الدفع (FCM) — تكامل Flutter مع Anmka LMS

**مسار الملف:** `public_html/FLUTTER_FCM.md` — انسخه أو أرسله لفريق Flutter.

## الملخص

1. أضف تطبيق Flutter إلى مشروع **Firebase** وفعّل **Cloud Messaging**.
2. احصل على **`fcm_token`** من Firebase وأرسله مع **`POST /api/auth/register`** أو **`POST /api/auth/login`** (أو لاحقاً عبر `POST /api/device/fcm-token` إن رغبت).
3. السيرفر يرسل **إشعاراً فورياً (Push)** + **إشعاراً داخل التطبيق** (يظهر في `GET /notifications`) في الحالتين:
   - **إضافة الطالب للدورة يدوياً** من لوحة التحكم.
   - **الموافقة على طلب اشتراك** الطالب في الدورة.

---

## الأمان (مهم)

- **لا تُضمّن** ملف مفتاح الخدمة (Service Account JSON) داخل التطبيق أو داخل الريبو.
- عُدْ إنشاء المفتاح في [Google Cloud Console](https://console.cloud.google.com/) إذا سُرّب في محادثة أو مستودع عام، واحذف المفتاح القديم.
- على السيرفر فقط: ضع الاعتماد عبر متغير بيئة أو مسار ملف آمن (انظر «إعداد السيرفر»).

---

## التسجيل وتسجيل الدخول (يُفضَّل)

يمكن إرسال **`fcm_token`** في نفس جسم الطلب عند **إنشاء حساب** أو **تسجيل الدخول** — يُحفظ الرمز تلقائياً دون طلب إضافي.

| المسار | المصادقة |
|--------|----------|
| `POST /api/auth/register` أو `/v1/auth/register` | لا (حساب جديد) |
| `POST /api/auth/login` أو `/v1/auth/login` | لا (بريد/هاتف + كلمة المرور) |
| `POST /api/auth/social-login` | لا | 

**حقول اختيارية في الـ JSON:**

```json
{
  "email": "…",
  "password": "…",
  "fcm_token": "<من FirebaseMessaging.instance.getToken()>",
  "platform": "android"
}
```

- **`fcm_token`** أو **`fcmToken`** — نفس المعنى.
- **`platform`**: `android` | `ios` | `web` — أو داخل كائن: `"device": { "platform": "ios" }`.

إذا لم يُرسل الرمز أو كان قصيراً جداً، يُكمَل التسجيل/الدخول بشكل طبيعي (لا يُرفض الطلب).

---

## مسار تسجيل الرمز فقط (Backend)

**القاعدة:** `{BASE_URL}` = عنوان الـ API (مثال: `https://elsherifacademy.anmka.com`).

| العنصر | القيمة |
|--------|--------|
| **الطريقة** | `POST` |
| **المسار** | `/api/device/fcm-token` أو `/v1/device/fcm-token` |
| **المصادقة** | `Authorization: Bearer <access_token>` (نفس توكن الجلسة بعد تسجيل الدخول) |

**الجسم (JSON):**

```json
{
  "fcm_token": "<string من Firebase>",
  "platform": "android"
}
```

- **`fcm_token`** (مطلوب): الرمز الذي يعيده Firebase للجهاز.
- **`platform`** (اختياري): أحد `android` | `ios` | `web`.

**استجابة ناجحة (مثال):**

```json
{
  "success": true,
  "data": { "success": true },
  "message": "تم حفظ رمز الإشعارات"
}
```

**متى تُرسل الطلب؟**

- بعد **نجاح تسجيل الدخول** ووجود `access_token`.
- بعد **تحديث الرمز** (`onTokenRefresh` في Firebase Messaging).
- يُفضَّل إعادة الإرسال عند كل تشغيل للتطبيق إذا تغيّر الرمز.

---

## إعداد Flutter (مختصر)

### 1) إضافة الحزم

في `pubspec.yaml`:

```yaml
dependencies:
  firebase_core: ^3.0.0
  firebase_messaging: ^15.0.0
```

ثم ربط المشروع بـ Firebase (`flutterfire configure`) ووضع `google-services.json` (Android) و`GoogleService-Info.plist` (iOS).

### 2) تهيئة Firebase

```dart
await Firebase.initializeApp();
```

### 3) طلب صلاحيات الإشعارات (Android 13+ / iOS)

استخدم `firebase_messaging` + `permission_handler` أو واجهات النظام المناسبة حسب المنصة.

### 4) الحصول على الرمز وإرساله للسيرفر

```dart
final messaging = FirebaseMessaging.instance;
String? token = await messaging.getToken();
// ثم POST إلى /api/device/fcm-token مع Bearer token

messaging.onTokenRefresh.listen((newToken) {
  // أعد إرسال newToken للسيرفر
});
```

### 5) استقبال الرسائل

- **Foreground:** `FirebaseMessaging.onMessage.listen(...)`
- **Background:** معالج top-level `firebaseMessagingBackgroundHandler` مسجَّل عبر `FirebaseMessaging.onBackgroundMessage`
- **فتح التطبيق من إشعار:** `getInitialMessage()` / `onMessageOpenedApp`

استخدم حقل **`data`** القادم من السيرفر للتوجيه (انظر أدناه).

---

## ما يرسله السيرفر في `data` (للتوجيه داخل التطبيق)

| `type` | المعنى |
|--------|--------|
| `course_enrolled` | أُضيف الطالب للدورة يدوياً |
| `enrollment_approved` | وُافق على طلب الاشتراك |

حقول إضافية (كل القيم **نصوص**):

- `course_id`: معرف الدورة
- `title` / `body`: نص الإشعار

مثال `data`:

```json
{
  "type": "enrollment_approved",
  "course_id": "uuid-الدورة",
  "title": "تم قبول طلب الاشتراك",
  "body": "تم قبول طلب اشتراكك في: ..."
}
```

حقل **`deep_link`** في الإشعار داخل التطبيق (قائمة الإشعارات) يكون بالشكل `course:<course_id>` لاستخدامه في التنقل إن رغبت.

---

## إعداد السيرفر (للمسؤول عن الاستضافة فقط)

اختر أحد الخيارين:

1. **`FIREBASE_SERVICE_ACCOUNT_JSON`** — محتوى JSON الكامل لمفتاح الخدمة كسلسلة نصية في متغير البيئة (مناسب في Docker / لوحات التحكم؛ تجنّب اللصق في الشات).
2. **`GOOGLE_APPLICATION_CREDENTIALS`** — مسار ملف JSON على الخادم (قراءة فقط من السيرفر).

بدون أحد هذين المتغيرين، يستمر النظام في إنشاء **إشعارات داخل التطبيق** فقط، دون **Push** عبر FCM.

---

## ملاحظات

- جهاز واحد قد يملك رمز FCM واحداً؛ إذا سجّل الطالب من جهازين، يُخزَّن أكثر من صف (حتى يُزال الرمز غير الصالح تلقائياً عند فشل الإرسال).
- الإشعارات المرتبطة بالدفع لا تحل محل شاشة الإشعارات داخل التطبيق؛ كلاهما يُستخدمان معاً لأفضل تجربة.
