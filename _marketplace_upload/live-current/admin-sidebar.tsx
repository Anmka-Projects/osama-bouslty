"use client"

import type React from "react"

import { useState, useEffect } from "react"
import Link from "next/link"
import { usePathname, useSearchParams } from "next/navigation"
import { cn } from "@/lib/utils"
import { BRAND_NAME } from "@/lib/branding"
import {
  LayoutDashboard,
  Users,
  FolderTree,
  BookOpen,
  Video,
  CreditCard,
  Settings,
  ChevronDown,
  GraduationCap,
  Award,
  Menu,
  X,
  User,
  MessageCircle,
  AlertTriangle,
  GalleryHorizontal,
} from "lucide-react"
import { Button } from "@/components/ui/button"

interface NavItem {
  title: string
  href: string
  icon: React.ReactNode
  children?: { title: string; href: string }[]
}

// Admin navigation items (full access)
const adminNavItems: NavItem[] = [
  {
    title: "لوحة التحكم",
    href: "/admin/dashboard",
    icon: <LayoutDashboard className="h-5 w-5" />,
  },
  {
    title: "المستخدمين",
    href: "/admin/users",
    icon: <Users className="h-5 w-5" />,
  },
  {
    title: "المدرسين",
    href: "/admin/instructors",
    icon: <GraduationCap className="h-5 w-5" />,
  },
  {
    title: "جلسات المدرسين",
    href: "/admin/marketplace",
    icon: <Video className="h-5 w-5" />,
  },
  {
    title: "مراجعة البروفايل والتنبيهات",
    href: "/admin/tutor-controls",
    icon: <AlertTriangle className="h-5 w-5" />,
  },
  {
    title: "التصنيفات والمواد",
    href: "/admin/categories",
    icon: <FolderTree className="h-5 w-5" />,
  },
  {
    title: "المحادثات",
    href: "/admin/chat",
    icon: <MessageCircle className="h-5 w-5" />,
  },
  {
    title: "المدفوعات",
    href: "/admin/payments",
    icon: <CreditCard className="h-5 w-5" />,
  },
  {
    title: "سلايدر التطبيق",
    href: "/admin/sliders",
    icon: <GalleryHorizontal className="h-5 w-5" />,
  },
  {
    title: "فيديوهات الرئيسية",
    href: "/admin/home-spot-videos",
    icon: <Video className="h-5 w-5" />,
  },
  {
    title: "الشهادات",
    href: "/admin/certificates",
    icon: <Award className="h-5 w-5" />,
  },
  {
    title: "إعدادات التطبيق",
    href: "/admin/settings",
    icon: <Settings className="h-5 w-5" />,
    children: [
      { title: "عام", href: "/admin/settings" },
      { title: "طرق دفع الدورات", href: "/admin/settings/payment-methods" },
    ],
  },
]

// Instructor navigation items (limited access)
const instructorNavItems: NavItem[] = [
  {
    title: "لوحة التحكم",
    href: "/admin/dashboard",
    icon: <LayoutDashboard className="h-5 w-5" />,
  },
  {
    title: "دوراتي",
    href: "/admin/courses",
    icon: <BookOpen className="h-5 w-5" />,
    children: [
      { title: "جميع دوراتي", href: "/admin/courses" },
      { title: "إضافة دورة", href: "/admin/courses/new" },
    ],
  },
  {
    title: "طلابي",
    href: "/admin/my-students",
    icon: <Users className="h-5 w-5" />,
  },
  {
    title: "المحادثات",
    href: "/admin/chat",
    icon: <MessageCircle className="h-5 w-5" />,
  },
  {
    title: "الملف الشخصي",
    href: "/admin/profile",
    icon: <User className="h-5 w-5" />,
  },
]

