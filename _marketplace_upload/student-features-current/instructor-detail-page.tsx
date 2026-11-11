"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import { useParams } from "next/navigation"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { MobileBottomNav } from "@/components/app/mobile-bottom-nav"
import { CourseGridCard } from "@/components/app/course-grid-card"
import { EmptyState } from "@/components/app/empty-state"
import { PageLoader } from "@/components/app/page-loader"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { Star, Users, BookOpen, MessageCircle, Award, ArrowRight, Loader2 } from "lucide-react"
import {
  instructorsApi, chatApi, isAuthenticated, mediaUrl,
  type Instructor, type Course,
} from "@/lib/api"
import { useRouter } from "next/navigation"
import { useToast } from "@/hooks/use-toast"
import { MarketplaceBooking } from "@/components/marketplace-booking"

export default function InstructorDetailsPage() {
  const params = useParams()
  const id = params.id as string
  const router = useRouter()
  const { toast } = useToast()

  const [isDark, setIsDark] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [loading, setLoading] = useState(true)
  const [instructor, setInstructor] = useState<Instructor | null>(null)
  const [courses, setCourses] = useState<Course[]>([])
  const [startingChat, setStartingChat] = useState(false)
  const [introVideo, setIntroVideo] = useState("")

  useEffect(() => {
    setMounted(true)
    const dark =
      localStorage.getItem("theme") === "dark" ||
      (!localStorage.getItem("theme") && window.matchMedia("(prefers-color-scheme: dark)").matches)
    setIsDark(dark)

    Promise.all([
      instructorsApi.getById(id).catch(() => ({ success: false, data: null })),
      instructorsApi.getCourses(id, { perPage: 24 }).catch(() => ({ success: false, data: { data: [] } })),
    ]).then(([insRes, coursesRes]) => {
      if (insRes.success && insRes.data) setInstructor(insRes.data)
      if (coursesRes.success) {
        const d: any = coursesRes.data
        setCourses(Array.isArray(d) ? d : d?.data || [])
      }
    }).finally(() => setLoading(false))
    fetch(`/api/trainers/${id}`).then((res) => res.json()).then((body) => {
      const video = body?.data?.intro_video_url
      if (video) setIntroVideo(String(video))
    }).catch(() => undefined)
  }, [id])

  useEffect(() => {
    if (!mounted) return
    if (isDark) document.documentElement.classList.add("dark")
    else document.documentElement.classList.remove("dark")
  }, [isDark, mounted])

  const startChat = async () => {
    if (!isAuthenticated()) {
      router.push(`/login?redirect=/instructors/${id}`)
      return
    }
    setStartingChat(true)
    try {
      const res = await chatApi.createConversation(id)
      const conv: any = res.data
      if (res.success && conv?.id) router.push(`/dashboard/chat/${conv.id}`)
      else router.push("/dashboard/chat")
    } catch (err: any) {
      toast({ title: "تعذر بدء المحادثة", description: err?.message, variant: "destructive" })
    } finally {
      setStartingChat(false)
    }
  }

  if (!mounted) return null

  return (
    <main dir="rtl" className="min-h-screen bg-muted/20 pb-24 lg:pb-0">
      <Navbar isDark={isDark} setIsDark={setIsDark} />

      {loading ? (
        <PageLoader />
      ) : !instructor ? (
        <div className="container mx-auto px-4 py-24">
          <EmptyState icon={Users} title="المدرس غير موجود" actionLabel="كل المدرسين" actionHref="/instructors" />
        </div>
      ) : (
        <>
          {/* Hero */}
          <div className="bg-gradient-to-l from-primary via-[#0B5960] to-[#06262A] text-white relative overflow-hidden">
            <div className="absolute -top-20 -left-20 w-72 h-72 bg-secondary/15 rounded-full blur-3xl" />
            <div className="container mx-auto px-4 py-12 relative">
              <div className="flex flex-col sm:flex-row items-center sm:items-start gap-6">
                <Avatar className="h-28 w-28 border-4 border-white/20 shadow-2xl">
                  <AvatarImage src={mediaUrl(instructor.avatar)} />
                  <AvatarFallback className="bg-secondary text-secondary-foreground text-4xl font-black">
                    {instructor.name?.charAt(0) || "?"}
                  </AvatarFallback>
                </Avatar>
                <div className="flex-1 text-center sm:text-right space-y-3">
                  <div>
                    <h1 className="text-3xl font-black">{instructor.name}</h1>
                    {instructor.title && <p className="text-secondary font-medium mt-1">{instructor.title}</p>}
                  </div>
                  <div className="flex items-center gap-5 justify-center sm:justify-end text-sm text-white/80 flex-wrap">
                    <span className="flex items-center gap-1.5"><Star className="h-4 w-4 text-secondary fill-current" />{(instructor.rating ?? 0).toFixed(1)} ({instructor.reviewsCount ?? 0} تقييم)</span>
                    <span className="flex items-center gap-1.5"><Users className="h-4 w-4" />{instructor.studentsCount ?? 0} طالب</span>
                    <span className="flex items-center gap-1.5"><BookOpen className="h-4 w-4" />{instructor.coursesCount ?? courses.length} دورة</span>
                  </div>
                  <div className="pt-2">
                    <Button onClick={startChat} disabled={startingChat} className="rounded-xl bg-secondary text-secondary-foreground hover:bg-secondary/90 font-bold gap-2">
                      {startingChat ? <Loader2 className="h-4 w-4 animate-spin" /> : <MessageCircle className="h-4 w-4" />}
                      راسل المدرس
                    </Button>
                  </div>
                </div>
              </div>
            </div>
          </div>

          <section className="container mx-auto px-4 py-10 space-y-10">
            {introVideo ? (
              <Card className="overflow-hidden rounded-3xl border-none shadow-sm">
                <div className="aspect-video">
                  <iframe src={introVideo.includes("watch?v=") ? introVideo.replace("watch?v=", "embed/").split("&")[0] : introVideo.includes("youtu.be/") ? `https://www.youtube.com/embed/${introVideo.split("youtu.be/")[1].split("?")[0]}` : introVideo} className="h-full w-full" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowFullScreen title="فيديو المدرس" />
                </div>
              </Card>
            ) : null}
            {instructor.bio && (
              <Card className="border-none shadow-sm rounded-3xl bg-white dark:bg-card animate-fade-up">
                <CardContent className="p-6 text-right space-y-2">
                  <h2 className="font-bold flex items-center gap-2 flex-row-reverse"><Award className="h-5 w-5 text-secondary" />نبذة عن المدرس</h2>
                  <p className="text-sm text-muted-foreground leading-8">{instructor.bio}</p>
                </CardContent>
              </Card>
            )}

            <MarketplaceBooking trainerId={id} />

            <div className="text-center">
              <Link href="/instructors">
                <Button variant="ghost" className="gap-2 text-primary font-bold"><ArrowRight className="h-4 w-4" />كل المدرسين</Button>
              </Link>
            </div>
          </section>
        </>
      )}

      <Footer />
      <MobileBottomNav />
    </main>
  )
}
