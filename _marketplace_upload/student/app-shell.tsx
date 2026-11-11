"use client"

import { useState, useEffect } from "react"
import Image from "next/image"
import Link from "next/link"
import { useRouter, usePathname } from "next/navigation"
import {
  BookOpen, FileQuestion, Trophy, Bell, Settings, LogOut, TrendingUp,
  Radio, MessageCircle, ClipboardList, Bookmark, QrCode, GraduationCap,
} from "lucide-react"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { MobileBottomNav } from "@/components/app/mobile-bottom-nav"
import { PageLoader } from "@/components/app/page-loader"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { useToast } from "@/hooks/use-toast"
import {
  isAuthenticated, getStoredUser, clearAuthTokens,
  profileApi, notificationsApi, certificatesApi,
  mediaUrl, type User,
} from "@/lib/api"

const NAV_ITEMS = [
  { id: "bookings", label: "حجوزاتي", icon: Radio, href: "/dashboard/bookings" },
  { id: "instructors", label: "احجز جلسة", icon: GraduationCap, href: "/instructors" },
  { id: "chat", label: "المحادثات", icon: MessageCircle, href: "/dashboard/chat" },
  { id: "qr-code", label: "رمز الحضور", icon: QrCode, href: "/dashboard/qr-code" },
  { id: "settings", label: "الإعدادات", icon: Settings, href: "/dashboard/settings" },
]

interface AppShellProps {
  /** id of the active nav item */
  active: string
  children: React.ReactNode
  /** render the inner content even while the shell data is loading */
  loading?: boolean
}

/**
 * Authenticated student-area layout: top navbar, user sidebar with the
 * app's full feature nav, footer and the mobile bottom navigation bar.
 * Mirrors the Flutter app's student flow navigation.
 */
