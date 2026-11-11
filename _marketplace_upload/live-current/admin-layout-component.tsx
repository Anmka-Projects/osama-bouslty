"use client"

import type React from "react"
import { useEffect, useState } from "react"
import { useRouter } from "next/navigation"
import { Sidebar } from "./sidebar"
import { Topbar } from "./topbar"
import { Toaster } from "sonner"
import { ThemeProvider } from "@/components/theme-provider"
import { NavigationProgress } from "@/components/ui/navigation-progress"

interface AdminLayoutProps {
  children: React.ReactNode
  title: string
  subtitle?: string
}

export function AdminLayout({ children, title, subtitle }: AdminLayoutProps) {
  const router = useRouter()
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
  }, [])

  useEffect(() => {
    if (!mounted) return
    const adminCookie = document.cookie.split('; ').find(row => row.startsWith('adminToken='))?.split('=')[1]
    const accessCookie = document.cookie.split('; ').find(row => row.startsWith('accessToken='))?.split('=')[1]
    const localToken = localStorage.getItem("adminToken")
    const token = adminCookie || accessCookie || localToken
    if (!token) {
      router.replace("/admin/login")
    }
  }, [mounted, router])

  // Same output on server and first client render to avoid hydration mismatch.
  // Extensions (e.g. password managers) may add attributes like fdprocessedid to buttons;
  // suppressHydrationWarning avoids React warning for that.
  if (!mounted) {
    return (
      <div className="min-h-screen flex items-center justify-center bg-background" dir="rtl" suppressHydrationWarning>
        <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600" />
      </div>
    )
  }

  return (
    <ThemeProvider attribute="class" defaultTheme="system" enableSystem>
      <NavigationProgress />
      <div className="min-h-screen bg-background" dir="rtl" suppressHydrationWarning>
        <Sidebar />
        <div className="lg:mr-72 min-h-screen">
          <Topbar title={title} subtitle={subtitle} />
          <main className="p-6 pb-12">{children}</main>
        </div>
        <Toaster position="top-center" richColors dir="rtl" />
      </div>
    </ThemeProvider>
  )
}
