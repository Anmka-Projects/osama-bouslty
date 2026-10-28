# Landing Page — مواصفات الفرونت إند

> **المشروع:** Bouslty  
> **الهدف:** صفحة هبوط (Landing Page) تعرض **الكورسات المجانية فقط**، تسمح لأي زائر بمشاهدة المحتوى **بدون تسجيل**، مع أنيميشن جذاب يعكس هوية التطبيق.  
> **المرجع:** تطبيق Flutter — `lib/core/design/app_colors.dart` + `lib/widgets/course_card.dart`

---

## 1. ملخص المنتج

| البند | التفاصيل |
|-------|----------|
| اسم المنصة (عربي) | Bouslty |
| اسم المنصة (إنجليزي) | Bouslty |
| الشعار (Tagline) | منصة التعليم الذكية |
| اللغة الافتراضية | **العربية (RTL)** — مع دعم EN |
| التسجيل | **مُعطّل** — لا يوجد Sign Up / Register |
| تسجيل الدخول | **مُخفى** من الـ Landing (اختياري: رابط صغير للأدمن فقط) |
| المحتوى المعروض | **كورسات مجانية فقط** (`is_free: true`) |
| مشاهدة الدروس | **بدون حساب** — Guest View (انظر §8 للـ Backend) |

---

## 2. الهوية البصرية (Brand Identity)

### 2.1 لوحة الألوان — Navy & Gold

هذه هي ألوان التطبيق الفعلية (مطابقة لـ Flutter). **استخدموها كمصدر أساسي** وليس ألوان الـ API القديمة.

#### Gold (الذهبي — Accent)

| Token | Hex | الاستخدام |
|-------|-----|-----------|
| `gold-light` | `#FFE566` | Highlights، hover، shimmer |
| `gold-primary` | `#F0B800` | أزرار CTA، badges، نجوم التقييم، أيقونات |
| `gold-text` | `#C8A030` | نصوص accent، روابط ثانوية |
| `gold-dark` | `#8B6500` | نص badge "مجاني"، success states |

#### Navy (الكحلي — Primary)

| Token | Hex | الاستخدام |
|-------|-----|-----------|
| `navy-light` | `#0E1F45` | Cards في Dark mode، gradient start |
| `navy-mid` | `#0A1628` | Primary buttons (light theme)، header |
| `navy-deep` | `#040C22` | خلفيات hero، footer، نصوص headings |

#### Surfaces (Light Theme — الافتراضي للـ Landing)

| Token | Hex | الاستخدام |
|-------|-----|-----------|
| `scaffold` | `#F6F4EF` | خلفية الصفحة |
| `card` | `#FFFFFF` | بطاقات الكورسات |
| `muted` | `#F5F0E6` | أقسام alternate background |
| `border` | `#D5CCB8` | حدود البطاقات |
| `text-primary` | `#040C22` | العناوين والنص الأساسي |
| `text-secondary` | `#5C6778` | الوصف والـ meta |
| `text-body` | `#3D4F63` | فقرات طويلة |

#### Semantic

| Token | Hex |
|-------|-----|
| `destructive` | `#DC2626` |
| `shadow` | `rgba(4, 12, 34, 0.12)` |

### 2.2 CSS Variables (انسخوا مباشرة)

```css
:root {
  /* Gold */
  --gold-light: #FFE566;
  --gold-primary: #F0B800;
  --gold-text: #C8A030;
  --gold-dark: #8B6500;
  --gold-primary-12: rgba(240, 184, 0, 0.12);
  --gold-primary-24: rgba(240, 184, 0, 0.24);

  /* Navy */
  --navy-light: #0E1F45;
  --navy-mid: #0A1628;
  --navy-deep: #040C22;

  /* Surfaces */
  --scaffold: #F6F4EF;
  --card: #FFFFFF;
  --muted: #F5F0E6;
  --border: #D5CCB8;
  --text-primary: #040C22;
  --text-secondary: #5C6778;

  /* Gradients */
  --gradient-header: linear-gradient(135deg, #0E1F45 0%, #0A1628 100%);
  --gradient-hero: linear-gradient(160deg, #0E1F45 0%, #0A1628 50%, #040C22 100%);
  --gradient-gold: linear-gradient(135deg, #FFE566 0%, #F0B800 50%, #8B6500 100%);
  --gradient-gold-subtle: linear-gradient(90deg, rgba(240,184,0,0.12) 0%, transparent 100%);

  /* Radius — مطابق للتطبيق */
  --radius-card: 24px;
  --radius-button: 16px;
  --radius-input: 12px;
  --radius-chip: 999px;

  /* Shadow */
  --shadow-card: 0 4px 12px rgba(4, 12, 34, 0.12);
  --shadow-elevated: 0 12px 24px rgba(4, 12, 34, 0.18);
  --shadow-gold-glow: 0 0 28px rgba(240, 184, 0, 0.35);
}
```

