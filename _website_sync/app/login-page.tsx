"use client"

import Link from "next/link"
import { useRouter, useSearchParams } from "next/navigation"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { BookOpen, Github, Mail } from "lucide-react"
import { Suspense, useState } from "react"

const BRAND_NAME = "بوصلة"

function LoginContent() {
  const [isDark, setIsDark] = useState(false)
  const [identifier, setIdentifier] = useState("")
  const [password, setPassword] = useState("")
  const [rememberMe, setRememberMe] = useState(false)
  const [loading, setLoading] = useState(false)
  const [error, setError] = useState("")
  const router = useRouter()
  const searchParams = useSearchParams()
  const redirect = searchParams.get("redirect")

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()
    setError("")
    setLoading(true)

    try {
      const response = await fetch("/api/auth/login", {
        method: "POST",
        headers: {
          "Content-Type": "application/json",
        },
        body: JSON.stringify(identifier.includes("@")
          ? { email: identifier.trim(), password }
          : { phone: identifier.trim(), password }),
      })

      const data = await response.json()

      if (response.ok && data.success) {
        // Store student session so API calls (enrollment requests, redeem…) carry auth
        const accessToken = data.data?.accessToken
        if (accessToken) {
          localStorage.setItem("studentToken", accessToken)
          localStorage.setItem("accessToken", accessToken)
          document.cookie = `accessToken=${encodeURIComponent(accessToken)}; path=/; max-age=315360000; SameSite=Lax`
        }
        if (data.data?.refreshToken) localStorage.setItem("refreshToken", data.data.refreshToken)
        if (data.data?.user) localStorage.setItem("user", JSON.stringify(data.data.user))
        const role = String(data.data?.user?.role || "student").toLowerCase()
        const roleHome = role === "instructor" ? "/instructor" : "/dashboard"
        const safeRedirect = redirect && !(role === "instructor" && redirect.startsWith("/dashboard"))
          ? redirect
          : roleHome
        router.replace(safeRedirect)
      } else {
        setError(data.message || "حدث خطأ أثناء تسجيل الدخول")
      }
    } catch (err) {
      setError("حدث خطأ في الاتصال بالخادم")
      console.error("Login error:", err)
    } finally {
      setLoading(false)
    }
  }

  return (
    <main
      className={`min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-gradient-to-br from-blue-50 to-purple-50 dark:from-slate-900 dark:to-slate-800 ${isDark ? "dark" : ""}`}
    >
      {/* Background Decorations - Enhanced dark mode gradients */}
      <div className="fixed top-0 right-0 w-96 h-96 bg-primary/15 rounded-full blur-[100px] animate-pulse-subtle opacity-50" />
      <div className="fixed bottom-0 left-0 w-96 h-96 bg-secondary/10 rounded-full blur-[120px] animate-pulse-subtle opacity-50" />

      {/* Main Container - Two-column design inspired by reference image */}
      <div className="w-full max-w-5xl relative z-10 grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-0 items-center">
        {/* Left Side - Form */}
        <div className="space-y-8 lg:p-12 animate-slide-in-right">
          {/* Header */}
          <div className="space-y-3">
            <Link href="/" className="inline-flex items-center gap-2 group mb-4">
              <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-secondary text-white shadow-lg">
                <BookOpen className="h-6 w-6" />
              </div>
              <span className="text-2xl font-black text-foreground">{BRAND_NAME}</span>
            </Link>
            <h1 className="text-3xl sm:text-4xl font-black tracking-tight">مرحباً بعودتك!</h1>
            <p className="text-sm text-foreground/70 font-medium">استكمل رحلة نجاحك من هنا</p>
          </div>

          {/* Form */}
          <form onSubmit={handleSubmit} className="space-y-5">
            {/* Error Message */}
            {error && (
              <div className="p-3 rounded-lg bg-destructive/10 border border-destructive/20 text-destructive text-sm text-right">
                {error}
              </div>
            )}

            {/* Email or phone */}
            <div className="space-y-2 text-right">
              <Label className="text-xs font-bold">البريد الإلكتروني أو رقم الهاتف</Label>
              <Input
                type="text"
                inputMode="email"
                placeholder="example@mail.com أو رقم الهاتف"
                value={identifier}
                onChange={(e) => setIdentifier(e.target.value)}
                required
                disabled={loading}
                className="h-11 rounded-lg border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-right placeholder-foreground/40 focus:border-primary transition-colors text-sm"
              />
            </div>

            {/* Password */}
            <div className="space-y-2 text-right">
              <div className="flex items-center justify-between">
                <Link href="/forgot-password" className="text-xs text-primary font-bold hover:underline">
                  نسيت كلمة المرور؟
                </Link>
                <Label className="text-xs font-bold">كلمة المرور</Label>
              </div>
              <Input
                type="password"
                value={password}
                onChange={(e) => setPassword(e.target.value)}
                required
                disabled={loading}
                className="h-11 rounded-lg border border-gray-300 dark:border-slate-600 bg-white dark:bg-slate-800 text-right placeholder-foreground/40 focus:border-primary transition-colors text-sm"
              />
            </div>

            {/* Remember */}
            <div className="flex items-center justify-end gap-2 text-sm">
              <Label className="font-medium cursor-pointer">تذكرني على هذا الجهاز</Label>
              <Checkbox 
                checked={rememberMe}
                onCheckedChange={(checked) => setRememberMe(checked === true)}
                disabled={loading}
                className="rounded border" 
              />
            </div>

            {/* Login Button - Orange colored */}
            <Button 
              type="submit"
              disabled={loading}
              className="w-full h-11 text-base font-bold rounded-lg shadow-lg bg-gradient-to-r from-primary to-primary/80 hover:shadow-xl transition-all text-sm disabled:opacity-50 disabled:cursor-not-allowed"
            >
              {loading ? "جاري تسجيل الدخول..." : "دخول →"}
            </Button>
          </form>

          {/* Divider */}
          <div className="relative">
            <div className="absolute inset-0 flex items-center">
              <span className="w-full border-t border-gray-300 dark:border-slate-600" />
            </div>
            <div className="relative flex justify-center">
              <span className="bg-white dark:bg-slate-900 px-2 text-xs text-muted-foreground font-medium">أو عبر</span>
            </div>
          </div>

          {/* Social Login */}
          <div className="grid grid-cols-2 gap-3">
            <Button
              variant="outline"
              className="h-10 rounded-lg border border-gray-300 dark:border-slate-600 bg-transparent hover:bg-gray-100 dark:hover:bg-slate-700 text-sm gap-2"
            >
              <Mail className="h-4 w-4" />
              Google
            </Button>
            <Button
              variant="outline"
              className="h-10 rounded-lg border border-gray-300 dark:border-slate-600 bg-transparent hover:bg-gray-100 dark:hover:bg-slate-700 text-sm gap-2"
            >
              <Github className="h-4 w-4" />
              GitHub
            </Button>
          </div>

          {/* Footer */}
          <p className="text-xs text-foreground/70 text-center">
            ليس لديك حساب؟{" "}
            <Link href="/register" className="text-primary font-bold hover:underline">
              إنشاء حساب جديد
            </Link>
          </p>
        </div>

        {/* Right Side - Illustration Area (Hidden on Mobile) - Modern gradient card design */}
        <div className="hidden lg:flex items-center justify-center lg:p-12">
          <div className="relative w-full max-w-sm">
            <div className="absolute inset-0 bg-gradient-to-br from-primary via-secondary to-primary/50 rounded-3xl blur-2xl opacity-40 animate-pulse-subtle" />
            <div className="relative bg-gradient-to-br from-primary/90 to-secondary/80 rounded-3xl p-8 space-y-6 shadow-2xl">
              {/* Mock Content Cards */}
              <div className="space-y-4">
                <div className="bg-white/20 backdrop-blur rounded-xl p-4 space-y-2">
                  <div className="h-2 bg-white/40 rounded w-2/3" />
                  <div className="h-2 bg-white/40 rounded w-1/2" />
                </div>
                <div className="flex gap-3">
                  <div className="h-10 w-10 bg-white/30 rounded-lg" />
                  <div className="h-10 w-10 bg-white/30 rounded-lg" />
                  <div className="h-10 w-10 bg-white/30 rounded-lg" />
                </div>
              </div>
              <div className="text-white/90 text-sm font-medium">جاهز للبدء معنا؟</div>
            </div>
          </div>
        </div>
      </div>
    </main>
  )
}

export default function LoginPage() {
  return (
    <Suspense fallback={null}>
      <LoginContent />
    </Suspense>
  )
}
