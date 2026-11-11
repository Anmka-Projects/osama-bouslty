"use client"

import { useEffect, useMemo, useState } from "react"
import { useRouter } from "next/navigation"
import { CalendarDays, Clock3, Upload } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Card, CardContent } from "@/components/ui/card"

type Offering = {
  id: string
  title: string
  description?: string
  payable: string
  currency: string
  duration_minutes: number
  session_count: number
}

type Slot = { slot_id: string; starts_at: string; ends_at: string; available: boolean }

function dayKey(value: string | Date) {
  const date = value instanceof Date ? value : new Date(value)
  const y = date.getFullYear()
  const m = String(date.getMonth() + 1).padStart(2, "0")
  const d = String(date.getDate()).padStart(2, "0")
  return `${y}-${m}-${d}`
}

function formatDayLabel(value: string) {
  return new Date(value).toLocaleDateString("ar-EG", {
    weekday: "long",
    day: "numeric",
    month: "long",
  })
}

function formatDayChip(value: string) {
  const date = new Date(value)
  return {
    weekday: date.toLocaleDateString("ar-EG", { weekday: "short" }),
    day: date.toLocaleDateString("ar-EG", { day: "numeric" }),
    month: date.toLocaleDateString("ar-EG", { month: "short" }),
  }
}

function formatTime(value: string) {
  return new Date(value).toLocaleTimeString("ar-EG", {
    hour: "2-digit",
    minute: "2-digit",
  })
}

