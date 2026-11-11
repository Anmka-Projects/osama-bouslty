"use client"

import Link from "next/link"
import { useState } from "react"
import { Button } from "@/components/ui/button"
import { Card, CardContent, CardDescription, CardHeader, CardTitle } from "@/components/ui/card"
import { StatusBadge } from "@/components/ui/status-badge"
import { Switch } from "@/components/ui/switch"
import { Label } from "@/components/ui/label"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { useToast } from "@/hooks/use-toast"

type Trainer = {
  id: string
  display_name?: string
  headline?: string | null
  bio?: string | null
  intro_video_url?: string | null
  years_experience?: number | null
  verification_status?: string
  is_accepting_bookings?: boolean
  rating_average?: number
  rating_count?: number
  students_count?: number
  completed_sessions_count?: number
  specialties?: Array<{ id?: string; name: string }>
  qualifications?: Array<{ id?: string; title: string }>
  offerings?: Array<{
    id: string
    type: string
    title: string
    description?: string | null
    session_count: number
    duration_minutes: number
    price?: string | null
    discount_price?: string | null
    currency?: string
    is_active: boolean
  }>
  availability_rules?: Array<{ weekday: number; start_minute: number; end_minute: number }>
}

const days = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]

function timeLabel(minute: number) {
  const h = Math.floor(minute / 60).toString().padStart(2, "0")
  const m = (minute % 60).toString().padStart(2, "0")
  return `${h}:${m}`
}

