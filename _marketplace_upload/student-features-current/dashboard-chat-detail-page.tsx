"use client"

import { useState, useEffect, useRef, useCallback } from "react"
import Link from "next/link"
import { useParams } from "next/navigation"
import { Navbar } from "@/components/navbar"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { ArrowRight, Send, Loader2, MessageCircle, Paperclip, Mic, Square } from "lucide-react"
import {
  chatApi, mediaUrl, isAuthenticated, getStoredUser, uploadApi,
  type ChatMessage, type ChatConversation,
} from "@/lib/api"
import { useRouter } from "next/navigation"
import { useToast } from "@/hooks/use-toast"

export default function ChatRoomPage() {
  const params = useParams()
  const conversationId = params.id as string
  const router = useRouter()
  const { toast } = useToast()
  const bottomRef = useRef<HTMLDivElement>(null)
  const myIdRef = useRef<string>("")

  const [isDark, setIsDark] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [loading, setLoading] = useState(true)
  const [sending, setSending] = useState(false)
  const [messages, setMessages] = useState<ChatMessage[]>([])
  const [otherUser, setOtherUser] = useState<{ id?: string; name: string; avatar?: string } | null>(null)
  const [draft, setDraft] = useState("")
  const [uploading, setUploading] = useState(false)
  const [recording, setRecording] = useState(false)
  const recorderRef = useRef<MediaRecorder | null>(null)
  const audioChunksRef = useRef<Blob[]>([])
  const recordingStartedRef = useRef(0)

  useEffect(() => {
    setMounted(true)
    const dark =
      localStorage.getItem("theme") === "dark" ||
      (!localStorage.getItem("theme") && window.matchMedia("(prefers-color-scheme: dark)").matches)
    setIsDark(dark)

    if (!isAuthenticated()) {
      router.push(`/login?redirect=/dashboard/chat/${conversationId}`)
      return
    }
    const me = getStoredUser()
    if (me?.id) myIdRef.current = me.id
  }, [conversationId, router])

  const scrollBottom = useCallback(() => {
    requestAnimationFrame(() => bottomRef.current?.scrollIntoView({ behavior: "smooth" }))
  }, [])

  const normalize = (data: any): ChatMessage[] => {
    const list: ChatMessage[] = Array.isArray(data) ? data : data?.messages || []
    // backend usually returns newest-first — render oldest-first
    return [...list].sort((a, b) => {
      const da = new Date(a.createdAt || a.created_at || 0).getTime()
      const db = new Date(b.createdAt || b.created_at || 0).getTime()
      return da - db
    })
  }

  const fetchMessages = useCallback(
    async (silent = false) => {
      try {
        const res = await chatApi.getMessages(conversationId, { perPage: 100 })
        if (res.success) {
          const list = normalize(res.data)
          setMessages(list)
          // mark incoming unread messages as read
          list
            .filter((m) => !m.isRead && !m.is_read && (m.senderId || m.sender_id) !== myIdRef.current)
            .slice(-10)
            .forEach((m) => chatApi.markMessageRead(m.id).catch(() => {}))
        }
      } catch {
        /* keep messages on error */
      } finally {
        if (!silent) setLoading(false)
      }
    },
    [conversationId]
  )

  useEffect(() => {
    fetchMessages().then(scrollBottom)
    const t = setInterval(() => fetchMessages(true), 6000)
    return () => clearInterval(t)
  }, [fetchMessages, scrollBottom])

  // resolve the other participant from the conversations list
  useEffect(() => {
    chatApi
      .getConversations({ perPage: 50 })
      .then((res) => {
        if (!res.success) return
        const data: any = res.data
        const list: ChatConversation[] = Array.isArray(data) ? data : data?.conversations || []
        const conv = list.find((c) => c.id === conversationId)
        const other = conv?.otherUser || conv?.other_user
        if (other) setOtherUser(other)
      })
      .catch(() => {})
  }, [conversationId])

  const send = async () => {
    const body = draft.trim()
    if (!body || sending) return
    setSending(true)
    setDraft("")
    const optimistic: ChatMessage = {
      id: `tmp-${Date.now()}`,
      senderId: myIdRef.current,
      body,
      createdAt: new Date().toISOString(),
      isRead: false,
    }
    setMessages((prev) => [...prev, optimistic])
    scrollBottom()
    try {
      const res = await chatApi.sendMessage(conversationId, body)
      if (res.success && res.data) {
        setMessages((prev) => prev.map((m) => (m.id === optimistic.id ? { ...m, ...res.data } : m)))
      }
    } catch (err: any) {
      setMessages((prev) => prev.filter((m) => m.id !== optimistic.id))
      setDraft(body)
      toast({ title: "تعذر إرسال الرسالة", description: err?.message, variant: "destructive" })
    } finally {
      setSending(false)
    }
  }

  const sendAttachment = async (file: File, type: "image" | "video" | "audio", durationSeconds?: number) => {
    if (uploading) return
    setUploading(true)
    try {
      const url = await uploadApi.upload(file)
      if (!url) throw new Error("لم يرجع رابط للمرفق")
      const res = await chatApi.sendMessage(conversationId, "", {
        url, type, name: file.name, size: file.size, durationSeconds,
      })
      if (res.success && res.data) {
        setMessages((prev) => [...prev, res.data])
        scrollBottom()
      }
    } catch (err: any) {
      toast({ title: "تعذر إرسال المرفق", description: err?.message, variant: "destructive" })
    } finally {
      setUploading(false)
    }
  }

  const toggleRecording = async () => {
    if (recording) {
      recorderRef.current?.stop()
      setRecording(false)
      return
    }
    try {
      const stream = await navigator.mediaDevices.getUserMedia({ audio: true })
      const recorder = new MediaRecorder(stream)
      recorderRef.current = recorder
      audioChunksRef.current = []
      recordingStartedRef.current = Date.now()
      recorder.ondataavailable = (event) => { if (event.data.size) audioChunksRef.current.push(event.data) }
      recorder.onstop = async () => {
        const blob = new Blob(audioChunksRef.current, { type: recorder.mimeType || "audio/webm" })
        stream.getTracks().forEach((track) => track.stop())
        const extension = blob.type.includes("mp4") ? "m4a" : "webm"
        const file = new File([blob], `voice-${Date.now()}.${extension}`, { type: blob.type })
        const duration = Math.max(1, Math.round((Date.now() - recordingStartedRef.current) / 1000))
        await sendAttachment(file, "audio", duration)
      }
      recorder.start()
      setRecording(true)
    } catch {
      toast({ title: "تعذر تشغيل الميكروفون", description: "اسمح للموقع باستخدام الميكروفون ثم جرّب مرة أخرى.", variant: "destructive" })
    }
  }

  if (!mounted) return null

  const isMine = (m: ChatMessage) => (m.senderId || m.sender_id) === myIdRef.current

  return (
    <main dir="rtl" className="min-h-screen bg-muted/20 flex flex-col">
      <Navbar isDark={isDark} setIsDark={setIsDark} />

      {/* Chat header */}
      <div className="sticky top-20 z-30 border-b bg-card/90 backdrop-blur-xl">
        <div className="container mx-auto px-4 h-16 flex items-center gap-3">
          <Link href="/dashboard/chat">
            <Button variant="ghost" size="icon" className="rounded-full">
              <ArrowRight className="h-5 w-5" />
            </Button>
          </Link>
          <Avatar className="h-10 w-10">
            <AvatarImage src={mediaUrl(otherUser?.avatar)} />
            <AvatarFallback className="bg-primary/10 text-primary font-bold">
              {otherUser?.name?.charAt(0) || "?"}
            </AvatarFallback>
          </Avatar>
          <div className="text-right">
            <p className="font-bold text-sm">{otherUser?.name || "محادثة"}</p>
            <p className="text-[11px] text-muted-foreground">محادثة مع المدرس</p>
          </div>
        </div>
      </div>

      {/* Messages */}
      <div className="flex-1 container mx-auto px-4 py-6 max-w-3xl">
        {loading ? (
          <div className="flex items-center justify-center py-32">
            <Loader2 className="h-8 w-8 animate-spin text-primary" />
          </div>
        ) : messages.length === 0 ? (
          <div className="flex flex-col items-center justify-center py-24 text-center">
            <MessageCircle className="h-14 w-14 text-muted-foreground/40 mb-4" />
            <p className="font-bold">ابدأ المحادثة</p>
            <p className="text-sm text-muted-foreground mt-1">أرسل أول رسالة للمدرس</p>
          </div>
        ) : (
          <div className="space-y-3">
            {messages.map((m, i) => {
              const mine = isMine(m)
              const read = m.isRead || m.is_read
              const prev = messages[i - 1]
              const showAvatar = !mine && (!prev || isMine(prev))
              const attachmentUrl = m.attachmentUrl || m.attachment_url
              const attachmentType = m.attachmentType || m.attachment_type
              return (
                <div key={m.id} className={`flex items-end gap-2 ${mine ? "flex-row" : "flex-row-reverse"} animate-fade-up`}>
                  {!mine && (
                    <Avatar className={`h-7 w-7 shrink-0 ${showAvatar ? "" : "invisible"}`}>
                      <AvatarImage src={mediaUrl(otherUser?.avatar)} />
                      <AvatarFallback className="bg-primary/10 text-primary text-xs font-bold">
                        {otherUser?.name?.charAt(0) || "?"}
                      </AvatarFallback>
                    </Avatar>
                  )}
                  <div
                    className={`max-w-[75%] rounded-3xl px-4 py-2.5 text-sm leading-6 shadow-sm ${
                      mine
                        ? "bg-primary text-primary-foreground rounded-br-md"
                        : "bg-white dark:bg-card rounded-bl-md"
                    }`}
                  >
                    {attachmentUrl && attachmentType === "image" ? (
                      <a href={mediaUrl(attachmentUrl)} target="_blank" rel="noreferrer">
                        <img src={mediaUrl(attachmentUrl)} alt={m.attachmentName || m.attachment_name || "صورة"} className="mb-2 max-h-72 w-full rounded-2xl object-cover" />
                      </a>
                    ) : null}
                    {attachmentUrl && attachmentType === "video" ? (
                      <video src={mediaUrl(attachmentUrl)} controls preload="metadata" className="mb-2 max-h-80 w-full rounded-2xl" />
                    ) : null}
                    {attachmentUrl && attachmentType === "audio" ? (
                      <audio src={mediaUrl(attachmentUrl)} controls preload="metadata" className="mb-2 max-w-full" />
                    ) : null}
                    {m.body ? <p className="whitespace-pre-wrap break-words">{m.body}</p> : null}
                    <p className={`text-[10px] mt-1 flex items-center gap-1 ${mine ? "text-primary-foreground/60 justify-start" : "text-muted-foreground justify-end"}`}>
                      {new Date(m.createdAt || m.created_at || Date.now()).toLocaleTimeString("ar-SA", { hour: "2-digit", minute: "2-digit" })}
                      {mine && <span>{read ? "✓✓" : "✓"}</span>}
                    </p>
                  </div>
                </div>
              )
            })}
            <div ref={bottomRef} />
          </div>
        )}
      </div>

      {/* Composer */}
      <div className="sticky bottom-0 border-t bg-card/95 backdrop-blur-xl">
        <div className="container mx-auto px-4 py-3 max-w-3xl">
          <form
            onSubmit={(e) => {
              e.preventDefault()
              send()
            }}
            className="flex items-center gap-2"
          >
            <Button type="submit" size="icon" disabled={!draft.trim() || sending} className="rounded-full h-11 w-11 shrink-0">
              {sending ? <Loader2 className="h-5 w-5 animate-spin" /> : <Send className="h-5 w-5 -scale-x-100" />}
            </Button>
            <Input
              value={draft}
              onChange={(e) => setDraft(e.target.value)}
              placeholder="اكتب رسالتك..."
              className="rounded-full h-11 bg-muted/60 border-none text-right"
            />
            <label className={`inline-flex h-11 w-11 shrink-0 cursor-pointer items-center justify-center rounded-full border ${uploading ? "pointer-events-none opacity-50" : ""}`} title="إرسال صورة أو فيديو">
              {uploading ? <Loader2 className="h-5 w-5 animate-spin" /> : <Paperclip className="h-5 w-5" />}
              <input
                type="file"
                accept="image/*,video/*"
                className="hidden"
                disabled={uploading || recording}
                onChange={(event) => {
                  const file = event.target.files?.[0]
                  if (file) sendAttachment(file, file.type.startsWith("video/") ? "video" : "image")
                  event.currentTarget.value = ""
                }}
              />
            </label>
            <Button type="button" variant={recording ? "destructive" : "outline"} size="icon" disabled={uploading} onClick={toggleRecording} className="h-11 w-11 shrink-0 rounded-full" title={recording ? "إيقاف وإرسال" : "تسجيل صوتي"}>
              {recording ? <Square className="h-4 w-4 fill-current" /> : <Mic className="h-5 w-5" />}
            </Button>
          </form>
        </div>
      </div>
    </main>
  )
}
