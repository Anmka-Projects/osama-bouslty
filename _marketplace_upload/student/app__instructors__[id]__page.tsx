"use client"

import Link from "next/link"
import { useEffect, useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowRight, MessageCircle, Star, Video } from "lucide-react"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { MarketplaceBooking } from "@/components/marketplace-booking"

function youtubeEmbed(url?: string) {
  const match = url?.match(/(?:youtube\.com\/(?:watch\?v=|embed\/|shorts\/)|youtu\.be\/)([A-Za-z0-9_-]{6,})/)
  return match ? `https://www.youtube.com/embed/${match[1]}` : ""
}
function mediaUrl(url?:string){if(!url)return "";if(url.startsWith("http"))return url;return url.startsWith("/api/")?url:`/api${url.startsWith("/uploads/")?url:`/uploads/${url}`}`}
function headers(){const access=typeof window==="undefined"?"":localStorage.getItem("studentToken")||"";return {"Content-Type":"application/json",...(access?{Authorization:`Bearer ${access}`}:{})}}

export default function InstructorDetailsPage() {
  const { id } = useParams<{id:string}>()
  const router=useRouter()
  const [profile,setProfile]=useState<any>(null)
  const [loading,setLoading]=useState(true)
  const [chatBusy,setChatBusy]=useState(false)
  useEffect(()=>{fetch(`/api/trainers/${id}`).then(r=>r.json()).then(body=>setProfile(body.data||null)).finally(()=>setLoading(false))},[id])
  async function startChat(){
    const otherUserId=profile?.user_id||profile?.userId||profile?.instructor_id
    if(!localStorage.getItem("studentToken"))return router.push(`/login?redirect=/instructors/${id}`)
    if(!otherUserId)return
    setChatBusy(true)
    try{const response=await fetch("/api/chat/conversations",{method:"POST",credentials:"include",headers:headers(),body:JSON.stringify({otherUserId})});const body=await response.json();if(!response.ok)throw new Error(body.message);const conversation=body.data;router.push(`/chat/${conversation.id||conversation.conversation_id}`)}catch(e:any){alert(e.message||"تعذر بدء المحادثة")}finally{setChatBusy(false)}
  }
  if(loading)return <div dir="rtl"><Navbar/><div className="py-32 text-center">جارٍ تحميل ملف المدرس...</div><Footer/></div>
  if(!profile)return <div dir="rtl"><Navbar/><div className="py-32 text-center">هذا المدرس غير متاح حاليًا.<div><Link className="mt-5 inline-block text-primary" href="/instructors">العودة للمدرسين</Link></div></div><Footer/></div>
  const video=profile.intro_video_url; const youtube=youtubeEmbed(video)
  return <div dir="rtl" className="min-h-screen bg-slate-50"><Navbar/><main>
    <section className="bg-gradient-to-l from-primary/15 via-white to-white"><div className="container mx-auto flex flex-col gap-6 px-4 py-10 md:flex-row md:items-center"><div className="flex h-28 w-28 shrink-0 items-center justify-center overflow-hidden rounded-3xl bg-primary/10 text-4xl font-black text-primary">{profile.avatar_url?<img src={mediaUrl(profile.avatar_url)} alt="" className="h-full w-full object-cover"/>:(profile.display_name||"م")[0]}</div><div className="flex-1"><h1 className="text-3xl font-black">{profile.display_name}</h1><p className="mt-2 text-lg text-muted-foreground">{profile.headline||"مدرس معتمد"}</p><div className="mt-3 flex items-center gap-2 text-sm"><Star className="h-4 w-4 fill-amber-400 text-amber-400"/>{Number(profile.rating||0).toFixed(1)} · {profile.completed_bookings||0} جلسة مكتملة</div></div><button onClick={startChat} disabled={chatBusy} className="flex items-center justify-center gap-2 rounded-xl bg-primary px-5 py-3 font-bold text-white"><MessageCircle className="h-5 w-5"/>{chatBusy?"جارٍ فتح المحادثة...":"راسل المدرس"}</button></div></section>
    <div className="container mx-auto grid gap-6 px-4 py-8 lg:grid-cols-[1fr_420px]"><div className="space-y-6">{video?<section className="overflow-hidden rounded-3xl border bg-black shadow-sm"><div className="relative aspect-video">{youtube?<iframe className="h-full w-full" src={youtube} title="الفيديو التعريفي" allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture" allowFullScreen/>:<video className="h-full w-full object-contain" src={mediaUrl(video)} controls playsInline/>}<span className="absolute right-3 top-3 flex items-center gap-1 rounded-full bg-black/60 px-3 py-1 text-xs text-white"><Video className="h-3 w-3"/>الفيديو التعريفي</span></div></section>:null}<section className="rounded-3xl border bg-white p-6 shadow-sm"><h2 className="text-xl font-black">عن المدرس</h2><p className="mt-3 whitespace-pre-wrap leading-8 text-muted-foreground">{profile.bio||"لم يضف المدرس نبذة بعد."}</p>{profile.specialties?.length?<div className="mt-5 flex flex-wrap gap-2">{profile.specialties.map((x:any)=><span key={x.id||x.name||x} className="rounded-full bg-primary/10 px-3 py-1 text-sm text-primary">{x.name||x}</span>)}</div>:null}</section></div><aside><MarketplaceBooking trainerId={id}/></aside></div>
    <div className="container mx-auto px-4 pb-10"><Link href="/instructors" className="inline-flex items-center gap-2 font-bold text-primary"><ArrowRight className="h-4 w-4"/>كل المدرسين</Link></div>
  </main><Footer/></div>
}