export function MarketplaceBooking({ trainerId }: { trainerId: string }) {
  const router = useRouter()
  const [offerings, setOfferings] = useState<Offering[]>([])
  const [offeringId, setOfferingId] = useState("")
  const [slots, setSlots] = useState<Slot[]>([])
  const [selectedDay, setSelectedDay] = useState("")
  const [slotId, setSlotId] = useState("")
  const [notes, setNotes] = useState("")
  const [message, setMessage] = useState("")
  const [busy, setBusy] = useState(false)
  const [receiptUrl, setReceiptUrl] = useState("")
  const [uploadingReceipt, setUploadingReceipt] = useState(false)
  const [quote, setQuote] = useState<{ quote_id: string; total: string; currency: string } | null>(null)

  useEffect(() => {
    fetch(`/api/trainers/${trainerId}`)
      .then((response) => response.json())
      .then((body) => {
        const list = body?.data?.offerings || []
        setOfferings(list)
        if (list[0]) setOfferingId(list[0].id)
      })
      .catch(() => setMessage("تعذر تحميل جلسات هذا المدرب"))
  }, [trainerId])

  useEffect(() => {
    fetch(`/api/trainers/${trainerId}/availability`)
      .then((response) => response.json())
      .then((body) => {
        const next = ((body?.data?.slots || []) as Slot[])
          .filter((slot) => slot.available)
          .sort((a, b) => +new Date(a.starts_at) - +new Date(b.starts_at))
          .slice(0, 60)
        setSlots(next)
        if (next[0]) {
          const firstDay = dayKey(next[0].starts_at)
          setSelectedDay(firstDay)
          setSlotId("")
          setQuote(null)
        } else {
          setSelectedDay("")
          setSlotId("")
          setQuote(null)
        }
      })
      .catch(() => setSlots([]))
  }, [trainerId])

  const days = useMemo(() => {
    const map = new Map<string, string>()
    for (const slot of slots) {
      const key = dayKey(slot.starts_at)
      if (!map.has(key)) map.set(key, slot.starts_at)
    }
    return Array.from(map.entries()).map(([key, startsAt]) => ({ key, startsAt }))
  }, [slots])

  const daySlots = useMemo(
    () => slots.filter((slot) => dayKey(slot.starts_at) === selectedDay),
    [slots, selectedDay],
  )

  async function prepareQuote(nextSlot = slotId) {
    if (!offeringId || !nextSlot) return
    setBusy(true)
    setMessage("")
    try {
      const response = await fetch("/api/booking-quotes", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json", "Idempotency-Key": crypto.randomUUID() },
        body: JSON.stringify({ offering_id: offeringId, slot_id: nextSlot }),
      })
      const body = await response.json()
      if (!response.ok || body.success === false) {
        if (response.status === 401) {
          router.push(`/login?redirect=/instructors/${trainerId}`)
          return
        }
        setMessage(body.message || "السعر غير متاح")
        setQuote(null)
        return
      }
      setQuote(body.data)
    } finally {
      setBusy(false)
    }
  }

  async function confirm() {
    if (!quote) return
    if (!localStorage.getItem("studentToken")) {
      router.push(`/login?redirect=/instructors/${trainerId}`)
      return
    }
    setBusy(true)
    try {
      const response = await fetch("/api/bookings", {
        method: "POST",
        credentials: "include",
        headers: { "Content-Type": "application/json", "Idempotency-Key": crypto.randomUUID() },
        body: JSON.stringify({
          quote_id: quote.quote_id,
          payment_method: "bank_transfer",
          student_notes: notes,
          receipt_url: receiptUrl || undefined,
        }),
      })
      const body = await response.json()
      if (!response.ok || body.success === false) {
        setMessage(body.message || "تعذر إتمام الحجز")
        return
      }
      router.push("/dashboard/bookings")
    } finally {
      setBusy(false)
    }
  }

  async function uploadReceipt(file?: File) {
    if (!file) return
    setUploadingReceipt(true)
    setMessage("")
    try {
      const form = new FormData()
      form.append("type", "image")
      form.append("image", file)
      const access = localStorage.getItem("studentToken") || ""
      const response = await fetch("/api/upload", {
        method: "POST",
        credentials: "include",
        headers: access ? { Authorization: `Bearer ${access}` } : undefined,
        body: form,
      })
      const body = await response.json()
      const url = body?.url || body?.data?.url
      if (!response.ok || !url) throw new Error(body?.message || "تعذر رفع الإيصال")
      setReceiptUrl(url)
      setMessage("تم رفع إيصال التحويل بنجاح")
    } catch (error: any) {
      setMessage(error.message || "تعذر رفع الإيصال")
    } finally {
      setUploadingReceipt(false)
    }
  }

  if (!offerings.length) return null
  const selected = offerings.find((item) => item.id === offeringId) || offerings[0]
  const selectedSlot = daySlots.find((slot) => slot.slot_id === slotId)

  return (
    <Card className="overflow-hidden border-none bg-white shadow-sm rounded-3xl dark:bg-card">
      <CardContent className="space-y-5 p-5 text-right md:p-6">
        <div>
          <h2 className="text-xl font-black">احجز جلسة مباشرة</h2>
          <p className="mt-1 text-sm text-muted-foreground">
            اختَر الباقة، بعدين اليوم، بعدين الساعة. السعر يتحسب من السيرفر قبل التأكيد.
          </p>
        </div>

        <section className="space-y-3">
          <div className="flex items-center justify-between gap-2">
            <span className="text-sm font-bold text-muted-foreground">1. نوع الجلسة</span>
          </div>
          <div className="grid gap-2">
            {offerings.map((offering) => {
              const active = offering.id === selected.id
              return (
                <button
                  key={offering.id}
                  type="button"
                  onClick={() => {
                    setOfferingId(offering.id)
                    setQuote(null)
                    if (slotId) prepareQuote(slotId)
                  }}
                  className={`rounded-2xl border px-4 py-3 text-right transition ${
                    active
                      ? "border-primary bg-primary text-primary-foreground shadow-sm"
                      : "border-border bg-muted/30 hover:border-primary/40"
                  }`}
                >
                  <div className="font-bold">{offering.title}</div>
                  <div className={`mt-1 text-sm ${active ? "text-primary-foreground/85" : "text-muted-foreground"}`}>
                    {offering.payable} {offering.currency} · {offering.duration_minutes} دقيقة · {offering.session_count} جلسة
                  </div>
                </button>
              )
            })}
          </div>
        </section>

        <section className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold text-muted-foreground">
            <CalendarDays className="h-4 w-4" />
            2. اختَر اليوم
          </div>
          {days.length === 0 ? (
            <div className="rounded-2xl border border-dashed p-4 text-sm text-muted-foreground">
              لا توجد مواعيد متاحة حاليًا.
            </div>
          ) : (
            <div className="-mx-1 flex gap-2 overflow-x-auto px-1 pb-1">
              {days.map((day) => {
                const chip = formatDayChip(day.startsAt)
                const active = day.key === selectedDay
                return (
                  <button
                    key={day.key}
                    type="button"
                    onClick={() => {
                      setSelectedDay(day.key)
                      setSlotId("")
                      setQuote(null)
                    }}
                    className={`min-w-[78px] shrink-0 rounded-2xl border px-3 py-3 text-center transition ${
                      active
                        ? "border-primary bg-primary text-primary-foreground"
                        : "border-border bg-white hover:border-primary/40"
                    }`}
                  >
                    <div className={`text-xs ${active ? "text-primary-foreground/80" : "text-muted-foreground"}`}>
                      {chip.weekday}
                    </div>
                    <div className="mt-1 text-lg font-black leading-none">{chip.day}</div>
                    <div className={`mt-1 text-xs ${active ? "text-primary-foreground/80" : "text-muted-foreground"}`}>
                      {chip.month}
                    </div>
                  </button>
                )
              })}
            </div>
          )}
          {selectedDay ? (
            <p className="text-xs text-muted-foreground">{formatDayLabel(days.find((d) => d.key === selectedDay)?.startsAt || selectedDay)}</p>
          ) : null}
        </section>

        <section className="space-y-3">
          <div className="flex items-center gap-2 text-sm font-bold text-muted-foreground">
            <Clock3 className="h-4 w-4" />
            3. اختَر الساعة
          </div>
          {daySlots.length === 0 ? (
            <div className="rounded-2xl border border-dashed p-4 text-sm text-muted-foreground">
              مفيش مواعيد في اليوم ده.
        </div>
          ) : (
            <div className="grid grid-cols-2 gap-2 sm:grid-cols-3">
              {daySlots.map((slot) => {
                const active = slot.slot_id === slotId
                return (
                  <button
              key={slot.slot_id}
              type="button"
              onClick={() => {
                setSlotId(slot.slot_id)
                prepareQuote(slot.slot_id)
              }}
                    className={`rounded-xl border px-3 py-3 text-sm font-bold transition ${
                      active
                        ? "border-primary bg-primary text-primary-foreground"
                        : "border-border bg-muted/20 hover:border-primary/40"
                    }`}
                  >
                    {formatTime(slot.starts_at)}
                  </button>
                )
              })}
            </div>
          )}
        </section>

        {selectedSlot || quote ? (
          <div className="rounded-2xl bg-primary/5 p-4">
            <div className="text-sm text-muted-foreground">ملخص الحجز</div>
            {selectedSlot ? (
              <div className="mt-1 font-bold">
                {formatDayLabel(selectedSlot.starts_at)} · {formatTime(selectedSlot.starts_at)}
              </div>
            ) : null}
            {quote ? (
              <div className="mt-2 text-lg font-black text-primary">
                المطلوب دفعه: {quote.total} {quote.currency}
              </div>
            ) : (
              <div className="mt-2 text-sm text-muted-foreground">جارٍ حساب السعر...</div>
            )}
        </div>
        ) : null}

        <textarea
          value={notes}
          onChange={(event) => setNotes(event.target.value)}
          maxLength={500}
          placeholder="ملاحظة للمدرب (اختياري)"
          className="min-h-[96px] w-full rounded-2xl border bg-muted/10 px-4 py-3 text-sm outline-none ring-primary focus:ring-2"
        />

        <label className="flex cursor-pointer items-center justify-center gap-2 rounded-2xl border border-dashed border-primary/40 bg-primary/5 px-4 py-3 text-sm font-bold text-primary">
          <Upload className="h-4 w-4" />
          {uploadingReceipt
            ? "جارٍ رفع الإيصال..."
            : receiptUrl
              ? "تم إرفاق الإيصال — اضغط لتغييره"
              : "إرفاق صورة إيصال التحويل (الآن أو لاحقًا)"}
          <input
            type="file"
            accept="image/*"
            className="hidden"
            disabled={uploadingReceipt}
            onChange={(event) => uploadReceipt(event.target.files?.[0])}
          />
        </label>

        {message ? <p className="text-sm text-destructive">{message}</p> : null}

        <Button
          disabled={busy || !quote}
          onClick={confirm}
          className="h-12 w-full rounded-2xl text-base font-bold"
        >
          {busy ? "جارٍ التأكيد..." : "تأكيد الحجز بالتحويل"}
        </Button>
      </CardContent>
    </Card>
  )
}
