# Privacy Policy & Terms — Website Content Spec

**Audience:** Website / Backend team  
**App:** Bouslty (Flutter)  
**Date:** 2026-09-06  
**Version:** 1.0

Mobile opens these pages in the browser:

| Page | Suggested URL | Opened from |
|------|---------------|-------------|
| Privacy Policy | `https://bouslty.anmka.com/privacy` | Register → «الشروط والأحكام» link · Settings → Privacy & Security |
| Terms of Use | `https://bouslty.anmka.com/terms` | Landing footer / `legal.terms_url` (optional) |

**Config API:** `GET /api/config/app` → `data.legal.privacy_url` and `data.legal.terms_url`  
If empty, the app falls back to the URLs above.

---

## Scope rules (must follow)

Publish **only** what is below. Do **not** include:

- Payment methods, bank transfer, checkout, invoices, wallets, or pricing
- Google Sign-In / Apple Sign-In / social login
- Third-party auth providers
- In-app purchases or store billing

Keep language educational-platform only: account, profile, courses, progress, notifications, support, account deletion.

---

## Backend / config checklist

1. Host public HTML (or CMS) pages at `/privacy` and `/terms` (Arabic primary; English optional on same page or `/en/...`).
2. Set in app config:

```json
{
  "legal": {
    "privacy_url": "https://bouslty.anmka.com/privacy",
    "terms_url": "https://bouslty.anmka.com/terms"
  }
}
```

3. Pages must be reachable **without login** (Play Store / App Store reviewers open them).
4. Use HTTPS, mobile-friendly layout, clear last-updated date.
5. Contact email/phone on the page should match support contacts used in the app.

---

## Page layout (both pages)

- Brand name: **Bouslty**
- Title (H1)
- «آخر تحديث» / Last updated: `YYYY-MM-DD`
- Short intro paragraph
- Numbered sections
- Contact block at the bottom
- RTL for Arabic; LTR if English version is separate

---

# 1) Privacy Policy — full copy

Use this as the body of `/privacy`.

### Arabic (primary)

**العنوان:** سياسة الخصوصية — Bouslty

**آخر تحديث:** 2026-09-06

مرحباً بك في منصة **Bouslty**. توضح هذه السياسة كيف نجمع بياناتك الشخصية ونستخدمها ونحميها عند استخدام تطبيقنا وخدماتنا التعليمية. باستخدامك للمنصة، فإنك توافق على ما ورد في هذه السياسة.

#### 1. من نحن
Bouslty منصة تعليمية تقدّم محتوى ودورات ومواد تعليمية للمستخدمين. يمكن التواصل معنا عبر بيانات الدعم الموضّحة في نهاية هذه الصفحة.

#### 2. البيانات التي نجمعها
قد نجمع أنواعاً من البيانات مثل:
- **بيانات الحساب:** الاسم، رقم الهاتف، والبريد الإلكتروني إن قدّمته.
- **بيانات الملف الشخصي:** صورة الملف الشخصي (إن رُفعت)، ونوع الحساب (مثل طالب أو معلّم) بحسب إعدادات المنصة.
- **بيانات الاستخدام التعليمي:** الدورات المسجّل بها، التقدّم في الدروس، نتائج الاختبارات إن وُجدت، والشهادات إن وُجدت.
- **بيانات الجهاز والإشعارات:** معرّف الجهاز ومعلومات تقنية لازمة لتشغيل التطبيق وإرسال الإشعارات عند تفعيلها.
- **بيانات التواصل:** الرسائل أو الاستفسارات التي ترسلها لفريق الدعم أو عبر المحادثة داخل التطبيق إن وُجدت.

لا نطلب منك بيانات غير لازمة لتشغيل الخدمة التعليمية.

#### 3. كيف نستخدم البيانات
نستخدم بياناتك من أجل:
- إنشاء حسابك وإدارته وتأمين الدخول.
- تقديم المحتوى التعليمي ومتابعة التقدّم.
- إرسال إشعارات متعلقة بالحساب أو المحتوى (عند موافقتك/تفعيل الإشعارات).
- تحسين تجربة الاستخدام وإصلاح الأعطال.
- الرد على طلبات الدعم.
- الالتزام بالمتطلبات القانونية المعمول بها.

