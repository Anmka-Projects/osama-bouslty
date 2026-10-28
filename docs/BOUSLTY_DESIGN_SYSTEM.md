# Bouslty Design System — مواصفة الألوان والستايل للداشبورد

الملف ده مستخرج مباشرة من كود التطبيق (`lib/core/design/`) عشان الداشبورد/الويب يطلع بنفس شكل التطبيق. كل القيم نفس tokens المستخدمة فعليًا — مفيش اختراع.

> المصدر الأصلي: Bouslty Brand Kit v1 (`06-For-Developers/tokens.json`) — التطبيق نفسه كان مبني على React/Tailwind، فالقيم بتترجم لـ CSS 1:1.

---

## 1) ألوان البراند الأساسية (Brand Palette)

| Token | Hex | الاستخدام |
|---|---|---|
| `brandDeepTeal` | `#083B41` | اللون الرئيسي الغامق — هيدرات، خلفيات براند |
| `brandTeal` | `#0E6E75` | Primary — أزرار، لينكات، أيقونات |
| `brandSaffron` | `#F2A922` | Accent/Secondary — badges، تقييم، عناصر نشطة |
| `brandSand` | `#FBF8F2` | خلفية الصفحات (Light) |
| `brandSandDeep` | `#E5DCCB` | حدود وخطوط فاصلة (Light) |
| `brandInk` | `#0D2A2E` | النص الرئيسي (Light) |
| `brandWhite` | `#FFFFFF` | أسطح مرفوعة + نص على البراند |

---

## 2) Light Theme Tokens

| Token | Hex | الاستخدام |
|---|---|---|
| `background` / `surface` | `#FBF8F2` | خلفية الصفحة |
| `surfaceRaised` / `card` | `#FFFFFF` | كروت، مودالز، inputs |
| `surfaceSunken` / `muted` | `#F3EDE2` | خلفيات غارقة، hover neutral |
| `surfaceBrand` | `#083B41` | أسطح براند (sidebar/header) |
| `scrim` | `#052A2E` @ 56% | Overlay خلف المودال |
| `line` / `border` | `#E5DCCB` | حدود خفيفة |
| `lineStrong` | `#7B8B89` | حدود أقوى |
| `ink` / `foreground` | `#0D2A2E` | نص أساسي |
| `inkMuted` | `#4A6063` | نص ثانوي |
| `inkSubtle` | `#5F7376` | نص خافت / أيقونات غير نشطة |
| `primary` | `#0E6E75` | الأزرار الرئيسية |
| `primaryForeground` | `#FFFFFF` | نص على الـ primary |
| `primarySoft` | `#E1F0EF` | خلفية ناعمة للـ primary (chips, selected bg) |
| `primaryHover` | `#0B5960` | hover للـ primary |
| `secondary` / `accent` | `#F2A922` | العنصر الذهبي |
| `accentHover` | `#DB9013` | hover للذهبي |
| `accentSoft` | `#FDF1D6` | خلفية ناعمة للذهبي |
| `accentInk` / `accentText` | `#865407` | نص ذهبي على خلفية فاتحة |
| `accentForeground` | `#083B41` | **نص على خلفية ذهبية — دايمًا teal غامق مش أبيض** |
| `secondaryMuted` | `#F2A922` @ 10% | tint خفيف |
| `ring` | `#0E6E75` | Focus ring |
| `input` | `#FFFFFF` | خلفية الحقول |
| `destructive` | `#B4372B` | حذف/خطر |
| `success` | `#1D7650` | نجاح |
| `warning` | `#8F5600` | تحذير |
| `info` | `#2A62A3` | معلومات |
| `successSoft` | `#E1F2E9` | خلفية ناعمة نجاح |
| `warningSoft` | `#FDF0D6` | خلفية ناعمة تحذير |
| `dangerSoft` | `#FBE5E1` | خلفية ناعمة خطر |
| `infoSoft` | `#E5EEF8` | خلفية ناعمة معلومات |
| `shadow` | `#083B41` @ 12% | لون الظل العام |
| `bottomNavActive` | `#F2A922` | العنصر النشط في الـ nav |
| `bottomNavInactive` | `#5F7376` | العناصر غير النشطة |
| `iconPrimary` | `#0E6E75` | لون الأيقونات الافتراضي |

## 3) Dark Theme Tokens

