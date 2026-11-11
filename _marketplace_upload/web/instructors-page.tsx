"use client"

import Link from "next/link"
import { useEffect, useMemo, useState } from "react"
import { Search, Star, Users, Video } from "lucide-react"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"

const rows = (body: any) => Array.isArray(body?.data) ? body.data : body?.data?.trainers || body?.data?.data || []

export default function InstructorsPage() {
  const [trainers, setTrainers] = useState<any[]>([])
  const [loading, setLoading] = useState(true)
  const [query, setQuery] = useState("")
  useEffect(() => { fetch("/api/trainers?per_page=100").then(r=>r.json()).then(body=>setTrainers(rows(body))).finally(()=>setLoading(false)) }, [])
  const filtered = useMemo(() => trainers.filter(t => `${t.display_name||t.name||""} ${t.headline||""} ${(t.specialties||[]).join(" ")}`.toLowerCase().includes(query.toLowerCase())), [trainers,query])
  return <div dir="rtl" className="min-h-screen bg-slate-50"><Navbar/><main className="container mx-auto px-4 py-10">
    <div className="mx-auto max-w-3xl text-center"><h1 className="text-3xl font-black md:text-5xl">اختار المدرس المناسب ليك</h1><p className="mt-3 text-muted-foreground">بروفايلات حقيقية، باقات ومواعيد متاحة للحجز مباشرة</p><label className="mx-auto mt-6 flex max-w-xl items-center gap-2 rounded-2xl border bg-white px-4 shadow-sm"><Search className="h-5 w-5 text-muted-foreground"/><input value={query} onChange={e=>setQuery(e.target.value)} placeholder="ابحث بالاسم أو التخصص" className="w-full bg-transparent py-4 outline-none"/></label></div>
    {loading?<div className="py-20 text-center">جارٍ تحميل المدرسين...</div>:null}
    {!loading&&!filtered.length?<div className="py-20 text-center text-muted-foreground">لا يوجد مدرسون مطابقون للبحث حاليًا.</div>:null}
    <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">{filtered.map(t=><Link href={`/instructors/${t.id}`} key={t.id} className="group overflow-hidden rounded-3xl border bg-white p-5 shadow-sm transition hover:-translate-y-1 hover:shadow-lg"><div className="flex items-center gap-4"><div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-primary/10 text-2xl font-black text-primary">{t.avatar_url||t.avatar?<img src={t.avatar_url||t.avatar} alt="" className="h-full w-full object-cover"/>:(t.display_name||t.name||"م")[0]}</div><div className="min-w-0"><h2 className="truncate text-lg font-black">{t.display_name||t.name}</h2><p className="line-clamp-2 text-sm text-muted-foreground">{t.headline||"مدرس معتمد"}</p></div></div><div className="mt-5 flex flex-wrap gap-2 text-xs"><span className="flex items-center gap-1 rounded-full bg-amber-50 px-3 py-1.5 text-amber-800"><Star className="h-3.5 w-3.5 fill-current"/>{Number(t.rating||0).toFixed(1)}</span><span className="flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5"><Users className="h-3.5 w-3.5"/>{t.completed_bookings||0} جلسة</span>{t.intro_video_url?<span className="flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1.5 text-primary"><Video className="h-3.5 w-3.5"/>فيديو تعريفي</span>:null}</div><div className="mt-5 rounded-xl bg-primary py-2.5 text-center text-sm font-bold text-white">عرض الباقات والحجز</div></Link>)}</div>
  </main><Footer/></div>
}
