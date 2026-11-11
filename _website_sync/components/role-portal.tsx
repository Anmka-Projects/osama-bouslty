"use client"

import Link from "next/link"
import { useEffect, useMemo, useState } from "react"
import { useRouter } from "next/navigation"
import {
  Bell, BookOpen, CalendarDays, CheckCircle2, ChevronLeft, Clock3,
  GraduationCap, LayoutDashboard, Loader2, LogOut, MessageCircle, Play,
  RefreshCw, Save, Search, Settings, Star, UserRound, Video, Wallet,
} from "lucide-react"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"

type Role = "student" | "instructor"

const studentNav = [
  ["overview", "الرئيسية", LayoutDashboard, "/dashboard"],
  ["courses", "كورساتي", BookOpen, "/dashboard/courses"],
  ["bookings", "حجوزاتي", CalendarDays, "/dashboard/bookings"],
  ["progress", "التقدم", CheckCircle2, "/dashboard/progress"],
  ["exams", "اختباراتي", GraduationCap, "/dashboard/exams"],
  ["certificates", "الشهادات", Star, "/dashboard/certificates"],
  ["messages", "الرسائل", MessageCircle, "/dashboard/messages"],
  ["notifications", "الإشعارات", Bell, "/dashboard/notifications"],
  ["profile", "حسابي", UserRound, "/dashboard/profile"],
] as const

const teacherNav = [
  ["overview", "الرئيسية", LayoutDashboard, "/instructor"],
  ["requests", "الطلبات", Bell, "/instructor/requests"],
  ["calendar", "الجدول والجلسات", CalendarDays, "/instructor/calendar"],
  ["messages", "الرسائل", MessageCircle, "/instructor/messages"],
  ["marketplace", "البروفايل والباقات", Settings, "/instructor/marketplace"],
  ["earnings", "الأرباح والسحب", Wallet, "/instructor/earnings"],
] as const

function token() {
  return typeof window === "undefined" ? "" : localStorage.getItem("studentToken") || localStorage.getItem("accessToken") || ""
}

async function api(path: string, init: RequestInit = {}) {
  const access = token()
  const response = await fetch(`/api${path}`, {
    credentials: "include",
    ...init,
    headers: {
      ...(access ? { Authorization: `Bearer ${access}` } : {}),
      ...(init.body instanceof FormData ? {} : { "Content-Type": "application/json" }),
      ...(init.headers || {}),
    },
  })
  const body = await response.json().catch(() => ({}))
  if (!response.ok) throw new Error(body.message || "تعذر تنفيذ الطلب")
  return body.data ?? body
}

const arr = (value: any, ...keys: string[]) => {
  if (Array.isArray(value)) return value
  for (const key of keys) if (Array.isArray(value?.[key])) return value[key]
  return []
}

const money = (value: any, currency = "USD") => `${Number(value || 0).toFixed(2)} ${currency}`
const dateTime = (value: any) => value ? new Date(value).toLocaleString("ar-EG", { dateStyle: "medium", timeStyle: "short" }) : "—"

const statusText: Record<string, string> = {
  requested: "بانتظار موافقة المدرّس", pending_payment: "بانتظار الدفع",
  confirmed: "مؤكد", scheduled: "مجدول", live: "مباشر الآن",
  completed: "مكتمل", cancelled: "ملغي", paid: "مدفوع",
  pending: "قيد المراجعة", unpaid: "غير مدفوع", failed: "فشل الدفع",
}

function Badge({ value }: { value?: string }) {
  const good = ["paid", "scheduled", "confirmed", "completed", "live", "approved"].includes(value || "")
  const bad = ["cancelled", "failed", "rejected", "suspended"].includes(value || "")
  return <span className={`inline-flex rounded-full px-2.5 py-1 text-xs font-bold ${good ? "bg-emerald-100 text-emerald-700" : bad ? "bg-red-100 text-red-700" : "bg-amber-100 text-amber-800"}`}>{statusText[value || ""] || value || "—"}</span>
}

function Card({ title, children, action }: { title?: string; children: React.ReactNode; action?: React.ReactNode }) {
  return <section className="rounded-3xl border bg-white p-5 shadow-sm">
    {title ? <div className="mb-4 flex items-center justify-between gap-3"><h2 className="text-lg font-black">{title}</h2>{action}</div> : null}
    {children}
  </section>
}

