"use client"

import Link from "next/link"
import { useEffect, useState } from "react"
import { BookOpen, ChevronLeft, Clock3, Search, Star, Users, Video } from "lucide-react"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"

type Category = { id: string; name?: string; name_ar?: string; children?: Category[]; subcategories?: Category[] }
const rows = (body: any) => Array.isArray(body?.data) ? body.data : body?.data?.trainers || body?.data?.data || []
const categoryRows = (body: any): Category[] => Array.isArray(body?.data) ? body.data : body?.data?.categories || []
const children = (item?: Category | null) => item?.children || item?.subcategories || []
const label = (item?: Category | null) => item?.name_ar || item?.name || ""

export default function InstructorsPage() {
  const [trainers, setTrainers] = useState<any[]>([])
  const [tree, setTree] = useState<Category[]>([])
  const [loading, setLoading] = useState(false)
  const [query, setQuery] = useState("")
  const [categoryId, setCategoryId] = useState("")
  const [subcategoryId, setSubcategoryId] = useState("")
  const [subjectId, setSubjectId] = useState("")

  const selectedCategory = tree.find(item => item.id === categoryId)
  const subcategories = children(selectedCategory)
  const selectedSubcategory = subcategories.find(item => item.id === subcategoryId)
  const subjects = children(selectedSubcategory)

  useEffect(() => {
    fetch("/api/categories").then(response => response.json()).then(body => setTree(categoryRows(body))).catch(() => setTree([]))
  }, [])

  useEffect(() => {
    if (!categoryId) { setTrainers([]); return }
    const params = new URLSearchParams({ per_page: "100", category_id: categoryId })
    if (query.trim()) params.set("q", query.trim())
    if (subcategoryId) params.set("subcategory_id", subcategoryId)
    if (subjectId) params.set("subject_id", subjectId)
    const abort = new AbortController()
    const timer = window.setTimeout(() => {
      setLoading(true)
      fetch(`/api/trainers?${params.toString()}`, { signal: abort.signal })
        .then(response => response.json()).then(body => setTrainers(rows(body)))
        .catch(error => { if (error?.name !== "AbortError") setTrainers([]) })
        .finally(() => setLoading(false))
    }, 250)
    return () => { window.clearTimeout(timer); abort.abort() }
  }, [query, categoryId, subcategoryId, subjectId])

  const chooseCategory = (id: string) => { setCategoryId(id); setSubcategoryId(""); setSubjectId(""); setQuery("") }
  const resetCategory = () => { setCategoryId(""); setSubcategoryId(""); setSubjectId(""); setQuery("") }

  return <div dir="rtl" className="min-h-screen bg-slate-50"><Navbar/><main className="container mx-auto px-4 py-10">
    <div className="mx-auto max-w-4xl text-center"><h1 className="text-3xl font-black md:text-5xl">اختار المدرس المناسب ليك</h1><p className="mt-3 text-muted-foreground">ابدأ باختيار المرحلة، وبعدها الصف والمادة.</p></div>

    {!categoryId ? <section className="mx-auto mt-10 max-w-5xl">
      <h2 className="mb-5 text-center text-2xl font-black">اختار التصنيف</h2>
      {!tree.length ? <div className="py-16 text-center text-muted-foreground">جارٍ تحميل التصنيفات...</div> : null}
      <div className="grid gap-4 sm:grid-cols-2 lg:grid-cols-4">{tree.map(category => <button key={category.id} onClick={() => chooseCategory(category.id)} className="group flex min-h-40 flex-col items-center justify-center rounded-3xl border bg-white p-6 text-center shadow-sm transition hover:-translate-y-1 hover:border-primary hover:shadow-lg"><span className="mb-4 flex h-14 w-14 items-center justify-center rounded-2xl bg-primary/10 text-primary"><BookOpen className="h-7 w-7"/></span><strong className="text-xl">{label(category)}</strong><span className="mt-2 flex items-center gap-1 text-sm text-muted-foreground">عرض المدرسين <ChevronLeft className="h-4 w-4"/></span></button>)}</div>
    </section> : <>
      <div className="mx-auto mt-8 max-w-4xl rounded-3xl border bg-white p-5 shadow-sm">
        <div className="mb-4 flex items-center justify-between gap-3"><div><span className="text-xs text-muted-foreground">التصنيف المختار</span><h2 className="text-xl font-black">{label(selectedCategory)}</h2></div><button onClick={resetCategory} className="rounded-xl border px-4 py-2 text-sm font-bold">تغيير التصنيف</button></div>
        <div className="grid gap-3 md:grid-cols-2">
          <select className="rounded-xl border bg-white px-3 py-3" value={subcategoryId} onChange={event => { setSubcategoryId(event.target.value); setSubjectId("") }}><option value="">كل التخصصات الفرعية</option>{subcategories.map(item => <option key={item.id} value={item.id}>{label(item)}</option>)}</select>
          <select className="rounded-xl border bg-white px-3 py-3" value={subjectId} disabled={!subcategoryId || !subjects.length} onChange={event => setSubjectId(event.target.value)}><option value="">{subcategoryId && !subjects.length ? "لم تُضف مواد بعد" : "كل المواد"}</option>{subjects.map(item => <option key={item.id} value={item.id}>{label(item)}</option>)}</select>
        </div>
        <label className="mt-3 flex items-center gap-2 rounded-2xl border bg-slate-50 px-4"><Search className="h-5 w-5 text-muted-foreground"/><input value={query} onChange={event => setQuery(event.target.value)} placeholder="ابحث باسم المدرس أو المادة" className="w-full bg-transparent py-4 outline-none"/></label>
      </div>

      {loading ? <div className="py-20 text-center">جارٍ تحميل المدرسين...</div> : null}
      {!loading && !trainers.length ? <div className="py-20 text-center text-muted-foreground">لا يوجد مدرسون مطابقون للاختيار حاليًا.</div> : null}
      <div className="mt-10 grid gap-5 sm:grid-cols-2 lg:grid-cols-3">{trainers.map(trainer => {
        const name=trainer.display_name||trainer.name||"مدرس", rating=Number(trainer.rating_average??trainer.rating??0), ratingCount=Number(trainer.rating_count||0), completed=Number(trainer.completed_sessions_count||0), students=Number(trainer.students_count||0), hours=Number(trainer.hours_count||completed), price=trainer.starting_price
        return <Link href={`/instructors/${trainer.id}`} key={trainer.id} className="group relative overflow-hidden rounded-3xl border bg-white p-5 shadow-sm transition hover:-translate-y-1 hover:shadow-lg">
          {trainer.badge_label?<span className="absolute left-4 top-4 rounded-full bg-amber-500 px-3 py-1 text-xs font-black text-white">{trainer.badge_label}</span>:null}
          <div className="flex items-center gap-4"><div className="flex h-20 w-20 shrink-0 items-center justify-center overflow-hidden rounded-2xl bg-primary/10 text-2xl font-black text-primary">{trainer.avatar_url||trainer.avatar?<img src={trainer.avatar_url||trainer.avatar} alt={name} className="h-full w-full object-cover"/>:name[0]}</div><div className="min-w-0"><h2 className="truncate text-lg font-black">{name}</h2><p className="line-clamp-2 text-sm text-muted-foreground">{trainer.headline||"مدرس معتمد"}</p></div></div>
          {trainer.bio?<p className="mt-4 line-clamp-2 min-h-10 text-sm leading-6 text-muted-foreground">{trainer.bio}</p>:null}
          <div className="mt-5 flex flex-wrap gap-2 text-xs"><span className="flex items-center gap-1 rounded-full bg-amber-50 px-3 py-1.5 text-amber-800"><Star className="h-3.5 w-3.5 fill-current"/>{rating.toFixed(1)} ({ratingCount})</span><span className="flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5"><Clock3 className="h-3.5 w-3.5"/>{hours} ساعة</span><span className="flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5"><Users className="h-3.5 w-3.5"/>{students} طالب</span><span className="flex items-center gap-1 rounded-full bg-slate-100 px-3 py-1.5"><BookOpen className="h-3.5 w-3.5"/>{completed} جلسة</span>{trainer.intro_video_url?<span className="flex items-center gap-1 rounded-full bg-primary/10 px-3 py-1.5 text-primary"><Video className="h-3.5 w-3.5"/>فيديو تعريفي</span>:null}</div>
          <div className="mt-5 flex items-center justify-between rounded-xl bg-primary px-4 py-2.5 text-sm font-bold text-white"><span>عرض الباقات والحجز</span><span>{price?`${Number(price).toFixed(2)} USD / الساعة`:"اعرف السعر"}</span></div>
        </Link>})}</div>
    </>}
  </main><Footer/></div>
}
