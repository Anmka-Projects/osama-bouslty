"use client"

import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { MobileBottomNav } from "@/components/app/mobile-bottom-nav"
import { CourseGridCard } from "@/components/app/course-grid-card"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Input } from "@/components/ui/input"
import { Skeleton } from "@/components/ui/skeleton"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Carousel, CarouselContent, CarouselItem, CarouselNext, CarouselPrevious, type CarouselApi } from "@/components/ui/carousel"
import {
  Bell, Search, PlayCircle, Star, ChevronLeft, BookOpen,
  GraduationCap, Sparkles, ArrowLeft,
} from "lucide-react"
import Image from "next/image"
import Link from "next/link"
import { useState, useEffect, useCallback } from "react"
import { useRouter } from "next/navigation"
import {
  homeApi, slidersApi, instructorsApi, enrollmentsApi,
  isAuthenticated, getStoredUser, mediaUrl,
  type Course, type Instructor, type Enrollment,
} from "@/lib/api"

/** Map the snake_case /api/home course shape to our Course type. */
function mapCourse(c: any): Course {
  return {
    id: c.id || c.slug,
    title: c.title,
    description: c.description,
    thumbnail: c.thumbnail || c.image,
    price: parseFloat(c.price) || 0,
    discountPrice: c.original_price && c.original_price !== c.price ? parseFloat(c.price) : undefined,
    level: c.level || "beginner",
    categoryId: c.category_id || c.categoryId || "",
    categoryName: c.category?.name || c.category_name || "",
    instructorId: c.instructor?.id || c.instructor_id || "",
    instructorName: c.instructor?.name || c.instructor_name || "",
    duration: c.duration_hours || c.duration || 0,
    lessonsCount: c.lessons_count || c.lessonsCount || 0,
    studentsCount: c.students_count || c.studentsCount || 0,
    rating: parseFloat(c.rating) || 0,
    reviewsCount: c.reviews_count || c.reviewsCount || 0,
    status: c.status || "published",
    isFeatured: c.is_featured ?? c.isFeatured ?? false,
    is_enrolled: c.is_enrolled ?? false,
  }
}

function mapTeacher(t: any): Instructor {
  return {
    id: t.id,
    name: t.name,
    title: t.title || t.titleEn || "مدرس",
    bio: t.bio,
    avatar: t.avatar || t.image,
    coursesCount: t.courses_count ?? t.coursesCount ?? 0,
    studentsCount: t.students_count ?? t.studentsCount ?? 0,
    rating: parseFloat(t.rating) || 0,
    reviewsCount: t.reviews_count ?? t.reviewsCount ?? 0,
  }
}

