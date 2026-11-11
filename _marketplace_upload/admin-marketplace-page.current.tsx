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
  const [trainers, setTrainers] = useState<Array<{ id: string; display_name?: string; verification_status?: string }>>([])
  const [message, setMessage] = useState("")
  const [paths, setPaths] = useState<string[]>([])
  const [newPath, setNewPath] = useState("")

  async function load() {
    const [bookingsRes, payoutsRes, trainersRes] = await Promise.all([
      fetch("/api/admin/marketplace/bookings?role=admin", { credentials: "include" }),
      fetch("/api/admin/marketplace/payouts", { credentials: "include" }),
      fetch("/api/admin/marketplace/trainers?status=pending", { credentials: "include" }),
    ])
    const bookingsBody = await bookingsRes.json()
    const payoutsBody = await payoutsRes.json()
    if (!bookingsRes.ok) {
      setMessage(bookingsBody.message || "سجل دخول الأدمن")
      return
    }
    setBookings(bookingsBody.data?.bookings || [])
    setPayouts(payoutsBody.data?.payouts || [])
    setTrainers((await trainersRes.json()).data?.trainers || [])
    try {
      const pathsBody = await (await fetch("/api/paths")).json()
      setPaths(pathsBody.data?.paths || [])
    } catch {}
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

  async function savePaths(next: string[]) {
    await fetch("/api/admin/marketplace/settings", {
      method: "PUT",
      credentials: "include",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ paths: next }),
    })
    setPaths(next)
    setNewPath("")
  }

  return (
    <div className="p-6 space-y-8 text-right" dir="rtl">
      <div>
        <h1 className="text-2xl font-black">حجوزات الجلسات المباشرة</h1>
        <p className="text-sm text-muted-foreground">موافقة ملفات المدرسين، قبول إيصالات الدفع، ومراجعة السحب. أي تعديل من المدرس يختفي عن الطلاب لحد الموافقة.</p>
        {message ? <p className="text-destructive mt-2">{message}</p> : null}
      </div>
      <div className="space-y-2 rounded-2xl border p-4">
        <h2 className="text-xl font-black">المسارات المتاحة</h2>
        <p className="text-sm text-muted-foreground">القائمة اللي بتظهر للطلاب في صفحة البحث.</p>
        <div className="flex gap-2">
          <input
            value={newPath}
            onChange={(e) => setNewPath(e.target.value)}
            placeholder="اسم المسار الجديد"
            className="flex-1 rounded-lg border px-3 py-2 text-sm"
          />
          <button
            className="rounded-lg bg-primary text-primary-foreground px-4 py-2 text-sm"
            onClick={() => {
              const v = newPath.trim()
              if (v && !paths.includes(v)) savePaths([...paths, v])
            }}
          >إضافة</button>
        </div>
        <div className="flex flex-wrap gap-2">
          {paths.length === 0 ? <p className="text-sm text-muted-foreground">لا توجد مسارات — هيتعرض للطلاب تجميع تلقائي من تخصصات المدرسين.</p> : null}
          {paths.map((p) => (
            <span key={p} className="inline-flex items-center gap-2 rounded-full border px-3 py-1 text-sm">
              {p}
              <button className="text-destructive font-bold" onClick={() => savePaths(paths.filter((x) => x !== p))}>×</button>
            </span>
          ))}
        </div>
      </div>
      <div className="space-y-2">
        <h2 className="text-xl font-black">مدرسون بانتظار الموافقة</h2>
        {trainers.length === 0 ? <p className="text-sm text-muted-foreground">لا توجد طلبات.</p> : null}
        {trainers.map((trainer) => (
          <div key={trainer.id} className="flex items-center justify-between rounded-xl border p-3">
            <span>{trainer.display_name} · {trainer.verification_status}</span>
            <span className="space-x-2 space-x-reverse">
              <button className="rounded-lg bg-primary text-primary-foreground px-3 py-1" onClick={() => verification(trainer.id, "approved")}>موافقة</button>
              <button className="rounded-lg border px-3 py-1" onClick={() => verification(trainer.id, "rejected")}>رفض</button>
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