function Empty({ text }: { text: string }) {
  return <div className="py-12 text-center text-sm text-muted-foreground"><CalendarDays className="mx-auto mb-3 h-10 w-10 opacity-40" />{text}</div>
}

export function RolePortal({ role, tab }: { role: Role; tab: string }) {
  const router = useRouter()
  const [user, setUser] = useState<any>(null)
  const [data, setData] = useState<any>({})
  const [loading, setLoading] = useState(true)
  const [error, setError] = useState("")
  const [saving, setSaving] = useState(false)
  const nav = role === "student" ? studentNav : teacherNav

  async function load() {
    setLoading(true); setError("")
    try {
      const me = await api("/auth/me")
      const actual = String(me?.role || me?.user?.role || "").toLowerCase()
      if (actual && actual !== role && actual !== "admin") {
        router.replace(actual === "instructor" ? "/instructor" : "/dashboard")
        return
      }
      const currentUser = me?.user || me
      setUser(currentUser)
      localStorage.setItem("user", JSON.stringify(currentUser))
      if (role === "student") await loadStudent()
      else await loadTeacher()
    } catch (e: any) { setError(e.message || "يرجى تسجيل الدخول") }
    finally { setLoading(false) }
  }

  async function loadStudent() {
    const tasks: Record<string, Promise<any>> = {
      enrollments: api("/enrollments").catch(() => []),
      bookings: api("/bookings?role=student&per_page=50").catch(() => ({})),
      notifications: api("/notifications").catch(() => []),
      conversations: api("/chat/conversations").catch(() => []),
    }
    if (["overview", "progress"].includes(tab)) tasks.progress = api("/progress?period=monthly").catch(() => ({}))
    if (["overview", "exams"].includes(tab)) {
      tasks.exams = api("/my-exams").catch(() => [])
      tasks.results = api("/my-exam-results").catch(() => [])
    }
    if (["overview", "certificates"].includes(tab)) tasks.certificates = api("/certificates").catch(() => [])
    const entries = await Promise.all(Object.entries(tasks).map(async ([key, promise]) => [key, await promise]))
    setData(Object.fromEntries(entries))
  }

  async function loadTeacher() {
    const entries = await Promise.all([
      ["profile", await api("/instructor/trainer-profile")],
      ["availability", await api("/instructor/availability").catch(() => ({}))],
      ["bookings", await api("/bookings?role=instructor&per_page=50").catch(() => ({}))],
      ["earnings", await api("/instructor/earnings").catch(() => ({}))],
      ["conversations", await api("/chat/conversations").catch(() => [])],
    ] as any)
    setData(Object.fromEntries(entries))
  }

  useEffect(() => { load() }, [role, tab])

  function logout() {
    localStorage.removeItem("studentToken")
    localStorage.removeItem("accessToken")
    localStorage.removeItem("refreshToken")
    localStorage.removeItem("user")
    document.cookie = "accessToken=; path=/; max-age=0"
    router.push("/login")
  }

  if (loading) return <main className="flex min-h-screen items-center justify-center"><Loader2 className="h-8 w-8 animate-spin text-primary" /></main>
  if (error) return <main className="flex min-h-screen items-center justify-center p-4"><Card><div className="text-center"><p className="mb-4 text-red-600">{error}</p><Link className="rounded-xl bg-primary px-5 py-2 text-white" href="/login">تسجيل الدخول</Link></div></Card></main>

  return <main className="min-h-screen bg-[#fbf8f2]" dir="rtl">
    <Navbar />
    <div className="container mx-auto grid gap-6 px-4 py-8 lg:grid-cols-[280px_1fr]">
      <aside className="h-fit rounded-3xl border bg-white p-4 shadow-sm lg:sticky lg:top-4">
        <div className="mb-5 rounded-2xl bg-gradient-to-l from-primary to-[#083b41] p-4 text-white">
          <div className="mb-3 flex h-12 w-12 items-center justify-center rounded-full bg-white/15"><UserRound /></div>
          <div className="font-black">{user?.name || user?.display_name || "حسابي"}</div>
          <div className="text-xs text-white/70">{role === "student" ? "طالب" : "مدرّس"} · {user?.email}</div>
        </div>
        <nav className="space-y-1">{nav.map(([id, label, Icon, href]) => <Link key={id} href={href} className={`flex items-center gap-3 rounded-xl px-3 py-3 text-sm font-bold transition ${tab === id ? "bg-primary text-white" : "hover:bg-muted"}`}><Icon className="h-5 w-5" />{label}<ChevronLeft className="mr-auto h-4 w-4 opacity-50" /></Link>)}</nav>
        <button onClick={logout} className="mt-4 flex w-full items-center gap-2 rounded-xl px-3 py-3 text-sm font-bold text-red-600 hover:bg-red-50"><LogOut className="h-5 w-5" />تسجيل الخروج</button>
      </aside>
      <div className="min-w-0 space-y-5">
        <header className="flex flex-wrap items-center justify-between gap-3"><div><h1 className="text-2xl font-black">{role === "student" ? "بوابة الطالب" : "بوابة المدرّس"}</h1><p className="text-sm text-muted-foreground">كل بياناتك محدثة من نفس النظام المستخدم في التطبيق.</p></div><button onClick={load} className="flex items-center gap-2 rounded-xl border bg-white px-4 py-2 text-sm font-bold"><RefreshCw className="h-4 w-4" />تحديث</button></header>
        {role === "student" ? <StudentView tab={tab} data={data} user={user} reload={load} /> : <TeacherView tab={tab} data={data} setData={setData} reload={load} saving={saving} setSaving={setSaving} />}
      </div>
    </div>
    <Footer />
  </main>
}