#### 4. أساس المعالجة والموافقة
نعالج بياناتك بناءً على تنفيذ الخدمة التي طلبتها (إنشاء الحساب واستخدام المنصة التعليمية)، وبناءً على موافقتك حيث يلزم (مثل الإشعارات أو رفع صورة شخصية)، وبما يقتضيه القانون.

#### 5. مشاركة البيانات
لا نبيع بياناتك الشخصية. قد نشارك بيانات محدودة فقط مع:
- مزوّدي خدمات تقنية يساعدوننا في تشغيل التطبيق والاستضافة والإشعارات، ضمن حدود لازمة للتشغيل.
- جهات مختصة إذا ألزمنا القانون بذلك.

يُطلب من أي طرف يعالج البيانات نيابةً عنا الالتزام بسرية البيانات وحمايتها.

#### 6. التخزين والحماية
نطبّق إجراءات تقنية وتنظيمية مناسبة لحماية بياناتك من الوصول غير المصرّح به أو الفقد أو التعديل. ومع ذلك، لا توجد وسيلة نقل أو تخزين إلكتروني آمنة بنسبة 100%، ونسعى دائماً لتحسين مستوى الحماية.

#### 7. مدة الاحتفاظ
نحتفظ ببياناتك طالما كان حسابك نشطاً، أو للمدة اللازمة لتقديم الخدمة والوفاء بالالتزامات القانونية. عند حذف الحساب، نحذف أو نُ مجهّل البيانات الشخصية وفق سياساتنا والإجراءات الداخلية، مع إمكانية الإبقاء على سجلات تقنية مجهّلة عند الحاجة للتشغيل أو الامتثال.

#### 8. حقوقك
بحسب الأنظمة المعمول بها، يمكنك:
- طلب الاطلاع على بياناتك الشخصية.
- طلب تصحيح بيانات غير دقيقة.
- طلب حذف الحساب والبيانات المرتبطة به عبر خاصية حذف الحساب داخل التطبيق أو بالتواصل مع الدعم.
- إيقاف الإشعارات من إعدادات الجهاز أو التطبيق.

للممارسة، تواصل معنا عبر قنوات الدعم أدناه.

#### 9. حسابات القُصّر
المنصة موجّهة للاستخدام التعليمي. إذا كنت ولي أمر وتعتقد أن قاصراً قدّم بيانات دون موافقة مناسبة، يرجى التواصل معنا لنراجع الطلب ونحذف البيانات عند اللزوم.

#### 10. الروابط الخارجية
قد يحتوي التطبيق أو الموقع على روابط لمواقع أو خدمات خارجية. لسنا مسؤولين عن ممارسات الخصوصية لتلك الأطراف. ننصح بقراءة سياساتهم قبل استخدامها.

#### 11. تحديث السياسة
قد نحدّث هذه السياسة من وقت لآخر. سننشر النسخة المحدَّثة على هذه الصفحة مع تاريخ «آخر تحديث». استمرارك في استخدام المنصة بعد التحديث يعني اطّلاعك على التغييرات الجوهرية المنشورة هنا.

#### 12. التواصل
للاستفسارات المتعلقة بالخصوصية أو طلبات البيانات:
- البريد / الهاتف: بحسب بيانات الدعم المعتمدة في التطبيق و`GET /api/config/app` → `support`
- أو عبر شاشة «المساعدة والدعم» داخل التطبيق

---

### English (optional secondary)

**Title:** Privacy Policy — Bouslty  

**Last updated:** 2026-09-06

Welcome to **Bouslty**. This policy explains how we collect, use, and protect personal data when you use our educational app and services. By using the platform, you agree to this policy.

#### 1. Who we are
Bouslty is an educational platform that provides courses and learning materials. Contact details are listed at the end of this page.

