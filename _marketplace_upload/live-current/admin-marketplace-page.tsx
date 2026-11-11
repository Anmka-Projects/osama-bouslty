"use client"

import { useEffect, useMemo, useState } from "react"
import { AdminLayout } from "@/components/layout/admin-layout"

type Offering = {
  id?: string
  type: "single_session" | "package"
  title: string
  description?: string
  session_count: number
  duration_minutes: number
  price: string
  discount_price?: string | null
  currency: string
  is_active: boolean
}

type Rule = { id?: string; weekday: number; start_minute: number; end_minute: number }
type TrainerSummary = {
  id: string
  display_name: string
  headline?: string
  verification_status: string
  is_accepting_bookings: boolean
  starting_price?: string
  currency?: string
  active_offerings_count?: number
}
type TrainerDetail = TrainerSummary & {
  bio?: string
  intro_video_url?: string
  years_experience?: number | null
  specialties: Array<{ id?: string; name: string }>
  offerings: Offering[]
  timezone?: string
  slot_duration_minutes?: number
  buffer_minutes?: number
  availability: { timezone: string; slot_duration_minutes: number; buffer_minutes: number; rules: Rule[] }
  user?: { email?: string; phone?: string; status?: string }
}
type Booking = {
  id: string; status: string; payment_status: string; scheduled_at: string; amount: string; currency: string
  student_summary?: { name?: string }; trainer_summary?: { display_name?: string; id?: string }; offering?: { title?: string }
}
type Payout = { id: string; amount: string; currency: string; status: string; trainer_name?: string }
type Section = "trainers" | "bookings" | "payouts" | "paths" | "prices"

const days = ["الأحد", "الإثنين", "الثلاثاء", "الأربعاء", "الخميس", "الجمعة", "السبت"]

async function api(url: string, init?: RequestInit) {
  const response = await fetch(url, { credentials: "include", ...init })
  const body = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(body.message || "تعذر تنفيذ الطلب")
  return body.data
}

function numberTime(value: number) {
  const h = Math.floor(value / 60).toString().padStart(2, "0")
  const m = (value % 60).toString().padStart(2, "0")
  return `${h}:${m}`
}

function timeNumber(value: string) {
  const [h, m] = value.split(":").map(Number)
  return (h || 0) * 60 + (m || 0)
}