| Token | Hex | الاستخدام |
|---|---|---|
| `darkSurface` | `#06262A` | خلفية الصفحة |
| `darkSurfaceRaised` | `#0B3237` | كروت وحقول |
| `darkSurfaceSunken` | `#041D20` | خلفيات غارقة |
| `darkSurfaceBrand` | `#11545C` | أسطح براند |
| `darkScrim` | `#000000` @ 60% | Overlay |
| `darkLine` | `#1C4B51` | حدود |
| `darkLineStrong` | `#5E8F93` | حدود أقوى |
| `darkInk` | `#F2EEE6` | نص أساسي |
| `darkInkMuted` | `#A9C0C0` | نص ثانوي |
| `darkInkSubtle` | `#8AA6A7` | نص خافت |
| `darkPrimary` | `#5CC7C1` | الـ primary في الدارك (teal أفتح) |
| `darkPrimaryHover` | `#86D7D2` | hover |
| `darkOnPrimary` | `#052A2E` | نص على الـ primary |
| `darkPrimarySoft` | `#0F3E43` | خلفية ناعمة |
| `darkAccentHover` | `#F7C056` | ذهبي أفتح في الدارك |
| `darkAccentSoft` | `#352A0F` | خلفية ذهبية ناعمة |
| `darkAccentInk` | `#F7C056` | نص ذهبي |
| `darkSuccess` / `Soft` | `#62CC9C` / `#0E3527` | نجاح |
| `darkWarning` / `Soft` | `#F2B54A` / `#382910` | تحذير |
| `darkDanger` / `Soft` | `#F2907F` / `#43201B` | خطر |
| `darkInfo` / `Soft` | `#8AB9EE` / `#132C45` | معلومات |

> ملحوظة زرار الـ ElevatedButton في الدارك: خلفيته **saffron** `#F2A922` ونصه **deep teal** `#083B41` — مش teal. ده قصدي من البراند.

## 4) ألوان المراحل الدراسية (Stage Colors)

| Stage | Light | Light Soft | Dark | Dark Soft |
|---|---|---|---|---|
| Primary (ابتدائي) | `#2B67A8` | `#E5EFF9` | `#8FBEF0` | `#14304B` |
| Intermediate (إعدادي) | `#1B7258` | `#E1F2EA` | `#6CCFA8` | `#10372B` |
| Secondary (ثانوي) | `#AE4128` | `#FBE8E1` | `#F39C85` | `#432319` |
| University (جامعة) | `#664AAA` | `#EEEAF8` | `#BBA8EF` | `#28224A` |

## 5) Gradients

```css
/* هيدر بسيط — تدرج teal */
--gradient-header-2: linear-gradient(135deg, #11545C, #083B41);

/* هيدر أعمق — 3 محطات */
--gradient-header-3: linear-gradient(135deg, #11545C, #083B41, #06262A);

/* تدرج ذهبي — CTA / badges */
--gradient-secondary: linear-gradient(135deg, #F2A922, #DB9013);

/* هيدر شاشات الدخول */
--gradient-auth: linear-gradient(135deg, #0E6E75, #083B41, #06262A);
```

## 6) الخطوط (Typography)

خطين من Google Fonts، الاتنين بيدعموا عربي + إنجليزي:

| الدور | الخط | الأوزان |
|---|---|---|
| العناوين (Headlines) | **Alexandria** | 600/700 |
| النص والواجهة (Body/UI) | **Readex Pro** | 400/500/600/700 |

```css
@import url('https://fonts.googleapis.com/css2?family=Alexandria:wght@600;700&family=Readex+Pro:wght@400;500;600;700&display=swap');
```

### المقاسات

| Style | Font | Size | Weight |
|---|---|---|---|
| H1 | Alexandria | 32px | 700 |
| H2 | Alexandria | 24px | 700 |
| H3 | Alexandria | 20px | 600 |
| H4 | Alexandria | 18px | 600 |
| Body Large | Readex Pro | 16px | 400 |
| Body Medium | Readex Pro | 14px | 400 |
| Body Small | Readex Pro | 12px | 400 |
| Label L/M/S | Readex Pro | 14/12/10px | 500 |
| Button L/M/S | Readex Pro | 18/16/14px | 700/600/600 |

## 7) Border Radius

الأساس `--radius: 1.5rem (24px)`:

| Token | Value | الاستخدام |
|---|---|---|
| `radius-sm` | 20px | عناصر صغيرة |
| `radius-md` | 22px | متوسط |
| `radius` (lg) | 24px | الكروت الأساسية `rounded-3xl` |
| `radius-xl` | 28px | كروت كبيرة |
| `radius-button` | 16px | أزرار `rounded-2xl` |
| `radius-input` | 12px | حقول `rounded-xl` |
| `radius-chip` | 999px | pills |
| `radius-large` | 48px | هيدرات/بانر `rounded-[3rem]` |

## 8) Spacing (Tailwind scale — 4px unit)

`xs 4 · sm 8 · md 12 · lg 16 · xl 20 · xxl 24 · 3xl 32 · 4xl 40 · 5xl 48 · 6xl 64`

الشائع: padding شاشة `16px`، padding كرت `16px`، مسافة بين السكاشن `24px`، gap عناصر `12–16px`.

## 9) Shadows (CSS جاهز)

```css
--shadow-sm: 0 1px 2px rgba(0,0,0,.05);
--shadow-md: 0 2px 4px rgba(0,0,0,.10);
--shadow-lg: 0 4px 8px rgba(0,0,0,.15);
--shadow-xl: 0 6px 12px rgba(0,0,0,.20);
--shadow-2xl: 0 8px 16px rgba(0,0,0,.25);
--shadow-card: 0 2px 8px rgba(0,0,0,.10);
--shadow-card-hover: 0 4px 12px rgba(0,0,0,.15);
--shadow-nav: 0 -4px 20px rgba(0,0,0,.30);
```

