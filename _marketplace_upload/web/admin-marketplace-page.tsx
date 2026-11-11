"use client"

import { useEffect, useState } from "react"

type Booking = {
  id: string
  status: string
  payment_status: string
  scheduled_at: string
  amount: string
  currency: string
  student_summary?: { name?: string }
  trainer_summary?: { display_name?: string; id?: string }
  offering?: { title?: string }
}

type Payout = { id: string; amount: string; currency: string; status: string; trainer_name?: string }

export default function AdminMarketplacePage() {
  const [bookings, setBookings] = useState<Booking[]>([])
  const [payouts, setPayouts] = useState<Payout[]>([])
  const [trainers, setTrainers] = useState<Array<{ id: string; display_name?: string; verification_status?: string; profile_review_status?: string; badge_label?: string; headline?: string }>>([])
  const [badges, setBadges] = useState<Record<string, string>>({})
  const [priceOptions, setPriceOptions] = useState<number[]>([])
  const [newPrice, setNewPrice] = useState("")
  const [message, setMessage] = useState("")

  async function load() {
    const [bookingsRes, payoutsRes, trainersRes, settingsRes] = await Promise.all([
      fetch("/api/admin/marketplace/bookings?role=admin", { credentials: "include" }),
      fetch("/api/admin/marketplace/payouts", { credentials: "include" }),
      fetch("/api/admin/marketplace/trainers?status=all", { credentials: "include" }),
      fetch("/api/admin/marketplace/settings", { credentials: "include" }),
    ])
    const bookingsBody = await bookingsRes.json()
    const payoutsBody = await payoutsRes.json()
    if (!bookingsRes.ok) {
      setMessage(bookingsBody.message || "سجل دخول الأدمن")
      return
    }
    setBookings(bookingsBody.data?.bookings || [])
    setPayouts(payoutsBody.data?.payouts || [])
    const trainerRows = (await trainersRes.json()).data?.trainers || []
    setTrainers(trainerRows)
    setBadges(Object.fromEntries(trainerRows.map((trainer: any) => [trainer.id, trainer.badge_label || ""])))
    if (settingsRes.ok) {
      const settingsBody = await settingsRes.json()
      setPriceOptions(settingsBody.data?.price_options_usd || [])
    }
    setMessage("")
  }

  useEffect(() => { load() }, [])

  async function payment(id: string, approve: boolean) {
    await fetch(`/api/admin/marketplace/bookings/${id}/payment`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ approve }),
    })
    await load()
  }

  async function payout(id: string, status: "paid" | "rejected") {
    await fetch(`/api/admin/marketplace/payouts/${id}`, {
      method: "POST",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ status }),
    })
    await load()
  }

  async function verification(trainerId: string, verification_status: string) {
    await fetch(`/api/admin/marketplace/trainers/${trainerId}/verification`, {
      method: "PUT",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ verification_status }),
    })
    await load()
  }

  async function updateTrainer(trainerId: string, body: Record<string, unknown>) {
    const response = await fetch(`/api/admin/marketplace/trainers/${trainerId}`, {
      method: "PUT",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(body),
    })
    const result = await response.json().catch(() => ({}))
    if (!response.ok) {
      setMessage(result.message || "تعذر حفظ بيانات المدرس")
      return
    }
    await load()
  }

  async function profileReview(trainerId: string, approve: boolean) {
    await updateTrainer(trainerId, {
      profile_review_action: approve ? "approve" : "reject",
    })
  }

  async function savePriceOptions(next: number[]) {
    const prices = [...new Set(next)].filter(value => Number.isFinite(value) && value > 0).sort((a, b) => a - b)
    const response = await fetch("/api/admin/marketplace/settings", {
      method: "PUT",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ default_currency: "USD", price_options_usd: prices }),
    })
    const result = await response.json().catch(() => ({}))
    if (response.ok) {
      setPriceOptions(result.data?.price_options_usd || prices)
      setNewPrice("")
    }
    setMessage(response.ok ? "تم حفظ أسعار الجلسات" : result.message || "تعذر حفظ الإعدادات")
  }

  return (
    <div className="p-6 space-y-8 text-right" dir="rtl">
      <div>
        <h1 className="text-2xl font-black">حجوزات الجلسات المباشرة</h1>
        <p className="text-sm text-muted-foreground">موافقة ملفات المدرسين، البادج، رينج السعر بالدولار، قبول إيصالات الدفع، ومراجعة السحب. النسخة القديمة تظل ظاهرة للطلاب لحد قبول أي تعديل.</p>
        {message ? <p className="text-destructive mt-2">{message}</p> : null}
      </div>
      <div className="space-y-3 rounded-2xl border p-4">
        <div className="flex flex-wrap items-end gap-3"><label className="min-w-52 flex-1 text-sm font-bold">إضافة سعر متاح (USD)<input className="mt-2 w-full rounded-lg border px-3 py-2" type="number" min="1" step="0.01" value={newPrice} onChange={event => setNewPrice(event.target.value)} /></label><button className="rounded-lg bg-primary px-4 py-2 font-bold text-primary-foreground" onClick={() => { const value=Number(newPrice); if(value>0) savePriceOptions([...priceOptions,value]) }}>إضافة</button><a className="rounded-lg border px-4 py-2 text-center font-bold" href="/admin/categories">إدارة التصنيفات والمواد</a></div>
        <div className="flex flex-wrap gap-2">{priceOptions.map(price=><span key={price} className="inline-flex items-center gap-2 rounded-full border px-3 py-2"><strong>{Number(price).toFixed(2)} USD</strong><button className="text-red-600" onClick={()=>savePriceOptions(priceOptions.filter(item=>item!==price))}>×</button></span>)}</div>
      </div>
      <div className="space-y-2">
        <h2 className="text-xl font-black">إدارة ملفات المدرسين</h2>
        {trainers.length === 0 ? <p className="text-sm text-muted-foreground">لا توجد ملفات.</p> : null}
        {trainers.map((trainer) => (
          <div key={trainer.id} className="grid gap-3 rounded-xl border p-3 lg:grid-cols-[1fr_260px_auto] lg:items-center">
            <div><strong>{trainer.display_name}</strong><div className="text-sm text-muted-foreground">{trainer.headline || "بدون مسمى"} · الحساب: {trainer.verification_status} · تعديل البروفايل: {trainer.profile_review_status || "لا يوجد"}</div></div>
            <label className="text-sm">بادج المدرس<input className="mt-1 w-full rounded-lg border px-3 py-2" value={badges[trainer.id] || ""} placeholder="مثال: موثّق" onChange={event => setBadges({ ...badges, [trainer.id]: event.target.value })} /></label>
            <span className="flex flex-wrap gap-2">
              <button className="rounded-lg border px-3 py-1" onClick={() => updateTrainer(trainer.id, { badge_label: badges[trainer.id] || null })}>حفظ البادج</button>
              {trainer.verification_status !== "approved" ? <button className="rounded-lg bg-primary text-primary-foreground px-3 py-1" onClick={() => verification(trainer.id, "approved")}>تفعيل الحساب</button> : null}
              {trainer.profile_review_status === "pending" ? <><button className="rounded-lg bg-primary text-primary-foreground px-3 py-1" onClick={() => profileReview(trainer.id, true)}>قبول التعديل</button><button className="rounded-lg border px-3 py-1" onClick={() => profileReview(trainer.id, false)}>رفض التعديل</button></> : null}
              <button className="rounded-lg border px-3 py-1 text-red-600" onClick={() => verification(trainer.id, "suspended")}>إيقاف</button>
            </span>
          </div>
        ))}
      </div>
      <div className="overflow-x-auto rounded-2xl border">
        <table className="w-full text-sm">
          <thead>
            <tr className="border-b">
              {["الطالب", "المدرب", "الجلسة", "الموعد", "المبلغ", "الحالة", "الدفع", ""].map((head) => <th key={head} className="p-3 text-right">{head}</th>)}
            </tr>
          </thead>
          <tbody>
            {bookings.map((row) => (
              <tr key={row.id} className="border-b">
                <td className="p-3">{row.student_summary?.name}</td>
                <td>{row.trainer_summary?.display_name}</td>
                <td>{row.offering?.title}</td>
                <td>{new Date(row.scheduled_at).toLocaleString("ar-EG")}</td>
                <td>{row.amount} {row.currency}</td>
                <td>{row.status}</td>
                <td>{row.payment_status}</td>
                <td className="space-x-2 space-x-reverse">
                  {row.payment_status === "pending" ? (
                    <>
                      <button className="rounded-lg bg-primary text-primary-foreground px-3 py-1" onClick={() => payment(row.id, true)}>قبول</button>
                      <button className="rounded-lg bg-destructive text-white px-3 py-1" onClick={() => payment(row.id, false)}>رفض</button>
                    </>
                  ) : null}
                  {row.trainer_summary?.id ? (
                    <button className="rounded-lg border px-3 py-1" onClick={() => verification(row.trainer_summary!.id!, "suspended")}>إيقاف المدرب</button>
                  ) : null}
                </td>
              </tr>
            ))}
          </tbody>
        </table>
      </div>
      <div>
        <h2 className="text-xl font-black mb-3">طلبات السحب</h2>
        {payouts.length === 0 ? <p className="text-sm text-muted-foreground">لا توجد طلبات.</p> : null}
        <div className="space-y-2">
          {payouts.map((row) => (
            <div key={row.id} className="flex items-center justify-between rounded-xl border p-3">
              <span>{row.trainer_name} · {row.amount} {row.currency} · {row.status}</span>
              {row.status === "pending" ? (
                <span className="space-x-2 space-x-reverse">
                  <button className="rounded-lg bg-primary text-primary-foreground px-3 py-1" onClick={() => payout(row.id, "paid")}>صرف</button>
                  <button className="rounded-lg border px-3 py-1" onClick={() => payout(row.id, "rejected")}>رفض</button>
                </span>
              ) : null}
            </div>
          ))}
        </div>
      </div>
    </div>
  )
}