#### 2. Data we collect
We may collect:
- **Account data:** name, phone number, and email if you provide it.
- **Profile data:** profile photo (if uploaded) and account type (e.g. student or instructor) as configured on the platform.
- **Learning activity:** enrollments, lesson progress, exam results (if any), and certificates (if any).
- **Device & notifications:** device identifiers and technical data needed to run the app and deliver notifications when enabled.
- **Support communications:** messages you send to support or in-app chat if available.

We do not ask for data that is unnecessary to operate the educational service.

#### 3. How we use data
We use your data to:
- Create and manage your account and secure access.
- Deliver educational content and track progress.
- Send account- or content-related notifications (when enabled).
- Improve the product and fix issues.
- Respond to support requests.
- Comply with applicable law.

#### 4. Legal basis
We process data to provide the service you requested, based on your consent where required (e.g. notifications or profile photo), and where required by law.

#### 5. Sharing
We do not sell your personal data. We may share limited data only with:
- Technical service providers that help host and operate the app and notifications, strictly as needed.
- Authorities when required by law.

Processors acting on our behalf must protect confidentiality.

#### 6. Security
We apply appropriate technical and organizational measures. No method of transmission or storage is 100% secure; we work to improve protection continuously.

#### 7. Retention
We keep data while your account is active or as needed to provide the service and meet legal duties. After account deletion, we delete or anonymize personal data according to our internal process, and may keep anonymized technical logs when needed for operations or compliance.

#### 8. Your rights
Subject to applicable law, you may:
- Access your personal data.
- Request correction of inaccurate data.
- Request account and related data deletion via in-app delete account or by contacting support.
- Disable notifications in device or app settings.

Contact us using the channels below.

#### 9. Minors
The platform is intended for educational use. If you are a parent/guardian and believe a minor provided data without appropriate consent, contact us so we can review and delete data when appropriate.

#### 10. External links
The app or site may link to third-party sites. We are not responsible for their privacy practices.

#### 11. Changes
We may update this policy and will post the new version here with an updated date. Continued use after changes means you have had the opportunity to review the published updates.

#### 12. Contact
For privacy questions or data requests, use the support contacts configured for the app (`GET /api/config/app` → `support`) or the in-app Help & Support screen.

---

# 2) Terms of Use — full copy

Use this as the body of `/terms`. Keep aligned with Privacy (no payments, no social login).

### Arabic (primary)

**العنوان:** الشروط والأحكام — Bouslty

**آخر تحديث:** 2026-09-06

باستخدامك لتطبيق أو موقع **Bouslty**، فإنك توافق على هذه الشروط. إذا لم توافق، يرجى عدم استخدام المنصة.

#### 1. وصف الخدمة
Bouslty منصة تعليمية تقدّم دورات ومحتوى تعليمياً ومواد مرتبطة بالحساب (مثل التقدّم والاختبارات إن وُجدت). قد تختلف الميزات حسب نوع الحساب وصلاحيات الإدارة.

#### 2. إنشاء الحساب
- يجب تقديم معلومات صحيحة (مثل الاسم ورقم الهاتف) والحفاظ على سرية كلمة المرور.
- أنت مسؤول عن النشاط الذي يتم عبر حسابك.
- نحتفظ بحق تعليق أو إيقاف الحساب عند مخالفة هذه الشروط أو إساءة استخدام المنصة.

#### 3. الاستخدام المقبول
تتعهّد بأن:
- تستخدم المنصة لأغراض تعليمية مشروعة فقط.
- لا تحاول اختراق النظام أو تعطيله أو استخراج المحتوى بطريقة غير مصرّح بها.
- لا تنشر محتوى مسيئاً أو غير قانوني عبر أي قناة تواصل داخل المنصة.
- لا تشارك بيانات الدخول مع الآخرين.