export default function AdminMarketplacePage() {
  const [section, setSection] = useState<Section>("trainers")
  const [trainers, setTrainers] = useState<TrainerSummary[]>([])
  const [bookings, setBookings] = useState<Booking[]>([])
  const [payouts, setPayouts] = useState<Payout[]>([])
  const [paths, setPaths] = useState<string[]>([])
  const [newPath, setNewPath] = useState("")
  const [priceOptions, setPriceOptions] = useState<number[]>([])
  const [newPrice, setNewPrice] = useState("")
  const [status, setStatus] = useState("all")
  const [query, setQuery] = useState("")
  const [selected, setSelected] = useState<TrainerDetail | null>(null)
  const [loading, setLoading] = useState(true)
  const [saving, setSaving] = useState(false)
  const [message, setMessage] = useState("")

  async function load() {
    setLoading(true)
    try {
      const [trainerData, bookingData, payoutData, pathData, settingsData] = await Promise.all([
        api(`/api/admin/marketplace/trainers?status=${encodeURIComponent(status)}&q=${encodeURIComponent(query)}`),
        api("/api/admin/marketplace/bookings?role=admin&per_page=50"),
        api("/api/admin/marketplace/payouts"),
        api("/api/paths"),
        api("/api/admin/marketplace/settings"),
      ])
      setTrainers(trainerData?.trainers || [])
      setBookings(bookingData?.bookings || [])
      setPayouts(payoutData?.payouts || [])
      setPaths(pathData?.paths || [])
      setPriceOptions(settingsData?.price_options_usd || [])
      setMessage("")
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "تعذر تحميل البيانات")
    } finally {
      setLoading(false)
    }
  }

  useEffect(() => {
    const searchParams = new URLSearchParams(window.location.search)
    const requested = searchParams.get("section") as Section | null
    if (requested && ["trainers", "bookings", "payouts", "paths", "prices"].includes(requested)) {
      setSection(requested)
    }
    if (searchParams.get("review") === "pending") setStatus("pending")
  }, [])

  useEffect(() => { load() }, [status])

  async function openTrainer(id: string) {
    setSaving(true)
    try {
      setSelected(await api(`/api/admin/marketplace/trainers/${id}`))
      setMessage("")
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "تعذر تحميل المدرس")
    } finally { setSaving(false) }
  }

  function patchDetail(patch: Partial<TrainerDetail>) {
    setSelected((current) => current ? { ...current, ...patch } : current)
  }

  function patchOffering(index: number, patch: Partial<Offering>) {
    if (!selected) return
    patchDetail({ offerings: selected.offerings.map((item, i) => i === index ? { ...item, ...patch } : item) })
  }

  async function saveTrainer() {
    if (!selected) return
    for (const item of selected.offerings) {
      const price = Number(item.price)
      const discount = item.discount_price ? Number(item.discount_price) : null
      if (!item.title.trim() || !price || price <= 0 || item.session_count < 1) {
        setMessage("راجع اسم الباقة والسعر وعدد الجلسات")
        return
      }
      if (discount !== null && discount >= price) {
        setMessage("السعر بعد الخصم يجب أن يكون أقل من السعر الأصلي")
        return
      }
    }
    setSaving(true)
    try {
      const updated = await api(`/api/admin/marketplace/trainers/${selected.id}`, {
        method: "PUT", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          display_name: selected.display_name,
          headline: selected.headline || "",
          bio: selected.bio || "",
          intro_video_url: selected.intro_video_url || "",
          years_experience: selected.years_experience,
          is_accepting_bookings: selected.is_accepting_bookings,
          specialties: selected.specialties.map((item) => item.name).filter(Boolean),
          offerings: selected.offerings,
          languages: ["ar"],
        }),
      })
      setSelected(updated)
      setMessage("تم حفظ ملف المدرس والباقات")
      await load()
    } catch (error) { setMessage(error instanceof Error ? error.message : "فشل الحفظ") }
    finally { setSaving(false) }
  }

  async function saveAvailability() {
    if (!selected) return
    setSaving(true)
    try {
      const updated = await api(`/api/admin/marketplace/trainers/${selected.id}/availability`, {
        method: "PUT", headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          timezone: selected.availability.timezone || "Africa/Cairo",
          slot_duration_minutes: selected.availability.slot_duration_minutes || 60,
          buffer_minutes: selected.availability.buffer_minutes || 0,
          rules: selected.availability.rules,
        }),
      })
      setSelected(updated)
      setMessage("تم حفظ مواعيد المدرس")
    } catch (error) { setMessage(error instanceof Error ? error.message : "فشل حفظ المواعيد") }
    finally { setSaving(false) }
  }

  async function setVerification(value: string) {
    if (!selected) return
    setSaving(true)
    try {
      await api(`/api/admin/marketplace/trainers/${selected.id}/verification`, {
        method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ verification_status: value }),
      })
      await openTrainer(selected.id)
      await load()
      setMessage("تم تحديث حالة المدرس")
    } catch (error) { setMessage(error instanceof Error ? error.message : "فشل تحديث الحالة") }
    finally { setSaving(false) }
  }

  async function payment(id: string, approve: boolean) {
    try {
      await api(`/api/admin/marketplace/bookings/${id}/payment`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ approve }) })
      await load()
    } catch (error) { setMessage(error instanceof Error ? error.message : "فشل تحديث الدفع") }
  }

  async function decidePayout(id: string, payoutStatus: "paid" | "rejected") {
    try {
      await api(`/api/admin/marketplace/payouts/${id}`, { method: "POST", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ status: payoutStatus }) })
      await load()
    } catch (error) { setMessage(error instanceof Error ? error.message : "فشل تحديث السحب") }
  }

  async function savePaths(next: string[]) {
    try {
      await api("/api/admin/marketplace/settings", { method: "PUT", headers: { "Content-Type": "application/json" }, body: JSON.stringify({ paths: next }) })
      setPaths(next); setNewPath(""); setMessage("تم حفظ المسارات")
    } catch (error) { setMessage(error instanceof Error ? error.message : "فشل حفظ المسارات") }
  }

  async function savePriceOptions(next: number[]) {
    const normalized = [...new Set(next)]
      .filter((value) => Number.isFinite(value) && value > 0)
      .sort((a, b) => a - b)
    try {
      const saved = await api("/api/admin/marketplace/settings", {
        method: "PUT",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ default_currency: "USD", price_options_usd: normalized }),
      })
      setPriceOptions(saved?.price_options_usd || normalized)
      setNewPrice("")
      setMessage("تم حفظ أسعار الجلسات المتاحة للمدرسين")
    } catch (error) {
      setMessage(error instanceof Error ? error.message : "فشل حفظ الأسعار")
    }
  }

  const counts = useMemo(() => ({
    trainers: trainers.length,
    pending: trainers.filter((item) => item.verification_status === "pending").length,
    bookings: bookings.length,
    payouts: payouts.filter((item) => item.status === "pending").length,
  }), [trainers, bookings, payouts])

  return (
    <AdminLayout title="إدارة المدرسين والجلسات" subtitle="تحكم كامل في الملفات والباقات والمواعيد والحجوزات.">
    <div className="space-y-6 text-right" dir="rtl">
      <div className="flex flex-wrap items-start justify-between gap-3">
        <div><h1 className="text-2xl font-black">إدارة المدرسين والجلسات</h1><p className="text-sm text-muted-foreground">تحكم كامل في الملفات والباقات والمواعيد والحجوزات.</p></div>
        <button className="rounded-lg border px-4 py-2 text-sm" onClick={load}>تحديث البيانات</button>
      </div>
      {message ? <div className="rounded-xl border bg-muted/40 p-3 text-sm">{message}</div> : null}
      <div className="grid grid-cols-2 gap-3 md:grid-cols-4">
        {[['المدرسون', counts.trainers], ['بانتظار الموافقة', counts.pending], ['الحجوزات', counts.bookings], ['طلبات السحب', counts.payouts]].map(([label, value]) => <div key={String(label)} className="rounded-2xl border p-4"><div className="text-sm text-muted-foreground">{label}</div><div className="text-2xl font-black">{value}</div></div>)}
      </div>
      <div className="flex flex-wrap gap-2">
        {([['trainers','المدرسون والباقات'],['bookings','جلسات المدربين'],['payouts','طلبات السحب'],['prices','أسعار الجلسات'],['paths','المسارات']] as Array<[Section,string]>).map(([id,label]) => <button key={id} onClick={() => setSection(id)} className={`rounded-xl px-4 py-2 text-sm ${section === id ? 'bg-primary text-primary-foreground' : 'border'}`}>{label}</button>)}
      </div>

      {section === "prices" ? <div className="max-w-2xl space-y-4 rounded-2xl border p-5">
        <div><h2 className="text-xl font-black">أسعار الساعة المتاحة للمدرسين</h2><p className="text-sm text-muted-foreground">المدرس لن يكتب سعرًا؛ سيختار قيمة من القائمة التالية بالدولار.</p></div>
        <div className="flex gap-2"><input type="number" min={1} step="0.01" className="min-w-0 flex-1 rounded-lg border px-3 py-2" value={newPrice} onChange={(event) => setNewPrice(event.target.value)} placeholder="مثال: 25"/><button className="rounded-lg bg-primary px-4 py-2 text-primary-foreground" onClick={() => { const value=Number(newPrice); if(value>0) savePriceOptions([...priceOptions,value]) }}>إضافة السعر</button></div>
        <div className="flex flex-wrap gap-2">{priceOptions.map((price) => <span key={price} className="inline-flex items-center gap-2 rounded-full border px-3 py-2"><strong>{Number(price).toFixed(2)} USD</strong><button className="text-red-600" onClick={() => savePriceOptions(priceOptions.filter((item) => item !== price))}>×</button></span>)}</div>
        {!priceOptions.length ? <p className="text-sm text-amber-700">أضف سعرًا واحدًا على الأقل حتى يقدر المدرسون إنشاء جلسات أو باقات.</p> : null}
      </div> : null}

      {section === "trainers" ? <div className="grid gap-5 xl:grid-cols-[360px_1fr]">
        <div className="space-y-3">
          <div className="flex gap-2"><input className="min-w-0 flex-1 rounded-lg border px-3 py-2" value={query} onChange={(e) => setQuery(e.target.value)} placeholder="بحث بالاسم أو البريد أو الهاتف" onKeyDown={(e) => e.key === 'Enter' && load()} /><button className="rounded-lg border px-3" onClick={load}>بحث</button></div>
          <select className="w-full rounded-lg border px-3 py-2" value={status} onChange={(e) => setStatus(e.target.value)}><option value="all">كل الحالات</option><option value="pending">بانتظار الموافقة</option><option value="approved">معتمد</option><option value="rejected">مرفوض</option><option value="suspended">موقوف</option><option value="draft">مسودة</option></select>
          <div className="max-h-[760px] space-y-2 overflow-auto">
            {loading ? <p>جارٍ التحميل...</p> : trainers.map((trainer) => <button key={trainer.id} onClick={() => openTrainer(trainer.id)} className={`w-full rounded-xl border p-3 text-right ${selected?.id === trainer.id ? 'border-primary bg-primary/5' : ''}`}><div className="font-bold">{trainer.display_name}</div><div className="text-xs text-muted-foreground">{trainer.headline || 'بدون مسمى'} · {trainer.verification_status}</div><div className="mt-1 text-xs">{trainer.active_offerings_count || 0} باقة نشطة · {trainer.starting_price || '—'} {trainer.currency || ''}</div></button>)}</div>
        </div>
        <div>{selected ? <div className="space-y-6">
          <div className="rounded-2xl border p-4 space-y-4">
            <div className="flex flex-wrap items-center justify-between gap-2"><div><h2 className="text-xl font-black">ملف {selected.display_name}</h2><p className="text-xs text-muted-foreground">{selected.user?.email} · {selected.user?.phone}</p></div><div className="flex gap-2"><select className="rounded-lg border px-3 py-2" value={selected.verification_status} onChange={(e) => setVerification(e.target.value)} disabled={saving}><option value="pending">بانتظار الموافقة</option><option value="approved">معتمد</option><option value="rejected">مرفوض</option><option value="suspended">موقوف</option><option value="draft">مسودة</option></select></div></div>
            <div className="grid gap-3 md:grid-cols-2"><label className="text-sm">الاسم الظاهر<input className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.display_name} onChange={(e) => patchDetail({ display_name: e.target.value })} /></label><label className="text-sm">المسمى التعريفي<input className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.headline || ''} onChange={(e) => patchDetail({ headline: e.target.value })} /></label><label className="text-sm md:col-span-2">النبذة<textarea className="mt-1 w-full rounded-lg border px-3 py-2" rows={3} value={selected.bio || ''} onChange={(e) => patchDetail({ bio: e.target.value })} /></label><label className="text-sm">الفيديو التعريفي<input className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.intro_video_url || ''} onChange={(e) => patchDetail({ intro_video_url: e.target.value })} /></label><label className="text-sm">سنوات الخبرة<input type="number" min={0} className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.years_experience ?? ''} onChange={(e) => patchDetail({ years_experience: e.target.value === '' ? null : Number(e.target.value) })} /></label><label className="text-sm md:col-span-2">التخصصات (بفاصلة)<input className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.specialties.map((item) => item.name).join(', ')} onChange={(e) => patchDetail({ specialties: e.target.value.split(',').map((name) => ({ name: name.trim() })).filter((item) => item.name) })} /></label></div>
            <label className="flex items-center gap-2 text-sm"><input type="checkbox" checked={selected.is_accepting_bookings} disabled={selected.verification_status !== 'approved'} onChange={(e) => patchDetail({ is_accepting_bookings: e.target.checked })} />يستقبل حجوزات من الطلاب</label>
          </div>

          <div className="rounded-2xl border p-4 space-y-3"><div className="flex items-center justify-between"><h3 className="text-lg font-black">الجلسات والباقات</h3><button disabled={!priceOptions.length} className="rounded-lg border px-3 py-2 text-sm disabled:opacity-50" onClick={() => patchDetail({ offerings: [...selected.offerings, { type:'package', title:'باقة جديدة', description:'', session_count:4, duration_minutes:60, price:String(priceOptions[0]), discount_price:null, currency:'USD', is_active:true }] })}>إضافة باقة</button></div>
            {selected.offerings.map((item, index) => <div key={item.id || index} className="grid gap-2 rounded-xl bg-muted/40 p-3 md:grid-cols-6"><select className="rounded-lg border px-2 py-2" value={item.type} onChange={(e) => patchOffering(index, { type: e.target.value as Offering['type'], session_count: e.target.value === 'single_session' ? 1 : item.session_count })}><option value="single_session">جلسة فردية</option><option value="package">باقة</option></select><input className="rounded-lg border px-2 py-2 md:col-span-2" value={item.title} onChange={(e) => patchOffering(index, { title: e.target.value })} placeholder="الاسم" /><input type="number" min={1} className="rounded-lg border px-2 py-2" value={item.session_count} onChange={(e) => patchOffering(index, { session_count: Number(e.target.value) })} title="عدد الجلسات" /><input type="number" min={15} className="rounded-lg border px-2 py-2" value={item.duration_minutes} onChange={(e) => patchOffering(index, { duration_minutes: Number(e.target.value) })} title="مدة الجلسة" /><label className="flex items-center gap-1 text-xs"><input type="checkbox" checked={item.is_active} onChange={(e) => patchOffering(index, { is_active: e.target.checked })} />ظاهرة</label><textarea className="rounded-lg border px-2 py-2 md:col-span-3" value={item.description || ''} onChange={(e) => patchOffering(index, { description: e.target.value })} placeholder="الوصف" /><select className="rounded-lg border px-2 py-2" value={item.price} onChange={(e) => patchOffering(index, { price:e.target.value, currency:'USD', discount_price:null })}><option value="">اختار السعر</option>{priceOptions.map((price)=><option key={price} value={String(price)}>{Number(price).toFixed(2)} USD</option>)}</select><select className="rounded-lg border px-2 py-2" value={item.discount_price || ''} onChange={(e) => patchOffering(index, { discount_price:e.target.value || null })}><option value="">بدون خصم</option>{priceOptions.filter((price)=>price<Number(item.price)).map((price)=><option key={price} value={String(price)}>{Number(price).toFixed(2)} USD</option>)}</select><input disabled className="rounded-lg border px-2 py-2" value="USD" /></div>)}
            <button disabled={saving} className="rounded-lg bg-primary px-5 py-2 text-primary-foreground disabled:opacity-50" onClick={saveTrainer}>{saving ? 'جارٍ الحفظ...' : 'حفظ الملف والباقات'}</button>
          </div>

          <div className="rounded-2xl border p-4 space-y-3"><h3 className="text-lg font-black">مواعيد التوافر</h3><div className="grid gap-3 md:grid-cols-3"><label className="text-sm">المنطقة الزمنية<input className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.availability.timezone} onChange={(e) => patchDetail({ availability: { ...selected.availability, timezone: e.target.value } })} /></label><label className="text-sm">مدة الجلسة<input type="number" min={15} className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.availability.slot_duration_minutes} onChange={(e) => patchDetail({ availability: { ...selected.availability, slot_duration_minutes: Number(e.target.value) } })} /></label><label className="text-sm">الفاصل بالدقائق<input type="number" min={0} className="mt-1 w-full rounded-lg border px-3 py-2" value={selected.availability.buffer_minutes} onChange={(e) => patchDetail({ availability: { ...selected.availability, buffer_minutes: Number(e.target.value) } })} /></label></div>
            <div className="grid gap-2 md:grid-cols-2">{days.map((day, weekday) => { const rule = selected.availability.rules.find((item) => item.weekday === weekday); return <div key={day} className="flex items-center gap-2 rounded-xl bg-muted/40 p-3"><input type="checkbox" checked={Boolean(rule)} onChange={(e) => patchDetail({ availability: { ...selected.availability, rules: e.target.checked ? [...selected.availability.rules, { weekday, start_minute:960, end_minute:1260 }] : selected.availability.rules.filter((item) => item.weekday !== weekday) } })} /><span className="w-16 text-sm font-bold">{day}</span>{rule ? <><input type="time" className="min-w-0 rounded border px-2 py-1" value={numberTime(rule.start_minute)} onChange={(e) => patchDetail({ availability: { ...selected.availability, rules: selected.availability.rules.map((item) => item.weekday === weekday ? { ...item, start_minute: timeNumber(e.target.value) } : item) } })} /><span>—</span><input type="time" className="min-w-0 rounded border px-2 py-1" value={numberTime(rule.end_minute)} onChange={(e) => patchDetail({ availability: { ...selected.availability, rules: selected.availability.rules.map((item) => item.weekday === weekday ? { ...item, end_minute: timeNumber(e.target.value) } : item) } })} /></> : <span className="text-xs text-muted-foreground">غير متاح</span>}</div> })}</div>
            <button disabled={saving} className="rounded-lg bg-primary px-5 py-2 text-primary-foreground disabled:opacity-50" onClick={saveAvailability}>حفظ المواعيد</button>
          </div>
        </div> : <div className="rounded-2xl border p-10 text-center text-muted-foreground">اختر مدرسًا لعرض ملفه والتحكم فيه.</div>}</div>
      </div> : null}

      {section === "bookings" ? <div className="overflow-x-auto rounded-2xl border"><table className="w-full text-sm"><thead><tr className="border-b">{["الطالب","المدرس","الجلسة","الموعد","المبلغ","الحالة","الدفع","الإجراء"].map((head) => <th key={head} className="p-3 text-right">{head}</th>)}</tr></thead><tbody>{bookings.map((row) => <tr key={row.id} className="border-b"><td className="p-3">{row.student_summary?.name}</td><td>{row.trainer_summary?.display_name}</td><td>{row.offering?.title}</td><td>{new Date(row.scheduled_at).toLocaleString('ar-EG')}</td><td>{row.amount} {row.currency}</td><td>{row.status}</td><td>{row.payment_status}</td><td className="space-x-2 space-x-reverse">{row.payment_status === 'pending' ? <><button className="rounded bg-primary px-3 py-1 text-primary-foreground" onClick={() => payment(row.id,true)}>قبول الدفع</button><button className="rounded border px-3 py-1" onClick={() => payment(row.id,false)}>رفض</button></> : '—'}</td></tr>)}</tbody></table></div> : null}

      {section === "payouts" ? <div className="space-y-2">{payouts.length === 0 ? <p>لا توجد طلبات سحب.</p> : payouts.map((row) => <div key={row.id} className="flex flex-wrap items-center justify-between gap-3 rounded-xl border p-4"><span>{row.trainer_name} · {row.amount} {row.currency} · {row.status}</span>{row.status === 'pending' ? <span className="flex gap-2"><button className="rounded bg-primary px-3 py-1 text-primary-foreground" onClick={() => decidePayout(row.id,'paid')}>صرف</button><button className="rounded border px-3 py-1" onClick={() => decidePayout(row.id,'rejected')}>رفض</button></span> : null}</div>)}</div> : null}

      {section === "paths" ? <div className="space-y-3 rounded-2xl border p-4"><h2 className="text-xl font-black">المسارات المتاحة للطلاب</h2><div className="flex gap-2"><input value={newPath} onChange={(e) => setNewPath(e.target.value)} placeholder="اسم المسار الجديد" className="flex-1 rounded-lg border px-3 py-2" /><button className="rounded-lg bg-primary px-4 text-primary-foreground" onClick={() => { const value = newPath.trim(); if (value && !paths.includes(value)) savePaths([...paths,value]) }}>إضافة</button></div><div className="flex flex-wrap gap-2">{paths.map((path) => <span key={path} className="inline-flex items-center gap-2 rounded-full border px-3 py-1">{path}<button className="font-bold text-destructive" onClick={() => savePaths(paths.filter((item) => item !== path))}>×</button></span>)}</div></div> : null}
    </div>
    </AdminLayout>
  )
}
