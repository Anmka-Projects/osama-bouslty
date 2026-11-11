"use client"

import { FormEvent, useCallback, useEffect, useRef, useState } from "react"
import { useParams, useRouter } from "next/navigation"
import { ArrowRight, Loader2, Send } from "lucide-react"
import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"

function authHeaders(json = false) {
  const access = typeof window === "undefined" ? "" : localStorage.getItem("studentToken") || localStorage.getItem("accessToken") || ""
  return { ...(access ? { Authorization: `Bearer ${access}` } : {}), ...(json ? { "Content-Type": "application/json" } : {}) }
}

export default function ChatPage() {
  const { conversationId } = useParams<{ conversationId: string }>()
  const router = useRouter()
  const [messages, setMessages] = useState<any[]>([])
  const [me, setMe] = useState<any>(null)
  const [text, setText] = useState("")
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [error, setError] = useState("")
  const bottom = useRef<HTMLDivElement>(null)

  const load = useCallback(async (silent = false) => {
    try {
      const [meResponse, messagesResponse] = await Promise.all([
        fetch("/api/auth/me", { credentials: "include", headers: authHeaders() }),
        fetch(`/api/chat/conversations/${conversationId}/messages?limit=100`, { credentials: "include", headers: authHeaders() }),
      ])
      if (meResponse.status === 401 || messagesResponse.status === 401) return router.replace(`/login?redirect=/chat/${conversationId}`)
      const meBody = await meResponse.json()
      const messagesBody = await messagesResponse.json()
      if (!messagesResponse.ok) throw new Error(messagesBody.message || "تعذر تحميل المحادثة")
      setMe(meBody.data?.user || meBody.data || null)
      const payload = messagesBody.data
      setMessages(Array.isArray(payload) ? payload : payload?.messages || payload?.data || [])
      setError("")
    } catch (e: any) {
      if (!silent) setError(e.message || "تعذر تحميل المحادثة")
    } finally {
      if (!silent) setLoading(false)
    }
  }, [conversationId, router])

  useEffect(() => {
    load()
    const timer = window.setInterval(() => load(true), 5000)
    return () => window.clearInterval(timer)
  }, [load])

  useEffect(() => bottom.current?.scrollIntoView({ behavior: "smooth" }), [messages.length])

  async function send(event: FormEvent) {
    event.preventDefault()
    const body = text.trim()
    if (!body || sending) return
    setSending(true)
    setText("")
    try {
      const response = await fetch(`/api/chat/conversations/${conversationId}/messages`, {
        method: "POST", credentials: "include", headers: authHeaders(true), body: JSON.stringify({ body }),
      })
      const result = await response.json()
      if (!response.ok) throw new Error(result.message || "تعذر إرسال الرسالة")
      await load(true)
    } catch (e: any) {
      setText(body)
      setError(e.message || "تعذر إرسال الرسالة")
    } finally { setSending(false) }
  }

  const myId = me?.id || me?.userId
  return <div dir="rtl" className="min-h-screen bg-slate-50"><Navbar />
    <main className="container mx-auto max-w-4xl px-4 py-8">
      <section className="overflow-hidden rounded-3xl border bg-white shadow-sm">
        <header className="flex items-center gap-3 border-b p-4"><button onClick={() => router.back()} className="rounded-xl border p-2" aria-label="رجوع"><ArrowRight className="h-5 w-5" /></button><div><h1 className="font-black">المحادثة</h1><p className="text-xs text-muted-foreground">يتم تحديث الرسائل تلقائيًا</p></div></header>
        <div className="h-[58vh] space-y-3 overflow-y-auto bg-slate-50 p-4">
          {loading ? <div className="flex h-full items-center justify-center"><Loader2 className="animate-spin text-primary" /></div> : null}
          {!loading && !messages.length ? <div className="flex h-full items-center justify-center text-sm text-muted-foreground">ابدأ المحادثة برسالة جديدة</div> : null}
          {messages.map((message: any) => { const senderId=message.senderId||message.sender_id||message.sender?.id; const mine=String(senderId)===String(myId); return <div key={message.id} className={`flex ${mine?"justify-start":"justify-end"}`}><div className={`max-w-[82%] rounded-2xl px-4 py-3 ${mine?"bg-primary text-white":"border bg-white"}`}><p className="whitespace-pre-wrap text-sm">{message.body||message.content}</p><div className={`mt-1 text-[10px] ${mine?"text-white/70":"text-muted-foreground"}`}>{new Date(message.createdAt||message.created_at).toLocaleString("ar-EG",{hour:"2-digit",minute:"2-digit",day:"numeric",month:"short"})}</div></div></div> })}
          <div ref={bottom} />
        </div>
        {error ? <p className="border-t bg-red-50 px-4 py-2 text-xs text-red-700">{error}</p> : null}
        <form onSubmit={send} className="flex gap-2 border-t p-4"><input value={text} onChange={e=>setText(e.target.value)} maxLength={2000} placeholder="اكتب رسالتك..." className="min-w-0 flex-1 rounded-xl border px-4 py-3 outline-none focus:border-primary"/><button disabled={sending||!text.trim()} className="flex items-center gap-2 rounded-xl bg-primary px-5 font-bold text-white disabled:opacity-50">{sending?<Loader2 className="h-4 w-4 animate-spin"/>:<Send className="h-4 w-4"/>}<span className="hidden sm:inline">إرسال</span></button></form>
      </section>
    </main><Footer /></div>
}
