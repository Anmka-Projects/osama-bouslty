"use client"

import { useEffect, useState } from "react"
import { AdminLayout } from "@/components/layout/admin-layout"

async function api(url: string, init?: RequestInit) {
  const response = await fetch(url, {
    credentials: "include",
    headers: { "Content-Type": "application/json", ...(init?.headers || {}) },
    ...init,
  })
  const body = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(body.message || "تعذر تنفيذ الطلب")
  return body.data
}

type Review = { id: string; display_name: string; headline?: string; pending_profile?: Record<string, unknown> }
type Alert = { id: string; sender_name: string; original_body: string; cleaned_body?: string; created_at: string; is_read: boolean }

export default function TutorControlsPage() {
  const [priceOptions, setPriceOptions] = useState<number[]>([])
  const [newPrice, setNewPrice] = useState("")
  const [reviews, setReviews] = useState<Review[]>([])
  const [alerts, setAlerts] = useState<Alert[]>([])
  const [badgeUser, setBadgeUser] = useState("")
  const [badge, setBadge] = useState("")
  const [message, setMessage] = useState("")

  const load = async () => {
    const [pricing, reviewData, alertData] = await Promise.all([
      api("/api/admin/marketplace/settings"),
      api("/api/admin/marketplace/profile-reviews"),
      api("/api/chat/moderation-alerts"),
    ])
    setPriceOptions(pricing.price_options_usd || [pricing.min_hourly_usd, pricing.max_hourly_usd].filter(Boolean))
    setReviews(reviewData.reviews || [])
    setAlerts(alertData.alerts || [])
  }

  useEffect(() => {
    load().catch((error) => setMessage(error.message))
  }, [])

  const savePrices = async (values: number[]) => {
    const normalized = Array.from(new Set(values.map(Number).filter((value) => Number.isFinite(value) && value > 0))).sort((a, b) => a - b)
    const saved = await api("/api/admin/marketplace/settings", { method: "PUT", body: JSON.stringify({ price_options_usd: normalized }) })
    setPriceOptions(saved.price_options_usd || normalized)
    setNewPrice("")
    setMessage("اتحفظت أسعار الساعة المتاحة للمدرسين")
  }

  return (
    <AdminLayout title="مراجعة البروفايل والتنبيهات" subtitle="الأسعار، موافقة البروفايل، البادج، وتنبيهات الشات.">
    <div className="space-y-8 text-right" dir="rtl">
      <div>
        <h1 className="text-2xl font-black">مراجعة المدرسين والتنبيهات</h1>
        <p className="text-sm text-muted-foreground">السعر بالدولار، موافقة البروفايل، البادج، وتنبيهات الشات.</p>
      </div>
      {message ? <div className="rounded-xl border bg-muted/40 p-3 text-sm">{message}</div> : null}

      <section className="space-y-3 rounded-2xl border p-4">
        <h2 className="text-lg font-black">أسعار الساعة المتاحة بالدولار</h2>
        <p className="text-sm text-muted-foreground">المدرس يختار من الأسعار دي فقط، ومش هيقدر يكتب سعر من عنده.</p>
        <div className="flex flex-wrap gap-3">
          <input type="number" min={1} step="0.01" className="rounded-lg border px-3 py-2" placeholder="مثال: 25" value={newPrice} onChange={(e) => setNewPrice(e.target.value)} />
          <button className="rounded-lg bg-primary px-4 py-2 text-primary-foreground" onClick={() => { const value = Number(newPrice); if (value > 0) savePrices([...priceOptions, value]).catch((error) => setMessage(error.message)) }}>إضافة السعر</button>
        </div>
        <div className="flex flex-wrap gap-2">{priceOptions.map((price) => <span key={price} className="inline-flex items-center gap-2 rounded-full border px-3 py-2"><strong>{Number(price).toFixed(2)} USD</strong><button className="text-red-600" onClick={() => savePrices(priceOptions.filter((item) => item !== price)).catch((error) => setMessage(error.message))}>×</button></span>)}</div>
      </section>

      <section className="space-y-3 rounded-2xl border p-4">
        <h2 className="text-lg font-black">تعديلات البروفايل بانتظار الموافقة</h2>
        {reviews.length === 0 ? <p className="text-sm text-muted-foreground">مفيش تعديلات معلقة.</p> : reviews.map((review) => (
          <div key={review.id} className="space-y-2 rounded-xl border p-3">
            <div className="font-bold">{review.display_name}</div>
            <pre className="max-h-40 overflow-auto whitespace-pre-wrap text-xs">{JSON.stringify(review.pending_profile, null, 2)}</pre>
            <div className="flex gap-2">
              <button className="rounded bg-primary px-3 py-1 text-primary-foreground" onClick={async () => { await api(`/api/admin/marketplace/profile-reviews/${review.id}`, { method: "POST", body: JSON.stringify({ approve: true }) }); await load() }}>قبول</button>
              <button className="rounded border px-3 py-1" onClick={async () => { await api(`/api/admin/marketplace/profile-reviews/${review.id}`, { method: "POST", body: JSON.stringify({ approve: false, note: "محتاج تعديل" }) }); await load() }}>رفض</button>
            </div>
          </div>
        ))}
      </section>

      <section className="space-y-3 rounded-2xl border p-4">
        <h2 className="text-lg font-black">بادج المدرس</h2>
        <p className="text-sm text-muted-foreground">البادج بتظهر فوق كارت المدرس عند الطالب، والأدمن بس اللي يضيفها.</p>
        <div className="flex flex-wrap gap-2">
          <input className="rounded-lg border px-3 py-2" placeholder="ID المدرس" value={badgeUser} onChange={(e) => setBadgeUser(e.target.value)} />
          <input className="rounded-lg border px-3 py-2" placeholder="نص البادج، مثال: موثّق" value={badge} onChange={(e) => setBadge(e.target.value)} />
          <button className="rounded-lg bg-primary px-4 text-primary-foreground" onClick={async () => {
            await api(`/api/admin/marketplace/trainers/${badgeUser}`, { method: "PUT", body: JSON.stringify({ badge_label: badge }) })
            setMessage("البادج اتحدثت")
          }}>حفظ البادج</button>
        </div>
      </section>

      <section className="space-y-3 rounded-2xl border p-4">
        <h2 className="text-lg font-black">تنبيهات الشات</h2>
        {alerts.length === 0 ? <p className="text-sm text-muted-foreground">مفيش محاولات أرقام أو @.</p> : alerts.map((alert) => (
          <div key={alert.id} className="rounded-xl border p-3 text-sm">
            <div className="font-bold">{alert.sender_name} · {new Date(alert.created_at).toLocaleString("ar-EG")}</div>
            <p className="mt-1">الأصل: {alert.original_body}</p>
            <p className="text-muted-foreground">بعد المسح: {alert.cleaned_body || "الرسالة كلها اتمسحت"}</p>
          </div>
        ))}
      </section>
    </div>
    </AdminLayout>
  )
}
