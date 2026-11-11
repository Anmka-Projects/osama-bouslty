"use client"

import { useState, useEffect, useMemo } from "react"
import { m } from "framer-motion"
import { ArrowRight, GraduationCap } from "lucide-react"
import Link from "next/link"
import { Button } from "@/components/ui/button"
import { useI18n } from "@/lib/i18n"
import { useApi, api } from "@/hooks/use-api"
import CourseCard from "./course-card"
import { useThemeConfigOptional } from "@/components/providers/ThemeConfigProvider"
import { sectionSurfaceStyle } from "@/lib/section-surface-style"
import { resolveImageUrl, toSameOriginUploadSrc } from "@/lib/utils"
import { isManaraInstituteTenantConfig } from "@/lib/is-manara-institute-tenant"
import { manaraTenantCleanCopy } from "@/lib/manara-i18n-overrides"
import {
  isEmbryobloomAcademyConfig,
  isEmbryobloomAcademyHostname,
} from "@/lib/is-embryobloom-academy-tenant"
import { getCoursesBrowseHref } from "@/lib/tenant-theme"
import { siteContentLocaleTextStrict } from "@/lib/site-content-text"

interface PlatformCategory {
  id: string
  name: string
  nameEn?: string
  slug: string
  children?: { id: string; name: string; nameEn?: string; slug: string }[]
}

type HomeCourseCard = {
  id: string
  thumbnail: string
  titleAr: string
  titleEn: string
  instructorAr: string
  instructorEn: string
  instructorAvatar: string
  rating: number
  students: number
  price: number
  originalPrice: number
  priceText?: string | null
  currency?: string | null
  category: string
  level: string
  hours: number
  lessons: number
  sections: number
  updatedAt: string
  language: string
  descriptionAr: string
  descriptionEn: string
}

function toStringOrName(val: unknown): string {
  if (typeof val === "string") return val
  if (val && typeof val === "object" && "name" in val && typeof (val as { name?: unknown }).name === "string")
    return String((val as { name: string }).name)
  return ""
}

function getCategorySlug(val: unknown): string {
  if (typeof val === "string") return val
  if (val && typeof val === "object" && "slug" in val && typeof (val as { slug?: unknown }).slug === "string")
    return String((val as { slug: string }).slug)
  return toStringOrName(val) || ""
}