export function AppShell({ active, children, loading }: AppShellProps) {
  const router = useRouter()
  const pathname = usePathname()
  const { toast } = useToast()

  const [isDark, setIsDark] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [shellLoading, setShellLoading] = useState(true)
  const [user, setUser] = useState<User | null>(null)
  const [unreadCount, setUnreadCount] = useState(0)
  const [certCount, setCertCount] = useState(0)

  useEffect(() => {
    setMounted(true)
    const dark =
      localStorage.getItem("theme") === "dark" ||
      (!localStorage.getItem("theme") && window.matchMedia("(prefers-color-scheme: dark)").matches)
    setIsDark(dark)

    if (!isAuthenticated()) {
      router.push(`/login?redirect=${encodeURIComponent(pathname || "/dashboard")}`)
      return
    }

    const stored = getStoredUser()
    if (stored) setUser(stored)

    Promise.all([
      profileApi.get().catch(() => ({ success: false, data: null })),
      notificationsApi.getMyNotifications({ perPage: 1 }).catch(() => ({ success: false, data: { notifications: [], unreadCount: 0 } })),
      certificatesApi.getMyCertificates().catch(() => ({ success: false, data: [] })),
    ]).then(([profileRes, notifRes, certRes]) => {
      if (profileRes.success && profileRes.data) setUser(profileRes.data)
      if (notifRes.success) setUnreadCount((notifRes.data as any)?.unreadCount || 0)
      if (certRes.success) setCertCount(Array.isArray(certRes.data) ? certRes.data.length : 0)
    }).finally(() => setShellLoading(false))
  }, [])

  useEffect(() => {
    if (!mounted) return
    if (isDark) {
      document.documentElement.classList.add("dark")
      localStorage.setItem("theme", "dark")
    } else {
      document.documentElement.classList.remove("dark")
      localStorage.setItem("theme", "light")
    }
  }, [isDark, mounted])

  const handleLogout = () => {
    clearAuthTokens()
    toast({ title: "تم تسجيل الخروج", description: "نراك قريبا!" })
    router.push("/login")
  }

  if (!mounted) return null

  const badgeFor = (id: string) => {
    if (id === "notifications") return unreadCount
    if (id === "certificates") return certCount
    return undefined
  }

  return (
    <main dir="rtl" className="min-h-screen bg-muted/20">
      <Navbar isDark={isDark} setIsDark={setIsDark} />
      <section className="py-8 md:py-12 pb-28 lg:pb-12">
        <div className="container mx-auto px-4">
          <div className="grid grid-cols-1 lg:grid-cols-4 gap-8">
            <aside className="lg:col-span-1 space-y-6">
              <Card className="border-none shadow-sm rounded-3xl overflow-hidden bg-white dark:bg-card text-right animate-fade-up">
                <CardContent className="p-6 space-y-6">
                  <div className="flex flex-col items-center gap-4 py-4 border-b">
                    <div className="h-24 w-24 rounded-full border-4 border-primary/10 overflow-hidden relative bg-muted">
                      {user?.avatar ? (
                        <Image src={mediaUrl(user.avatar)} alt={user?.name || "User"} fill className="object-cover" />
                      ) : (
                        <div className="w-full h-full flex items-center justify-center bg-gradient-to-br from-primary to-secondary text-white text-3xl font-bold">
                          {user?.name?.charAt(0) || "U"}
                        </div>
                      )}
                    </div>
                    <div className="text-center">
                      <h3 className="text-lg font-bold">{user?.name || "مستخدم"}</h3>
                      <p className="text-xs text-muted-foreground">
                        طالب نشط منذ {user?.createdAt ? new Date(user.createdAt).toLocaleDateString("ar-SA", { month: "long", year: "numeric" }) : "غير محدد"}
                      </p>
                    </div>
                  </div>
                  <nav className="space-y-1">
                    {NAV_ITEMS.map((item) => {
                      const itemActive = item.id === active
                      const badge = badgeFor(item.id)
                      return (
                        <Link
                          key={item.id}
                          href={item.href}
                          className={`flex items-center justify-between p-3.5 rounded-2xl transition-all ${
                            itemActive
                              ? "bg-primary text-primary-foreground font-bold shadow-lg shadow-primary/20"
                              : "hover:bg-muted"
                          }`}
                        >
                          <div className="flex items-center gap-2">
                            <item.icon className={`h-5 w-5 ${itemActive ? "" : "text-muted-foreground"}`} />
                            {badge !== undefined && badge > 0 && (
                              <Badge variant={itemActive ? "secondary" : "default"} className="h-5 min-w-5 text-[10px]">
                                {badge}
                              </Badge>
                            )}
                          </div>
                          <span className="text-sm">{item.label}</span>
                        </Link>
                      )
                    })}
                    <button
                      onClick={handleLogout}
                      className="flex items-center justify-between p-3.5 rounded-2xl transition-all hover:bg-red-50 dark:hover:bg-red-950 text-red-600 w-full"
                    >
                      <LogOut className="h-5 w-5" />
                      <span className="text-sm">تسجيل الخروج</span>
                    </button>
                  </nav>
                </CardContent>
              </Card>
              <Card className="bg-primary text-primary-foreground border-none rounded-3xl p-6 relative overflow-hidden animate-fade-up">
                <div className="relative z-10 space-y-4 text-right">
                  <GraduationCap className="h-10 w-10 opacity-50 ml-auto" />
                  <h4 className="font-bold">احجز جلسة مع مدرب</h4>
                  <p className="text-sm opacity-80">جلسة واحدة أو باقة جلسات، وتختار الموعد المناسب.</p>
                  <Link href="/instructors">
                    <button className="w-full rounded-xl bg-secondary text-secondary-foreground font-bold py-2.5 px-4 text-sm hover:opacity-90 transition-opacity">
                      احجز جلسة
                    </button>
                  </Link>
                </div>
                <div className="absolute -bottom-10 -left-10 w-32 h-32 bg-white/10 rounded-full blur-2xl" />
              </Card>
            </aside>
            <div className="lg:col-span-3 space-y-8 min-w-0">
              {shellLoading || loading ? <PageLoader /> : children}
            </div>
          </div>
        </div>
      </section>
      <Footer />
      <MobileBottomNav />
    </main>
  )
}
