"use client"

import type React from "react"
import { useState, useEffect } from "react"
import { Sidebar } from "./sidebar"
import { Topbar } from "./topbar"
import { Toaster } from "sonner"
import Link from "next/link"
import { ChevronLeft, Loader2 } from "lucide-react"

interface Breadcrumb {
  title: string
  href?: string
}

interface AppLayoutProps {
  children: React.ReactNode
  title: string
  subtitle?: string
  breadcrumbs?: Breadcrumb[]
}

export function AppLayout({ children, title, subtitle, breadcrumbs }: AppLayoutProps) {
  const [mounted, setMounted] = useState(false)
  useEffect(() => {
    setMounted(true)
  }, [])

  if (!mounted) {
    return (
      <div className="min-h-screen bg-background" dir="rtl">
        <div className="lg:mr-64 flex items-center justify-center min-h-screen">
          <Loader2 className="h-8 w-8 animate-spin text-muted-foreground" />
        </div>
        <Toaster position="top-center" richColors dir="rtl" />
      </div>
    )
  }

  return (
    <div className="min-h-screen bg-background" dir="rtl">
      <Sidebar />
      <div className="lg:mr-64">
        <Topbar title={title} subtitle={subtitle} />
        {breadcrumbs && breadcrumbs.length > 0 && (
          <div className="border-b border-border/50 bg-card/30 px-6 py-3">
            <nav className="flex items-center gap-2 text-sm">
              {breadcrumbs.map((crumb, index) => (
                <div key={index} className="flex items-center gap-2">
                  {index > 0 && <ChevronLeft className="h-4 w-4 text-muted-foreground" />}
                  {crumb.href ? (
                    <Link href={crumb.href} className="text-muted-foreground transition-colors hover:text-foreground">
                      {crumb.title}
                    </Link>
                  ) : (
                    <span className="text-foreground">{crumb.title}</span>
                  )}
                </div>
              ))}
            </nav>
          </div>
        )}
        <main className="p-6">{children}</main>
      </div>
      <Toaster position="top-center" richColors dir="rtl" />
    </div>
  )
}