### 2.3 Typography

| العنصر | Font | Weight | Size (Desktop) | Size (Mobile) |
|--------|------|--------|----------------|---------------|
| H1 Hero | Cairo | 700 | 48–56px | 32–36px |
| H2 Section | Cairo | 700 | 32px | 24px |
| H3 Card Title | Cairo | 700 | 16–18px | 16px |
| Body | Cairo | 400 | 16px | 14px |
| Meta / Label | Cairo | 500 | 12–14px | 12px |
| Button | Cairo | 600–700 | 16–18px | 16px |

```html
<link href="https://fonts.googleapis.com/css2?family=Cairo:wght@400;500;600;700&display=swap" rel="stylesheet">
```

```css
body {
  font-family: 'Cairo', sans-serif;
  direction: rtl;
  background: var(--scaffold);
  color: var(--text-primary);
}
```

### 2.4 Border Radius (من التطبيق)

- بطاقات الكورس: **24px** (`rounded-3xl`)
- أزرار: **16px**
- Inputs: **12px**
- Chips / Badges: **pill (999px)**

---

## 3. هيكل الصفحة (Page Sections)

```
┌─────────────────────────────────────────┐
│  Navbar (sticky, blur)                  │
├─────────────────────────────────────────┤
│  Hero Section (gradient navy + anim)    │
├─────────────────────────────────────────┤
│  Stats Bar (animated counters)          │
├─────────────────────────────────────────┤
│  Free Courses Grid (القسم الرئيسي)      │
├─────────────────────────────────────────┤
│  Featured Course Spotlight (optional)   │
├─────────────────────────────────────────┤
│  How It Works (3 steps)                 │
├─────────────────────────────────────────┤
│  App Download CTA (optional)            │
├─────────────────────────────────────────┤
│  Footer (social + support)              │
└─────────────────────────────────────────┘
```

**لا تعرضوا:** كورسات مدفوعة، أسعار، checkout، تسجيل، wishlist، exams، certificates.

---

## 4. تفاصيل كل Section

### 4.1 Navbar

**Layout:** Logo (يمين في RTL) | روابط: "الكورسات المجانية" · "كيف تبدأ" | CTA: "ابدأ التعلم مجاناً"

| Property | Value |
|----------|-------|
| Background | `rgba(255,255,255,0.85)` + `backdrop-filter: blur(12px)` |
| Border bottom | `1px solid var(--border)` |
| Height | 64–72px |
| Sticky | `position: sticky; top: 0; z-index: 50` |
| Scroll behavior | بعد 80px scroll → خلفية أوضح + shadow خفيف |

**Animation:** Fade-in + slide-down عند التحميل (300ms ease-out).

**مهم:** لا يوجد زر "تسجيل" أو "دخول".

---

### 4.2 Hero Section

**Background:** `--gradient-hero` مع animated mesh/orbs ذهبية شفافة.

**Content (RTL, centered-right on desktop):**

```
[Badge] 🎓 كورسات مجانية 100%

[ H1 ]
تعلّم مهاراتك
<span class="text-gold">بدون أي تكلفة</span>

[ Subtitle ]
اكتشف كورسات Bouslty المجانية — شاهد الدروس فوراً
بدون إنشاء حساب

[ CTA Primary ]  ابدأ التعلم الآن  → scroll to #free-courses
[ CTA Ghost ]    تصفّح الكورسات

[ Hero Visual ]
Mockup هاتف / carousel صور slider من API
```

**Hero Visual Options (اختر واحد):**
1. **Phone mockup** يعرض screenshot من التطبيق + floating course cards
2. **Slider carousel** من `GET /api/sliders`
3. **Lottie animation** — شخص يتعلم / كتاب مفتوح (ذهبي على navy)

**Animations:**
- H1: staggered word fade-up (each word +80ms delay)
- Badge: subtle pulse glow (`box-shadow` gold)
- CTA Primary: hover scale 1.03 + gold glow shadow
- Background orbs: slow float (20s infinite, CSS `@keyframes float`)
- Scroll indicator: bouncing chevron at bottom