export default function CoursesSection() {
  const { t, dir, locale } = useI18n()
  const isAr = locale === "ar"
  const themeCtx = useThemeConfigOptional()
  const sc = themeCtx?.config?.siteContent
  const coursesBrowseHref = getCoursesBrowseHref(themeCtx?.config?.pageConfig)
  const manaraTenant = isManaraInstituteTenantConfig(themeCtx?.config)
  const { data: apiCourses, loading } = useApi(() => api.getFeaturedCourses())

  const [embryobloomHost, setEmbryobloomHost] = useState(() =>
    typeof window !== "undefined" ? isEmbryobloomAcademyHostname(window.location.hostname) : false
  )
  const isEmbryobloomTenant =
    embryobloomHost || isEmbryobloomAcademyConfig(themeCtx?.config)
  const [categories, setCategories] = useState<PlatformCategory[]>([])

  useEffect(() => {
    if (typeof window === "undefined") return
    setEmbryobloomHost(isEmbryobloomAcademyHostname(window.location.hostname))
  }, [])

  useEffect(() => {
    if (!isEmbryobloomTenant) return
    api
      .request<PlatformCategory[]>("/settings/categories?service=platform")
      .then((res) => {
        if (res.success && Array.isArray(res.data)) setCategories(res.data)
      })
      .catch(() => {})
  }, [isEmbryobloomTenant])

  const categoryCollator = useMemo(
    () => new Intl.Collator(locale === "ar" ? "ar" : "en", { sensitivity: "base", numeric: true }),
    [locale]
  )

  const categoryLabelForSlug = useMemo(() => {
    const map = new Map<string, string>()
    for (const c of categories) {
      map.set(c.slug, locale === "ar" ? c.name : (c.nameEn || c.name))
      if (c.children?.length) {
        for (const child of c.children) {
          map.set(
            child.slug,
            locale === "ar" ? `${c.name} › ${child.name}` : (child.nameEn || child.name)
          )
        }
      }
    }
    return (slug: string) => map.get(slug) || slug
  }, [categories, locale])

  const displayedCourses = useMemo((): HomeCourseCard[] => {
    if (!apiCourses || !Array.isArray(apiCourses) || apiCourses.length === 0) return []
    const mapped: HomeCourseCard[] = apiCourses.slice(0, 6).map((c: Record<string, unknown>) => {
      const instructorObj = c.instructor as { name?: string; avatar?: string } | undefined
      return {
        id: String(c.id ?? ""),
        thumbnail: (c.thumbnail as string) || "/course-1.png",
        titleAr: (c.titleAr as string) || (c.title as string) || "",
        titleEn: (c.titleEn as string) || (c.title as string) || "",
        instructorAr: toStringOrName(c.instructorAr) || (instructorObj?.name ?? "") || toStringOrName(c.instructor) || "",
        instructorEn: toStringOrName(c.instructorEn) || (instructorObj?.name ?? "") || toStringOrName(c.instructor) || "",
        instructorAvatar:
          toSameOriginUploadSrc(
            resolveImageUrl(
              (c.instructorAvatar as string) || (instructorObj?.avatar as string) || "",
              ""
            )
          ) || "/user-avatar.png",
        rating: Number(c.averageRating ?? c.rating ?? 4.5),
        students: Number(c.totalStudents ?? c.students ?? 0),
        price: Number(c.discountPrice ?? c.price ?? 0),
        originalPrice: Number(c.price ?? 0),
        priceText: (c.priceText as string) || null,
        currency: ((c.currency as string) || "").trim() || undefined,
        category:
          getCategorySlug(c.category) ||
          (typeof c.category === "string" ? c.category : toStringOrName(c.category)) ||
          "presentations",
        level: (c.level as string) || "beginner",
        hours: Number(c.duration ?? c.hours ?? 0),
        lessons:
          Number((c as { chaptersCount?: number; lessonsCount?: number }).lessonsCount ?? (c as { chaptersCount?: number }).chaptersCount ?? 0) * 3,
        sections: Number((c as { chaptersCount?: number }).chaptersCount ?? 0),
        updatedAt: (c.updatedAt as string) || "",
        language: (c.language as string) || "en",
        descriptionAr: (c.descriptionAr as string) || "",
        descriptionEn: (c.descriptionEn as string) || "",
      }
    })

    if (!isEmbryobloomTenant) return mapped

    return [...mapped].sort((a, b) => {
      const byCat = categoryCollator.compare(categoryLabelForSlug(a.category), categoryLabelForSlug(b.category))
      if (byCat !== 0) return byCat
      return categoryCollator.compare(isAr ? a.titleAr : a.titleEn, isAr ? b.titleAr : b.titleEn)
    })
  }, [apiCourses, isEmbryobloomTenant, categoryCollator, categoryLabelForSlug, isAr])

  const coursesTitleRaw = siteContentLocaleTextStrict(sc, locale, "courses_title", "courses_title_en")
  const coursesHeading = manaraTenant
    ? manaraTenantCleanCopy(coursesTitleRaw, "", { tenantCfg: themeCtx?.config })
    : coursesTitleRaw
  const coursesSubtitle = manaraTenant
    ? manaraTenantCleanCopy(
        siteContentLocaleTextStrict(sc, locale, "courses_subtitle", "courses_subtitle_en"),
        "",
        { tenantCfg: themeCtx?.config }
      )
    : siteContentLocaleTextStrict(sc, locale, "courses_subtitle", "courses_subtitle_en")
  const showCoursesHeader = Boolean(coursesHeading || coursesSubtitle)
  const isRtl = dir === "rtl"

  return (
    <section
      className="relative overflow-hidden bg-[var(--color-body-bg)] py-16 sm:py-24 lg:py-32"
      style={sectionSurfaceStyle(sc, "courses")}
    >
      <m.div
        className="pointer-events-none absolute end-[6%] top-[8%] hidden h-14 w-14 rounded-2xl border border-gray-200 bg-white shadow-md lg:flex items-center justify-center"
        style={{ willChange: "transform" }}
        animate={{ y: [0, -12, 0] }}
        transition={{ duration: 5, repeat: Infinity, ease: "easeInOut" }}
      >
        <GraduationCap className="h-6 w-6 text-medex-red/50" />
      </m.div>

      <div className="container relative mx-auto px-4">
        {showCoursesHeader ? (
          <div className="mb-14 flex w-full flex-col items-start gap-6 text-start sm:flex-row sm:items-end sm:justify-between sm:gap-8 lg:mb-16">
            <m.div
              initial={{ opacity: 0, y: 24 }}
              whileInView={{ opacity: 1, y: 0 }}
              viewport={{ once: true, margin: "-60px" }}
              transition={{ duration: 0.5 }}
              className="max-w-2xl"
            >
              {coursesHeading ? (
                <h2 className="mb-3 text-start text-3xl font-bold tracking-tight text-body-theme sm:text-4xl lg:text-5xl font-display">
                  {coursesHeading}
                </h2>
              ) : null}
              {coursesSubtitle ? (
                <p className="max-w-lg text-start text-base leading-relaxed text-body-theme-muted sm:text-lg">
                  {coursesSubtitle}
                </p>
              ) : null}
            </m.div>

            <m.div
              initial={{ opacity: 0, x: isRtl ? -20 : 20 }}
              whileInView={{ opacity: 1, x: 0 }}
              viewport={{ once: true }}
              transition={{ duration: 0.5, delay: 0.3 }}
              className="self-start"
            >
              <Button
                asChild
                className="group h-12 rounded-xl bg-medex-red px-7 text-sm font-semibold text-white shadow-lg shadow-red-500/20 transition-all hover:bg-medex-red-dark"
              >
                <Link href={coursesBrowseHref} className="flex items-center gap-2">
                  {isAr ? "عرض جميع الدورات" : "View All Courses"}
                  <ArrowRight
                    className={`h-4 w-4 transition-transform duration-300 group-hover:translate-x-0.5 ${
                      isRtl ? "rotate-180 group-hover:-translate-x-0.5" : ""
                    }`}
                  />
                </Link>
              </Button>
            </m.div>
          </div>
        ) : null}

        <div className="grid grid-cols-1 gap-6 sm:grid-cols-2 sm:gap-7 lg:grid-cols-3 lg:gap-8">
          {loading ? (
            <div className="col-span-full flex justify-center py-12">
              <div className="h-10 w-10 animate-spin rounded-full border-2 border-medex-red border-t-transparent" />
            </div>
          ) : displayedCourses.length === 0 ? (
            <div className="col-span-full text-center py-12 text-gray-400">
              {isAr ? "لا توجد دورات متاحة حالياً" : "No courses available yet"}
            </div>
          ) : displayedCourses.map((course, i) => (
            <m.div
              key={course.id}
              initial={{ opacity: 0, y: 40, scale: 0.97 }}
              whileInView={{ opacity: 1, y: 0, scale: 1 }}
              viewport={{ once: true, margin: "-40px" }}
              transition={{
                duration: 0.6,
                delay: i * 0.08,
                ease: [0.25, 0.46, 0.45, 0.94],
              }}
            >
              <CourseCard course={course} />
            </m.div>
          ))}
        </div>

        <m.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.5 }}
          className="mt-14 text-center lg:mt-16"
        >
          {!loading && displayedCourses.length > 0 && (
            <p className="mb-5 text-sm text-body-theme-muted">
              {isAr ? `عرض ${displayedCourses.length} دورة متاحة` : `Showing ${displayedCourses.length} available courses`}
            </p>
          )}
          <Button
            asChild
            variant="outline"
            className="group h-12 rounded-xl border border-[var(--color-body-text)]/20 px-8 text-sm font-semibold text-body-theme transition-all hover:border-[var(--color-primary)]/40 hover:bg-[color-mix(in_srgb,var(--color-primary)_10%,transparent)] hover:text-[var(--color-primary)] bg-[var(--color-body-bg)]"
          >
            <Link href={coursesBrowseHref} className="flex items-center gap-2">
              {isAr ? "استكشف جميع الدورات" : "Explore All Courses"}
              <ArrowRight
                className={`h-4 w-4 transition-transform duration-300 group-hover:translate-x-0.5 ${
                  isRtl ? "rotate-180 group-hover:-translate-x-0.5" : ""
                }`}
              />
            </Link>
          </Button>
        </m.div>
      </div>
    </section>
  )
}
