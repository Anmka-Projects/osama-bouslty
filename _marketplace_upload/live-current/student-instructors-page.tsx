"use client"

import { Navbar } from "@/components/navbar"
import { Footer } from "@/components/footer"
import { Card, CardContent } from "@/components/ui/card"
import { Badge } from "@/components/ui/badge"
import { Button } from "@/components/ui/button"
import { Star, Users, PlayCircle, Award, Loader2, GraduationCap, Sparkles, ChevronLeft, BookOpen } from "lucide-react"
import Image from "next/image"
import Link from "next/link"
import { useState, useEffect } from "react"

type Category = { id: string; name?: string; name_ar?: string; children?: Category[]; subcategories?: Category[] }
const categoryChildren = (item?: Category | null) => item?.children || item?.subcategories || []
const categoryLabel = (item?: Category | null) => item?.name_ar || item?.name || ""

export default function InstructorsPage() {
  const [isDark, setIsDark] = useState(false)
  const [mounted, setMounted] = useState(false)
  const [instructors, setInstructors] = useState<any[]>([])
  const [categories, setCategories] = useState<Category[]>([])
  const [categoryId, setCategoryId] = useState("")
  const [subcategoryId, setSubcategoryId] = useState("")
  const [subjectId, setSubjectId] = useState("")
  const [query, setQuery] = useState("")
  const [loading, setLoading] = useState(false)

  useEffect(() => {
    setMounted(true)
    const dark = localStorage.getItem("theme") === "dark" || (!localStorage.getItem("theme") && window.matchMedia("(prefers-color-scheme: dark)").matches)
    setIsDark(dark)
    fetch("/api/categories")
      .then((response) => response.json())
      .then((body) => setCategories(Array.isArray(body?.data) ? body.data : body?.data?.categories || []))
      .catch(() => setCategories([]))
  }, [])

  useEffect(() => {
    if (!mounted) return
    if (isDark) { document.documentElement.classList.add("dark"); localStorage.setItem("theme", "dark") }
    else { document.documentElement.classList.remove("dark"); localStorage.setItem("theme", "light") }
  }, [isDark, mounted])

  useEffect(() => {
    if (!mounted) return
    const timer = window.setTimeout(fetchInstructors, 250)
    return () => window.clearTimeout(timer)
  }, [mounted, categoryId, subcategoryId, subjectId, query])

  const fetchInstructors = async () => {
    try {
      setLoading(true)
      const params = new URLSearchParams({ per_page: "40" })
      if (categoryId) params.set("category_id", categoryId)
      if (subcategoryId) params.set("subcategory_id", subcategoryId)
      if (subjectId) params.set("subject_id", subjectId)
      if (query.trim()) params.set("q", query.trim())
      const response = await fetch(`/api/trainers?${params.toString()}`)
      const body = await response.json()
      const teachersArray = body?.data?.trainers || []
      setInstructors(teachersArray.map((t: any) => ({
        id: t.id,
        name: t.display_name || t.name,
        title: t.headline || "مدرس",
        bio: t.bio,
        avatar: t.avatar_url,
        studentsCount: t.students_count || 0,
        rating: Number(t.rating_average) || 0,
        reviewsCount: t.rating_count || 0,
        hours: t.hours_count || 0,
        price: t.starting_price,
        currency: "USD",
        badge: t.badge_label,
      })))
    } catch (error) {
      console.error("Error fetching instructors:", error)
    } finally {
      setLoading(false)
    }
  }

  const selectedCategory = categories.find((item) => item.id === categoryId)
  const subcategories = categoryChildren(selectedCategory)
  const selectedSubcategory = subcategories.find((item) => item.id === subcategoryId)
  const subjects = categoryChildren(selectedSubcategory)

  if (!mounted) return null

  return (
    <main className="min-h-screen bg-background text-foreground">
      <Navbar isDark={isDark} setIsDark={setIsDark} />

      {/* Hero Section */}
      <section className="py-20 bg-gradient-to-br from-primary/5 via-secondary/5 to-transparent dark:from-primary/10 dark:via-secondary/10 relative overflow-hidden">
        <div className="absolute top-0 right-0 w-96 h-96 bg-primary/10 blur-[120px] rounded-full" />
        <div className="absolute bottom-0 left-0 w-96 h-96 bg-secondary/10 blur-[120px] rounded-full" />
        
        <div className="container mx-auto px-4 text-center space-y-6 relative z-10">
          <Badge className="bg-secondary/20 text-secondary border-none font-bold px-4 py-2 rounded-full w-fit mx-auto">
            <Sparkles className="h-4 w-4 ml-2" />
            المدربون
          </Badge>
          <h1 className="text-4xl md:text-5xl lg:text-6xl font-black">
            تعلم من <span className="text-primary">أفضل الخبراء</span>
          </h1>
          <p className="text-lg text-muted-foreground max-w-3xl mx-auto leading-relaxed">
            مدربونا هم نخبة من المتخصصين الذين يمتلكون خبرة عملية عميقة وشغفاً حقيقياً بمشاركة معرفتهم مع المجتمع العربي.
          </p>
        </div>
      </section>

      <section className="py-20">
        <div className="container mx-auto px-4">
          <div className="mx-auto mb-10 max-w-5xl rounded-3xl border bg-card p-5 shadow-sm">
            <div className="mb-4">
              <h2 className="text-xl font-black">ابحث عن المدرس المناسب</h2>
              <p className="mt-1 text-sm text-muted-foreground">ابحث بالاسم، أو اختار التصنيف والتخصص والمادة.</p>
            </div>
            <input className="mb-3 w-full rounded-xl border bg-background px-4 py-3" value={query} onChange={(event) => setQuery(event.target.value)} placeholder="اكتب اسم المدرس" />
            <div className="grid gap-3 md:grid-cols-3">
              <select className="rounded-xl border bg-background px-3 py-3" value={categoryId} onChange={(event) => { setCategoryId(event.target.value); setSubcategoryId(""); setSubjectId("") }}><option value="">كل التصنيفات</option>{categories.map((item) => <option key={item.id} value={item.id}>{categoryLabel(item)}</option>)}</select>
              <select className="rounded-xl border bg-background px-3 py-3" value={subcategoryId} disabled={!categoryId || !subcategories.length} onChange={(event) => { setSubcategoryId(event.target.value); setSubjectId("") }}><option value="">كل التخصصات الفرعية</option>{subcategories.map((item) => <option key={item.id} value={item.id}>{categoryLabel(item)}</option>)}</select>
              <select className="rounded-xl border bg-background px-3 py-3" value={subjectId} disabled={!subcategoryId || !subjects.length} onChange={(event) => setSubjectId(event.target.value)}><option value="">كل المواد</option>{subjects.map((item) => <option key={item.id} value={item.id}>{categoryLabel(item)}</option>)}</select>
            </div>
            {(categoryId || subcategoryId || subjectId || query) ? <div className="mt-3 flex justify-end"><Button variant="outline" onClick={() => { setCategoryId(""); setSubcategoryId(""); setSubjectId(""); setQuery("") }}>مسح البحث والفلاتر</Button></div> : null}
          </div>

          {!categoryId && categories.length ? (
            <div className="mx-auto max-w-6xl">
              <div className="mb-8 text-center">
                <h2 className="text-3xl font-black">اختار التصنيف</h2>
                <p className="mt-2 text-muted-foreground">اختار المرحلة الأول، وبعدها الصف والمادة.</p>
              </div>
              <div className="grid gap-5 sm:grid-cols-2 lg:grid-cols-4">
                {categories.map((category) => (
                  <button type="button" key={category.id} onClick={() => { setCategoryId(category.id); setSubcategoryId(""); setSubjectId("") }} className="group flex min-h-48 flex-col items-center justify-center rounded-3xl border bg-card p-6 text-center shadow-sm transition hover:-translate-y-1 hover:border-primary hover:shadow-xl">
                    <span className="mb-4 flex h-16 w-16 items-center justify-center rounded-2xl bg-primary/10 text-primary group-hover:bg-primary group-hover:text-white"><BookOpen className="h-8 w-8" /></span>
                    <strong className="text-xl">{categoryLabel(category)}</strong>
                    <span className="mt-3 flex items-center gap-1 text-sm text-muted-foreground">عرض المدرسين <ChevronLeft className="h-4 w-4" /></span>
                  </button>
                ))}
              </div>
            </div>
          ) : null}
          <div className={categoryId ? "" : "mt-12"}>
          {loading ? (
            <div className="flex items-center justify-center py-20">
              <div className="text-center space-y-4">
                <Loader2 className="h-12 w-12 animate-spin text-primary mx-auto" />
                <p className="text-muted-foreground">جاري تحميل المدربين...</p>
              </div>
            </div>
          ) : instructors.length > 0 ? (
            <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 xl:grid-cols-4 gap-8">
              {instructors.map((instructor) => (
                <Card key={instructor.id} className="group border border-border hover:border-primary/30 shadow-sm hover:shadow-2xl transition-all duration-500 rounded-3xl overflow-hidden bg-card dark:bg-card/80 hover:translate-y-[-8px]">
                  {/* Profile Image */}
                  <div className="relative aspect-[4/3] bg-gradient-to-br from-primary/10 to-secondary/10 overflow-hidden">
                    {instructor.avatar ? (
                      <Image 
                        src={instructor.avatar.startsWith('http') ? instructor.avatar : instructor.avatar} 
                        alt={instructor.name} 
                        fill 
                        className="object-cover group-hover:scale-105 transition-transform duration-500" 
                      />
                    ) : (
                      <div className="w-full h-full flex items-center justify-center">
                        <div className="h-32 w-32 rounded-full bg-gradient-to-br from-primary to-secondary flex items-center justify-center shadow-2xl">
                          <span className="text-5xl font-bold text-white">{instructor.name.charAt(0)}</span>
                        </div>
                      </div>
                    )}
                    
                    {/* Overlay gradient */}
                    <div className="absolute inset-0 bg-gradient-to-t from-black/60 via-transparent to-transparent" />
                    
                    {/* Expert Badge */}
                    {instructor.badge ? (
                    <div className="absolute top-4 right-4">
                      <Badge className="bg-gradient-to-r from-amber-500 to-orange-500 text-white border-none font-bold shadow-lg">
                        <Award className="h-3 w-3 ml-1" />
                        {instructor.badge}
                      </Badge>
                    </div>
                    ) : null}
                    
                    {/* Rating Badge */}
                    {instructor.rating !== undefined && instructor.rating > 0 && (
                      <div className="absolute top-4 left-4">
                        <div className="bg-white/90 dark:bg-black/70 backdrop-blur-sm rounded-full px-3 py-1 flex items-center gap-1 shadow-lg">
                          <Star className="h-3 w-3 fill-yellow-400 text-yellow-400" />
                          <span className="font-bold text-sm">{instructor.rating.toFixed(1)}</span>
                    </div>
                  </div>
                    )}

                    {/* Name overlay on image */}
                    <div className="absolute bottom-0 left-0 right-0 p-4 text-white text-right">
                      <h3 className="text-xl font-bold drop-shadow-lg">{instructor.name}</h3>
                      <p className="text-sm text-white/80 font-medium">{instructor.title || 'مدرب خبير'}</p>
                    </div>
                  </div>
                  
                  <CardContent className="p-6 space-y-5 text-right">
                    {/* Bio */}
                    {instructor.bio && (
                      <p className="text-sm text-muted-foreground line-clamp-2 leading-relaxed">
                        {instructor.bio}
                      </p>
                    )}

                    {/* Stats */}
                    <div className="grid grid-cols-3 gap-3 py-4 border-t border-b border-border/50">
                      <div className="text-center space-y-1">
                        <div className="h-10 w-10 rounded-xl bg-yellow-50 dark:bg-yellow-900/20 flex items-center justify-center mx-auto">
                          <Star className="h-5 w-5 text-yellow-500" />
                        </div>
                        <p className="text-lg font-bold">{instructor.rating?.toFixed(1) || '0.0'}</p>
                        <p className="text-[10px] text-muted-foreground">التقييم</p>
                      </div>
                      <div className="text-center space-y-1">
                        <div className="h-10 w-10 rounded-xl bg-primary/10 flex items-center justify-center mx-auto">
                          <Users className="h-5 w-5 text-primary" />
                        </div>
                        <p className="text-lg font-bold">{instructor.studentsCount?.toLocaleString() || 0}</p>
                        <p className="text-[10px] text-muted-foreground">طالب</p>
                      </div>
                      <div className="text-center space-y-1">
                        <div className="h-10 w-10 rounded-xl bg-secondary/10 flex items-center justify-center mx-auto">
                          <BookOpen className="h-5 w-5 text-secondary" />
                        </div>
                        <p className="text-lg font-bold">{instructor.hours || 0}</p>
                        <p className="text-[10px] text-muted-foreground">ساعة</p>
                      </div>
                    </div>
                    
                    {instructor.price ? (
                      <p className="text-sm font-black text-primary">{instructor.price} USD / الساعة</p>
                    ) : null}
                    {/* CTA Button */}
                    <Link href={`/instructors/${instructor.id}`} className="block">
                      <Button className="w-full rounded-xl h-11 font-bold shadow-md group-hover:shadow-lg group-hover:bg-primary/90 transition-all">
                        <ChevronLeft className="h-4 w-4 mr-2 group-hover:-translate-x-1 transition-transform" />
                        احجز جلسة
                      </Button>
                    </Link>
                  </CardContent>
                </Card>
              ))}
            </div>
          ) : (
            <div className="text-center py-20">
              <GraduationCap className="h-16 w-16 mx-auto text-muted-foreground/50 mb-4" />
              <p className="text-muted-foreground text-lg">لا يوجد مدربين حالياً</p>
            </div>
          )}
          </div>
        </div>
      </section>

      <Footer />
    </main>
  )
}