## 10) CSS Variables جاهزة للنسخ

```css
:root {
  /* Brand */
  --brand-deep-teal: #083B41;
  --brand-teal: #0E6E75;
  --brand-saffron: #F2A922;
  --brand-sand: #FBF8F2;
  --brand-sand-deep: #E5DCCB;
  --brand-ink: #0D2A2E;

  /* Semantic — Light */
  --background: #FBF8F2;
  --foreground: #0D2A2E;
  --card: #FFFFFF;
  --card-foreground: #0D2A2E;
  --muted: #F3EDE2;
  --muted-foreground: #4A6063;
  --subtle-foreground: #5F7376;
  --border: #E5DCCB;
  --input: #FFFFFF;
  --ring: #0E6E75;

  --primary: #0E6E75;
  --primary-foreground: #FFFFFF;
  --primary-hover: #0B5960;
  --primary-soft: #E1F0EF;

  --secondary: #F2A922;
  --secondary-foreground: #083B41;   /* نص على الذهبي دايمًا teal غامق */
  --secondary-hover: #DB9013;
  --secondary-soft: #FDF1D6;
  --accent-ink: #865407;

  --destructive: #B4372B;
  --destructive-foreground: #FFFFFF;
  --success: #1D7650;
  --warning: #8F5600;
  --info: #2A62A3;
  --success-soft: #E1F2E9;
  --warning-soft: #FDF0D6;
  --danger-soft: #FBE5E1;
  --info-soft: #E5EEF8;

  /* Radius */
  --radius: 1.5rem;          /* 24px */
  --radius-sm: 1.25rem;      /* 20px */
  --radius-md: 1.375rem;     /* 22px */
  --radius-xl: 1.75rem;      /* 28px */
  --radius-button: 1rem;     /* 16px */
  --radius-input: 0.75rem;   /* 12px */

  /* Gradients */
  --gradient-header: linear-gradient(135deg, #11545C, #083B41);
  --gradient-header-deep: linear-gradient(135deg, #11545C, #083B41, #06262A);
  --gradient-gold: linear-gradient(135deg, #F2A922, #DB9013);

  /* Fonts */
  --font-headline: 'Alexandria', sans-serif;
  --font-body: 'Readex Pro', sans-serif;
}

.dark {
  --background: #06262A;
  --foreground: #F2EEE6;
  --card: #0B3237;
  --card-foreground: #F2EEE6;
  --muted: #041D20;
  --muted-foreground: #A9C0C0;
  --subtle-foreground: #8AA6A7;
  --border: #1C4B51;
  --input: #0B3237;
  --ring: #5CC7C1;

  --primary: #5CC7C1;
  --primary-foreground: #052A2E;
  --primary-hover: #86D7D2;
  --primary-soft: #0F3E43;

  --secondary: #F2A922;
  --secondary-foreground: #083B41;
  --secondary-hover: #F7C056;
  --secondary-soft: #352A0F;
  --accent-ink: #F7C056;

  --destructive: #F2907F;
  --destructive-foreground: #43201B;
  --success: #62CC9C;
  --warning: #F2B54A;
  --info: #8AB9EE;
  --success-soft: #0E3527;
  --warning-soft: #382910;
  --danger-soft: #43201B;
  --info-soft: #132C45;
}
```

## 11) قواعد مهمة من البراند

1. **النص على خلفية saffron الذهبية دايمًا deep teal** `#083B41` — ممنوع أبيض.
2. الـ primary الافتراضي teal؛ الزرار الرئيسي في **الدارك مود saffron** بنص teal.
3. الكروت بلا elevation تقريبًا — حدود خفيفة `#E5DCCB` + ظل ناعم.
4. الـ card radius الأساسي كبير (24px) — ده من هوية البراند، متصغروش.
5. الـ icon الافتراضي teal في اللويت وmint `#5CC7C1` في الدارك.
6. التطبيق RTL (عربي أولًا) — الداشبورد لو عربي يفضّل نفس الاتجاه ونفس الخط.

## 12) Tailwind (لو الداشبورد Tailwind)

```js
// tailwind.config.js — extend فقط
theme: {
  extend: {
    colors: {
      brand: {
        deepTeal: '#083B41', teal: '#0E6E75', saffron: '#F2A922',
        sand: '#FBF8F2', sandDeep: '#E5DCCB', ink: '#0D2A2E',
      },
    },
    fontFamily: {
      headline: ['Alexandria', 'sans-serif'],
      body: ['"Readex Pro"', 'sans-serif'],
    },
    borderRadius: { card: '1.5rem', button: '1rem', input: '0.75rem' },
  },
}
```

---

### ملفات المصدر في التطبيق

- `lib/core/design/app_colors.dart` — كل توكنز الألوان
- `lib/core/design/app_theme.dart` — بناء ThemeData (light/dark)
- `lib/core/design/app_radius.dart` / `app_spacing.dart` / `app_shadows.dart` / `app_text_styles.dart`