**Dimensions:**
- Min height: `90vh` (desktop), `80vh` (mobile)
- Padding: `80px 24px` (desktop), `48px 16px` (mobile)

---

### 4.3 Stats Bar

شريط أفقي فوق قسم الكورسات — **animated counters** عند دخول viewport.

| Stat | Example | Source |
|------|---------|--------|
| كورسات مجانية | `1+` | `meta.total` from courses API |
| دروس | `34+` | sum of `lessons_count` |
| متعلمين | `7+` | sum of `students_count` |
| ساعات محتوى | `2+` | sum of `duration_hours` |

**Style:**
- Background: `var(--card)` with `--shadow-card`
- Border-radius: `var(--radius-card)`
- Numbers: `var(--gold-primary)`, bold, 32px
- Labels: `var(--text-secondary)`, 14px
- Divider: vertical line `var(--border)`

**Animation:** Count-up from 0 → target over 1.5s when section enters viewport (Intersection Observer). Use `requestAnimationFrame` or library like `react-countup`.

---

### 4.4 Free Courses Section — `#free-courses`

**القسم الأهم.** يعرض **فقط** كورسات `is_free === true`.

#### Grid Layout

| Breakpoint | Columns | Gap |
|------------|---------|-----|
| Mobile (<640px) | 1 | 16px |
| Tablet (640–1024px) | 2 | 20px |
| Desktop (>1024px) | 3 | 24px |
| Wide (>1280px) | 3–4 | 24px |

#### Course Card Spec (مطابق للتطبيق)

```
┌──────────────────────────────┐
│  [Thumbnail 16:9]            │
│  ┌─────────┐                 │
│  │  مجاني  │  ← badge top-right
│  └─────────┘                 │
├──────────────────────────────┤
│  Course Title (bold, 2 lines)│
│  👤 Instructor Name          │
│  ⭐ 0  ·  ⏱ 2 س 42 د  ·  📚 34│
│  [  شاهد الآن — مجاناً  ]    │
└──────────────────────────────┘
```

| Property | Value |
|----------|-------|
| Width | 100% (grid cell) |
| Image height | 180px (desktop), 160px (mobile) |
| Border-radius | 24px |
| Border | `1px solid var(--border)` |
| Shadow | `var(--shadow-card)` |
| Hover | `translateY(-4px)` + stronger shadow + gold border tint |

**Free Badge:**
```css
.free-badge {
  background: var(--gold-primary-24);
  color: var(--gold-dark);
  font-size: 12px;
  font-weight: 600;
  padding: 4px 12px;
  border-radius: var(--radius-chip);
}
```

**CTA Button (per card):**
- Text: **"شاهد الآن — مجاناً"**
- Style: Navy background (`--navy-mid`), white text
- Hover: Gold background, navy text
- Action: Navigate to `/courses/{courseId}` (course viewer page)

**Card Animation:**
- Stagger fade-up on scroll: each card +100ms delay
- Image: subtle zoom on hover (`scale(1.05)` over 400ms)
- Skeleton loading: shimmer gold/navy (match app skeleton)

**Empty State:**
```
لا توجد كورسات مجانية حالياً — تابعونا قريباً!
```

**Search (optional):**
- Input above grid, filters client-side by `title`
- Style: white bg, gold focus ring (`2px solid var(--gold-primary)`)

---

### 4.5 Course Viewer Page — `/courses/[id]`

صفحة داخلية (ليست landing) لعرض الكورس ومشاهدة الدروس **بدون تسجيل**.

#### Layout

```
┌──────────────────────────────────────────────────┐
│  ← رجوع للكورسات                                 │
├──────────────────────┬───────────────────────────┤
│                      │  Curriculum Sidebar       │
│   Video Player       │  ┌─ Section 1            │
│   (16:9)             │  │  ✓ Lesson 1 (active)  │
│                      │  │    Lesson 2           │
│                      │  └─ Section 2            │
│   Lesson Title       │                           │
│   Description        │                           │
└──────────────────────┴───────────────────────────┘
```

**Video Player:**
- YouTube embed / HLS / direct MP4 — حسب `content` من API
- Controls: play, pause, seek, fullscreen, speed (0.75x–2x)
- **No download button** on web landing
- Autoplay: **off** (UX best practice)