#### 4. المحتوى التعليمي
- المحتوى المقدَّم عبر المنصة محمي بحقوق الملكية الفكرية الخاصة بـ Bouslty أو المرخّصين لها.
- يُسمح لك بالوصول للمحتوى للاستخدام الشخصي التعليمي وفق الصلاحيات الممنوحة لحسابك.
- لا يجوز نسخ المحتوى أو إعادة توزيعه أو بيعه أو نشره علناً دون إذن كتابي مسبق.

#### 5. الحساب وحذف الحساب
يمكنك طلب حذف حسابك من داخل التطبيق عند توفر الخاصية، أو عبر التواصل مع الدعم. بعد الحذف، يتوقف الوصول للحساب، وتُعالَج البيانات وفق **سياسة الخصوصية**.

#### 6. إخلاء المسؤولية
نقدّم المنصة «كما هي» في حدود ما يسمح به القانون. لا نضمن عدم انقطاع الخدمة أو خلوّها من الأخطاء في كل الأوقات، ونسعى لإصلاح المشكلات خلال وقت معقول.

#### 7. التعديلات
قد نعدّل هذه الشروط أو نحدّث الميزات. تُنشر النسخة المحدَّثة على هذه الصفحة مع تاريخ التحديث. استمرار الاستخدام بعد النشر يعني قبول الشروط المحدَّثة.

#### 8. القانون الواجب التطبيق
تخضع هذه الشروط للقوانين المعمول بها في جمهورية مصر العربية، ما لم تقتضِ قواعد آمرة خلاف ذلك.

#### 9. التواصل
للاستفسارات حول الشروط: استخدم قنوات الدعم داخل التطبيق أو بيانات الدعم المعتمدة للمنصة.

---

### English (optional secondary)

**Title:** Terms of Use — Bouslty  

**Last updated:** 2026-09-06

By using the **Bouslty** app or website, you agree to these terms. If you do not agree, do not use the platform.

#### 1. Service
Bouslty is an educational platform offering courses and learning-related account features (such as progress and exams where available). Features may vary by account type.

#### 2. Accounts
- Provide accurate information (e.g. name and phone) and keep your password confidential.
- You are responsible for activity under your account.
- We may suspend or terminate accounts that violate these terms or misuse the platform.

#### 3. Acceptable use
You agree to:
- Use the platform only for lawful educational purposes.
- Not attempt to breach, disrupt, or scrape the service without authorization.
- Not post abusive or illegal content via any in-app communication channel.
- Not share login credentials with others.

#### 4. Educational content
- Content is protected by intellectual property rights owned by Bouslty or its licensors.
- You may access content for personal educational use under your account permissions.
- You may not copy, redistribute, sell, or publicly republish content without prior written permission.

#### 5. Account deletion
You may delete your account in-app when the feature is available, or by contacting support. After deletion, access ends and data is handled per the **Privacy Policy**.

#### 6. Disclaimer
The service is provided “as is” to the extent permitted by law. We do not guarantee uninterrupted or error-free operation at all times and will work to resolve issues within a reasonable time.

#### 7. Changes
We may update these terms. The updated version will be posted here with a new date. Continued use after posting means acceptance of the updated terms.

#### 8. Governing law
These terms are governed by the laws of the Arab Republic of Egypt, unless mandatory rules require otherwise.

#### 9. Contact
For questions about these terms, use in-app support or the platform’s published support contacts.

---

## Mobile wiring (already implemented)

| Location | Action |
|----------|--------|
| `register_screen.dart` | «الشروط والأحكام» opens **Privacy** URL |
| `settings_screen.dart` | Privacy & Security card opens **Privacy** URL |
| `lib/core/legal/legal_urls.dart` | Resolves URL from config + fallbacks |

---

## QA for website team

- [ ] `https://bouslty.anmka.com/privacy` loads on mobile browser without login
- [ ] `https://bouslty.anmka.com/terms` loads without login
- [ ] No mention of payments, billing, Google login, or Apple login
- [ ] Arabic readable (RTL), last-updated date visible
- [ ] Support contact present
- [ ] `legal.privacy_url` / `legal.terms_url` in `GET /api/config/app` point to the live pages
- [ ] Opening from app Register + Settings lands on Privacy page
