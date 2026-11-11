"use client"

import { AppShell } from "@/components/app/app-shell"
import { CourseGridCard } from "@/components/app/course-grid-card"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardHeader, CardTitle } from "@/components/ui/card"
import { Progress } from "@/components/ui/progress"
import { Badge } from "@/components/ui/badge"
import {
  BookOpen, GraduationCap, Clock, PlayCircle, Trophy, Bell,
  FileQuestion, Radio, MessageCircle, ClipboardList, Bookmark, QrCode,
  TrendingUp, Settings,
  CalendarDays,
} from "lucide-react"
import Image from "next/image"
import Link from "next/link"
import { useState, useEffect } from "react"
import {
  enrollmentsApi, certificatesApi, progressApi, liveApi, mediaUrl,
} from "@/lib/api"
import type { Enrollment, Certificate, Progress as ProgressType, LiveSession } from "@/lib/api"

const QUICK_LINKS = [
  { label: "حجوزاتي", icon: CalendarDays, href: "/dashboard/bookings", color: "bg-teal-100 text-teal-700 dark:bg-teal-900/30 dark:text-teal-300" },
  { label: "تقدمي", icon: TrendingUp, href: "/dashboard/progress", color: "bg-primary/10 text-primary" },
  { label: "اختباراتي", icon: FileQuestion, href: "/dashboard/exams", color: "bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-300" },
  { label: "لايف مباشر", icon: Radio, href: "/dashboard/live", color: "bg-red-100 text-red-600 dark:bg-red-900/30 dark:text-red-400" },
  { label: "المحادثات", icon: MessageCircle, href: "/dashboard/chat", color: "bg-blue-100 text-blue-600 dark:bg-blue-900/30 dark:text-blue-300" },
  { label: "طلبات التسجيل", icon: ClipboardList, href: "/dashboard/enrollment-requests", color: "bg-secondary/15 text-secondary" },
  { label: "المفضلة", icon: Bookmark, href: "/dashboard/wishlist", color: "bg-pink-100 text-pink-600 dark:bg-pink-900/30 dark:text-pink-300" },
  { label: "رمز الحضور", icon: QrCode, href: "/dashboard/qr-code", color: "bg-green-100 text-green-700 dark:bg-green-900/30 dark:text-green-400" },
  { label: "الإشعارات", icon: Bell, href: "/dashboard/notifications", color: "bg-orange-100 text-orange-600 dark:bg-orange-900/30 dark:text-orange-300" },
]