export function Sidebar() {
  const pathname = usePathname()
  const searchParams = useSearchParams()
  const [expandedItems, setExpandedItems] = useState<string[]>([])
  const [isMobileOpen, setIsMobileOpen] = useState(false)
  const [userRole, setUserRole] = useState<string>("admin")
  const currentPath = pathname + (searchParams.toString() ? `?${searchParams.toString()}` : "")

  useEffect(() => {
    // Get user role from localStorage
    if (typeof window !== "undefined") {
      const adminUser = localStorage.getItem("adminUser")
      if (adminUser) {
        try {
          const user = JSON.parse(adminUser)
          setUserRole(user.role || "admin")
        } catch (e) {
          console.error("Error parsing user data:", e)
        }
      }
    }
  }, [])

  // Auto-expand parent when current path matches a child
  useEffect(() => {
    const items = userRole === "instructor" ? instructorNavItems : adminNavItems
    const parentsToExpand: string[] = []
    items.forEach((item) => {
      if (item.children?.some((child) => currentPath === child.href)) {
        parentsToExpand.push(item.href)
      }
    })
    if (parentsToExpand.length > 0) {
      setExpandedItems((prev) => [...new Set([...prev, ...parentsToExpand])])
    }
  }, [currentPath, userRole])

  const toggleExpanded = (href: string) => {
    setExpandedItems((prev) => (prev.includes(href) ? prev.filter((item) => item !== href) : [...prev, href]))
  }

  const isActive = (href: string) => pathname === href || pathname.startsWith(href + "/")
  const isParentOrChildActive = (item: NavItem) =>
    isActive(item.href) || (item.children?.some((c) => pathname === c.href) ?? false)

  // Get navigation items based on user role
  const navItems = userRole === "instructor" ? instructorNavItems : adminNavItems
  const isInstructor = userRole === "instructor"

  return (
    <>
      {/* Mobile Toggle Button */}
      <Button
        variant="ghost"
        size="icon"
        className="fixed top-4 right-4 z-50 lg:hidden"
        onClick={() => setIsMobileOpen(!isMobileOpen)}
      >
        {isMobileOpen ? <X className="h-6 w-6" /> : <Menu className="h-6 w-6" />}
      </Button>

      {/* Overlay */}
      {isMobileOpen && (
        <div className="fixed inset-0 z-40 bg-black/50 lg:hidden" onClick={() => setIsMobileOpen(false)} />
      )}

      {/* Sidebar - suppressHydrationWarning: extensions (e.g. password managers) may add attributes to buttons */}
      <aside
        className={cn(
          "fixed right-0 top-0 z-40 h-screen w-72 border-l border-border/50 bg-gradient-to-b from-card to-background transition-transform lg:translate-x-0",
          isMobileOpen ? "translate-x-0" : "translate-x-full lg:translate-x-0",
        )}
        suppressHydrationWarning
      >
        {/* Logo */}
        <div className="flex h-16 items-center gap-3 border-b border-border/50 px-6">
          <div className="flex h-10 w-10 items-center justify-center overflow-hidden rounded-xl shadow-sm">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img src="/landing/logo.png" alt={BRAND_NAME} className="h-10 w-10 object-cover" />
          </div>
          <div>
            <h1 className="font-bold text-foreground">{BRAND_NAME}</h1>
            <p className="text-xs text-muted-foreground">{isInstructor ? "لوحة المدرب" : "لوحة الإدارة"}</p>
          </div>
        </div>

        {/* Navigation */}
        <nav className="h-[calc(100vh-4rem)] overflow-y-auto p-4">
          <ul className="space-y-1">
            {navItems.map((item) => (
              <li key={item.href}>
                {item.children ? (
                  <div>
                    <button
                      type="button"
                      onClick={() => toggleExpanded(item.href)}
                      className={cn(
                        "flex w-full items-center justify-between rounded-lg px-3 py-2.5 text-sm font-medium transition-colors",
                        isParentOrChildActive(item)
                          ? "bg-purple-500/10 text-purple-400"
                          : "text-muted-foreground hover:bg-muted/50 hover:text-foreground",
                      )}
                      suppressHydrationWarning
                    >
                      <div className="flex min-w-0 items-center gap-3">
                        {item.icon}
                        <span className="whitespace-nowrap">{item.title}</span>
                      </div>
                      <ChevronDown
                        className={cn(
                          "h-4 w-4 transition-transform",
                          expandedItems.includes(item.href) && "rotate-180",
                        )}
                      />
                    </button>
                    {expandedItems.includes(item.href) && (
                      <ul className="mr-6 mt-1 space-y-1 border-r border-border/50 pr-4">
                        {item.children.map((child) => (
                          <li key={child.href}>
                            <Link
                              href={child.href}
                              prefetch={true}
                              onClick={() => setIsMobileOpen(false)}
                              className={cn(
                                "block rounded-lg px-3 py-2 text-sm transition-all duration-150 ease-in-out relative",
                                currentPath === child.href
                                  ? "bg-purple-500/10 text-purple-400 font-medium"
                                  : "text-muted-foreground hover:bg-muted/50 hover:text-foreground",
                              )}
                            >
                              {child.title}
                            </Link>
                          </li>
                        ))}
                      </ul>
                    )}
                  </div>
                ) : (
                  <Link
                    href={item.href}
                    prefetch={true}
                    onClick={() => setIsMobileOpen(false)}
                    className={cn(
                      "flex min-w-0 items-center gap-3 rounded-lg px-3 py-2.5 text-sm font-medium transition-all duration-150 ease-in-out",
                      isActive(item.href)
                        ? "bg-purple-500/10 text-purple-400"
                        : "text-muted-foreground hover:bg-muted/50 hover:text-foreground",
                    )}
                  >
                    {item.icon}
                    <span className="whitespace-nowrap">{item.title}</span>
                  </Link>
                )}
              </li>
            ))}
          </ul>
        </nav>
      </aside>
    </>
  )
}
