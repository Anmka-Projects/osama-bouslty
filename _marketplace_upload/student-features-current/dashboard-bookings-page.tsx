"use client"

import { useEffect, useState } from "react"
import Link from "next/link"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { Card, CardContent } from "@/components/ui/card"
import { Button } from "@/components/ui/button"

type Booking = {
  id: string
  status: string
  payment_status: string
  scheduled_at: string
  amount: string
  currency: string
  offering?: { title?: string }
  trainer_summary?: { display_name?: string }
  can_join?: boolean
}

export default function MyBookingsPage() {
  const [isDark, setIsDark] = useState(false)
  const [rows, setRows] = useState<Booking[]>([])
  const [message, setMessage] = useState("جاري تحميل حجوزاتك...")
  const [joining, setJoining] = useState("")

  async function joinBooking(id: string) {
    setJoining(id)
    try {
      const response = await fetch(`/api/bookings/${id}/join`, { method: "POST", credentials: "include" })
      const body = await response.json()
      if (!response.ok || body.success === false) {
        setMessage(body.message || "الدخول للجلسة غير متاح حاليًا")
        return
      }
      const url = body?.data?.join_url
      if (url) window.location.href = url
    } finally {
      setJoining("")
    }
  }

  useEffect(() => {
    const dark = localStorage.getItem("theme") === "dark"
    setIsDark(dark)
    fetch("/api/bookings?role=student&per_page=50", { credentials: "include" })
      .then((response) => response.json().then((body) => ({ response, body })))
      .then(({ response, body }) => {
        if (!response.ok) {
          setMessage(body.message || "سجل الدخول لعرض الحجوزات")
          return
        }
        const list = body?.data?.bookings || []
        setRows(list)
        setMessage(list.length ? "" : "لسه ما عندكش حجوزات. اختار مدرب واحجز جلسة.")
      })
      .catch(() => setMessage("تعذر تحميل الحجوزات"))
  }, [])

  return (
    <main dir="rtl" className="min-h-screen bg-muted/20">
      <Navbar isDark={isDark} setIsDark={setIsDark} />
      <section className="container mx-auto px-4 py-10 space-y-4">
        <div className="flex items-center justify-between">
          <h1 className="text-3xl font-black">حجوزاتي</h1>
          <Link href="/instructors"><Button className="rounded-xl">احجز جلسة</Button></Link>
        </div>
        {message ? <p className="text-muted-foreground">{message}</p> : null}
        {rows.map((row) => (
          <Card key={row.id} className="rounded-3xl border-none shadow-sm">
            <CardContent className="p-5 text-right space-y-1">
              <h2 className="font-black">{row.trainer_summary?.display_name}</h2>
              <p>{row.offering?.title}</p>
              <p className="text-sm text-muted-foreground">{new Date(row.scheduled_at).toLocaleString("ar-EG")}</p>
              <p className="font-bold text-primary">{row.amount} {row.currency} · {row.status} · {row.payment_status}</p>
              <div className="flex flex-wrap gap-2 pt-3">
                {row.can_join ? <Button disabled={joining === row.id} onClick={() => joinBooking(row.id)} className="rounded-xl">{joining === row.id ? "جارٍ الدخول..." : "ادخل الجلسة"}</Button> : null}
                <Link href="/dashboard/chat"><Button variant="outline" className="rounded-xl">المحادثات</Button></Link>
              </div>
            </CardContent>
          </Card>
        ))}
      </section>
      <Footer />
    </main>
  )
}
