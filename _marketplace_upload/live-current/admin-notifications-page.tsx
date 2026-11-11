"use client"
import { useEffect, useState } from "react"
import { AdminLayout } from "@/components/layout/admin-layout"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { Label } from "@/components/ui/label"
import { Textarea } from "@/components/ui/textarea"
import { Select, SelectContent, SelectItem, SelectTrigger, SelectValue } from "@/components/ui/select"
import { Dialog, DialogContent, DialogHeader, DialogTitle, DialogFooter } from "@/components/ui/dialog"
import { StatusBadge } from "@/components/ui/status-badge"
import { CardSkeleton } from "@/components/ui/loading-skeleton"
import { ErrorState } from "@/components/ui/error-state"
import { EmptyState } from "@/components/ui/empty-state"
import { useApi, useMutation } from "@/hooks/use-api"
import { notificationsApi } from "@/lib/api"
import type { Notification } from "@/types/api"
import { Plus, Send, Clock, Bell, Users, Loader2 } from "lucide-react"

export default function NotificationsPage() {
  const { data: notifications, isLoading, error, execute } = useApi(notificationsApi.getAll)
  const { mutate: sendNotification, isLoading: isSending } = useMutation(notificationsApi.create, {
    successMessage: "تم إرسال الإشعار بنجاح",
    onSuccess: () => {
      execute()
      setIsDialogOpen(false)
      resetForm()
    },
  })

  const [isDialogOpen, setIsDialogOpen] = useState(false)
  const [formData, setFormData] = useState({
    title: "",
    body: "",
    targetAudience: "all" as Notification["targetAudience"],
    deepLink: "",
    scheduledAt: "",
  })

  useEffect(() => {
    execute()
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [])

  const resetForm = () => {
    setFormData({
      title: "",
      body: "",
      targetAudience: "all",
      deepLink: "",
      scheduledAt: "",
    })
  }

  const handleSubmit = async () => {
    await sendNotification(formData)
  }

  const getStatusBadge = (status: Notification["status"]) => {
    const statusMap = {
      draft: { type: "warning" as const, label: "مسودة" },
      scheduled: { type: "info" as const, label: "مجدول" },
      sent: { type: "success" as const, label: "تم الإرسال" },
    }
    return statusMap[status]
  }

  const getAudienceLabel = (audience: Notification["targetAudience"]) => {
    const audienceMap = {
      all: "جميع المستخدمين",
      students: "الطلاب فقط",
      instructors: "المدرسين فقط",
      specific: "مستخدمين محددين",
    }
    return audienceMap[audience]
  }

  if (error) {
    return (
      <AdminLayout title="الإشعارات">
        <ErrorState message={error} onRetry={() => execute()} />
      </AdminLayout>
    )
  }

  return (
    <AdminLayout title="الإشعارات" subtitle="إرسال وإدارة الإشعارات للمستخدمين">
      <div className="space-y-6">
        <div className="flex items-center justify-between">
          <p className="text-muted-foreground">{notifications?.length || 0} إشعار</p>
          <Button onClick={() => setIsDialogOpen(true)} className="gap-2 bg-purple-600 hover:bg-purple-700">
            <Plus className="h-4 w-4" />
            إرسال إشعار
          </Button>
        </div>

        {isLoading ? (
          <div className="grid gap-4 md:grid-cols-2">
            {Array.from({ length: 4 }).map((_, i) => (
              <CardSkeleton key={i} />
            ))}
          </div>
        ) : notifications?.length === 0 ? (
          <EmptyState
            icon="notifications"
            title="لا توجد إشعارات"
            description="ابدأ بإرسال إشعار جديد للمستخدمين"
            action={{
              label: "إرسال إشعار",
              onClick: () => setIsDialogOpen(true),
            }}
          />
        ) : (
          <div className="grid gap-4 md:grid-cols-2">
            {(Array.isArray(notifications) ? notifications : [])?.map((notification) => (
              <div key={notification.id} className="rounded-xl border border-border/50 bg-card p-6">
                <div className="flex items-start justify-between">
                  <div className="flex items-center gap-3">
                    <div className="rounded-lg bg-purple-500/10 p-2">
                      <Bell className="h-5 w-5 text-purple-400" />
                    </div>
                    <div>
                      <h3 className="font-semibold text-foreground">{notification.title}</h3>
                      <p className="text-sm text-muted-foreground line-clamp-2">{notification.body}</p>
                    </div>
                  </div>
                  <StatusBadge status={getStatusBadge(notification.status).type}>
                    {getStatusBadge(notification.status).label}
                  </StatusBadge>
                </div>
                <div className="mt-4 flex items-center justify-between border-t border-border/50 pt-4 text-sm text-muted-foreground">
                  <div className="flex items-center gap-2">
                    <Users className="h-4 w-4" />
                    <span>{getAudienceLabel(notification.targetAudience)}</span>
                  </div>
                  <div className="flex items-center gap-2">
                    <Clock className="h-4 w-4" />
                    <span>
                      {notification.sentAt
                        ? new Date(notification.sentAt).toLocaleDateString("ar-EG")
                        : notification.scheduledAt
                          ? new Date(notification.scheduledAt).toLocaleDateString("ar-EG")
                          : "غير محدد"}
                    </span>
                  </div>
                </div>
              </div>
            ))}
          </div>
        )}
      </div>

      <Dialog open={isDialogOpen} onOpenChange={setIsDialogOpen}>
        <DialogContent className="sm:max-w-lg" dir="rtl">
          <DialogHeader>
            <DialogTitle>إرسال إشعار جديد</DialogTitle>
          </DialogHeader>
          <div className="space-y-4 py-4">
            <div className="space-y-2">
              <Label htmlFor="title">عنوان الإشعار *</Label>
              <Input
                id="title"
                value={formData.title}
                onChange={(e) => setFormData({ ...formData, title: e.target.value })}
                className="bg-muted/50"
                placeholder="أدخل عنوان الإشعار"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="body">نص الإشعار *</Label>
              <Textarea
                id="body"
                value={formData.body}
                onChange={(e) => setFormData({ ...formData, body: e.target.value })}
                className="bg-muted/50 min-h-[100px]"
                placeholder="اكتب محتوى الإشعار"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="targetAudience">الجمهور المستهدف</Label>
              <Select
                value={formData.targetAudience}
                onValueChange={(value) =>
                  setFormData({ ...formData, targetAudience: value as Notification["targetAudience"] })
                }
              >
                <SelectTrigger className="bg-muted/50">
                  <SelectValue />
                </SelectTrigger>
                <SelectContent>
                  <SelectItem value="all">جميع المستخدمين</SelectItem>
                  <SelectItem value="students">الطلاب فقط</SelectItem>
                  <SelectItem value="instructors">المدرسين فقط</SelectItem>
                </SelectContent>
              </Select>
            </div>
            <div className="space-y-2">
              <Label htmlFor="deepLink">رابط التوجيه (اختياري)</Label>
              <Input
                id="deepLink"
                value={formData.deepLink}
                onChange={(e) => setFormData({ ...formData, deepLink: e.target.value })}
                className="bg-muted/50"
                placeholder="app://courses/123"
                dir="ltr"
              />
            </div>
            <div className="space-y-2">
              <Label htmlFor="scheduledAt">جدولة الإرسال (اختياري)</Label>
              <Input
                id="scheduledAt"
                type="datetime-local"
                value={formData.scheduledAt}
                onChange={(e) => setFormData({ ...formData, scheduledAt: e.target.value })}
                className="bg-muted/50"
                dir="ltr"
              />
            </div>
          </div>
          <DialogFooter className="gap-2">
            <Button variant="outline" onClick={() => setIsDialogOpen(false)}>
              إلغاء
            </Button>
            <Button
              onClick={handleSubmit}
              disabled={isSending || !formData.title || !formData.body}
              className="gap-2 bg-purple-600 hover:bg-purple-700"
            >
              {isSending ? <Loader2 className="h-4 w-4 animate-spin" /> : <Send className="h-4 w-4" />}
              إرسال
            </Button>
          </DialogFooter>
        </DialogContent>
      </Dialog>
    </AdminLayout>
  )
}