**Sidebar Curriculum:**
- Accordion sections from `curriculum[]`
- Active lesson: gold left border + gold text
- Completed: checkmark (localStorage only — no account)
- Locked lessons: **only if not free** — on landing all should be unlocked

**Guest Progress (localStorage):**
```js
// Key: `guest_progress_{courseId}`
{ "lessonId": "percent_watched", ... }
```

**No enrollment button.** No login prompt. If API returns 401, show friendly message (see §8).

---

### 4.6 How It Works

3 steps أفقي (vertical on mobile):

| Step | Icon | Title | Description |
|------|------|-------|-------------|
| 1 | 🔍 | اختر كورسك | تصفّح الكورسات المجانية واختر ما يناسبك |
| 2 | ▶️ | شاهد فوراً | اضغط "شاهد الآن" — بدون تسجيل أو انتظار |
| 3 | 📈 | تطوّر مهاراتك | أكمل الدروس بالترتيب واستفد من المحتوى |

**Animation:** Icons fade-in sequentially on scroll + connecting dashed line (gold) between steps.

---

### 4.7 App Download CTA (Optional)

```
حمّل التطبيق للتعلم أينما كنت
[App Store]  [Google Play]
```

- Background: `--gradient-gold-subtle` on `--muted`
- Badges: official store images
- Links: TBD (from app store listings)

---

### 4.8 Footer

**Background:** `--navy-deep`  
**Text:** white / `--gold-text`

Columns:
1. Logo + tagline
2. روابط سريعة: الكورسات المجانية · سياسة الخصوصية · الشروط
3. تواصل: WhatsApp · Email · Phone (from config API)
4. Social: Instagram · Facebook · YouTube · TikTok · Telegram

**Social links:** اجلبها ديناميكياً من `GET /api/config/app` → `social_links` (instagram, facebook, youtube, tiktok, telegram, whatsapp).  
**ملاحظة:** اسم البراند ثابت **Bouslty** — لا تعتمد على `app_name` من الـ API إذا كان مختلفاً (قد يكون إعداد white-label قديم على السيرفر).

---

## 5. Animations & Motion Design

### 5.1 مكتبات مقترحة

| Library | Use Case |
|---------|----------|
| **Framer Motion** (React) | Page transitions, scroll reveals, stagger |
| **GSAP + ScrollTrigger** | Hero parallax, counter animations |
| **CSS `@keyframes`** | Orbs float, shimmer skeleton, pulse badge |
| **Lottie** (optional) | Hero illustration |

### 5.2 Animation Tokens

```css
--ease-out-expo: cubic-bezier(0.16, 1, 0.3, 1);
--duration-fast: 200ms;
--duration-normal: 400ms;
--duration-slow: 800ms;
```

### 5.3 قائمة Animations

| Element | Animation | Trigger | Duration |
|---------|-----------|---------|----------|
| Page load | Fade in body | on mount | 400ms |
| Navbar | Slide down + fade | on mount | 300ms |
| Hero H1 | Stagger word up | on mount | 600ms total |
| Hero badge | Pulse glow | infinite | 2s |
| Hero orbs | Float XY | infinite | 20s |
| Stats numbers | Count up | scroll into view | 1.5s |
| Course cards | Stagger fade-up | scroll into view | 100ms stagger |
| Card hover | Lift + shadow | hover | 200ms |
| Card image | Scale 1.05 | hover | 400ms |
| CTA button | Scale + glow | hover | 200ms |
| Section titles | Fade up | scroll into view | 500ms |
| How-it-works icons | Pop in sequence | scroll into view | 150ms stagger |
| Page transition | Fade | route change | 300ms |

### 5.4 Reduced Motion

```css
@media (prefers-reduced-motion: reduce) {
  *, *::before, *::after {
    animation-duration: 0.01ms !important;
    transition-duration: 0.01ms !important;
  }
}
```

---

## 6. API Integration

### 6.1 Base URLs

```text
API Base:     https://bouslty.anmka.com/api
Media Base:   https://bouslty.anmka.com
Config:       GET /api/config/app
```

### 6.2 Endpoints المطلوبة

| Endpoint | Auth | Usage |
|----------|------|-------|
| `GET /api/config/app` | ❌ No | App name, tagline, social, support, legal |
| `GET /api/courses?price=free&per_page=20&page=1` | ❌ No* | قائمة الكورسات المجانية |
| `GET /api/courses/{id}` | ❌ No | تفاصيل الكورس + `curriculum` |
| `GET /api/courses/{id}/lessons/{lessonId}/content` | ⚠️ See §8 | فيديو/محتوى الدرس |
| `GET /api/sliders` | ❌ No | صور Hero carousel |
| `GET /api/categories` | ❌ No | Optional filter chips |
| `GET /api/home` | ❌ No | Alternative: `popular_courses` filtered by `is_free` |