export function InstructorTrainerDetails({
  userId,
  trainer,
  taughtCourses = [],
  bookingStudents = [],
  onChanged,
}: {
  userId: string
  trainer: Trainer | null
  taughtCourses?: any[]
  bookingStudents?: any[]
  onChanged?: () => void
}) {
  const { toast } = useToast()
  const [saving, setSaving] = useState(false)
  const [local, setLocal] = useState(trainer)

  if (!local) {
    return (
      <Card>
        <CardHeader>
          <CardTitle>ملف المدرب (Marketplace)</CardTitle>
          <CardDescription>لا يوجد ملف مدرب بعد — سيُنشأ تلقائيًا عند أول فتح للبروفايل.</CardDescription>
        </CardHeader>
        <CardContent>
          <Button asChild variant="outline">
            <Link href={`/admin/marketplace`}>فتح إدارة المدرسين والجلسات</Link>
          </Button>
        </CardContent>
      </Card>
    )
  }

  async function setVerification(value: string) {
    setSaving(true)
    try {
      const res = await fetch(`/api/admin/marketplace/trainers/${userId}/verification`, {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ verification_status: value }),
      })
      const body = await res.json().catch(() => ({}))
      if (!res.ok) throw new Error(body.message || "فشل تحديث الحالة")
      setLocal((t) => (t ? { ...t, verification_status: value, is_accepting_bookings: value === "approved" } : t))
      toast({ title: "تم تحديث ظهور المدرب للطلاب" })
      onChanged?.()
    } catch (e: any) {
      toast({ title: e?.message || "فشل التحديث", variant: "destructive" })
    } finally {
      setSaving(false)
    }
  }

  async function toggleAccepting(checked: boolean) {
    setSaving(true)
    try {
      const res = await fetch(`/api/admin/marketplace/trainers/${userId}`, {
        method: "PUT",
        credentials: "include",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ is_accepting_bookings: checked }),
      })
      const body = await res.json().catch(() => ({}))
      if (!res.ok) throw new Error(body.message || "فشل التحديث")
      setLocal((t) => (t ? { ...t, is_accepting_bookings: checked } : t))
      toast({ title: checked ? "المدرب ظاهر ويستقبل حجوزات" : "تم إيقاف استقبال الحجوزات" })
      onChanged?.()
    } catch (e: any) {
      toast({ title: e?.message || "فشل التحديث", variant: "destructive" })
    } finally {
      setSaving(false)
    }
  }

  return (
    <div className="space-y-6">
      <Card>
        <CardHeader>
          <div className="flex flex-wrap items-start justify-between gap-3">
            <div>
              <CardTitle>ملف المدرب الكامل</CardTitle>
              <CardDescription>
                {local.display_name}
                {local.headline ? ` · ${local.headline}` : ""}
              </CardDescription>
            </div>
            <div className="flex flex-wrap items-center gap-2">
              <Select value={local.verification_status || "pending"} onValueChange={setVerification} disabled={saving}>
                <SelectTrigger className="w-[180px]">
                  <SelectValue placeholder="حالة الظهور" />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="pending">بانتظار الموافقة</SelectItem>
                  <SelectItem value="approved">ظاهر للطلاب</SelectItem>
                  <SelectItem value="rejected">مرفوض</SelectItem>
                  <SelectItem value="suspended">موقوف</SelectItem>
                  <SelectItem value="draft">مسودة</SelectItem>
                </SelectContent>
              </Select>
              <Button asChild variant="outline" size="sm">
                <Link href="/admin/marketplace">تعديل متقدم</Link>
              </Button>
            </div>
          </div>
        </CardHeader>
        <CardContent className="space-y-4">
          <div className="flex items-center gap-3 rounded-xl border p-3">
            <Switch
              checked={!!local.is_accepting_bookings && local.verification_status === "approved"}
              disabled={saving || local.verification_status !== "approved"}
              onCheckedChange={toggleAccepting}
            />
            <Label>ظاهر للطلاب ويستقبل حجوزات</Label>
            <StatusBadge status={local.verification_status === "approved" ? "success" : "warning"}>
              {local.verification_status || "—"}
            </StatusBadge>
          </div>
          <div className="grid gap-3 md:grid-cols-2">
            <div>
              <p className="text-sm text-muted-foreground">النبذة</p>
              <p className="whitespace-pre-wrap">{local.bio || "—"}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">الفيديو التعريفي</p>
              {local.intro_video_url ? (
                <a className="text-primary underline break-all" href={local.intro_video_url} target="_blank" rel="noreferrer">
                  {local.intro_video_url}
                </a>
              ) : (
                <p>—</p>
              )}
            </div>
            <div>
              <p className="text-sm text-muted-foreground">سنوات الخبرة</p>
              <p>{local.years_experience ?? "—"}</p>
            </div>
            <div>
              <p className="text-sm text-muted-foreground">التقييم / الطلاب / الجلسات</p>
              <p>
                {local.rating_average ?? 0} ({local.rating_count ?? 0}) · {local.students_count ?? 0} طالب ·{" "}
                {local.completed_sessions_count ?? 0} جلسة
              </p>
            </div>
            <div className="md:col-span-2">
              <p className="text-sm text-muted-foreground">التخصصات</p>
              <p>{(local.specialties || []).map((s) => s.name).join("، ") || "—"}</p>
            </div>
            <div className="md:col-span-2">
              <p className="text-sm text-muted-foreground">المؤهلات</p>
              <p>{(local.qualifications || []).map((q) => q.title).join("، ") || "—"}</p>
            </div>
          </div>
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>الباقات والجلسات ({local.offerings?.length || 0})</CardTitle>
        </CardHeader>
        <CardContent className="space-y-3">
          {(local.offerings || []).length === 0 ? <p className="text-sm text-muted-foreground">لا توجد باقات.</p> : null}
          {(local.offerings || []).map((o) => (
            <div key={o.id} className="rounded-xl border p-3">
              <div className="flex flex-wrap items-center justify-between gap-2">
                <div className="font-medium">
                  {o.title} · {o.type === "package" ? "باقة" : "جلسة فردية"}
                </div>
                <StatusBadge status={o.is_active ? "success" : "warning"}>{o.is_active ? "ظاهرة" : "مخفية"}</StatusBadge>
              </div>
              <p className="text-sm text-muted-foreground mt-1">{o.description || "—"}</p>
              <p className="text-sm mt-1">
                {o.session_count} جلسة · {o.duration_minutes} دقيقة · {o.discount_price || o.price} {o.currency}
                {o.discount_price ? ` (قبل الخصم ${o.price})` : ""}
              </p>
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>مواعيد التوافر</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {(local.availability_rules || []).length === 0 ? <p className="text-sm text-muted-foreground">لا توجد مواعيد.</p> : null}
          {(local.availability_rules || []).map((r, idx) => (
            <div key={idx} className="flex justify-between rounded-lg border px-3 py-2 text-sm">
              <span>{days[r.weekday] || r.weekday}</span>
              <span>
                {timeLabel(r.start_minute)} — {timeLabel(r.end_minute)}
              </span>
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>الكورسات ({taughtCourses.length})</CardTitle>
        </CardHeader>
        <CardContent className="space-y-2">
          {taughtCourses.length === 0 ? <p className="text-sm text-muted-foreground">لا توجد كورسات.</p> : null}
          {taughtCourses.map((c) => (
            <div key={c.id} className="flex justify-between rounded-lg border px-3 py-2 text-sm">
              <span>{c.title}</span>
              <span className="text-muted-foreground">
                {c.status} · {c.studentsCount || 0} طالب
              </span>
            </div>
          ))}
        </CardContent>
      </Card>

      <Card>
        <CardHeader>
          <CardTitle>طلاب الحجوزات المباشرة ({bookingStudents.length})</CardTitle>
          <CardDescription>يشمل الطلاب اللي حجزوا مع المدرس حتى لو مش مسجلين في كورس.</CardDescription>
        </CardHeader>
        <CardContent className="space-y-2">
          {bookingStudents.length === 0 ? <p className="text-sm text-muted-foreground">لا يوجد طلاب حجوزات بعد.</p> : null}
          {bookingStudents.map((s) => (
            <div key={s.id} className="flex items-center justify-between rounded-lg border px-3 py-2 text-sm">
              <div>
                <div className="font-medium">{s.name}</div>
                <div className="text-muted-foreground">
                  {s.email} {s.phone ? `· ${s.phone}` : ""}
                </div>
              </div>
              <Button asChild size="sm" variant="outline">
                <Link href={`/admin/users/${s.id}/details`}>عرض</Link>
              </Button>
            </div>
          ))}
        </CardContent>
      </Card>
    </div>
  )
}
