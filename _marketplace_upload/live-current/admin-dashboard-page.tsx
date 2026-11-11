"use client"

import { useEffect, useState } from "react"
import { AdminLayout } from "@/components/layout/admin-layout"
import { OverviewCards } from "@/components/dashboard/overview-cards"
import { InstructorOverviewCards } from "@/components/dashboard/instructor-overview-cards"
import { DashboardCharts } from "@/components/dashboard/charts"
import { Button } from "@/components/ui/button"
import { RefreshCw } from "lucide-react"
import { useRouter } from "next/navigation"

export default function AdminDashboardPage() {
  const router = useRouter()
  const [userRole, setUserRole] = useState<string>("admin")
  const [mounted, setMounted] = useState(false)
  const [refreshing, setRefreshing] = useState(false)

  useEffect(() => {
    setMounted(true)
    // Get user role from localStorage
    if (typeof window !== "undefined") {
      const adminUser = localStorage.getItem("adminUser")
      if (adminUser) {
        try {
          const user = JSON.parse(adminUser)
          setUserRole(user.role || "admin")
        } catch (e) {
          console.error("Error parsing user data:", e)
        }
      }
    }
  }, [])

  const handleRefresh = async () => {
    setRefreshing(true)
    // Force refresh by reloading the page data
    router.refresh()
    // Small delay to show loading state
    setTimeout(() => {
      setRefreshing(false)
      // Reload the page to get fresh data
      window.location.reload()
    }, 500)
  }

  const isInstructor = userRole === "instructor"

  if (!mounted) {
    return (
      <AdminLayout title="لوحة التحكم" subtitle="نظرة عامة على الأداء">
        <div className="flex items-center justify-center py-12">
          <div className="animate-spin rounded-full h-8 w-8 border-b-2 border-purple-600"></div>
        </div>
      </AdminLayout>
    )
  }

  return (
    <AdminLayout title="لوحة التحكم" subtitle={isInstructor ? "نظرة عامة على أداء دوراتك" : "نظرة عامة على أداء المنصة"}>
      <div className="space-y-8">
        {/* Refresh Button */}
        <div className="flex justify-end">
          <Button
            variant="outline"
            size="sm"
            onClick={handleRefresh}
            disabled={refreshing}
            className="gap-2"
          >
            <RefreshCw className={`h-4 w-4 ${refreshing ? 'animate-spin' : ''}`} />
            {refreshing ? 'جاري التحديث...' : 'تحديث البيانات'}
          </Button>
        </div>

        {/* Stats Overview */}
        {isInstructor ? <InstructorOverviewCards /> : <OverviewCards />}
        
        {/* Charts - Hide for instructors for now */}
        {!isInstructor && <DashboardCharts />}
      </div>
    </AdminLayout>
  )
}