function StudentView({ tab, data, user, reload }: any) {
  const enrollments = arr(data.enrollments, "enrollments", "data")
  const bookings = arr(data.bookings, "bookings")
  const notifications = arr(data.notifications, "notifications", "data")
  const exams = arr(data.exams, "exams", "data")
  const certificates = arr(data.certificates, "certificates", "data")
  const conversations = arr(data.conversations, "conversations", "data")

  if (tab === "overview") {
    const upcoming = bookings.filter((b: any) => !["completed", "cancelled"].includes(b.status))
    return <>
      <div className="grid gap-4 md:grid-cols-4">{[
        ["كورساتي", enrollments.length, BookOpen], ["الجلسات القادمة", upcoming.length, CalendarDays],
        ["اختباراتي", exams.length, GraduationCap], ["الإشعارات", notifications.length, Bell],
      ].map(([label, value, Icon]: any) => <Card key={label}><div className="flex items-center justify-between"><div><div className="text-sm text-muted-foreground">{label}</div><div className="mt-1 text-3xl font-black">{value}</div></div><Icon className="h-9 w-9 text-primary/50" /></div></Card>)}</div>
      <div className="grid gap-5 xl:grid-cols-2"><Bookings bookings={upcoming.slice(0, 3)} reload={reload} /><Courses enrollments={enrollments.slice(0, 4)} /></div>
      <Card title="وصول سريع"><div className="grid gap-3 sm:grid-cols-3"><Link className="rounded-2xl bg-primary p-4 font-bold text-white" href="/instructors">احجز مع مدرّس</Link><Link className="rounded-2xl bg-muted p-4 font-bold" href="/courses">اكتشف الكورسات</Link><Link className="rounded-2xl bg-muted p-4 font-bold" href="/dashboard/messages">افتح الرسائل</Link></div></Card>
    </>
  }
  if (tab === "courses") return <Courses enrollments={enrollments} />
  if (tab === "bookings") return <Bookings bookings={bookings} reload={reload} />
  if (tab === "notifications") return <SimpleList title="الإشعارات" rows={notifications} primary={["title", "message"]} secondary={["body", "created_at"]} />
  if (tab === "messages") return <Conversations rows={conversations} />
  if (tab === "exams") return <SimpleList title="اختباراتي" rows={exams} primary={["title", "name"]} secondary={["course_title", "status"]} />
  if (tab === "certificates") return <SimpleList title="شهاداتي" rows={certificates} primary={["course_title", "title"]} secondary={["certificate_number", "issue_date"]} />
  if (tab === "progress") return <ProgressView progress={data.progress} enrollments={enrollments} />
  return <ProfileEditor user={user} reload={reload} />
}