export default function Home() {
  const router = useRouter()
  const [isDark, setIsDark] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [loading, setLoading] = useState(true)
  const [userName, setUserName] = useState("")
  const [unread, setUnread] = useState(0)

  const [sliders, setSliders] = useState<any[]>([])
  const [spotVideos, setSpotVideos] = useState<any[]>([])
  const [teachers, setTeachers] = useState<Instructor[]>([])
  const [featured, setFeatured] = useState<Course[]>([])
  const [popular, setPopular] = useState<Course[]>([])
  const [continueLearning, setContinueLearning] = useState<any[]>([])
  const [query, setQuery] = useState("")
  const [carouselApi, setCarouselApi] = useState<CarouselApi>()
  const [slideIdx, setSlideIdx] = useState(0)

  useEffect(() => {
    setMounted(true)
    const dark =
      localStorage.getItem("theme") === "dark" ||
      (!localStorage.getItem("theme") && window.matchMedia("(prefers-color-scheme: dark)").matches)
    setIsDark(dark)

    const stored = getStoredUser()
    if (stored?.name) setUserName(stored.name)

    const load = async () => {
      const [homeRes, slidersRes, teachersRes, enrollRes] = await Promise.all([
        homeApi.get().catch(() => ({ success: false, data: null })),
        slidersApi.getAll().catch(() => ({ success: false, data: [] })),
        instructorsApi.getAll({ perPage: 10 }).catch(() => ({ success: false, data: { data: [] } })),
        isAuthenticated()
          ? enrollmentsApi.getMyEnrollments({ perPage: 6 }).catch(() => ({ success: false, data: { data: [] } }))
          : Promise.resolve({ success: false, data: { data: [] } }),
      ])

      const home: any = homeRes.success ? homeRes.data : null
      if (home) {
        setFeatured((home.featured_courses || home.featuredCourses || []).map(mapCourse))
        setPopular((home.popular_courses || home.popularCourses || []).map(mapCourse))
        setSpotVideos(home.home_spot_videos || home.spot_videos || [])
        setContinueLearning(home.continue_learning || [])
        if (home.user_summary?.unread_notifications) setUnread(home.user_summary.unread_notifications)
      }
      if (slidersRes.success) {
        const d: any = slidersRes.data
        setSliders(Array.isArray(d) ? d : d?.sliders || [])
      }
      if (teachersRes.success) {
        const d: any = teachersRes.data
        const list = Array.isArray(d) ? d : d?.teachers || d?.data || []
        setTeachers(list.map(mapTeacher))
      }
      if (enrollRes.success && continueLearning.length === 0) {
        const d: any = enrollRes.data
        const list = Array.isArray(d) ? d : d?.data || []
        if (list.length) {
          setContinueLearning(list.map((e: Enrollment) => ({
            id: e.courseId, title: e.course?.title, thumbnail: e.course?.thumbnail, progress: e.progress,
          })))
        }
      }
      setLoading(false)
    }
    load()
  }, [])

  useEffect(() => {
    if (!mounted) return
    if (isDark) document.documentElement.classList.add("dark")
    else document.documentElement.classList.remove("dark")
  }, [isDark, mounted])

  useEffect(() => {
    if (!carouselApi) return
    const onSelect = () => setSlideIdx(carouselApi.selectedScrollSnap())
    carouselApi.on("select", onSelect)
    const t = setInterval(() => carouselApi.scrollNext(), 6000)
    return () => { carouselApi.off("select", onSelect); clearInterval(t) }
  }, [carouselApi])

  const doSearch = (e: React.FormEvent) => {
    e.preventDefault()
    router.push(query.trim() ? `/instructors?search=${encodeURIComponent(query.trim())}` : "/instructors")
  }

  if (!mounted) return null

  const SectionHeader = ({ title, href }: { title: string; href?: string }) => (
    <div className="flex items-center justify-between">
      <h2 className="text-xl font-black">{title}</h2>
      {href && (
        <Link href={href} className="flex items-center gap-1 text-sm font-bold text-primary hover:underline">
          عرض الكل <ChevronLeft className="h-4 w-4" />
        </Link>
      )}
    </div>
  )

  return (
    <main dir="rtl" className="min-h-screen bg-background pb-28 lg:pb-0">
      <Navbar isDark={isDark} setIsDark={setIsDark} />

      {/* ===== App-style header band (greeting + search + bell) ===== */}
      <section className="relative overflow-hidden bg-gradient-to-br from-[#11545C] via-[#083B41] to-[#06262A] text-white">
        <div className="absolute -top-20 -left-20 w-72 h-72 bg-secondary/15 rounded-full blur-3xl" />
        <div className="absolute -bottom-24 -right-10 w-64 h-64 bg-primary/30 rounded-full blur-3xl" />
        <div className="container mx-auto px-4 pt-8 pb-24 relative">
          <div className="flex items-center justify-between gap-4">
            <div className="text-right">
              <p className="text-white/60 text-sm">أهلاً بك 👋</p>
              <h1 className="text-2xl font-black mt-0.5">{userName || "في بوصلتي"}</h1>
              <p className="text-white/70 text-sm mt-1">واصل رحلة تعلمك اليوم</p>
            </div>
            <Link href="/dashboard/notifications" className="relative shrink-0">
              <div className="h-12 w-12 rounded-2xl bg-white/10 backdrop-blur border border-white/15 flex items-center justify-center hover:bg-white/20 transition-colors">
                <Bell className="h-5 w-5" />
              </div>
              {unread > 0 && (
                <span className="absolute -top-1 -left-1 h-5 min-w-5 px-1 rounded-full bg-secondary text-secondary-foreground text-[10px] font-black flex items-center justify-center">
                  {unread}
                </span>
              )}
            </Link>
          </div>

          {/* Search — navigates to /courses */}
          <form onSubmit={doSearch} className="mt-6 relative max-w-xl">
            <Input
              value={query}
              onChange={(e) => setQuery(e.target.value)}
              placeholder="ابحث عن دورة أو مدرس..."
              className="h-14 rounded-2xl bg-white/10 border-white/15 text-white placeholder:text-white/50 pl-12 text-right backdrop-blur"
            />
            <button type="submit" className="absolute left-2 top-1/2 -translate-y-1/2 h-10 w-10 rounded-xl bg-secondary text-secondary-foreground flex items-center justify-center hover:opacity-90 transition-opacity">
              <Search className="h-5 w-5" />
            </button>
          </form>
        </div>
      </section>

      {/* ===== Promo slider — overlaps the header like the app ===== */}
      <section className="container mx-auto px-4 -mt-14 relative z-10">
        {loading ? (
          <Skeleton className="h-48 sm:h-64 rounded-3xl" />
        ) : sliders.length > 0 ? (
          <div className="relative">
            <Carousel setApi={setCarouselApi} opts={{ direction: "rtl", loop: true }} className="w-full">
              <CarouselContent>
                {sliders.map((s: any, i: number) => {
                  const img = mediaUrl(s.image || s.imageUrl || s.banner || s.thumbnail)
                  const href = s.linkUrl || s.link_url || (s.courseId ? `/courses/${s.courseId}` : s.course_id ? `/courses/${s.course_id}` : null)
                  const Slide = (
                    <div className="relative h-48 sm:h-64 rounded-3xl overflow-hidden bg-gradient-to-l from-primary/80 to-[#06262A]">
                      {img && <Image src={img} alt={s.title || "slide"} fill className="object-cover" />}
                      <div className="absolute inset-0 bg-gradient-to-l from-black/60 via-black/20 to-transparent" />
                      <div className="absolute bottom-0 right-0 p-5 text-white text-right">
                        {s.title && <h3 className="font-black text-lg sm:text-2xl line-clamp-1">{s.title}</h3>}
                        {(s.subtitle || s.description) && (
                          <p className="text-white/80 text-xs sm:text-sm mt-1 line-clamp-2 max-w-md">{s.subtitle || s.description}</p>
                        )}
                      </div>
                    </div>
                  )
                  return (
                    <CarouselItem key={s.id || i}>
                      {href ? <Link href={href}>{Slide}</Link> : Slide}
                    </CarouselItem>
                  )
                })}
              </CarouselContent>
              <CarouselPrevious className="hidden sm:flex left-4 right-auto" />
              <CarouselNext className="hidden sm:flex left-14 right-auto" />
            </Carousel>
            {sliders.length > 1 && (
              <div className="flex justify-center gap-1.5 mt-3">
                {sliders.map((_, i) => (
                  <span key={i} className={`h-1.5 rounded-full transition-all ${i === slideIdx ? "w-6 bg-secondary" : "w-1.5 bg-muted-foreground/30"}`} />
                ))}
              </div>
            )}
          </div>
        ) : (
          // Fallback promo card when there are no sliders
          <div className="relative h-48 sm:h-64 rounded-3xl overflow-hidden bg-gradient-to-l from-primary to-[#0B5960] flex items-center">
            <div className="absolute -left-10 -top-10 w-56 h-56 bg-secondary/20 rounded-full blur-3xl" />
            <div className="p-8 sm:p-10 text-white text-right relative space-y-3">
              <Badge className="bg-secondary text-secondary-foreground border-none gap-1"><Sparkles className="h-3 w-3" />بوصلتي</Badge>
              <h3 className="font-black text-2xl sm:text-3xl">تعلّم بذكاء مع أفضل المدرسين</h3>
              <p className="text-white/70 text-sm">جلسات مباشرة وباقات مع المدرس، وتحجز الموعد من هنا.</p>
              <Link href="/instructors"><Button className="rounded-xl bg-secondary text-secondary-foreground hover:bg-secondary/90 font-bold mt-2">احجز جلسة</Button></Link>
            </div>
          </div>
        )}
      </section>

      <div className="container mx-auto px-4 py-10 space-y-12">

        {/* ===== Home spot videos row ===== */}
        {spotVideos.length > 0 && (
          <section className="space-y-4">
            <SectionHeader title="فيديوهات مميزة" />
            <div className="flex gap-4 overflow-x-auto pb-2 snap-x [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {spotVideos.map((v: any, i: number) => {
                const thumb = mediaUrl(v.thumbnail || v.image || v.poster)
                const href = v.video_url || v.url || v.link || "#"
                return (
                  <a key={v.id || i} href={href} target={href !== "#" ? "_blank" : undefined} rel="noopener noreferrer"
                    className="group snap-start shrink-0 w-56 sm:w-64">
                    <div className="relative aspect-video rounded-2xl overflow-hidden bg-gradient-to-br from-primary/20 to-secondary/20">
                      {thumb && <Image src={thumb} alt={v.title || "video"} fill className="object-cover transition-transform duration-500 group-hover:scale-105" />}
                      <div className="absolute inset-0 bg-black/30 flex items-center justify-center">
                        <div className="h-12 w-12 rounded-full bg-white/20 backdrop-blur flex items-center justify-center group-hover:scale-110 transition-transform">
                          <PlayCircle className="h-7 w-7 text-white" />
                        </div>
                      </div>
                      {v.duration && <Badge className="absolute bottom-2 left-2 bg-black/60 text-white border-none text-[10px]">{v.duration}</Badge>}
                    </div>
                    <p className="mt-2 text-sm font-bold line-clamp-1 text-right">{v.title || "فيديو"}</p>
                  </a>
                )
              })}
            </div>
          </section>
        )}

        {/* ===== Teachers slider ===== */}
        <section className="space-y-4">
          <SectionHeader title="احجز جلسة مع مدرب" href="/instructors" />
          {loading ? (
            <div className="flex gap-5 overflow-hidden">
              {Array.from({ length: 6 }).map((_, i) => (
                <div key={i} className="flex flex-col items-center gap-2 shrink-0">
                  <Skeleton className="h-20 w-20 rounded-full" />
                  <Skeleton className="h-3 w-16 rounded" />
                </div>
              ))}
            </div>
          ) : (
            <div className="flex gap-5 overflow-x-auto pb-2 snap-x [-ms-overflow-style:none] [scrollbar-width:none] [&::-webkit-scrollbar]:hidden">
              {teachers.map((t) => (
                <Link key={t.id} href={`/instructors/${t.id}`} className="group snap-start shrink-0 w-24 text-center">
                  <div className="relative mx-auto w-20 h-20">
                    <Avatar className="h-20 w-20 border-4 border-card shadow-md group-hover:scale-105 transition-transform">
                      <AvatarImage src={mediaUrl(t.avatar)} />
                      <AvatarFallback className="bg-gradient-to-br from-primary to-[#083B41] text-white text-2xl font-black">
                        {t.name?.charAt(0) || "?"}
                      </AvatarFallback>
                    </Avatar>
                    {(t.rating ?? 0) > 0 && (
                      <span className="absolute -bottom-1 left-1/2 -translate-x-1/2 bg-secondary text-secondary-foreground text-[10px] font-black px-2 py-0.5 rounded-full flex items-center gap-0.5 shadow">
                        <Star className="h-2.5 w-2.5 fill-current" />{t.rating?.toFixed(1)}
                      </span>
                    )}
                  </div>
                  <p className="mt-2.5 text-xs font-bold line-clamp-1">{t.name}</p>
                  <p className="text-[10px] text-muted-foreground line-clamp-1">{t.title}</p>
                </Link>
              ))}
            </div>
          )}
        </section>

        {/* ===== CTA band ===== */}
        <section className="relative overflow-hidden rounded-3xl bg-gradient-to-l from-[#11545C] via-[#083B41] to-[#06262A] text-white">
          <div className="absolute -top-16 -right-16 w-64 h-64 bg-secondary/15 rounded-full blur-3xl" />
          <div className="relative p-8 sm:p-12 flex flex-col md:flex-row items-center justify-between gap-6">
            <div className="text-right space-y-3">
              <h2 className="text-2xl sm:text-3xl font-black">احجز جلستك مع المدرب</h2>
              <p className="text-white/70 text-sm sm:text-base flex items-center gap-2 justify-end">
                جلسة واحدة أو باقة جلسات، وتختار الموعد المناسب
                <GraduationCap className="h-5 w-5 text-secondary" />
              </p>
            </div>
            <Link href="/instructors">
              <Button className="rounded-2xl bg-secondary text-secondary-foreground hover:bg-secondary/90 font-black px-10 h-13 text-lg gap-2 shadow-xl shadow-secondary/20">
                {isAuthenticated() ? "اختار مدرب" : "ابدأ الحجز"}
                <ArrowLeft className="h-5 w-5" />
              </Button>
            </Link>
          </div>
        </section>
      </div>

      <Footer />
      <MobileBottomNav />
    </main>
  )
}
