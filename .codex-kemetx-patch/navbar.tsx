"use client"

import { useState, useEffect, useMemo, useRef } from "react"
import Link from "next/link"
import Image from "next/image"
import { usePlatformBranding } from "@/hooks/use-platform-branding"
import { usePathname, useRouter } from "next/navigation"
import { m, AnimatePresence } from "framer-motion"
import {
  ShoppingCart,
  Menu,
  X,
  Sparkles,
  LogOut,
  User,
  LayoutDashboard,
  ChevronDown,
  ChevronLeft,
  ShoppingBag,
  Tag,
  Phone,
  Globe,
} from "lucide-react"
import { Button } from "@/components/ui/button"
import { useI18n } from "@/lib/i18n"
import { useStore } from "@/lib/store"
import { cn, safeStr, getDashboardPath, getMyCoursesPath } from "@/lib/utils"
import { categoryBrowseHref, getPostAuthLandingPath, isPhysicsCodeTenant } from "@/lib/is-physics-code-tenant"
import { getApiBase } from "@/lib/api"
import { fetchInstructorsEnabledDeduped } from "@/lib/instructors-enabled-once"
import { FeatureGate } from "@/components/feature-gate"
import { useThemeConfigOptional } from "@/components/providers/ThemeConfigProvider"
import { isTenantPageEnabled } from "@/lib/tenant-theme"
import { isManaraInstituteTenantConfig } from "@/lib/is-manara-institute-tenant"
import { manaraTenantCleanCopy } from "@/lib/manara-i18n-overrides"
import { siteContentLocaleText } from "@/lib/site-content-text"
import { isGoalsTargetsTenant } from "@/lib/goals-targets"
import { isSpeakoraTenant } from "@/lib/is-speakora-tenant"
import { SPEAKORA_COLORS } from "@/lib/speakora"
import { isDnesatTenantSkinActive } from "@/lib/is-dne-sat-tenant"
import { DnesatNavbarBridge } from "@/components/home/dnesat/dnesat-navbar-bridge"
import { isFahdmareyTenantSkinActive } from "@/lib/is-eng-fahdmarey-tenant"
import { isFahdmareyPublicRoute } from "@/lib/fahdmarey"
import { FahdmareyNavbar } from "@/components/home/fahdmarey/fahdmarey-navbar"
import { isTmceduTenant, TMCEDU_CONTACT_NAV_LINK, TMCEDU_NAV_LINKS, tmceduNavLabel } from "@/lib/tmcedu"
import {
  isMathapexTenant,
  MATHAPEX_RESOURCE_NAV_LINKS,
  MATHAPEX_BLOG_PATH,
  MATHAPEX_TESTS_NAV_LINK,
  MATHAPEX_TESTS_PATH,
  handleMathapexHashNavClick,
  mathapexNavLabel,
} from "@/lib/mathapex"
import { mathapexNavLink, mathapexNavLinkDense, mathapexNavWrap } from "@/lib/mathapex-theme"
import {
  hasTenantNavbarLogoOverride,
  parseTenantLogoSizePx,
  resolveTenantNavbarLogoUrl,
} from "@/lib/tenant-branding"
import { TmceduBrandLogo } from "@/components/brand/tmcedu-brand-logo"
import { LogoPreviewTrigger } from "@/components/brand/logo-preview-trigger"
import { isEngFahdmareyTenant } from "@/lib/is-eng-fahdmarey-tenant"
import { ThemeModeToggle } from "@/components/theme/theme-mode-toggle"
import { TenantHighlightedText } from "@/components/tenant/tenant-highlighted-text"
import { useThemeMode } from "@/components/providers/ThemeModeProvider"
import { useContentNavCollapse } from "@/hooks/use-content-nav-collapse"
import {
  ConfiguredNavLinks,
  ConfiguredMobileNavLinks,
  configuredCtaItems,
  parseTenantNavConfig,
} from "@/components/navbar/configured-nav-items"
import { navItemLabel } from "@/lib/nav-config"

const STORE_ENABLED_KEY = "lms_store_enabled"
const INSTRUCTORS_ENABLED_KEY = "lms_instructors_enabled"

type NavLandingPage = {
  id?: string
  slug: string
  title: string
  titleAr?: string | null
  navLabel?: string | null
  navLabelAr?: string | null
  children?: NavLandingPage[]
}

function navPageLabel(page: NavLandingPage, locale: string) {
  return locale === "ar"
    ? (page.navLabelAr || page.titleAr || page.navLabel || page.title)
    : (page.navLabel || page.title)
}