function Courses({ enrollments }: { enrollments: any[] }) {
  return <Card title="كورساتي" action={<Link className="text-sm font-bold text-primary" href="/courses">كل الكورسات</Link>}>
    {enrollments.length ? <div className="grid gap-3 sm:grid-cols-2">{enrollments.map((row: any) => { const course = row.course || row; const progress = Number(row.progress || course.progress || 0); return <Link href={course.id ? `/courses/${course.id}` : "/learning"} key={row.id || course.id} className="rounded-2xl border p-4 transition hover:border-primary"><div className="font-black">{course.title || "كورس"}</div><div className="mt-3 h-2 overflow-hidden rounded-full bg-muted"><div className="h-full bg-primary" style={{ width: `${progress}%` }} /></div><div className="mt-1 text-xs text-muted-foreground">اكتمل {progress}%</div></Link> })}</div> : <Empty text="لا توجد كورسات مسجلة بعد." />}
  </Card>
}

function Bookings({ bookings, reload }: { bookings: any[]; reload: () => void }) {
  async function join(id: string) { try { const result = await api(`/bookings/${id}/join`, { method: "POST", body: "{}" }); if (result?.join_url) window.open(result.join_url, "_blank", "noopener") } catch (e: any) { alert(e.message) } }
  return <Card title="الجلسات المباشرة" action={<Link className="text-sm font-bold text-primary" href="/instructors">حجز جديد</Link>}>
    {bookings.length ? <div className="space-y-3">{bookings.map((b: any) => <div key={b.id} className="rounded-2xl border p-4"><div className="flex flex-wrap items-start justify-between gap-3"><div><div className="font-black">{b.offering?.title || "جلسة مباشرة"}</div><div className="text-sm text-muted-foreground">{b.trainer_summary?.display_name || b.student_summary?.name}</div></div><div className="flex gap-2"><Badge value={b.status} /><Badge value={b.payment_status} /></div></div><div className="mt-3 flex flex-wrap items-center gap-3 text-sm"><span><Clock3 className="ml-1 inline h-4 w-4" />{dateTime(b.scheduled_at)}</span><strong>{money(b.amount, b.currency)}</strong></div><div className="mt-3 flex flex-wrap gap-2">{b.can_join ? <button onClick={() => join(b.id)} className="flex items-center gap-2 rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white"><Video className="h-4 w-4" />دخول الجلسة</button> : null}{b.conversation_id ? <Link href={`/dashboard/messages?conversation=${b.conversation_id}`} className="rounded-xl border px-4 py-2 text-sm font-bold">محادثة</Link> : null}</div></div>)}</div> : <Empty text="لا توجد حجوزات حتى الآن." />}
  </Card>
}

function ProgressView({ progress, enrollments }: any) {
  const stats = progress?.statistics || progress?.data?.statistics || progress || {}
  return <><div className="grid gap-4 md:grid-cols-3">{[["نسبة الإنجاز", stats.overall_progress || stats.progress || 0], ["الدروس المكتملة", stats.completed_lessons || 0], ["ساعات التعلم", stats.learning_hours || stats.total_hours || 0]].map(([l,v]) => <Card key={String(l)}><div className="text-sm text-muted-foreground">{l}</div><div className="mt-2 text-3xl font-black">{String(v)}{l === "نسبة الإنجاز" ? "%" : ""}</div></Card>)}</div><Courses enrollments={enrollments} /></>
}

function SimpleList({ title, rows, primary, secondary }: any) {
  const pick = (row: any, keys: string[]) => keys.map((k) => row?.[k]).find(Boolean) || "—"
  return <Card title={title}>{rows.length ? <div className="divide-y">{rows.map((row: any, i: number) => <div className="py-4" key={row.id || i}><div className="font-bold">{pick(row, primary)}</div><div className="text-sm text-muted-foreground">{pick(row, secondary)}</div></div>)}</div> : <Empty text={`لا توجد بيانات في ${title}.`} />}</Card>
}