> *Flutter app sends auth token if available, but API responds without auth for course listing.

### 6.3 Filter Logic (Frontend)

```javascript
// Primary: use API filter
const url = `${API_BASE}/courses?price=free&per_page=20&page=${page}`;

// Fallback: filter client-side
const freeCourses = courses.filter(c => c.is_free === true);

// Pricing helper (match Flutter CoursePricingUtils)
function isFreeCourse(course) {
  if (course.is_free === true) return true;
  if (course.is_free === false) return false;
  const price = Number(course.price) || 0;
  const original = Number(course.original_price) || 0;
  return price === 0 && original === 0;
}
```

### 6.4 Image URL Helper

```javascript
function getImageUrl(path) {
  if (!path) return '/placeholder-course.jpg';
  if (path.startsWith('http')) return path;
  let clean = path.startsWith('/') ? path : `/${path}`;
  if (clean.startsWith('/uploads/')) clean = `/api${clean}`;
  return `https://bouslty.anmka.com${clean}`;
}
```

### 6.5 Course Card — Data Mapping

```javascript
{
  id: course.id,
  title: course.title,
  description: course.description,
  thumbnail: getImageUrl(course.thumbnail || course.image),
  instructor: course.instructor?.name ?? '—',
  instructorAvatar: getImageUrl(course.instructor?.avatar),
  rating: Number(course.rating) || 0,
  reviewsCount: course.reviews_count ?? 0,
  studentsCount: course.students_count ?? 0,
  lessonsCount: course.lessons_count ?? 0,
  duration: course.duration_label || course.duration,
  isFree: course.is_free === true,
}
```

### 6.6 Pagination

```javascript
// Response shape
{
  "success": true,
  "data": {
    "courses": [...],
    "meta": {
      "current_page": 1,
      "per_page": 20,
      "total": 1,
      "total_pages": 1,
      "has_more": false
    }
  }
}
```

Show "تحميل المزيد" button when `meta.has_more === true`.

---

## 7. Responsive Breakpoints

```css
/* Mobile first */
--bp-sm: 640px;
--bp-md: 768px;
--bp-lg: 1024px;
--bp-xl: 1280px;
```

| Element | Mobile | Desktop |
|---------|--------|---------|
| Hero H1 | 32px | 56px |
| Section padding | 48px 16px | 80px 24px |
| Course grid | 1 col | 3 col |
| Navbar | Hamburger menu | Full links |
| Course viewer | Stack (video top, curriculum bottom sheet) | Side-by-side |
| Stats bar | 2×2 grid | 4 columns row |

---

## 8. ⚠️ Backend Requirement — Guest Lesson Viewing

**حالة حالية (تم التحقق):**

| Endpoint | بدون Auth |
|----------|-----------|
| `GET /api/courses?price=free` | ✅ 200 |
| `GET /api/courses/{id}` | ✅ 200 (includes curriculum) |
| `GET /api/courses/{id}/lessons/{id}/content` | ❌ 401 — "يرجى تسجيل الدخول للوصول" |

**المطلوب من Backend:**

تفعيل وصول **Guest** لمحتوى الدروس في الكورسات المجانية فقط:

```
GET /api/courses/{courseId}/lessons/{lessonId}/content
Authorization: (optional — not required when course.is_free === true)
```

**Alternative:** endpoint جديد:

```
GET /api/public/courses/{courseId}/lessons/{lessonId}/content
```

**Frontend behavior until backend is ready:**
- Show course details + curriculum (works today)
- On lesson click → show modal: "المحتوى قريباً" or contact support
- Or: embed preview video if `lesson.preview_url` exists in curriculum item

**Action item for Backend team:** confirm ETA for public free-lesson access.

---

## 9. Routes (Next.js / React Router)

| Route | Page | Description |
|-------|------|-------------|
| `/` | Landing | Hero + free courses grid |
| `/courses/[id]` | Course Viewer | Video player + curriculum |
| `/privacy` | Privacy | From `legal.privacy_url` |
| `/terms` | Terms | From `legal.terms_url` |

**No routes for:** `/login`, `/register`, `/checkout`, `/profile`

---

## 10. SEO & Meta Tags

```html
<title>Bouslty — كورسات مجانية</title>
<meta name="description" content="تعلّم مهاراتك مجاناً مع Bouslty. شاهد الكورسات والدروس بدون تسجيل.">
<meta property="og:title" content="Bouslty — كورسات مجانية">
<meta property="og:description" content="Bouslty — منصة التعليم الذكية · كورسات مجانية 100%">
<meta property="og:type" content="website">
<meta property="og:locale" content="ar_EG">
<meta name="twitter:card" content="summary_large_image">
```

---

## 11. Tech Stack Recommendation

| Layer | Suggestion |
|-------|------------|
| Framework | **Next.js 14+** (App Router) — SSR for SEO |
| Styling | **Tailwind CSS** + CSS variables above |
| Animation | **Framer Motion** |
| Data fetching | TanStack Query (React Query) |
| Video | `react-player` or native `<video>` / YouTube iframe |
| Icons | Lucide React or Heroicons |
| Images | `next/image` with lazy loading |
| i18n | next-intl (ar default, en optional) |

---

## 12. Assets Needed from Design/Client

- [ ] Logo PNG/SVG (light + dark versions)
- [ ] App Store / Google Play badges + links
- [ ] Favicon (32×32, 180×180 apple-touch)
- [ ] OG image (1200×630) — navy gradient + logo + tagline
- [ ] Optional: Lottie hero animation file
- [ ] Optional: Phone mockup template

---

## 13. Acceptance Criteria (Checklist)

### Visual
- [ ] الألوان مطابقة لـ Navy & Gold tokens (§2)
- [ ] خط Cairo على كل النصوص
- [ ] RTL صحيح على كل الصفحة
- [ ] Responsive على mobile / tablet / desktop
- [ ] Course cards مطابقة ل spec (§4.4)

### Functional
- [ ] يعرض **كورسات مجانية فقط**
- [ ] **لا يوجد** تسجيل أو login UI
- [ ] زائر يفتح كورس → يرى curriculum
- [ ] زائر يشغّل درس مجاني (بعد Backend fix §8)
- [ ] Pagination / Load more يعمل
- [ ] Skeleton loading أثناء fetch
- [ ] Empty state + error state

### Animation
- [ ] Hero animations on load
- [ ] Scroll reveal on sections
- [ ] Counter animation on stats
- [ ] Card hover effects
- [ ] `prefers-reduced-motion` respected

### Performance
- [ ] Lighthouse Performance > 85
- [ ] Images lazy-loaded + WebP
- [ ] LCP < 2.5s on 4G

---

## 14. Wireframe Reference (Mobile)

```
┌─────────────────────┐
│ ☰  [Logo]           │
├─────────────────────┤
│                     │
│  🎓 كورسات مجانية   │
│                     │
│  تعلّم مهاراتك      │
│  بدون أي تكلفة      │
│                     │
│  [ابدأ التعلم الآن] │
│  [تصفّح الكورسات]   │
│                     │
│  ┌───────────────┐  │
│  │  phone/slider │  │
│  └───────────────┘  │
│         ⌄           │
├─────────────────────┤
│  1+    34+   7+  2+ │
│ كورس  درس  متعلم  س  │
├─────────────────────┤
│  الكورسات المجانية  │
│  ┌───────────────┐  │
│  │ [img]  مجاني  │  │
│  │ presentation  │  │
│  │ Dr. Alaa Ammar│  │
│  │ [شاهد الآن]   │  │
│  └───────────────┘  │
├─────────────────────┤
│  كيف تبدأ؟          │
│  1 → 2 → 3         │
├─────────────────────┤
│  Footer             │
└─────────────────────┘
```

---

## 15. Contact & Handoff

| Role | Action |
|------|--------|
| **Frontend** | Implement per this spec |
| **Backend** | Enable guest access to free lesson content (§8) |
| **Design** | Provide logo + OG image + optional Lottie |
| **Product** | Confirm domain (e.g. `bouslty.anmka.com` or custom) |

**Flutter app reference files:**
- Colors: `lib/core/design/app_colors.dart`
- Theme: `lib/core/design/app_theme.dart`
- Course card: `lib/widgets/course_card.dart`
- Pricing logic: `lib/core/courses/course_pricing_utils.dart`
- API endpoints: `lib/core/api/api_endpoints.dart`

---

*آخر تحديث: سبتمبر 2026 — v1.0*