export function Navbar() {
  const { locale, dir, setLocale, t } = useI18n()
  const { user, isLoggedIn, logout, cartCount, hydrated } = useStore()
  const { branding } = usePlatformBranding()
  const router = useRouter()
  const routePathname = (usePathname() || "").toLowerCase()
  const [isScrolled, setIsScrolled] = useState(false)
  const [isMobileMenuOpen, setIsMobileMenuOpen] = useState(false)
  const [isProfileOpen, setIsProfileOpen] = useState(false)
  const [storeEnabled, setStoreEnabled] = useState(false)
  const [instructorsEnabled, setInstructorsEnabled] = useState(false)
  const [categories, setCategories] = useState<{ id: string; name: string; nameEn?: string; slug: string; children?: { id: string; name: string; nameEn?: string; slug: string }[] }[]>([])
  const [landingNavPages, setLandingNavPages] = useState<NavLandingPage[]>([])
  const [categoriesOpen, setCategoriesOpen] = useState(false)
  const [landingNavOpenId, setLandingNavOpenId] = useState<string | null>(null)
  const [mounted, setMounted] = useState(false)
  const themeCtx = useThemeConfigOptional()
  const { mode: themeMode } = useThemeMode()
  const isUserDarkMode = themeMode === "dark"
  const tenantReady = themeCtx?.ready ?? true
  const sc = themeCtx?.config?.siteContent
  const manaraTenant = isManaraInstituteTenantConfig(themeCtx?.config)
  const tenantPhone =
    (themeCtx?.config?.contactPhone || "").trim() || undefined
  const tenantEmail =
    (themeCtx?.config?.contactEmail || "").trim() || undefined
  const showCategoriesInHeader = themeCtx?.config?.generalSettings?.show_categories_in_header !== false
  const showNavbarTopBar =
    themeCtx?.config?.generalSettings?.navbar_top_bar_enabled !== false
  const enabledLangs = themeCtx?.config?.generalSettings?.enabled_languages || { ar: true, en: true, fr: false, tr: false }
  const defaultLang = themeCtx?.config?.generalSettings?.default_language || "ar"
  const orderedLangs = ["ar", "en", "fr", "tr"] as const
  const enabledList = orderedLangs.filter((k) => enabledLangs?.[k] !== false)
  const showLanguageSwitcher = enabledList.length > 1
  const cycleLocale = () => {
    const idx = Math.max(0, enabledList.indexOf(locale as any))
    const next = enabledList[(idx + 1) % Math.max(1, enabledList.length)] || defaultLang
    setLocale(next as any)
  }
  const tenantLogoUrl = resolveTenantNavbarLogoUrl(themeCtx?.config, locale)
  const tenantBusinessNameRaw = (themeCtx?.config?.business_name || "").trim()
  const siteName = (sc?.site_name || tenantBusinessNameRaw || branding.platformName || "").trim()
  const avatarSrc =
    typeof user?.avatar === "string" && user.avatar.trim().length > 0
      ? user.avatar
      : "/user-avatar.png"
  const tenantHost =
    typeof window !== "undefined" ? window.location.host.toLowerCase() : ""
  const tenantBusinessName = (themeCtx?.config?.business_name || "")
    .toLowerCase()
    .trim()
  const isEmbryobloomTenant =
    tenantHost.includes("embryobloom-academy.e.anmka.com") ||
    tenantBusinessName.includes("embryobloom")
  const isMoneyMapTenant =
    tenantHost.includes("money-map.e.anmka.com") ||
    tenantBusinessName.includes("money map")
  const goalsTargetsTenant = isGoalsTargetsTenant(tenantHost, themeCtx?.config?.business_name, sc?.site_name)
  const speakoraTenant = isSpeakoraTenant(themeCtx?.config, tenantHost)
  const tmceduTenant = isTmceduTenant(tenantHost, themeCtx?.config?.business_name, sc?.site_name)
  const mathapexTenant = isMathapexTenant(tenantHost, themeCtx?.config?.business_name, sc?.site_name)
  const dnesatTenant = isDnesatTenantSkinActive(themeCtx?.config, tenantHost)
  const fahdmareyTenant = isEngFahdmareyTenant(themeCtx?.config, tenantHost)
  const fahdmareySkin = isFahdmareyTenantSkinActive(themeCtx?.config, tenantHost)
  const tmceduCustomNavbarLogo =
    tmceduTenant && hasTenantNavbarLogoOverride(themeCtx?.config, locale, true)
  const logoSrc = tenantLogoUrl || branding.logo || ""
  const showBranding = Boolean(logoSrc && siteName)
  const compactNavTenant = goalsTargetsTenant || tmceduTenant || speakoraTenant
  const physicsCategoryHubNav = isPhysicsCodeTenant(tenantHost, themeCtx?.config)
  const studentNavHome =
    physicsCategoryHubNav && (user?.role || "student").toLowerCase() === "student"
  const profileLandingPath = hydrated
    ? studentNavHome
      ? getPostAuthLandingPath(user?.role, tenantHost, themeCtx?.config)
      : getDashboardPath(user?.role)
    : "/dashboard"
  const coursesPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "courses")
  const storePageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "store")
  const blogPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "blog")
  const recommendationsPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "recommendations")
  const plansPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "plans")
  const coursesFeatureEnabled = themeCtx?.isFeatureEnabled("courses") ?? true
  const blogFeatureEnabled = themeCtx?.isFeatureEnabled("blog") ?? true
  const recommendationsFeatureEnabled = themeCtx?.isFeatureEnabled("recommendations") ?? true
  const subscriptionsFeatureEnabled = themeCtx?.isFeatureEnabled("subscriptions") ?? false
  const eventsPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "events")
  const eventsFeatureEnabled = themeCtx?.isFeatureEnabled("events_workshops") ?? false
  const aboutPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "about")
  const contactPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "contact")
  const brandSubtitle = mathapexTenant
    ? ""
    : isMoneyMapTenant
    ? siteContentLocaleText(sc, locale, "navbar_logo_subtitle", "navbar_logo_subtitle_en")
    : goalsTargetsTenant
      ? locale === "ar"
        ? "منصة تعليمية واستثمارية"
        : "Education & Market Targets"
      : manaraTenant
      ? manaraTenantCleanCopy(
          siteContentLocaleText(sc, locale, "navbar_logo_subtitle", "navbar_logo_subtitle_en"),
          "",
          { tenantCfg: themeCtx?.config }
        )
      : siteContentLocaleText(sc, locale, "navbar_logo_subtitle", "navbar_logo_subtitle_en")
  const moneyMapNavLinks = useMemo(() => {
    const base: { href: string; label: string }[] = [
      { href: "/", label: locale === "ar" ? "الصفحة الرئيسية" : "Home" },
    ]
    if (coursesPageEnabled && coursesFeatureEnabled) {
      base.push(
        { href: "/courses", label: locale === "ar" ? "جميع الكورسات" : "All Courses" },
        { href: "/courses?status=upcoming", label: locale === "ar" ? "الكورسات القادمة" : "Upcoming Courses" },
      )
    }
    if (instructorsEnabled) {
      base.push({ href: "/instructors", label: t("nav.instructors") })
    }
    base.push(
      { href: "/about", label: locale === "ar" ? "نبذة عنا" : "About Us" },
    )
    if (plansPageEnabled && subscriptionsFeatureEnabled) {
      base.push({ href: "/plans", label: locale === "ar" ? "الاشتراكات" : "Subscriptions" })
    }
    return base
  }, [locale, instructorsEnabled, t, coursesPageEnabled, coursesFeatureEnabled, plansPageEnabled, subscriptionsFeatureEnabled])
  const tmcEduContactLabel = tmceduNavLabel(TMCEDU_CONTACT_NAV_LINK, locale)
  const configuredNav = useMemo(() => {
    const parsed = parseTenantNavConfig(themeCtx?.config?.navConfig)
    if (!parsed || !mathapexTenant) return parsed
    // MathApex: hide Categories + Instructors, ensure Past Trials (/tests) is present
    const items = parsed.items.filter(
      (i) => i.id !== "categories" && i.id !== "instructors"
    )
    if (!items.some((i) => i.id === "tests" || i.href === MATHAPEX_TESTS_PATH)) {
      const coursesOrder = items.find((i) => i.id === "courses")?.order ?? 0
      items.push({
        id: "tests",
        kind: "link",
        href: MATHAPEX_TESTS_PATH,
        labelAr: MATHAPEX_TESTS_NAV_LINK.labelAr,
        labelEn: MATHAPEX_TESTS_NAV_LINK.labelEn,
        visible: true,
        order: coursesOrder + 0.5,
        builtin: true,
      })
    }
    return { items }
  }, [themeCtx?.config?.navConfig, mathapexTenant])
  const configuredCtas = useMemo(
    () => (configuredNav ? configuredCtaItems(configuredNav) : []),
    [configuredNav]
  )
  const mathapexResourceNavLinks = useMemo(
    () =>
      MATHAPEX_RESOURCE_NAV_LINKS
        // Blog hidden on MathApex home — restore by removing this filter
        .filter((link) => link.href !== MATHAPEX_BLOG_PATH)
        .map((link) => ({
          href: link.href,
          label: mathapexNavLabel(link, locale),
        })),
    [locale]
  )
  const tmcEduNavLinks = useMemo(() => {
    return TMCEDU_NAV_LINKS.map((link) => ({
      href: link.href,
      label: tmceduNavLabel(link, locale),
    }))
  }, [locale])
  const speakoraNavLinks = useMemo(() => {
    const links: { href: string; label: string }[] = [{ href: "/", label: locale === "ar" ? "الرئيسية" : "Home" }]
    if (coursesPageEnabled && coursesFeatureEnabled) {
      links.push({ href: "/courses", label: locale === "ar" ? "الكورسات" : "Courses" })
    }
    if (aboutPageEnabled) {
      links.push({ href: "/about", label: locale === "ar" ? "عن المدرسة" : "About" })
    }
    links.push({ href: "/#testimonials", label: locale === "ar" ? "آراء الطلاب" : "Testimonials" })
    if (contactPageEnabled) {
      links.push({ href: "/contact", label: locale === "ar" ? "تواصل معنا" : "Contact" })
    }
    return links
  }, [locale, coursesPageEnabled, coursesFeatureEnabled, aboutPageEnabled, contactPageEnabled])

  const goalsTargetsNavLinks = useMemo(() => {
    const links: { href: string; label: string }[] = [{ href: "/", label: locale === "ar" ? "الرئيسية" : "Home" }]
    if (coursesPageEnabled && coursesFeatureEnabled) links.push({ href: "/courses", label: locale === "ar" ? "الكورسات" : "Courses" })
    if (recommendationsPageEnabled && recommendationsFeatureEnabled) {
      links.push({ href: "/recommendations", label: locale === "ar" ? "التوصيات" : "Recommendations" })
    }
    if (eventsPageEnabled && eventsFeatureEnabled) {
      links.push({ href: "/events", label: locale === "ar" ? "الفعاليات والورش" : "Events" })
    }
    return links
  }, [
    locale,
    coursesPageEnabled,
    coursesFeatureEnabled,
    recommendationsPageEnabled,
    recommendationsFeatureEnabled,
    eventsPageEnabled,
    eventsFeatureEnabled,
  ])
  const landingNavLinks = useMemo(() => {
    return landingNavPages.map((page) => ({
      href: `/${page.slug}`,
      label: navPageLabel(page, locale) || page.slug,
      children: (page.children || []).map((child) => ({
        href: `/${child.slug}`,
        label: navPageLabel(child, locale) || child.slug,
      })),
    }))
  }, [landingNavPages, locale])
  const navLinkMuted = isUserDarkMode && !isMoneyMapTenant ? "text-black" : "text-gray-500"
  const navLinkHoverBg = "hover:bg-white"
  const defaultDesktopNavLinkClass = cn(
    "group relative px-5 py-2.5 text-sm font-medium transition-all duration-300 rounded-xl hover:text-medex-red",
    navLinkHoverBg,
    navLinkMuted
  )
  const defaultDesktopNavDropdownClass = cn(
    "flex items-center gap-1.5 px-5 py-2.5 text-sm font-medium rounded-xl transition-all duration-300 hover:text-medex-red",
    navLinkHoverBg,
    navLinkMuted
  )
  const gtDesktopNavLinkClass = compactNavTenant
    ? `group relative px-2.5 py-2 text-xs font-medium ${navLinkMuted} transition-all duration-300 rounded-lg hover:text-medex-red ${navLinkHoverBg} text-center leading-snug`
    : `group relative px-5 py-2.5 text-sm font-medium ${navLinkMuted} transition-all duration-300 rounded-xl hover:text-medex-red ${navLinkHoverBg}`
  const gtDesktopNavDropdownClass = compactNavTenant
    ? cn(
        "flex items-center gap-0.5 px-2.5 py-2 text-xs font-medium rounded-lg transition-all duration-300 text-center leading-snug",
        navLinkMuted
      )
    : cn(
        "flex items-center gap-1.5 px-5 py-2.5 text-sm font-medium rounded-xl transition-all duration-300",
        navLinkMuted
      )
  const gtDesktopNavWrapClass = compactNavTenant
    ? cn(
        "flex items-center gap-0 rounded-2xl border p-0.5",
        isUserDarkMode && !isMoneyMapTenant
          ? "border-gray-200/80 bg-white/95"
          : "border-gray-100 bg-gray-50/50"
      )
    : cn(
        "flex items-center gap-0.5 rounded-2xl border p-1",
        isUserDarkMode && !isMoneyMapTenant
          ? "border-gray-200/80 bg-white/95"
          : "border-gray-100 bg-gray-50/50"
      )
  const mathapexDesktopNavLinkClass = cn(mathapexNavLink, navLinkMuted)
  const mathapexDesktopNavLinkDenseClass = cn(mathapexNavLinkDense, navLinkMuted)
  const mathapexDesktopNavDropdownClass = cn(
    "flex items-center gap-1",
    mathapexNavLink,
    navLinkMuted
  )
  const mathapexDesktopNavWrapClass = cn(mathapexNavWrap)
  const activeDesktopNavLinkClass = mathapexTenant ? mathapexDesktopNavLinkClass : defaultDesktopNavLinkClass
  const activeDesktopNavDropdownClass = mathapexTenant ? mathapexDesktopNavDropdownClass : defaultDesktopNavDropdownClass
  const activeDesktopNavWrapClass = mathapexTenant ? mathapexDesktopNavWrapClass : gtDesktopNavWrapClass
  const defaultLogoSize = isEmbryobloomTenant ? 52 : 44
  const logoSize = parseTenantLogoSizePx(sc?.navbar_logo_size, defaultLogoSize)
  const parsedBrandFontSize = Number.parseInt(sc?.navbar_brand_font_size || "", 10)
  const brandFontSize = Number.isFinite(parsedBrandFontSize) ? Math.min(48, Math.max(12, parsedBrandFontSize)) : 20
  const mathapexMeasureRef = useRef<HTMLDivElement>(null)
  const mathapexCompactMeasureRef = useRef<HTMLDivElement>(null)
  const mathapexDenseMeasureRef = useRef<HTMLDivElement>(null)
  const mathapexActionsMeasureRef = useRef<HTMLDivElement>(null)
  const mathapexLogoRef = useRef<HTMLDivElement>(null)
  const mathapexCollapseDeps = [
    locale,
    coursesPageEnabled,
    instructorsEnabled,
    isLoggedIn,
    user?.name,
    landingNavPages.length,
    mathapexResourceNavLinks.length,
    storeEnabled,
    storePageEnabled,
    plansPageEnabled,
    subscriptionsFeatureEnabled,
    eventsPageEnabled,
    eventsFeatureEnabled,
    themeCtx?.config?.enabled_features?.community,
    showLanguageSwitcher,
    siteName,
    logoSize,
    brandFontSize,
  ]
  const {
    containerRef: mathapexNavContainerRef,
    collapsed: mathapexNavCollapsed,
    hideAbout: mathapexHideAbout,
    dense: mathapexNavDense,
    mode: mathapexNavMode,
    ready: mathapexNavReady,
    thresholdPx: mathapexNavThresholdPx,
  } = useContentNavCollapse(
    mathapexMeasureRef,
    {
      enabled: mathapexTenant,
      compactMeasureRef: mathapexCompactMeasureRef,
      denseMeasureRef: mathapexDenseMeasureRef,
      logoRef: mathapexLogoRef,
      actionsMeasureRef: mathapexActionsMeasureRef,
      rowGapPx: 8,
      bufferPx: 0,
    },
    mathapexCollapseDeps,
  )
  const mathapexLiveNavLinkClass = mathapexNavDense
    ? mathapexDesktopNavLinkDenseClass
    : activeDesktopNavLinkClass
  const desktopNavLinkClass = mathapexTenant ? mathapexLiveNavLinkClass : activeDesktopNavLinkClass
  const mathapexShowDesktopNav =
    mathapexTenant && (!mathapexNavReady || !mathapexNavCollapsed)
  const mathapexShowMobileNav =
    mathapexTenant && mathapexNavReady && mathapexNavCollapsed
  const navDesktopVisibleClass = mathapexTenant
    ? cn(mathapexShowDesktopNav ? "flex" : "hidden", "items-center")
    : "hidden lg:flex"
  const navMobileVisibleClass = mathapexTenant
    ? cn(mathapexShowMobileNav ? "flex" : "hidden", "items-center gap-1.5 shrink-0")
    : "flex items-center gap-1.5 shrink-0 lg:hidden"
  const useCenteredDesktopNav = !mathapexTenant
  const parsedBrandFontWeight = Number.parseInt(sc?.navbar_brand_font_weight || "", 10)
  const brandFontWeight = Number.isFinite(parsedBrandFontWeight) ? Math.min(900, Math.max(300, parsedBrandFontWeight)) : 700
  const brandSubtitleClassName = manaraTenant
    ? locale === "en"
      ? "text-[8px] sm:text-[9px] font-medium text-primary uppercase tracking-[0.08em] leading-tight max-w-[14rem] sm:max-w-[18rem]"
      : "text-[9px] sm:text-[10px] font-medium text-primary tracking-[0.06em] leading-tight max-w-[14rem] sm:max-w-[18rem]"
    : "text-[10px] font-medium text-medex-red uppercase tracking-[0.15em]"
  useEffect(() => setMounted(true), [])

  useEffect(() => {
    const ctrl = new AbortController()
    const tid = setTimeout(() => ctrl.abort(), 12000)
    const headers: Record<string, string> = {}
    if (typeof window !== "undefined") headers["X-Tenant-Host"] = window.location.host
    fetch(`${getApiBase()}/settings/categories?service=platform`, { signal: ctrl.signal, headers })
        .then((r) => r.json())
        .then((json) => {
          if (json.success && Array.isArray(json.data)) setCategories(json.data)
        })
        .catch(() => {})
        .finally(() => clearTimeout(tid))
    return () => {
      clearTimeout(tid)
      ctrl.abort()
    }
  }, [])

  useEffect(() => {
    const ctrl = new AbortController()
    const tid = setTimeout(() => ctrl.abort(), 12000)
    const headers: Record<string, string> = {}
    if (typeof window !== "undefined") headers["X-Tenant-Host"] = window.location.host
    fetch(`${getApiBase()}/content/pages/nav`, { signal: ctrl.signal, headers })
      .then((r) => r.json())
      .then((json) => {
        if (json.success && Array.isArray(json.data)) {
          setLandingNavPages(
            json.data.filter((p: NavLandingPage) => typeof p.slug === "string" && p.slug.trim().length > 0)
          )
        }
      })
      .catch(() => {})
      .finally(() => clearTimeout(tid))
    return () => {
      clearTimeout(tid)
      ctrl.abort()
    }
  }, [])

  useEffect(() => {
    const checkStore = () => {
      if (typeof window !== "undefined") {
        setStoreEnabled(localStorage.getItem(STORE_ENABLED_KEY) === "true")
      }
    }
    const checkInstructors = () => {
      if (typeof window !== "undefined") {
        const val = localStorage.getItem(INSTRUCTORS_ENABLED_KEY)
        setInstructorsEnabled(val === "true")
      }
    }
    checkStore()
    checkInstructors()
    const ctrl = new AbortController()
    const tid = setTimeout(() => ctrl.abort(), 12000)
    Promise.all([
        fetch(`${getApiBase()}/settings/store-status`, { signal: ctrl.signal }).then((r) => r.json()),
        fetchInstructorsEnabledDeduped(),
      ]).then(([storeJson, instructorsEnabled]) => {
        if (storeJson?.success && storeJson?.data) {
          const enabled = storeJson.data.enabled === true
          setStoreEnabled(enabled)
          localStorage.setItem(STORE_ENABLED_KEY, String(enabled))
        }
        setInstructorsEnabled(instructorsEnabled)
      }).catch(() => {}).finally(() => clearTimeout(tid))
    const onStorage = () => { checkStore(); checkInstructors() }
    window.addEventListener("store-toggle", checkStore)
    window.addEventListener("instructors-toggle", checkInstructors)
    window.addEventListener("storage", onStorage)
    return () => {
      clearTimeout(tid)
      ctrl.abort()
      window.removeEventListener("store-toggle", checkStore)
      window.removeEventListener("instructors-toggle", checkInstructors)
      window.removeEventListener("storage", onStorage)
    }
  }, [])

  useEffect(() => {
    if (mathapexTenant && !mathapexNavCollapsed && isMobileMenuOpen) {
      setIsMobileMenuOpen(false)
    }
  }, [mathapexTenant, mathapexNavCollapsed, isMobileMenuOpen])

  useEffect(() => {
    const handleScroll = () => setIsScrolled(window.scrollY > 10)
    window.addEventListener("scroll", handleScroll, { passive: true })
    return () => window.removeEventListener("scroll", handleScroll)
  }, [])

  useEffect(() => {
    if (isMobileMenuOpen) {
      document.body.style.overflow = "hidden"
    } else {
      document.body.style.overflow = ""
    }
    return () => { document.body.style.overflow = "" }
  }, [isMobileMenuOpen])

  useEffect(() => {
    if (!isProfileOpen) return
    const close = () => setIsProfileOpen(false)
    document.addEventListener("click", close)
    return () => document.removeEventListener("click", close)
  }, [isProfileOpen])

  useEffect(() => {
    if (!categoriesOpen) return
    const close = () => setCategoriesOpen(false)
    document.addEventListener("click", close)
    return () => document.removeEventListener("click", close)
  }, [categoriesOpen])

  useEffect(() => {
    if (!landingNavOpenId) return
    const close = () => setLandingNavOpenId(null)
    document.addEventListener("click", close)
    return () => document.removeEventListener("click", close)
  }, [landingNavOpenId])

  const renderLandingNavLink = (link: { href: string; label: string; children?: { href: string; label: string }[] }, key: string) => {
    if (link.children?.length) {
      const open = landingNavOpenId === key
      return (
        <div key={key} className="relative" onClick={(e) => e.stopPropagation()}>
          <button
            onClick={() => setLandingNavOpenId(open ? null : key)}
            className={cn(
              gtDesktopNavDropdownClass,
              open ? "text-medex-red bg-white" : cn(navLinkMuted, "hover:text-medex-red", navLinkHoverBg)
            )}
          >
            {link.label}
            <ChevronDown className={cn("w-3.5 h-3.5 transition-transform", open && "rotate-180")} />
          </button>
          <AnimatePresence>
            {open && (
              <m.div
                initial={{ opacity: 0, y: -8 }}
                animate={{ opacity: 1, y: 0 }}
                exit={{ opacity: 0, y: -8 }}
                transition={{ duration: 0.15 }}
                className="absolute top-full mt-1 start-0 min-w-[240px] rounded-2xl border border-gray-200 bg-white shadow-xl overflow-hidden z-[100]"
              >
                <div className="py-2 max-h-[70vh] overflow-y-auto">
                  <Link
                    href={link.href}
                    onClick={() => setLandingNavOpenId(null)}
                    className="flex items-center gap-2 px-4 py-2.5 text-sm font-semibold text-medex-dark hover:bg-red-50 hover:text-medex-red transition-colors border-b border-gray-100"
                  >
                    {link.label}
                  </Link>
                  {link.children.map((child) => (
                    <Link
                      key={child.href}
                      href={child.href}
                      onClick={() => setLandingNavOpenId(null)}
                      className="flex items-center gap-2 px-4 py-2.5 ms-2 text-sm font-medium text-gray-500 hover:bg-red-50 hover:text-medex-red transition-colors"
                    >
                      <ChevronLeft className="w-3 h-3 text-gray-300" />
                      {child.label}
                    </Link>
                  ))}
                </div>
              </m.div>
            )}
          </AnimatePresence>
        </div>
      )
    }

    return (
      <Link
        key={key}
        href={link.href}
        className={gtDesktopNavLinkClass}
      >
        {link.label}
      </Link>
    )
  }

  const renderMathapexMeasureNavItems = (includeAbout: boolean, linkClass: string) => (
    <>
      <span className={linkClass}>{t("nav.home")}</span>
      {coursesPageEnabled && (
        <span className={linkClass}>{t("nav.courses")}</span>
      )}
      <span className={linkClass}>
        {mathapexNavLabel(MATHAPEX_TESTS_NAV_LINK, locale)}
      </span>
      {storeEnabled && storePageEnabled && (
        <span className={linkClass}>{t("nav.store")}</span>
      )}
      {/* Instructors hidden on MathApex home
      {instructorsEnabled && (
        <span className={linkClass}>{t("nav.instructors")}</span>
      )}
      */}
      {mathapexResourceNavLinks.map((link) => (
        <span key={link.href} className={linkClass}>
          {link.label}
        </span>
      ))}
      {/* Community hidden on MathApex home
      {(themeCtx?.isFeatureEnabled("community") ?? false) && (
        <span className={linkClass}>{t("nav.community")}</span>
      )}
      */}
      {eventsPageEnabled && eventsFeatureEnabled && (
        <span className={linkClass}>
          {locale === "ar" ? "الفعاليات" : "Events"}
        </span>
      )}
      {includeAbout && (
        <span className={linkClass}>{t("nav.aboutUs")}</span>
      )}
      {/* Plans hidden on MathApex home
      {plansPageEnabled && subscriptionsFeatureEnabled && (
        <span className={linkClass}>
          {locale === "ar" ? "الاشتراكات" : "Plans"}
        </span>
      )}
      */}
      <span className={linkClass}>{t("nav.contact")}</span>
      {landingNavLinks.map((link) => (
        <span key={`measure-${link.href}`} className={linkClass}>
          {link.label}
        </span>
      ))}
    </>
  )

  const renderMobileLandingNavLinks = (startDelay = 0.2) =>
    landingNavLinks.map((link, index) => {
      const delay = startDelay + index * 0.02
      if (link.children?.length) {
        return (
          <m.div key={link.href} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay }} className="space-y-0.5">
            <Link
              href={link.href}
              onClick={() => setIsMobileMenuOpen(false)}
              className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
            >
              {link.label}
            </Link>
            {link.children.map((child) => (
              <Link
                key={child.href}
                href={child.href}
                onClick={() => setIsMobileMenuOpen(false)}
                className="flex items-center gap-2 px-6 py-2.5 text-[14px] font-medium text-gray-500 rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
              >
                <ChevronLeft className="w-3 h-3" />
                {child.label}
              </Link>
            ))}
          </m.div>
        )
      }

      return (
        <m.div key={link.href} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay }}>
          <Link
            href={link.href}
            onClick={() => setIsMobileMenuOpen(false)}
            className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
          >
            {link.label}
          </Link>
        </m.div>
      )
    })

  const handleLogout = () => {
    logout()
    setIsProfileOpen(false)
    router.push("/")
  }

  const pathname =
    (routePathname || (typeof window !== "undefined" ? window.location.pathname.toLowerCase() : "")).toLowerCase()
  const dnesatPublicChrome =
    dnesatTenant &&
    !pathname.startsWith("/dashboard") &&
    !pathname.startsWith("/admin") &&
    !pathname.startsWith("/instructor") &&
    !pathname.startsWith("/teacher") &&
    !pathname.startsWith("/assistant") &&
    !pathname.startsWith("/parent") &&
    !pathname.startsWith("/super-admin") &&
    !pathname.startsWith("/learning")

  if (dnesatPublicChrome) {
    return <DnesatNavbarBridge transparentOverHero={pathname === "/" || pathname === ""} />
  }

  if (fahdmareySkin && isFahdmareyPublicRoute(pathname)) {
    return <FahdmareyNavbar />
  }

  return (
    <>
      {/* Top Bar */}
      {!isMoneyMapTenant && showNavbarTopBar && (
        <div className="hidden lg:block bg-medex-red text-white text-xs">
          <div className="container mx-auto px-4 sm:px-6 lg:px-8 flex items-center justify-between h-9">
            <div className="flex items-center gap-4">
              <a href={tenantPhone ? `tel:${tenantPhone}` : "#"} className="flex items-center gap-1.5 hover:text-white/80 transition-colors">
                <Phone className="w-3 h-3" />
                {tenantPhone || (tenantReady ? "-" : "...")}
              </a>
              <span className="text-white/40">|</span>
              <a href={tenantEmail ? `mailto:${tenantEmail}` : "#"} className="hover:text-white/80 transition-colors">
                {tenantEmail || (tenantReady ? "-" : "...")}
              </a>
            </div>
            <div className="flex items-center gap-3">
              <span className="text-white/70">
                {manaraTenant
                  ? manaraTenantCleanCopy(
                      siteContentLocaleText(sc, locale, "navbar_tagline", "navbar_tagline_en"),
                      "",
                      { tenantCfg: themeCtx?.config }
                    )
                  : siteContentLocaleText(sc, locale, "navbar_tagline", "navbar_tagline_en")}
              </span>
              {/* Always show language switcher if multiple languages are enabled */}
              {showLanguageSwitcher && (
                <>
                  <span className="text-white/40">|</span>
                  <button onClick={cycleLocale} className="flex items-center gap-1.5 hover:text-white/80 transition-colors font-medium">
                    <Globe className="w-3 h-3" />
                    {locale === "ar" ? "English" : "العربية"}
                  </button>
                </>
              )}
            </div>
          </div>
        </div>
      )}

      <m.header
        dir={dir}
        initial={mounted ? { y: -100 } : false}
        animate={mounted ? { y: 0 } : undefined}
        transition={{ type: "spring", stiffness: 300, damping: 30 }}
        className={cn(
          "sticky top-0 inset-x-0 z-50 transition-all duration-500",
          isMoneyMapTenant || isUserDarkMode
            ? "bg-[#0b1220]/95 backdrop-blur-xl border-b border-slate-700/70 shadow-sm"
            : isScrolled
              ? "bg-white/95 backdrop-blur-xl border-b border-gray-200/60 shadow-sm"
              : "bg-white border-b border-gray-100"
        )}
      >
        <div className="container mx-auto px-4 sm:px-6 lg:px-8">
          {mathapexTenant && (
            <>
              <div
                ref={mathapexMeasureRef}
                aria-hidden
                className="pointer-events-none fixed top-0 -left-[10000px] whitespace-nowrap opacity-0"
              >
                <div className={activeDesktopNavWrapClass}>
                  {renderMathapexMeasureNavItems(true, mathapexDesktopNavLinkClass)}
                </div>
              </div>
              <div
                ref={mathapexCompactMeasureRef}
                aria-hidden
                className="pointer-events-none fixed top-0 -left-[10000px] whitespace-nowrap opacity-0"
              >
                <div className={activeDesktopNavWrapClass}>
                  {renderMathapexMeasureNavItems(false, mathapexDesktopNavLinkClass)}
                </div>
              </div>
              <div
                ref={mathapexDenseMeasureRef}
                aria-hidden
                className="pointer-events-none fixed top-0 -left-[10000px] whitespace-nowrap opacity-0"
              >
                <div className={mathapexDesktopNavWrapClass}>
                  {renderMathapexMeasureNavItems(false, mathapexDesktopNavLinkDenseClass)}
                </div>
              </div>
              <div
                ref={mathapexActionsMeasureRef}
                aria-hidden
                className="pointer-events-none fixed top-0 -left-[10000px] flex items-center gap-2 whitespace-nowrap opacity-0"
              >
                <div className="h-10 w-10 shrink-0" />
                {showLanguageSwitcher && <div className="h-10 w-10 shrink-0" />}
                <div className="ms-1 flex items-center gap-2">
                  {isLoggedIn && user ? (
                    <div className="flex h-10 shrink-0 items-center gap-2.5 rounded-xl border border-gray-200 px-3 py-1.5">
                      <div className="h-8 w-8 shrink-0 rounded-lg" />
                      <span className="max-w-[100px] truncate text-sm font-semibold text-medex-dark">
                        {safeStr(user.name)}
                      </span>
                    </div>
                  ) : (
                    <>
                      <span className="inline-flex h-9 shrink-0 items-center px-3 text-xs font-medium text-gray-500">
                        {t("nav.login")}
                      </span>
                      <span className="inline-flex h-9 shrink-0 items-center gap-1.5 rounded-xl bg-medex-red px-4 text-xs font-semibold text-white">
                        <span className="inline-block h-3 w-3 shrink-0" aria-hidden />
                        {t("nav.register")}
                      </span>
                    </>
                  )}
                </div>
              </div>
            </>
          )}
          <nav
            role="navigation"
            aria-label={locale === "ar" ? "التنقل الرئيسي" : "Main navigation"}
            ref={mathapexTenant ? mathapexNavContainerRef : undefined}
            data-nav-collapse-mode={mathapexTenant ? mathapexNavMode : undefined}
            data-nav-collapse-threshold={mathapexTenant && mathapexNavThresholdPx ? mathapexNavThresholdPx : undefined}
            className={cn(
              "flex h-[68px] items-center justify-between lg:h-[76px]",
              useCenteredDesktopNav &&
                "lg:grid lg:grid-cols-[minmax(0,1fr)_auto_minmax(0,1fr)] lg:items-center lg:gap-4",
            )}
          >
            {useCenteredDesktopNav ? (
              <>
                <div className="flex min-w-0 flex-1 items-center lg:flex-none lg:justify-self-start">
                  <div className="shrink-0">
                    <Link href="/" className="flex items-center gap-2.5 group">
                      {tmceduTenant ? (
                        <m.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                          <TmceduBrandLogo
                            height={Math.round(logoSize * 0.72)}
                            src={tmceduCustomNavbarLogo ? logoSrc : undefined}
                            tone={isUserDarkMode && !isMoneyMapTenant ? "dark" : "light"}
                            priority
                          />
                        </m.div>
                      ) : (
                        <>
                          <LogoPreviewTrigger enabled={fahdmareyTenant} src={logoSrc} alt={siteName}>
                            <m.div
                              whileHover={{ scale: 1.05 }}
                              whileTap={{ scale: 0.95 }}
                              className="relative overflow-hidden rounded-xl shadow-md transition-shadow duration-300 group-hover:shadow-lg"
                              style={{ width: `${logoSize}px`, height: `${logoSize}px` }}
                            >
                              {showBranding ? (
                                <Image
                                  src={logoSrc}
                                  alt={siteName}
                                  fill
                                  className="object-contain"
                                  sizes={`${logoSize}px`}
                                />
                              ) : (
                                <div className="h-full w-full animate-pulse bg-gray-100" />
                              )}
                            </m.div>
                          </LogoPreviewTrigger>
                          <div className="hidden max-w-[220px] lg:block xl:max-w-[280px]">
                            <span
                              className={cn(
                                "font-medex block leading-tight tracking-tight line-clamp-2",
                                isUserDarkMode && !isMoneyMapTenant ? "text-white" : "text-medex-dark",
                              )}
                              style={{ fontSize: `${brandFontSize}px`, fontWeight: brandFontWeight }}
                            >
                              {showBranding ? siteName : "..."}
                            </span>
                            {brandSubtitle ? (
                              <span className={cn(brandSubtitleClassName, "line-clamp-1")}>
                                <TenantHighlightedText>{brandSubtitle}</TenantHighlightedText>
                              </span>
                            ) : null}
                          </div>
                        </>
                      )}
                    </Link>
                  </div>
                </div>

                <div className={cn(navDesktopVisibleClass, "min-w-0 lg:justify-self-center")}>
                  <div className={activeDesktopNavWrapClass}>
                {configuredNav ? (
                  <ConfiguredNavLinks
                    config={configuredNav}
                    locale={locale}
                    linkClassName={compactNavTenant ? gtDesktopNavLinkClass : desktopNavLinkClass}
                    dropdownClassName={compactNavTenant ? gtDesktopNavDropdownClass : activeDesktopNavDropdownClass}
                    navLinkMuted={navLinkMuted}
                    navLinkHoverBg={navLinkHoverBg}
                    categories={categories}
                    categoriesOpen={categoriesOpen}
                    setCategoriesOpen={setCategoriesOpen}
                    excludeCta
                    useCategoryHub={physicsCategoryHubNav}
                    pageConfig={themeCtx?.config?.pageConfig}
                  />
                ) : tmceduTenant ? (
                  <>
                    {tmcEduNavLinks.map((link) => (
                      <Link key={link.href} href={link.href} className={gtDesktopNavLinkClass}>
                        {link.label}
                      </Link>
                    ))}
                  </>
                ) : speakoraTenant ? (
                  <>
                    {speakoraNavLinks.map((link) => (
                      <Link key={link.href} href={link.href} className={gtDesktopNavLinkClass}>
                        {link.label}
                      </Link>
                    ))}
                  </>
                ) : goalsTargetsTenant ? (
                  <>
                    {goalsTargetsNavLinks.map((link) => (
                      <Link
                        key={link.href}
                        href={link.href}
                        className={gtDesktopNavLinkClass}
                      >
                        {link.label}
                      </Link>
                    ))}
                    {landingNavLinks.map((link) => renderLandingNavLink(link, link.href))}
                  </>
                ) : isMoneyMapTenant ? (
                  <>
                    {moneyMapNavLinks.map((link) =>
                      link.href === "/instructors" ? (
                        <FeatureGate key={link.href} feature="instructors">
                          <Link
                            href={link.href}
                            className={defaultDesktopNavLinkClass}
                          >
                            {link.label}
                          </Link>
                        </FeatureGate>
                      ) : (
                        <Link
                          key={link.href}
                          href={link.href}
                          className={defaultDesktopNavLinkClass}
                        >
                          {link.label}
                        </Link>
                      ),
                    )}
                    {landingNavLinks.map((link) => renderLandingNavLink(link, link.href))}
                  </>
                ) : (
                  <>
                    <Link href="/" className={desktopNavLinkClass}>
                      {t("nav.home")}
                    </Link>
                    {coursesPageEnabled && (
                      <Link href="/courses" className={desktopNavLinkClass}>
                        {t("nav.courses")}
                      </Link>
                    )}
                    {mathapexTenant && (
                      <Link href={MATHAPEX_TESTS_PATH} className={desktopNavLinkClass}>
                        {mathapexNavLabel(MATHAPEX_TESTS_NAV_LINK, locale)}
                      </Link>
                    )}
                    {!compactNavTenant && !mathapexTenant && categories.length > 0 && showCategoriesInHeader && (
                      <div className="relative" onClick={(e) => e.stopPropagation()}>
                        <button
                          onClick={() => setCategoriesOpen(!categoriesOpen)}
                          className={cn(
                            activeDesktopNavDropdownClass,
                            categoriesOpen ? "text-medex-red bg-white" : cn(navLinkMuted, "hover:text-medex-red", navLinkHoverBg)
                          )}
                        >
                          <Tag className="w-3.5 h-3.5 shrink-0" />
                          {t("nav.categories")}
                          <ChevronDown className={cn("w-3.5 h-3.5 shrink-0 transition-transform", categoriesOpen && "rotate-180")} />
                        </button>
                        <AnimatePresence>
                          {categoriesOpen && (
                            <m.div
                              initial={{ opacity: 0, y: -8 }}
                              animate={{ opacity: 1, y: 0 }}
                              exit={{ opacity: 0, y: -8 }}
                              transition={{ duration: 0.15 }}
                              className="absolute top-full mt-1 start-0 min-w-[260px] rounded-2xl border border-gray-200 bg-white shadow-xl overflow-hidden z-[100]"
                            >
                              <div className="py-2 max-h-[70vh] overflow-y-auto">
                                {categories.map((cat) => (
                                  <div key={cat.id} className="group/cat">
                                    {cat.children?.length ? (
                                      <>
                                        <div className="px-4 py-2.5 text-xs font-bold text-medex-red/60 uppercase tracking-wider">
                                          {cat.nameEn || cat.name}
                                        </div>
                                        {cat.children.map((sub) => (
                                          <Link
                                            key={sub.id}
                                            href={categoryBrowseHref(sub.slug, physicsCategoryHubNav, themeCtx?.config?.pageConfig)}
                                            onClick={() => setCategoriesOpen(false)}
                                            className="flex items-center gap-2 px-4 py-2.5 ms-4 text-sm font-medium text-gray-500 hover:bg-red-50 hover:text-medex-red transition-colors"
                                          >
                                            <ChevronLeft className="w-3 h-3 text-gray-300" />
                                            {sub.nameEn || sub.name}
                                          </Link>
                                        ))}
                                      </>
                                    ) : (
                                      <Link
                                        href={categoryBrowseHref(cat.slug, physicsCategoryHubNav, themeCtx?.config?.pageConfig)}
                                        onClick={() => setCategoriesOpen(false)}
                                        className="flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-gray-500 hover:bg-red-50 hover:text-medex-red transition-colors"
                                      >
                                        <Tag className="w-3.5 h-3.5 text-gray-300" />
                                        {cat.nameEn || cat.name}
                                      </Link>
                                    )}
                                  </div>
                                ))}
                              </div>
                            </m.div>
                          )}
                        </AnimatePresence>
                      </div>
                    )}
                    {!compactNavTenant && storeEnabled && storePageEnabled && (
                      <FeatureGate feature="store">
                        <Link href="/store" className={desktopNavLinkClass}>
                          {t("nav.store")}
                        </Link>
                      </FeatureGate>
                    )}
                    {!compactNavTenant && !mathapexTenant && instructorsEnabled && (
                      <FeatureGate feature="instructors">
                        <Link href="/instructors" className={desktopNavLinkClass}>
                          {t("nav.instructors")}
                        </Link>
                      </FeatureGate>
                    )}
                    {mathapexTenant &&
                      mathapexResourceNavLinks.map((link) => (
                        <Link
                          key={link.href}
                          href={link.href}
                          className={desktopNavLinkClass}
                          onClick={(e) => handleMathapexHashNavClick(link.href, e)}
                        >
                          {link.label}
                        </Link>
                      ))}
                    {!compactNavTenant && !mathapexTenant && (
                      <FeatureGate feature="community">
                        <Link href="/community" className={desktopNavLinkClass}>
                          {t("nav.community")}
                        </Link>
                      </FeatureGate>
                    )}
                    {!compactNavTenant && eventsPageEnabled && eventsFeatureEnabled && (
                      <FeatureGate feature="events_workshops">
                        <Link href="/events" className={desktopNavLinkClass}>
                          {locale === "ar" ? "الفعاليات" : "Events"}
                        </Link>
                      </FeatureGate>
                    )}
                    {!(mathapexTenant && mathapexHideAbout) && (
                    <Link href="/about" className={desktopNavLinkClass}>
                      {t("nav.aboutUs")}
                    </Link>
                    )}
                    {!mathapexTenant && plansPageEnabled && subscriptionsFeatureEnabled && (
                      <Link href="/plans" className={desktopNavLinkClass}>
                        {locale === "ar" ? "الاشتراكات" : "Plans"}
                      </Link>
                    )}
                    <Link href="/contact" className={desktopNavLinkClass}>
                      {t("nav.contact")}
                    </Link>
                    {landingNavLinks.map((link) => renderLandingNavLink(link, link.href))}
                  </>
                )}
              </div>
                </div>
              </>
            ) : (
              <>
                <div className="flex min-w-0 flex-1 items-center gap-2 lg:gap-3">
                  <div ref={mathapexLogoRef} className="shrink-0">
                    <Link href="/" className="flex shrink-0 items-center gap-2.5 group">
                      {tmceduTenant ? (
                        <m.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                          <TmceduBrandLogo
                            height={Math.round(logoSize * 0.72)}
                            src={tmceduCustomNavbarLogo ? logoSrc : undefined}
                            tone={isUserDarkMode && !isMoneyMapTenant ? "dark" : "light"}
                            priority
                          />
                        </m.div>
                      ) : (
                        <>
                          <LogoPreviewTrigger enabled={fahdmareyTenant} src={logoSrc} alt={siteName}>
                            <m.div
                              whileHover={{ scale: 1.05 }}
                              whileTap={{ scale: 0.95 }}
                              className="relative overflow-hidden rounded-xl shadow-md transition-shadow duration-300 group-hover:shadow-lg"
                              style={{ width: `${logoSize}px`, height: `${logoSize}px` }}
                            >
                              {showBranding ? (
                                <Image
                                  src={logoSrc}
                                  alt={siteName}
                                  fill
                                  className="object-contain"
                                  sizes={`${logoSize}px`}
                                />
                              ) : (
                                <div className="h-full w-full animate-pulse bg-gray-100" />
                              )}
                            </m.div>
                          </LogoPreviewTrigger>
                          <div className="hidden xl:block">
                            <span
                              className={cn(
                                "font-medex block leading-tight tracking-tight",
                                isUserDarkMode && !isMoneyMapTenant ? "text-white" : "text-medex-dark",
                              )}
                              style={{ fontSize: `${brandFontSize}px`, fontWeight: brandFontWeight }}
                            >
                              {showBranding ? siteName : "..."}
                            </span>
                            {brandSubtitle ? (
                              <span className={brandSubtitleClassName}>
                                <TenantHighlightedText>{brandSubtitle}</TenantHighlightedText>
                              </span>
                            ) : null}
                          </div>
                        </>
                      )}
                    </Link>
                  </div>

                  <div className="flex min-w-0 flex-1 items-center overflow-hidden">
                    <div className={cn(navDesktopVisibleClass, "shrink-0")}>
                      <div className={activeDesktopNavWrapClass}>
                        {configuredNav ? (
                          <ConfiguredNavLinks
                            config={configuredNav}
                            locale={locale}
                            linkClassName={compactNavTenant ? gtDesktopNavLinkClass : desktopNavLinkClass}
                            dropdownClassName={compactNavTenant ? gtDesktopNavDropdownClass : activeDesktopNavDropdownClass}
                            navLinkMuted={navLinkMuted}
                            navLinkHoverBg={navLinkHoverBg}
                            categories={categories}
                            categoriesOpen={categoriesOpen}
                            setCategoriesOpen={setCategoriesOpen}
                            excludeCta
                            useCategoryHub={physicsCategoryHubNav}
                            pageConfig={themeCtx?.config?.pageConfig}
                          />
                        ) : tmceduTenant ? (
                          <>
                            {tmcEduNavLinks.map((link) => (
                              <Link key={link.href} href={link.href} className={gtDesktopNavLinkClass}>
                                {link.label}
                              </Link>
                            ))}
                          </>
                        ) : speakoraTenant ? (
                          <>
                            {speakoraNavLinks.map((link) => (
                              <Link key={link.href} href={link.href} className={gtDesktopNavLinkClass}>
                                {link.label}
                              </Link>
                            ))}
                          </>
                        ) : goalsTargetsTenant ? (
                          <>
                            {goalsTargetsNavLinks.map((link) => (
                              <Link key={link.href} href={link.href} className={gtDesktopNavLinkClass}>
                                {link.label}
                              </Link>
                            ))}
                            {landingNavLinks.map((link) => renderLandingNavLink(link, link.href))}
                          </>
                        ) : isMoneyMapTenant ? (
                          <>
                            {moneyMapNavLinks.map((link) =>
                              link.href === "/instructors" ? (
                                <FeatureGate key={link.href} feature="instructors">
                                  <Link href={link.href} className={defaultDesktopNavLinkClass}>
                                    {link.label}
                                  </Link>
                                </FeatureGate>
                              ) : (
                                <Link key={link.href} href={link.href} className={defaultDesktopNavLinkClass}>
                                  {link.label}
                                </Link>
                              ),
                            )}
                            {landingNavLinks.map((link) => renderLandingNavLink(link, link.href))}
                          </>
                        ) : (
                          <>
                            <Link href="/" className={desktopNavLinkClass}>
                              {t("nav.home")}
                            </Link>
                            {coursesPageEnabled && (
                              <Link href="/courses" className={desktopNavLinkClass}>
                                {t("nav.courses")}
                              </Link>
                            )}
                            {!compactNavTenant && !mathapexTenant && categories.length > 0 && showCategoriesInHeader && (
                              <div className="relative" onClick={(e) => e.stopPropagation()}>
                                <button
                                  onClick={() => setCategoriesOpen(!categoriesOpen)}
                                  className={cn(
                                    activeDesktopNavDropdownClass,
                                    categoriesOpen ? "text-medex-red bg-white" : cn(navLinkMuted, "hover:text-medex-red", navLinkHoverBg),
                                  )}
                                >
                                  <Tag className="h-3.5 w-3.5 shrink-0" />
                                  {t("nav.categories")}
                                  <ChevronDown className={cn("h-3.5 w-3.5 shrink-0 transition-transform", categoriesOpen && "rotate-180")} />
                                </button>
                                <AnimatePresence>
                                  {categoriesOpen && (
                                    <m.div
                                      initial={{ opacity: 0, y: -8 }}
                                      animate={{ opacity: 1, y: 0 }}
                                      exit={{ opacity: 0, y: -8 }}
                                      transition={{ duration: 0.15 }}
                                      className="absolute top-full z-[100] mt-1 min-w-[260px] overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xl start-0"
                                    >
                                      <div className="max-h-[70vh] overflow-y-auto py-2">
                                        {categories.map((cat) => (
                                          <div key={cat.id} className="group/cat">
                                            {cat.children?.length ? (
                                              <>
                                                <div className="px-4 py-2.5 text-xs font-bold uppercase tracking-wider text-medex-red/60">
                                                  {cat.nameEn || cat.name}
                                                </div>
                                                {cat.children.map((sub) => (
                                                  <Link
                                                    key={sub.id}
                                                    href={categoryBrowseHref(sub.slug, physicsCategoryHubNav, themeCtx?.config?.pageConfig)}
                                                    onClick={() => setCategoriesOpen(false)}
                                                    className="ms-4 flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-gray-500 transition-colors hover:bg-red-50 hover:text-medex-red"
                                                  >
                                                    <ChevronLeft className="h-3 w-3 text-gray-300" />
                                                    {sub.nameEn || sub.name}
                                                  </Link>
                                                ))}
                                              </>
                                            ) : (
                                              <Link
                                                href={categoryBrowseHref(cat.slug, physicsCategoryHubNav, themeCtx?.config?.pageConfig)}
                                                onClick={() => setCategoriesOpen(false)}
                                                className="flex items-center gap-2 px-4 py-2.5 text-sm font-medium text-gray-500 transition-colors hover:bg-red-50 hover:text-medex-red"
                                              >
                                                <Tag className="h-3.5 w-3.5 text-gray-300" />
                                                {cat.nameEn || cat.name}
                                              </Link>
                                            )}
                                          </div>
                                        ))}
                                      </div>
                                    </m.div>
                                  )}
                                </AnimatePresence>
                              </div>
                            )}
                            {!compactNavTenant && storeEnabled && storePageEnabled && (
                              <FeatureGate feature="store">
                                <Link href="/store" className={desktopNavLinkClass}>
                                  {t("nav.store")}
                                </Link>
                              </FeatureGate>
                            )}
                            {!compactNavTenant && !mathapexTenant && instructorsEnabled && (
                              <FeatureGate feature="instructors">
                                <Link href="/instructors" className={desktopNavLinkClass}>
                                  {t("nav.instructors")}
                                </Link>
                              </FeatureGate>
                            )}
                            {mathapexResourceNavLinks.map((link) => (
                              <Link
                                key={link.href}
                                href={link.href}
                                className={desktopNavLinkClass}
                                onClick={(e) => handleMathapexHashNavClick(link.href, e)}
                              >
                                {link.label}
                              </Link>
                            ))}
                            {!compactNavTenant && (
                              <FeatureGate feature="community">
                                <Link href="/community" className={desktopNavLinkClass}>
                                  {t("nav.community")}
                                </Link>
                              </FeatureGate>
                            )}
                            {eventsPageEnabled && eventsFeatureEnabled && (
                              <FeatureGate feature="events_workshops">
                                <Link href="/events" className={desktopNavLinkClass}>
                                  {locale === "ar" ? "الفعاليات" : "Events"}
                                </Link>
                              </FeatureGate>
                            )}
                            {!(mathapexHideAbout) && (
                              <Link href="/about" className={desktopNavLinkClass}>
                                {t("nav.aboutUs")}
                              </Link>
                            )}
                            <Link href="/contact" className={desktopNavLinkClass}>
                              {t("nav.contact")}
                            </Link>
                            {landingNavLinks.map((link) => renderLandingNavLink(link, link.href))}
                          </>
                        )}
                      </div>
                    </div>
                  </div>
                </div>
              </>
            )}

            <div
              className={cn(
                navDesktopVisibleClass,
                "items-center gap-2 shrink-0",
                useCenteredDesktopNav && "lg:justify-self-end",
              )}
            >
              <ThemeModeToggle />
              {showLanguageSwitcher && (
                <m.button
                  whileHover={{ scale: 1.05 }}
                  whileTap={{ scale: 0.95 }}
                  onClick={cycleLocale}
                  className="flex items-center justify-center w-10 h-10 rounded-xl border border-gray-200 bg-gray-50 text-gray-500 transition-all hover:border-medex-red/30 hover:bg-red-50 hover:text-medex-red"
                  title={locale === "ar" ? "English" : "العربية"}
                >
                  <Globe className="w-[18px] h-[18px]" />
                </m.button>
              )}
              {!tmceduTenant && !mathapexTenant && (
                <Link href="/cart">
                  <m.div
                    whileHover={{ scale: 1.05 }}
                    whileTap={{ scale: 0.95 }}
                    className="relative flex items-center justify-center w-10 h-10 rounded-xl border border-gray-200 bg-gray-50 text-gray-500 transition-all hover:border-medex-red/30 hover:bg-red-50 hover:text-medex-red"
                  >
                    <ShoppingCart className="w-[18px] h-[18px]" />
                    {mounted && cartCount > 0 && (
                      <m.span
                        initial={{ scale: 0 }}
                        animate={{ scale: 1 }}
                        className="absolute -top-1.5 -end-1.5 flex h-5 w-5 items-center justify-center rounded-full bg-medex-red text-[10px] font-bold text-white shadow-lg"
                      >
                        {cartCount}
                      </m.span>
                    )}
                  </m.div>
                </Link>
              )}
              {configuredCtas.length > 0
                ? configuredCtas.map((cta) => (
                    <Link key={cta.id} href={cta.href || "/contact"}>
                      <Button
                        variant="outline"
                        size="sm"
                        className="rounded-xl border-gray-200 bg-white text-gray-600 hover:border-medex-red/30 hover:bg-red-50 hover:text-medex-red font-medium px-5 h-10"
                      >
                        {navItemLabel(cta, locale)}
                      </Button>
                    </Link>
                  ))
                : tmceduTenant && (
                <Link href={TMCEDU_CONTACT_NAV_LINK.href}>
                  <Button
                    variant="outline"
                    size="sm"
                    className="rounded-xl border-gray-200 bg-white text-gray-600 hover:border-medex-red/30 hover:bg-red-50 hover:text-medex-red font-medium px-5 h-10"
                  >
                    {tmcEduContactLabel}
                  </Button>
                </Link>
              )}
              {isLoggedIn && user ? (
                <div className="relative" onClick={(e) => e.stopPropagation()}>
                    <m.button
                      whileHover={{ scale: 1.02 }}
                      whileTap={{ scale: 0.98 }}
                      onClick={() => setIsProfileOpen(!isProfileOpen)}
                      className="flex items-center gap-2.5 rounded-xl border border-gray-200 bg-gray-50 px-3 py-1.5 transition-all hover:border-medex-red/30 hover:bg-red-50"
                    >
                      <div className="relative h-8 w-8 overflow-hidden rounded-lg ring-2 ring-medex-red/20">
                        <Image src={avatarSrc} alt={safeStr(user.name)} fill className="object-cover" />
                      </div>
                      <span className="text-sm font-semibold text-medex-dark max-w-[100px] truncate">{safeStr(user.name)}</span>
                      <ChevronDown className={cn("w-3.5 h-3.5 text-gray-400 transition-transform", isProfileOpen && "rotate-180")} />
                    </m.button>

                    <AnimatePresence>
                      {isProfileOpen && (
                        <m.div
                          initial={{ opacity: 0, y: 8, scale: 0.95 }}
                          animate={{ opacity: 1, y: 0, scale: 1 }}
                          exit={{ opacity: 0, y: 8, scale: 0.95 }}
                          transition={{ duration: 0.15 }}
                          className="absolute top-full end-0 mt-2 w-56 overflow-hidden rounded-2xl border border-gray-200 bg-white shadow-xl"
                        >
                          <div className="border-b border-gray-100 px-4 py-3">
                            <p className="text-sm font-bold text-medex-dark truncate">{safeStr(user.name)}</p>
                            <p className="text-xs text-gray-400 truncate">{user.email}</p>
                          </div>
                          <div className="py-1.5">
                            <Link
                              href={profileLandingPath}
                              onClick={() => setIsProfileOpen(false)}
                              className="flex items-center gap-3 px-4 py-2.5 text-sm font-medium text-gray-600 hover:bg-red-50 hover:text-medex-red transition-colors"
                            >
                              <LayoutDashboard className="w-4 h-4" />
                              {studentNavHome ? (locale === "ar" ? "الرئيسية" : "Home") : t("nav.dashboard")}
                            </Link>
                            <Link
                              href={hydrated ? getMyCoursesPath(user?.role) : "/dashboard/courses"}
                              onClick={() => setIsProfileOpen(false)}
                              className="flex items-center gap-3 px-4 py-2.5 text-sm font-medium text-gray-600 hover:bg-red-50 hover:text-medex-red transition-colors"
                            >
                              <User className="w-4 h-4" />
                              {t("nav.myCourses")}
                            </Link>
                          </div>
                          <div className="border-t border-gray-100 py-1.5">
                            <button
                              onClick={handleLogout}
                              className="flex w-full items-center gap-3 px-4 py-2.5 text-sm font-medium text-red-500 hover:bg-red-50 transition-colors"
                            >
                              <LogOut className="w-4 h-4" />
                              {t("nav.logout")}
                            </button>
                          </div>
                        </m.div>
                      )}
                    </AnimatePresence>
                  </div>
                ) : (
                  <>
                    <Link href="/login">
                      <Button variant="ghost" size="sm" className="rounded-xl text-gray-500 hover:text-medex-red hover:bg-red-50 font-medium px-5 h-10">
                        {t("nav.login")}
                      </Button>
                    </Link>
                    {!tmceduTenant && (
                      <Link href="/register">
                        <m.div whileHover={{ scale: 1.02 }} whileTap={{ scale: 0.98 }}>
                          <Button size="sm" className="relative overflow-hidden rounded-xl bg-medex-red text-white shadow-lg shadow-red-500/20 hover:bg-medex-red-dark transition-all font-semibold px-6 h-10 gap-2">
                            <Sparkles className="w-3.5 h-3.5" />
                            {t("nav.register")}
                            <m.div
                              className="absolute inset-0 bg-gradient-to-r from-transparent via-white/10 to-transparent"
                              animate={{ x: ["-100%", "200%"] }}
                              transition={{ duration: 3, repeat: Infinity, repeatDelay: 5, ease: "easeInOut" }}
                            />
                          </Button>
                        </m.div>
                      </Link>
                    )}
                  </>
                )}
            </div>

            <div className={cn(navMobileVisibleClass)}>
              <ThemeModeToggle />
              {showLanguageSwitcher && (
                <button
                  onClick={cycleLocale}
                  className="flex items-center justify-center w-10 h-10 rounded-xl text-gray-500 hover:text-medex-red hover:bg-red-50 transition-colors"
                  title={locale === "ar" ? "English" : "العربية"}
                >
                  <Globe className="w-5 h-5" />
                </button>
              )}
              {!tmceduTenant && !mathapexTenant && (
                <Link href="/cart">
                  <div className="relative flex items-center justify-center w-10 h-10 rounded-xl text-gray-500 hover:text-medex-red hover:bg-red-50 transition-colors">
                    <ShoppingCart className="w-5 h-5" />
                    {mounted && cartCount > 0 && (
                      <span className="absolute -top-0.5 -end-0.5 flex h-4 w-4 items-center justify-center rounded-full bg-medex-red text-[9px] font-bold text-white">{cartCount}</span>
                    )}
                  </div>
                </Link>
              )}
              {isLoggedIn && user && (
                <Link href={profileLandingPath}>
                  <div className="relative h-9 w-9 overflow-hidden rounded-xl ring-2 ring-medex-red/20">
                    <Image src={avatarSrc} alt={safeStr(user.name)} fill className="object-cover" />
                  </div>
                </Link>
              )}
              <m.button
                whileTap={{ scale: 0.9 }}
                onClick={() => setIsMobileMenuOpen(!isMobileMenuOpen)}
                className="flex items-center justify-center w-10 h-10 rounded-xl text-medex-dark hover:bg-gray-100 transition-colors"
                aria-label={locale === "ar" ? "فتح القائمة" : "Toggle menu"}
                aria-expanded={isMobileMenuOpen}
                aria-controls="mobile-main-menu"
              >
                <AnimatePresence mode="wait" initial={false}>
                  <m.div key={isMobileMenuOpen ? "close" : "open"} initial={{ rotate: -90, opacity: 0 }} animate={{ rotate: 0, opacity: 1 }} exit={{ rotate: 90, opacity: 0 }} transition={{ duration: 0.15 }}>
                    {isMobileMenuOpen ? <X className="w-6 h-6" /> : <Menu className="w-6 h-6" />}
                  </m.div>
                </AnimatePresence>
              </m.button>
            </div>
          </nav>
        </div>
      </m.header>

      {/* Mobile Menu */}
      <AnimatePresence>
        {isMobileMenuOpen && (
          <m.div dir={dir} initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} transition={{ duration: 0.2 }} className={cn("fixed inset-0 z-[60]", mathapexTenant ? (mathapexNavCollapsed ? "" : "hidden") : "lg:hidden")}>
            <m.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 bg-black/30 backdrop-blur-sm" onClick={() => setIsMobileMenuOpen(false)} />
            <m.div
              initial={{ x: -320, opacity: 0 }}
              animate={{ x: 0, opacity: 1 }}
              exit={{ x: -320, opacity: 0 }}
              transition={{ type: "spring", damping: 30, stiffness: 300 }}
              className="absolute inset-y-0 start-0 w-[320px] max-w-[85vw] bg-white flex flex-col shadow-2xl border-e border-gray-100"
            >
              <div className="flex items-center justify-between px-6 h-20 border-b border-gray-100">
                <Link href="/" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-2.5">
                  {tmceduTenant ? (
                    <TmceduBrandLogo
                      height={Math.max(32, Math.round(logoSize * 0.65))}
                      src={tmceduCustomNavbarLogo ? logoSrc : undefined}
                    />
                  ) : (
                    <>
                      <LogoPreviewTrigger enabled={fahdmareyTenant} src={logoSrc} alt={siteName}>
                        <div
                          className="relative overflow-hidden rounded-xl ring-1 ring-gray-200"
                          style={{
                            width: `${Math.max(28, Math.min(56, Math.round(logoSize * 0.8)))}px`,
                            height: `${Math.max(28, Math.min(56, Math.round(logoSize * 0.8)))}px`,
                          }}
                        >
                          {showBranding ? (
                            <Image src={logoSrc} alt={siteName} fill className="object-contain" sizes="36px" />
                          ) : (
                            <div className="h-full w-full animate-pulse bg-gray-100" />
                          )}
                        </div>
                      </LogoPreviewTrigger>
                      <span
                        className="text-medex-dark font-medex"
                        style={{ fontSize: `${Math.max(15, brandFontSize - 2)}px`, fontWeight: brandFontWeight }}
                      >
                        {showBranding ? siteName : "..."}
                      </span>
                    </>
                  )}
                </Link>
                <m.button whileTap={{ scale: 0.9 }} onClick={() => setIsMobileMenuOpen(false)} className="p-2 rounded-xl text-gray-400 hover:bg-gray-100 transition-colors">
                  <X className="w-5 h-5" />
                </m.button>
              </div>

              {isLoggedIn && user && (
                <div className="px-6 py-4 border-b border-gray-100 flex items-center gap-3">
                  <div className="relative h-11 w-11 overflow-hidden rounded-xl ring-2 ring-medex-red/20">
                    <Image src={avatarSrc} alt={safeStr(user.name)} fill className="object-cover" />
                  </div>
                  <div className="min-w-0 flex-1">
                    <p className="text-sm font-bold text-medex-dark truncate">{safeStr(user.name)}</p>
                    <p className="text-xs text-gray-400 truncate">{user.email}</p>
                  </div>
                </div>
              )}

              <div className="flex-1 overflow-y-auto px-4 py-6">
                <div className="space-y-1">
                  {configuredNav ? (
                    <ConfiguredMobileNavLinks
                      config={configuredNav}
                      locale={locale}
                      categories={categories}
                      excludeCta
                      useCategoryHub={physicsCategoryHubNav}
                      pageConfig={themeCtx?.config?.pageConfig}
                      onNavigate={() => setIsMobileMenuOpen(false)}
                    />
                  ) : tmceduTenant ? (
                    <>
                      {tmcEduNavLinks.map((link, index) => (
                        <m.div key={link.href} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 + index * 0.02 }}>
                          <Link
                            href={link.href}
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
                          >
                            {link.label}
                          </Link>
                        </m.div>
                      ))}
                    </>
                  ) : speakoraTenant ? (
                    <>
                      {speakoraNavLinks.map((link, index) => (
                        <m.div key={link.href} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 + index * 0.02 }}>
                          <Link
                            href={link.href}
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold rounded-xl transition-all"
                            style={{ color: SPEAKORA_COLORS.forest }}
                          >
                            {link.label}
                          </Link>
                        </m.div>
                      ))}
                    </>
                  ) : goalsTargetsTenant ? (
                    <>
                      {goalsTargetsNavLinks.map((link, index) => (
                        <m.div key={link.href} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 + index * 0.02 }}>
                          <Link
                            href={link.href}
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
                          >
                            {link.label}
                          </Link>
                        </m.div>
                      ))}
                      {renderMobileLandingNavLinks(0.1 + goalsTargetsNavLinks.length * 0.02)}
                    </>
                  ) : isMoneyMapTenant ? (
                    <>
                      {moneyMapNavLinks.map((link, index) => (
                        <m.div key={link.href} initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 + index * 0.02 }}>
                          {link.href === "/instructors" ? (
                            <FeatureGate feature="instructors">
                              <Link
                                href={link.href}
                                onClick={() => setIsMobileMenuOpen(false)}
                                className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
                              >
                                {link.label}
                              </Link>
                            </FeatureGate>
                          ) : (
                            <Link
                              href={link.href}
                              onClick={() => setIsMobileMenuOpen(false)}
                              className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
                            >
                              {link.label}
                            </Link>
                          )}
                        </m.div>
                      ))}
                      {renderMobileLandingNavLinks(0.1 + moneyMapNavLinks.length * 0.02)}
                    </>
                  ) : (
                    <>
                      <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.1 }}>
                        <Link href="/" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                          {t("nav.home")}
                        </Link>
                      </m.div>
                      {coursesPageEnabled && (
                        <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.12 }}>
                          <Link href="/courses" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                            {t("nav.courses")}
                          </Link>
                        </m.div>
                      )}
                      {mathapexTenant && (
                        <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.13 }}>
                          <Link href={MATHAPEX_TESTS_PATH} onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                            {mathapexNavLabel(MATHAPEX_TESTS_NAV_LINK, locale)}
                          </Link>
                        </m.div>
                      )}
                      {renderMobileLandingNavLinks(0.2)}
                    </>
                  )}
                  {!compactNavTenant && !isMoneyMapTenant && !mathapexTenant && categories.length > 0 && showCategoriesInHeader && (
                    <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.14 }}>
                      <div className="px-4 py-2 text-xs font-bold text-medex-red/50 uppercase tracking-wider">
                        {t("nav.categories")}
                      </div>
                      {categories.map((cat) => (
                        <div key={cat.id} className="space-y-0.5">
                          {cat.children?.length ? (
                            <>
                              <div className="px-4 py-1.5 text-xs font-semibold text-gray-400">
                                {cat.nameEn || cat.name}
                              </div>
                              {cat.children.map((sub) => (
                                <Link
                                  key={sub.id}
                                  href={categoryBrowseHref(sub.slug, physicsCategoryHubNav, themeCtx?.config?.pageConfig)}
                                  onClick={() => setIsMobileMenuOpen(false)}
                                  className="flex items-center gap-2 px-6 py-2.5 text-[14px] font-medium text-gray-500 rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
                                >
                                  <ChevronLeft className="w-3 h-3" />
                                  {sub.nameEn || sub.name}
                                </Link>
                              ))}
                            </>
                          ) : (
                            <Link
                              href={categoryBrowseHref(cat.slug, physicsCategoryHubNav, themeCtx?.config?.pageConfig)}
                              onClick={() => setIsMobileMenuOpen(false)}
                              className="flex items-center gap-3 px-4 py-3 text-[14px] font-medium text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
                            >
                              <Tag className="w-4 h-4 text-gray-300" />
                              {cat.nameEn || cat.name}
                            </Link>
                          )}
                        </div>
                      ))}
                    </m.div>
                  )}
                  {!compactNavTenant && !isMoneyMapTenant && storeEnabled && storePageEnabled && (
                    <FeatureGate feature="store">
                      <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.16 }}>
                        <Link href="/store" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                          {t("nav.store")}
                        </Link>
                      </m.div>
                    </FeatureGate>
                  )}
                  {!compactNavTenant && !isMoneyMapTenant && !mathapexTenant && instructorsEnabled && (
                    <FeatureGate feature="instructors">
                      <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.18 }}>
                        <Link href="/instructors" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                          {t("nav.instructors")}
                        </Link>
                      </m.div>
                    </FeatureGate>
                  )}
                  {mathapexTenant &&
                    mathapexResourceNavLinks.map((link, index) => (
                      <m.div
                        key={link.href}
                        initial={{ opacity: 0, x: -20 }}
                        animate={{ opacity: 1, x: 0 }}
                        transition={{ delay: 0.185 + index * 0.02 }}
                      >
                        <Link
                          href={link.href}
                          onClick={(e) => {
                            if (handleMathapexHashNavClick(link.href, e)) {
                              setIsMobileMenuOpen(false)
                            }
                          }}
                          className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all"
                        >
                          {link.label}
                        </Link>
                      </m.div>
                    ))}
                  {!compactNavTenant && !isMoneyMapTenant && (
                    <>
                      {!mathapexTenant && (
                      <FeatureGate feature="community">
                        <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.19 }}>
                          <Link href="/community" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                            {t("nav.community")}
                          </Link>
                        </m.div>
                      </FeatureGate>
                      )}
                      {eventsPageEnabled && eventsFeatureEnabled && (
                        <FeatureGate feature="events_workshops">
                          <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.2 }}>
                            <Link href="/events" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                              {locale === "ar" ? "الفعاليات والورش" : "Events & Workshops"}
                            </Link>
                          </m.div>
                        </FeatureGate>
                      )}
                      <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.21 }}>
                        <Link href="/about" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                          {t("nav.aboutUs")}
                        </Link>
                      </m.div>
                      {!mathapexTenant && plansPageEnabled && subscriptionsFeatureEnabled && (
                        <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.22 }}>
                          <Link href="/plans" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                            {locale === "ar" ? "الاشتراكات" : "Plans"}
                          </Link>
                        </m.div>
                      )}
                      <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.23 }}>
                        <Link href="/contact" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                          {t("nav.contact")}
                        </Link>
                      </m.div>
                    </>
                  )}
                  {!tmceduTenant && !mathapexTenant && (
                    <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.3 }}>
                      <Link href="/cart" onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                        <ShoppingCart className="w-5 h-5 text-gray-400" />
                        {t("nav.cart")}
                        {mounted && cartCount > 0 && <span className="ms-auto flex h-6 w-6 items-center justify-center rounded-full bg-medex-red text-xs font-bold text-white">{cartCount}</span>}
                      </Link>
                    </m.div>
                  )}
                  {isLoggedIn && (
                    <m.div initial={{ opacity: 0, x: -20 }} animate={{ opacity: 1, x: 0 }} transition={{ delay: 0.35 }}>
                      <Link href={profileLandingPath} onClick={() => setIsMobileMenuOpen(false)} className="flex items-center gap-3 px-4 py-3.5 text-[15px] font-semibold text-medex-dark rounded-xl hover:bg-red-50 hover:text-medex-red transition-all">
                        <LayoutDashboard className="w-5 h-5 text-gray-400" />
                        {studentNavHome ? (locale === "ar" ? "الرئيسية" : "Home") : t("nav.dashboard")}
                      </Link>
                    </m.div>
                  )}
                </div>
              </div>

              <div className="px-4 pb-28 pt-4 space-y-2.5 border-t border-gray-100">
                {isLoggedIn ? (
                  <Button onClick={() => { handleLogout(); setIsMobileMenuOpen(false) }} variant="outline" className="w-full justify-center h-12 rounded-xl border border-red-200 text-red-500 hover:bg-red-50 bg-transparent font-semibold gap-2">
                    <LogOut className="w-4 h-4" />
                    {t("nav.logout")}
                  </Button>
                ) : (
                  <>
                    {configuredCtas.length > 0
                      ? configuredCtas.map((cta) => (
                          <Link
                            key={cta.id}
                            href={cta.href || "/contact"}
                            onClick={() => setIsMobileMenuOpen(false)}
                            className="block"
                          >
                            <Button
                              variant="outline"
                              className="w-full justify-center h-12 rounded-xl border border-gray-200 text-medex-dark hover:bg-gray-50 bg-transparent font-semibold transition-all"
                            >
                              {navItemLabel(cta, locale)}
                            </Button>
                          </Link>
                        ))
                      : tmceduTenant && (
                      <Link href={TMCEDU_CONTACT_NAV_LINK.href} onClick={() => setIsMobileMenuOpen(false)} className="block">
                        <Button
                          variant="outline"
                          className="w-full justify-center h-12 rounded-xl border border-gray-200 text-medex-dark hover:bg-gray-50 bg-transparent font-semibold transition-all"
                        >
                          {tmcEduContactLabel}
                        </Button>
                      </Link>
                    )}
                    <Link href="/login" onClick={() => setIsMobileMenuOpen(false)} className="block">
                      <Button variant="outline" className="w-full justify-center h-12 rounded-xl border border-gray-200 text-medex-dark hover:bg-gray-50 bg-transparent font-semibold transition-all">
                        {t("nav.login")}
                      </Button>
                    </Link>
                    {!tmceduTenant && (
                      <Link href="/register" onClick={() => setIsMobileMenuOpen(false)} className="block">
                        <Button className="w-full justify-center h-12 rounded-xl bg-medex-red text-white shadow-lg shadow-red-500/20 font-semibold gap-2 hover:bg-medex-red-dark">
                          <Sparkles className="w-4 h-4" />
                          {t("nav.register")}
                        </Button>
                      </Link>
                    )}
                  </>
                )}
              </div>
            </m.div>
          </m.div>
        )}
      </AnimatePresence>
    </>
  )
}