function Conversations({ rows }: { rows: any[] }) {
  return <Card title="الرسائل">{rows.length ? <div className="grid gap-3">{rows.map((row: any) => <Link key={row.id} href={`/chat/${row.id}`} className="flex items-center gap-3 rounded-2xl border p-4 hover:border-primary"><div className="flex h-11 w-11 items-center justify-center rounded-full bg-primary/10"><MessageCircle className="text-primary" /></div><div><div className="font-bold">{row.other_user?.name || row.otherUser?.name || row.participant?.name || row.title || "محادثة"}</div><div className="line-clamp-1 text-sm text-muted-foreground">{row.last_message?.body || row.last_message?.content || row.lastMessage?.body || (typeof row.last_message === "string" ? row.last_message : "") || "افتح المحادثة"}</div></div></Link>)}</div> : <Empty text="لا توجد محادثات بعد." />}</Card>
}

function ProfileEditor({ user, reload }: any) {
  const [form, setForm] = useState({ name: user?.name || "", phone: user?.phone || "", bio: user?.bio || "" })
  const [saving, setSaving] = useState(false)
  async function save() { setSaving(true); try { await api("/auth/profile", { method: "PUT", body: JSON.stringify(form) }); await reload(); alert("تم حفظ البيانات") } catch (e: any) { alert(e.message) } finally { setSaving(false) } }
  return <Card title="الملف الشخصي"><div className="grid gap-4 md:grid-cols-2"><Field label="الاسم" value={form.name} onChange={(name) => setForm({ ...form, name })} /><Field label="الهاتف" value={form.phone} onChange={(phone) => setForm({ ...form, phone })} /><div className="md:col-span-2"><Field label="نبذة" value={form.bio} onChange={(bio) => setForm({ ...form, bio })} area /></div></div><button disabled={saving} onClick={save} className="mt-5 flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 font-bold text-white"><Save className="h-4 w-4" />حفظ التعديلات</button></Card>
}

function TeacherView({ tab, data, setData, reload, saving, setSaving }: any) {
  const profile = data.profile || {}
  const bookings = arr(data.bookings, "bookings")
  const earnings = data.earnings || {}
  const conversations = arr(data.conversations, "conversations", "data")
  const requests = bookings.filter((b: any) => b.status === "requested")
  if (tab === "overview") return <><div className="grid gap-4 md:grid-cols-4">{[["طلبات جديدة", requests.length, Bell], ["جلسات قادمة", bookings.filter((b:any)=>["scheduled","confirmed","live"].includes(b.status)).length, CalendarDays], ["الرصيد المتاح", money(earnings.available, earnings.currency), Wallet], ["التقييم", profile.rating_average || 0, Star]].map(([l,v,Icon]:any)=><Card key={l}><div className="flex items-center justify-between"><div><div className="text-sm text-muted-foreground">{l}</div><div className="mt-1 text-2xl font-black">{v}</div></div><Icon className="h-8 w-8 text-primary/50" /></div></Card>)}</div><TeacherBookings rows={bookings.slice(0,5)} reload={reload} /><Card title="ملفك العام"><div className="flex flex-wrap items-center justify-between gap-3"><div><div className="text-xl font-black">{profile.display_name}</div><div className="text-muted-foreground">{profile.headline}</div></div><div className="flex gap-2"><Badge value={profile.verification_status} /><Badge value={profile.is_accepting_bookings ? "approved" : "suspended"} /></div></div></Card></>
  if (tab === "requests") return <TeacherBookings rows={requests} reload={reload} requests />
  if (tab === "calendar") return <TeacherBookings rows={bookings} reload={reload} />
  if (tab === "messages") return <Conversations rows={conversations} />
  if (tab === "earnings") return <Earnings data={earnings} reload={reload} />
  return <TeacherMarketplace data={data} setData={setData} reload={reload} saving={saving} setSaving={setSaving} />
}

