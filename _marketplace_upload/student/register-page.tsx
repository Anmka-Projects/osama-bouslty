"use client"

import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Checkbox } from "@/components/ui/checkbox"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Mail, Github, Loader2, Eye, EyeOff } from "lucide-react"
import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { authApi, categoriesApi, isAuthenticated, setAuthTokens, storeUser } from "@/lib/api"
import { useToast } from "@/hooks/use-toast"

/** Egyptian phone normalization — same rule as the app: 01xxxxxxxxx -> +201xxxxxxxxx */
function normalizePhone(raw: string): string {
  const phone = raw.trim().replace(/[\s-]/g, "")
  if (/^01[0-9]{9}$/.test(phone)) return `+20${phone.substring(1)}`
  if (/^\+?20?1[0-9]{9}$/.test(phone)) return phone.startsWith("+") ? phone : `+${phone}`
  return phone
}

interface Grade { id: string; name: string }
interface Stage { id: string; name: string; children: Grade[] }

export default function RegisterPage() {
  const router = useRouter()
  const { toast } = useToast()

  const [name, setName] = useState("")
  const [email, setEmail] = useState("")
  const [phone, setPhone] = useState("")
  const [password, setPassword] = useState("")
  const [confirmPassword, setConfirmPassword] = useState("")
  const [stageId, setStageId] = useState("")
  const [gradeId, setGradeId] = useState("")
  const [stages, setStages] = useState<Stage[]>([])
  const [acceptTerms, setAcceptTerms] = useState(false)
  const [accountRole, setAccountRole] = useState<"student" | "instructor">("student")
  const [showPassword, setShowPassword] = useState(false)
  const [loading, setLoading] = useState(false)
  const [mounted, setMounted] = useState(false)

  useEffect(() => {
    setMounted(true)
    if (isAuthenticated()) router.push("/dashboard")

    // Educational stages = top-level categories; grades = their children
    fetch("/backend-api/categories")
      .then((r) => r.json())
      .then((res) => {
        const list = res?.data || res || []
        setStages(
          list.map((c: any) => ({
            id: c.id,
            name: c.name || c.name_ar,
            children: (c.children || c.subcategories || []).map((g: any) => ({ id: g.id, name: g.name || g.name_ar })),
          }))
        )
      })
      .catch(() => {})
  }, [router])

  const grades = stages.find((s) => s.id === stageId)?.children || []

  const handleSubmit = async (e: React.FormEvent) => {
    e.preventDefault()

    if (!name || !phone || !password) {
      toast({ title: "خطأ", description: "يرجى ملء جميع الحقول المطلوبة", variant: "destructive" })
      return
    }
    const normalizedPhone = normalizePhone(phone)
    if (!/^\+?20?1[0-9]{9}$/.test(normalizedPhone.replace("+", "")) && !/^\+201[0-9]{9}$/.test(normalizedPhone)) {
      toast({ title: "خطأ", description: "يرجى إدخال رقم هاتف مصري صحيح", variant: "destructive" })
      return
    }
    if (password !== confirmPassword) {
      toast({ title: "خطأ", description: "كلمتا المرور غير متطابقتان", variant: "destructive" })
      return
    }
    if (password.length < 8) {
      toast({ title: "خطأ", description: "كلمة المرور يجب أن تكون 8 أحرف على الأقل", variant: "destructive" })
      return
    }
    if (!acceptTerms) {
      toast({ title: "خطأ", description: "يرجى الموافقة على شروط الخدمة وسياسة الخصوصية", variant: "destructive" })
      return
    }
    if (!stageId || (grades.length > 0 && !gradeId)) {
      toast({
        title: "اختيار التصنيف مطلوب",
        description: accountRole === "student" ? "اختر المرحلة والصف الدراسي" : "اختر المجال والتخصص الفرعي",
        variant: "destructive",
      })
      return
    }

    setLoading(true)
    try {
      const response = await authApi.register({
        name: name.trim(),
        email: email.trim() || undefined,
        phone: normalizedPhone,
        password,
        password_confirmation: confirmPassword,
        category_id: stageId || undefined,
        subcategory_id: gradeId || undefined,
        accept_terms: true,
        role: accountRole,
        student_type: accountRole === "student" ? "online" : undefined,
      })

      if (response.success) {
        const { user, accessToken, refreshToken } = response.data
        setAuthTokens(accessToken, refreshToken)
        storeUser(user)
        toast({ title: "تم إنشاء الحساب بنجاح", description: accountRole === "instructor" ? "كمّل ملفك والفيديو. الظهور للطلاب بعد موافقة الأدمن." : `مرحباً ${user.name}!` })
        router.push(accountRole === "instructor" ? "/instructors" : "/dashboard")
      }
    } catch (error: any) {
      toast({
        title: "خطأ في إنشاء الحساب",
        description: error.message || "حدث خطأ أثناء إنشاء الحساب، يرجى المحاولة مرة أخرى",
        variant: "destructive",
      })
    } finally {
      setLoading(false)
    }
  }

  if (!mounted) return null

  return (
    <main className="min-h-screen flex items-center justify-center p-4 relative overflow-hidden bg-gradient-to-br from-[#0B5960] via-[#083B41] to-[#06262A]">
      <div className="fixed top-0 right-0 w-96 h-96 bg-primary/20 rounded-full blur-[100px] animate-pulse-subtle opacity-50" />
      <div className="fixed bottom-0 left-0 w-96 h-96 bg-secondary/10 rounded-full blur-[120px] animate-pulse-subtle opacity-50" />

      <div className="w-full max-w-5xl relative z-10 grid grid-cols-1 lg:grid-cols-2 gap-8 lg:gap-0 items-center">
        {/* Right Side - Form */}
        <div className="space-y-8 lg:p-12 animate-slide-in-left">
          {/* Header */}
          <div className="space-y-3">
            <Link href="/" className="inline-flex items-center gap-2 group mb-4">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img src="/student-public/brand/logo-ar-reverse.png" alt="Bouslty | بوصلتي" className="h-14 w-auto object-contain" />
            </Link>
            <h1 className="text-3xl sm:text-4xl font-black tracking-tight text-white">ابدأ رحلتك</h1>
            <p className="text-sm text-white/70 font-medium">انضم إلى آلاف الطلاب الناجحين</p>
          </div>

          {/* Form — mirrors the Flutter register screen fields */}
          <form onSubmit={handleSubmit} className="space-y-4">
            <div className="grid grid-cols-2 gap-2">
              <button type="button" onClick={() => setAccountRole("student")} className={`rounded-xl h-12 font-bold ${accountRole === "student" ? "bg-secondary text-secondary-foreground" : "bg-white/10 text-white"}`}>طالب</button>
              <button type="button" onClick={() => setAccountRole("instructor")} className={`rounded-xl h-12 font-bold ${accountRole === "instructor" ? "bg-secondary text-secondary-foreground" : "bg-white/10 text-white"}`}>مدرس</button>
            </div>
            {accountRole === "instructor" ? <p className="text-xs text-white/70 text-right">الفيديو التعريفي والباقات والسعر يظهروا للطلاب بعد موافقة الأدمن.</p> : null}
            {/* Full name */}
            <div className="space-y-2 text-right">
              <Label className="text-xs font-bold text-white/80">الاسم الكامل *</Label>
              <Input
                value={name}
                onChange={(e) => setName(e.target.value)}
                placeholder="أحمد علي"
                className="h-12 rounded-xl bg-white/10 border-white/15 text-white placeholder:text-white/40 text-right"
              />
            </div>

            {/* Phone — required like the app */}
            <div className="space-y-2 text-right">
              <Label className="text-xs font-bold text-white/80">رقم الهاتف *</Label>
              <Input
                type="tel"
                value={phone}
                onChange={(e) => setPhone(e.target.value)}
                placeholder="01xxxxxxxxx"
                className="h-12 rounded-xl bg-white/10 border-white/15 text-white placeholder:text-white/40 text-left"
                dir="ltr"
              />
            </div>

            {/* Email — optional like the app */}
            <div className="space-y-2 text-right">
              <Label className="text-xs font-bold text-white/80">البريد الإلكتروني (اختياري)</Label>
              <Input
                type="email"
                value={email}
                onChange={(e) => setEmail(e.target.value)}
                placeholder="example@mail.com"
                className="h-12 rounded-xl bg-white/10 border-white/15 text-white placeholder:text-white/40 text-left"
                dir="ltr"
              />
            </div>

            {/* Stage + grade pickers — app parity */}
            {stages.length > 0 && (
              <div className="grid grid-cols-2 gap-3">
                <div className="space-y-2 text-right">
                  <Label className="text-xs font-bold text-white/80">{accountRole === "student" ? "المرحلة الدراسية" : "المجال الرئيسي"}</Label>
                  <Select value={stageId} onValueChange={(v) => { setStageId(v); setGradeId("") }}>
                    <SelectTrigger className="h-12 rounded-xl bg-white/10 border-white/15 text-white">
                      <SelectValue placeholder={accountRole === "student" ? "اختر المرحلة" : "اختر المجال"} />
                    </SelectTrigger>
                    <SelectContent>
                      {stages.map((s) => (
                        <SelectItem key={s.id} value={s.id}>{s.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
                <div className="space-y-2 text-right">
                  <Label className="text-xs font-bold text-white/80">{accountRole === "student" ? "الصف الدراسي" : "التخصص الفرعي"}</Label>
                  <Select value={gradeId} onValueChange={setGradeId} disabled={!stageId}>
                    <SelectTrigger className="h-12 rounded-xl bg-white/10 border-white/15 text-white">
                      <SelectValue placeholder={accountRole === "student" ? "اختر الصف" : "اختر التخصص"} />
                    </SelectTrigger>
                    <SelectContent>
                      {grades.map((g) => (
                        <SelectItem key={g.id} value={g.id}>{g.name}</SelectItem>
                      ))}
                    </SelectContent>
                  </Select>
                </div>
              </div>
            )}

            {/* Password + confirm */}
            <div className="grid grid-cols-2 gap-3">
              <div className="space-y-2 text-right">
                <Label className="text-xs font-bold text-white/80">كلمة المرور *</Label>
                <Input
                  type={showPassword ? "text" : "password"}
                  value={password}
                  onChange={(e) => setPassword(e.target.value)}
                  className="h-12 rounded-xl bg-white/10 border-white/15 text-white"
                />
              </div>
              <div className="space-y-2 text-right">
                <Label className="text-xs font-bold text-white/80">تأكيد كلمة المرور *</Label>
                <div className="relative">
                  <Input
                    type={showPassword ? "text" : "password"}
                    value={confirmPassword}
                    onChange={(e) => setConfirmPassword(e.target.value)}
                    className="h-12 rounded-xl bg-white/10 border-white/15 text-white pl-10"
                  />
                  <button type="button" onClick={() => setShowPassword(!showPassword)} className="absolute left-3 top-1/2 -translate-y-1/2 text-white/50 hover:text-white">
                    {showPassword ? <EyeOff className="h-4 w-4" /> : <Eye className="h-4 w-4" />}
                  </button>
                </div>
              </div>
            </div>

            {/* Terms checkbox — required like the app */}
            <label className="flex items-center gap-2 justify-end cursor-pointer text-sm text-white/70">
              <span>
                بالتسجيل، أنت توافق على{" "}
                <Link href="/terms" className="text-secondary font-bold hover:underline">شروط الخدمة</Link>
                {" "}و{" "}
                <Link href="/privacy" className="text-secondary font-bold hover:underline">سياسة الخصوصية</Link>
              </span>
              <Checkbox checked={acceptTerms} onCheckedChange={(v) => setAcceptTerms(!!v)} />
            </label>

            <Button
              type="submit"
              disabled={loading}
              className="w-full h-13 rounded-xl bg-secondary text-secondary-foreground hover:bg-secondary/90 font-black text-lg gap-2"
            >
              {loading ? <Loader2 className="h-5 w-5 animate-spin" /> : null}
              إنشاء الحساب
            </Button>

            <p className="text-center text-sm text-white/60">
              عندك حساب بالفعل؟{" "}
              <Link href="/login" className="text-secondary font-bold hover:underline">تسجيل الدخول</Link>
            </p>
          </form>
        </div>

        {/* Left Side - Brand panel */}
        <div className="hidden lg:flex flex-col items-center justify-center space-y-6 text-center p-12">
          <div className="space-y-4">
            <h2 className="text-3xl font-black text-white">تعلّم بذكاء مع بوصلتي</h2>
            <p className="text-white/60 leading-8 max-w-sm">
              دورات وجلسات مباشرة واختبارات وشهادات معتمدة — كل رحلة تعلمك في مكان واحد.
            </p>
          </div>
        </div>
      </div>
    </main>
  )
}