export default function DashboardPage() {
  const [loading, setLoading] = useState(true)
  const [enrollments, setEnrollments] = useState<Enrollment[]>([])
  const [certificates, setCertificates] = useState<Certificate[]>([])
  const [progress, setProgress] = useState<ProgressType | null>(null)
  const [liveSessions, setLiveSessions] = useState<LiveSession[]>([])

  useEffect(() => {
    const fetchDashboardData = async () => {
      try {
        setLoading(true)
        const [enrollmentsRes, certificatesRes, progressRes, liveRes] = await Promise.all([
          enrollmentsApi.getMyEnrollments().catch(() => ({ success: false, data: { data: [] } })),
          certificatesApi.getMyCertificates().catch(() => ({ success: false, data: [] })),
          progressApi.get("weekly").catch(() => ({ success: false, data: null })),
          liveApi.getAll().catch(() => ({ success: false, data: [] })),
        ])

        if (enrollmentsRes.success) {
          const enrollmentData = Array.isArray(enrollmentsRes.data)
            ? enrollmentsRes.data
            : (enrollmentsRes.data as any)?.data || []
          setEnrollments(enrollmentData)
        }
        if (certificatesRes.success) setCertificates(Array.isArray(certificatesRes.data) ? certificatesRes.data : [])
        if (progressRes.success && progressRes.data) setProgress(progressRes.data)
        if (liveRes.success) {
          const d: any = liveRes.data
          setLiveSessions(Array.isArray(d) ? d : d?.sessions || [])
        }
      } catch (error) {
        console.error("Error fetching dashboard data:", error)
      } finally {
        setLoading(false)
      }
    }
    fetchDashboardData()
  }, [])

  const stats = {
    totalCourses: enrollments.length,
    completedLessons: progress?.completedLessons || 0,
    totalHours: progress?.completedHours || 0,
  }

  const upcomingLive = liveSessions.filter((s) => s.status === "live" || s.status === "upcoming").slice(0, 3)

  return (
    <AppShell active="bookings" loading={loading}>
      {/* Stats */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-6 stagger-children">
        {[
          { label: "كورسات قيد الدراسة", value: stats.totalCourses.toString(), icon: BookOpen, color: "bg-primary/10 text-primary" },
          { label: "دروس مكتملة", value: stats.completedLessons.toString(), icon: PlayCircle, color: "bg-green-100 text-green-600 dark:bg-green-900/30 dark:text-green-400" },
          { label: "ساعات التعلم", value: stats.totalHours.toFixed(1), icon: Clock, color: "bg-purple-100 text-purple-600 dark:bg-purple-900/30 dark:text-purple-300" },
        ].map((stat, i) => (
          <Card key={i} className="border-none shadow-sm rounded-3xl bg-white dark:bg-card text-right">
            <CardContent className="p-6 flex items-center justify-between gap-4">
              <div className={`h-12 w-12 rounded-2xl flex items-center justify-center ${stat.color}`}>
                <stat.icon className="h-6 w-6" />
              </div>
              <div className="space-y-1">
                <p className="text-sm text-muted-foreground">{stat.label}</p>
                <p className="text-2xl font-black">{stat.value}</p>
              </div>
            </CardContent>
          </Card>
        ))}
      </div>

      {/* Quick links — app feature parity */}
      <div className="grid grid-cols-4 sm:grid-cols-8 gap-3 stagger-children">
        {QUICK_LINKS.map((q) => (
          <Link key={q.href} href={q.href} className="group">
            <div className="flex flex-col items-center gap-2 p-3 rounded-2xl bg-white dark:bg-card shadow-sm hover:shadow-md transition-all hover:-translate-y-0.5">
              <div className={`h-11 w-11 rounded-2xl flex items-center justify-center ${q.color} transition-transform group-hover:scale-110`}>
                <q.icon className="h-5 w-5" />
              </div>
              <span className="text-[10px] font-bold text-center leading-4">{q.label}</span>
            </div>
          </Link>
        ))}
      </div>

      {/* Live strip */}
      {upcomingLive.length > 0 && (
        <div className="space-y-4">
          <div className="flex items-center justify-between flex-row-reverse">
            <h2 className="text-xl font-bold flex items-center gap-2 flex-row-reverse">
              <Radio className="h-5 w-5 text-red-500" />
              الجلسات المباشرة
            </h2>
            <Link href="/dashboard/live"><Button variant="link" className="text-primary font-bold">عرض الكل</Button></Link>
          </div>
          <div className="grid grid-cols-1 md:grid-cols-3 gap-4 stagger-children">
            {upcomingLive.map((s) => (
              <Link key={s.id} href="/dashboard/live">
                <Card className="border-none shadow-sm rounded-2xl bg-white dark:bg-card hover:shadow-md transition-all overflow-hidden">
                  <CardContent className="p-4 flex items-center gap-3">
                    <div className={`h-11 w-11 rounded-2xl flex items-center justify-center shrink-0 ${s.status === "live" ? "bg-red-100 text-red-500 animate-live-pulse" : "bg-secondary/15 text-secondary"}`}>
                      <Radio className="h-5 w-5" />
                    </div>
                    <div className="flex-1 min-w-0 text-right">
                      <p className="font-bold text-sm line-clamp-1">{s.title}</p>
                      <p className="text-[11px] text-muted-foreground">
                        {s.status === "live" ? "مباشر الآن" : new Date(s.startTime).toLocaleString("ar-SA", { day: "numeric", month: "short", hour: "2-digit", minute: "2-digit" })}
                      </p>
                    </div>
                    {s.status === "live" && <Badge className="bg-red-500 text-white border-none text-[10px]">LIVE</Badge>}
                  </CardContent>
                </Card>
              </Link>
            ))}
          </div>
        </div>
      )}

      {/* My courses */}
      <div className="space-y-6">
        <div className="flex items-center justify-between flex-row-reverse">
          <h2 className="text-2xl font-bold">كورساتي الحالية</h2>
          <Link href="/instructors"><Button variant="link" className="text-primary font-bold">احجز جلسة</Button></Link>
        </div>
        {enrollments.length > 0 ? (
          <div className="grid grid-cols-1 md:grid-cols-2 gap-6 stagger-children">
            {enrollments.slice(0, 4).map((enrollment) => (
              <Card key={enrollment.id} className="group overflow-hidden border-none shadow-sm hover:shadow-md transition-all rounded-3xl bg-white dark:bg-card text-right">
                <div className="relative h-40 overflow-hidden">
                  {enrollment.course?.thumbnail ? (
                    <Image src={mediaUrl(enrollment.course.thumbnail)} alt={enrollment.course?.title || "Course"} fill className="object-cover" />
                  ) : (
                    <div className="w-full h-full bg-gradient-to-br from-primary/20 to-secondary/20" />
                  )}
                  <div className="absolute inset-0 bg-black/40 flex items-center justify-center opacity-0 group-hover:opacity-100 transition-opacity">
                    <Link href={`/learning/${enrollment.courseId}`}>
                      <Button className="rounded-full px-8 gap-2 flex-row-reverse"><PlayCircle className="h-5 w-5" />واصل المشاهدة</Button>
                    </Link>
                  </div>
                </div>
                <CardContent className="p-6 space-y-4">
                  <Badge variant="secondary" className="bg-primary/10 text-primary border-none text-[10px]">{enrollment.course?.categoryName || "دورة"}</Badge>
                  <h3 className="font-bold line-clamp-1">{enrollment.course?.title || "دورة"}</h3>
                  <div className="space-y-2">
                    <div className="flex items-center justify-between text-xs mb-1">
                      <span className="text-muted-foreground">نسبة الإنجاز</span>
                      <span className="font-bold text-primary" dir="ltr">{enrollment.progress || 0}%</span>
                    </div>
                    <Progress value={enrollment.progress || 0} className="h-2" />
                  </div>
                  <p className="text-xs text-muted-foreground">
                    الدروس المكتملة: <span className="text-foreground font-medium">{enrollment.completedLessons || 0}/{enrollment.totalLessons || 0}</span>
                  </p>
                </CardContent>
              </Card>
            ))}
          </div>
        ) : (
          <Card className="border-none shadow-sm rounded-3xl bg-white dark:bg-card text-center p-12 animate-fade-up">
            <BookOpen className="h-16 w-16 mx-auto mb-4 text-muted-foreground/50" />
            <h3 className="text-lg font-bold mb-2">ابدأ بحجز جلسة مع مدرب</h3>
            <p className="text-muted-foreground mb-6">اختار مدرب واحجز جلسة واحدة أو باقة جلسات</p>
            <Link href="/instructors"><Button className="rounded-full px-8">احجز جلسة</Button></Link>
          </Card>
        )}
      </div>

      {/* Certificates preview */}
      <Card className="border-none shadow-sm rounded-3xl bg-white dark:bg-card text-right overflow-hidden">
        <CardHeader className="border-b bg-muted/10 flex flex-row items-center justify-between">
          <CardTitle className="text-lg">شهاداتي</CardTitle>
          {certificates.length > 0 && (
            <Link href="/dashboard/certificates"><Button variant="link" className="text-primary text-sm font-bold">عرض الكل</Button></Link>
          )}
        </CardHeader>
        <CardContent className="p-8">
          {certificates.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 gap-4">
              {certificates.slice(0, 4).map((cert) => (
                <div key={cert.id} className="flex items-center gap-4 p-4 bg-muted/20 rounded-2xl">
                  <div className="h-12 w-12 rounded-xl bg-secondary/20 flex items-center justify-center">
                    <Trophy className="h-6 w-6 text-secondary" />
                  </div>
                  <div className="flex-1 min-w-0">
                    <p className="font-bold text-sm line-clamp-1">{cert.courseName || cert.courseTitle}</p>
                    <p className="text-xs text-muted-foreground">
                      {new Date(cert.issueDate || cert.completedAt || "").toLocaleDateString("ar-SA")}
                    </p>
                  </div>
                </div>
              ))}
            </div>
          ) : (
            <div className="flex flex-col items-center justify-center space-y-4 py-8">
              <div className="h-20 w-20 bg-muted rounded-full flex items-center justify-center grayscale opacity-50">
                <Trophy className="h-10 w-10" />
              </div>
              <p className="text-muted-foreground">أكمل كورسك الأول لتحصل على شهادتك الأولى!</p>
            </div>
          )}
        </CardContent>
      </Card>
    </AppShell>
  )
}