function TeacherBookings({ rows, reload, requests = false }: any) {
  async function respond(id: string, accept: boolean) { try { await api(`/instructor/bookings/${id}/respond`, { method: "POST", body: JSON.stringify({ accept, reason: accept ? undefined : "رفض المدرّس" }) }); await reload() } catch (e:any) { alert(e.message) } }
  async function join(id: string) { try { const r = await api(`/bookings/${id}/join`, { method: "POST", body: "{}" }); if(r.join_url) window.open(r.join_url,"_blank","noopener") } catch(e:any){ alert(e.message) } }
  return <Card title={requests ? "طلبات الحجز الجديدة" : "جدول الجلسات"}>{rows.length ? <div className="space-y-3">{rows.map((b:any)=><div key={b.id} className="rounded-2xl border p-4"><div className="flex flex-wrap justify-between gap-3"><div><div className="font-black">{b.offering?.title}</div><div className="text-sm text-muted-foreground">الطالب: {b.student_summary?.name} · {dateTime(b.scheduled_at)}</div></div><div className="flex gap-2"><Badge value={b.status}/><Badge value={b.payment_status}/></div></div><div className="mt-3 flex gap-2">{b.status === "requested" ? <><button onClick={()=>respond(b.id,true)} className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white">قبول</button><button onClick={()=>respond(b.id,false)} className="rounded-xl border px-4 py-2 text-sm font-bold text-red-600">رفض</button></> : null}{b.can_join ? <button onClick={()=>join(b.id)} className="rounded-xl bg-primary px-4 py-2 text-sm font-bold text-white">دخول الجلسة</button>:null}{b.conversation_id?<Link className="rounded-xl border px-4 py-2 text-sm font-bold" href={`/chat/${b.conversation_id}`}>محادثة</Link>:null}</div></div>)}</div>:<Empty text="لا توجد جلسات في هذه القائمة."/>}</Card>
}

function Earnings({ data, reload }: any) {
  const [amount,setAmount]=useState("")
  const entries=arr(data,"entries")
  async function payout(){try{await api("/instructor/payouts",{method:"POST",body:JSON.stringify({amount})});setAmount("");await reload();alert("تم إرسال طلب السحب")}catch(e:any){alert(e.message)}}
  return <><div className="grid gap-4 md:grid-cols-3"><Card><div className="text-sm text-muted-foreground">المتاح</div><div className="text-2xl font-black">{money(data.available,data.currency)}</div></Card><Card><div className="text-sm text-muted-foreground">قيد الانتظار</div><div className="text-2xl font-black">{money(data.pending,data.currency)}</div></Card><Card><div className="flex gap-2"><input className="min-w-0 flex-1 rounded-xl border px-3" value={amount} onChange={e=>setAmount(e.target.value)} placeholder="المبلغ"/><button onClick={payout} className="rounded-xl bg-primary px-4 py-2 font-bold text-white">سحب</button></div></Card></div><SimpleList title="سجل الأرباح" rows={entries} primary={["note","type"]} secondary={["created_at","amount"]}/></>
}

function TeacherMarketplace({ data, setData, reload, saving, setSaving }: any) {
  const p=data.profile || {}; const availability=data.availability || {rules:[]}
  const [uploadingVideo,setUploadingVideo]=useState(false)
  const [classification,setClassification]=useState<any[]>([])
  useEffect(()=>{api("/categories").then(value=>setClassification(arr(value,"categories"))).catch(()=>setClassification([]))},[])
  const patch=(next:any)=>setData({...data,profile:{...p,...next}})
  const patchOffering=(i:number,next:any)=>patch({offerings:(p.offerings||[]).map((o:any,n:number)=>n===i?{...o,...next}:o)})
  const roots=classification.filter((item:any)=>!item.parent_id)
  const selectedCategory=roots.find((item:any)=>item.id===p.category_id)
  const subcategories=selectedCategory?.children||selectedCategory?.subcategories||classification.filter((item:any)=>item.parent_id===p.category_id)
  const selectedSubcategory=subcategories.find((item:any)=>item.id===p.subcategory_id)
  const subjects=selectedSubcategory?.children||selectedSubcategory?.subcategories||classification.filter((item:any)=>item.parent_id===p.subcategory_id)
  const subjectIds=new Set((p.subjects||[]).map((item:any)=>String(item.id||item)))
  async function saveProfile(){setSaving(true);try{await api("/instructor/trainer-profile",{method:"PUT",body:JSON.stringify({display_name:p.display_name,headline:p.headline,bio:p.bio,intro_video_url:p.intro_video_url,is_accepting_bookings:p.is_accepting_bookings,category_id:p.category_id||null,subcategory_id:p.subcategory_id||null,subject_ids:[...subjectIds],languages:p.languages||["ar"],offerings:(p.offerings||[]).map((o:any)=>({...o,currency:"USD"}))})});await reload();alert("تم إرسال التعديلات للمراجعة، وستظل النسخة الحالية ظاهرة حتى موافقة الأدمن") }catch(e:any){alert(e.message)}finally{setSaving(false)}}
  async function saveAvailability(){setSaving(true);try{await api("/instructor/availability",{method:"PUT",body:JSON.stringify(availability)});await reload();alert("تم حفظ المواعيد") }catch(e:any){alert(e.message)}finally{setSaving(false)}}
  async function uploadVideo(file?:File){if(!file)return;setUploadingVideo(true);try{const form=new FormData();form.append("type","file");form.append("file",file);const uploaded=await api("/upload",{method:"POST",body:form});const url=uploaded?.url||uploaded;if(!url)throw new Error("لم يرجع السيرفر رابط الفيديو");patch({intro_video_url:url});alert("تم رفع الفيديو. اضغط حفظ لنشره.")}catch(e:any){alert(e.message)}finally{setUploadingVideo(false)}}
  return <div className="space-y-5"><Card title="البروفايل العام"><div className="grid gap-4 md:grid-cols-2"><Field label="الاسم الظاهر" value={p.display_name||""} onChange={(display_name)=>patch({display_name})}/><Field label="المسمى التعريفي" value={p.headline||""} onChange={(headline)=>patch({headline})}/><div className="md:col-span-2"><Field label="نبذة عنك" value={p.bio||""} onChange={(bio)=>patch({bio})} area/></div><label className="text-sm font-bold">التصنيف<select className="mt-2 w-full rounded-xl border px-3 py-2" value={p.category_id||""} onChange={e=>patch({category_id:e.target.value,subcategory_id:null,subjects:[]})}><option value="">اختر التصنيف</option>{roots.map((item:any)=><option key={item.id} value={item.id}>{item.name_ar||item.name}</option>)}</select></label><label className="text-sm font-bold">التخصص الفرعي<select className="mt-2 w-full rounded-xl border px-3 py-2" value={p.subcategory_id||""} onChange={e=>patch({subcategory_id:e.target.value,subjects:[]})}><option value="">اختر التخصص</option>{subcategories.map((item:any)=><option key={item.id} value={item.id}>{item.name_ar||item.name}</option>)}</select></label><div className="md:col-span-2"><div className="mb-2 text-sm font-bold">المواد التي أضافها الأدمن</div><div className="flex flex-wrap gap-2">{subjects.length?subjects.map((item:any)=>{const selected=subjectIds.has(String(item.id));return <button type="button" key={item.id} onClick={()=>patch({subjects:selected?(p.subjects||[]).filter((x:any)=>String(x.id||x)!==String(item.id)):[...(p.subjects||[]),item]})} className={`rounded-full border px-3 py-1.5 text-sm ${selected?"border-primary bg-primary text-white":"bg-white"}`}>{item.name_ar||item.name}</button>}):<span className="text-sm text-muted-foreground">اختار التخصص أولًا، أو اطلب من الأدمن إضافة المواد.</span>}</div></div><div className="md:col-span-2"><Field label="رابط الفيديو التعريفي (YouTube أو MP4)" value={p.intro_video_url||""} onChange={(intro_video_url)=>patch({intro_video_url})}/><label className="mt-2 inline-flex cursor-pointer items-center gap-2 rounded-xl border px-4 py-2 text-sm"><Video className="h-4 w-4"/>{uploadingVideo?"جارٍ رفع الفيديو...":"أو ارفع فيديو من الجهاز"}<input type="file" accept="video/*" className="hidden" disabled={uploadingVideo} onChange={e=>uploadVideo(e.target.files?.[0])}/></label></div></div><label className="mt-4 flex items-center gap-2"><input type="checkbox" checked={!!p.is_accepting_bookings} onChange={e=>patch({is_accepting_bookings:e.target.checked})}/>أستقبل حجوزات جديدة</label></Card>
  <Card title="الجلسات والباقات" action={<button disabled={!(p.price_options_usd||[]).length} onClick={()=>patch({offerings:[...(p.offerings||[]),{type:"package",title:"باقة جديدة",session_count:4,duration_minutes:60,price:String(p.price_options_usd[0]),discount_price:null,currency:"USD",is_active:true}]})} className="rounded-xl border px-3 py-2 text-sm font-bold disabled:opacity-50">إضافة باقة</button>}><p className="mb-3 text-sm text-muted-foreground">اختار السعر من قائمة الأدمن بالدولار USD.</p>{!(p.price_options_usd||[]).length?<p className="mb-3 rounded-xl bg-amber-50 p-3 text-sm text-amber-800">الأدمن لسه مضفش أسعار متاحة.</p>:null}<div className="space-y-3">{(p.offerings||[]).map((o:any,i:number)=><div key={o.id||i} className="grid gap-2 rounded-2xl bg-muted/50 p-3 md:grid-cols-7"><select className="rounded-xl border px-2" value={o.type} onChange={e=>patchOffering(i,{type:e.target.value})}><option value="single_session">جلسة فردية</option><option value="package">باقة</option></select><input className="rounded-xl border px-3 py-2 md:col-span-2" value={o.title} onChange={e=>patchOffering(i,{title:e.target.value})}/><input className="rounded-xl border px-3 py-2" type="number" value={o.session_count} onChange={e=>patchOffering(i,{session_count:Number(e.target.value)})} title="عدد الجلسات"/><select className="rounded-xl border px-3 py-2" value={o.price||""} onChange={e=>patchOffering(i,{price:e.target.value,discount_price:null,currency:"USD"})}><option value="">اختار السعر</option>{(p.price_options_usd||[]).map((price:number)=><option key={price} value={String(price)}>{Number(price).toFixed(2)} USD</option>)}</select><select className="rounded-xl border px-3 py-2" value={o.discount_price||""} onChange={e=>patchOffering(i,{discount_price:e.target.value||null})}><option value="">بدون خصم</option>{(p.price_options_usd||[]).filter((price:number)=>price<Number(o.price)).map((price:number)=><option key={price} value={String(price)}>{Number(price).toFixed(2)} USD</option>)}</select><label className="flex items-center gap-1 text-xs"><input type="checkbox" checked={o.is_active!==false} onChange={e=>patchOffering(i,{is_active:e.target.checked})}/>ظاهرة</label></div>)}</div><button disabled={saving||!(p.price_options_usd||[]).length} onClick={saveProfile} className="mt-4 flex items-center gap-2 rounded-xl bg-primary px-5 py-2.5 font-bold text-white disabled:opacity-50"><Save className="h-4 w-4"/>إرسال التعديلات للمراجعة</button></Card>
  <Card title="مواعيد التوافر"><div className="grid gap-2 sm:grid-cols-2">{["الأحد","الإثنين","الثلاثاء","الأربعاء","الخميس","الجمعة","السبت"].map((day,index)=>{const rule=(availability.rules||[]).find((r:any)=>r.weekday===index);return <label key={day} className="flex items-center justify-between rounded-xl border p-3"><span className="font-bold">{day}</span><input type="checkbox" checked={!!rule} onChange={e=>setData({...data,availability:{...availability,rules:e.target.checked?[...(availability.rules||[]),{weekday:index,start_minute:960,end_minute:1260}]:(availability.rules||[]).filter((r:any)=>r.weekday!==index)}})}/></label>})}</div><button disabled={saving} onClick={saveAvailability} className="mt-4 rounded-xl bg-primary px-5 py-2.5 font-bold text-white">حفظ المواعيد</button></Card></div>
}

function Field({ label, value, onChange, area=false }: any) {
  return <label className="block text-sm font-bold">{label}{area?<textarea rows={4} className="mt-2 w-full rounded-xl border px-3 py-2 font-normal" value={value} onChange={e=>onChange(e.target.value)}/>:<input className="mt-2 w-full rounded-xl border px-3 py-2 font-normal" value={value} onChange={e=>onChange(e.target.value)}/>}</label>
}
