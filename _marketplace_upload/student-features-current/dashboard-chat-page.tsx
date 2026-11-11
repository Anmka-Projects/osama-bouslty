"use client"

import { useState, useEffect, useCallback } from "react"
import Link from "next/link"
import { AppShell } from "@/components/app/app-shell"
import { EmptyState } from "@/components/app/empty-state"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { MessageCircle, ChevronLeft } from "lucide-react"
import { chatApi, mediaUrl, type ChatConversation } from "@/lib/api"

function timeAgo(dateStr?: string) {
  if (!dateStr) return ""
  const diff = Date.now() - new Date(dateStr).getTime()
  const mins = Math.floor(diff / 60000)
  if (mins < 1) return "الآن"
  if (mins < 60) return `${mins}د`
  const hours = Math.floor(mins / 60)
  if (hours < 24) return `${hours}س`
  return `${Math.floor(hours / 24)}ي`
}

export default function ChatPage() {
  const [loading, setLoading] = useState(true)
  const [conversations, setConversations] = useState<ChatConversation[]>([])

  const fetchConversations = useCallback(async (silent = false) => {
    try {
      const res = await chatApi.getConversations({ perPage: 50 })
      if (res.success) {
        const data: any = res.data
        setConversations(Array.isArray(data) ? data : data?.conversations || [])
      }
    } catch {
      /* keep existing list on error */
    } finally {
      if (!silent) setLoading(false)
    }
  }, [])

  useEffect(() => {
    fetchConversations()
    const t = setInterval(() => fetchConversations(true), 15000)
    return () => clearInterval(t)
  }, [fetchConversations])

  return (
    <AppShell active="chat" loading={loading}>
      <div className="text-right">
        <h1 className="text-2xl font-black">المحادثات</h1>
        <p className="text-sm text-muted-foreground mt-1">تواصل مع مدرسيك مباشرة</p>
      </div>

      {conversations.length === 0 ? (
        <Card className="border-none shadow-sm rounded-3xl bg-white dark:bg-card">
          <EmptyState
            icon={MessageCircle}
            title="لا توجد محادثات"
            description="ابدأ محادثة مع مدرسيك من صفحة الدورة أو صفحة المدرس."
            actionLabel="تصفح الدورات"
            actionHref="/courses"
          />
        </Card>
      ) : (
        <Card className="border-none shadow-sm rounded-3xl bg-white dark:bg-card overflow-hidden">
          <CardContent className="p-2 divide-y divide-border/60">
            {conversations.map((c) => {
              const other = c.otherUser || c.other_user
              const last = c.lastMessage || c.last_message
              const unread = c.unreadCount ?? c.unread_count ?? 0
              return (
                <Link key={c.id} href={`/dashboard/chat/${c.id}`} className="block">
                  <div className={`flex items-center gap-3 p-4 rounded-2xl transition-colors hover:bg-muted/60 ${unread ? "bg-primary/5" : ""}`}>
                    <Avatar className="h-12 w-12 shrink-0">
                      <AvatarImage src={mediaUrl(other?.avatar)} />
                      <AvatarFallback className="bg-primary/10 text-primary font-bold">
                        {other?.name?.charAt(0) || "?"}
                      </AvatarFallback>
                    </Avatar>
                    <div className="flex-1 min-w-0 text-right">
                      <div className="flex items-center justify-between gap-2">
                        <p className="font-bold text-sm line-clamp-1">{other?.name || "محادثة"}</p>
                        <span className="text-[10px] text-muted-foreground shrink-0">{timeAgo(last?.createdAt || last?.created_at || c.updatedAt)}</span>
                      </div>
                      <div className="flex items-center justify-between gap-2 mt-0.5">
                        <p className={`text-xs line-clamp-1 ${unread ? "text-foreground font-medium" : "text-muted-foreground"}`}>
                          {last?.body || ((last?.attachmentType || last?.attachment_type) === "image" ? "صورة" : (last?.attachmentType || last?.attachment_type) === "video" ? "فيديو" : (last?.attachmentType || last?.attachment_type) === "audio" ? "تسجيل صوتي" : "ابدأ المحادثة")}
                        </p>
                        {unread > 0 && (
                          <Badge className="bg-secondary text-secondary-foreground h-5 min-w-5 text-[10px] shrink-0">{unread}</Badge>
                        )}
                      </div>
                    </div>
                    <ChevronLeft className="h-4 w-4 text-muted-foreground shrink-0" />
                  </div>
                </Link>
              )
            })}
          </CardContent>
        </Card>
      )}
    </AppShell>
  )
}
