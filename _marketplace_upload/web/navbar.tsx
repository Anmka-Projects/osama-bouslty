"use client"

import Link from "next/link"
import { Button } from "@/components/ui/button"
import { BookOpen, Menu, Moon, Sun } from "lucide-react"
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet"
import { BRAND_NAME } from "@/lib/branding"

export function Navbar({ isDark, setIsDark }: { isDark: boolean; setIsDark: (value: boolean) => void }) {
  return (
    <header className="sticky top-0 z-50 w-full glass-morphism border-b border-white/40 dark:border-white/10">
      <div className="container mx-auto flex h-20 items-center justify-between px-4">
        {/* Logo */}
        <div className="flex items-center gap-2">
          <Link href="/" className="flex items-center gap-3 group">
            <div className="flex h-10 w-10 items-center justify-center rounded-xl bg-gradient-to-br from-primary to-secondary text-white group-hover:scale-110 transition-transform shadow-lg">
              <BookOpen className="h-6 w-6" />
            </div>
            <span className="hidden sm:block text-2xl font-black tracking-tighter text-foreground group-hover:text-primary transition-colors">
              {BRAND_NAME}
            </span>
          </Link>
        </div>

        {/* Desktop Nav */}
        <nav className="hidden lg:flex items-center gap-8">
          <Link href="/courses" className="text-sm font-bold hover:text-primary transition-colors relative group">
            الدورات
            <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-primary group-hover:w-full transition-all" />
          </Link>
          <Link href="/instructors" className="text-sm font-bold hover:text-primary transition-colors relative group">
            المدربون
            <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-primary group-hover:w-full transition-all" />
          </Link>
          <Link href="/about" className="text-sm font-bold hover:text-primary transition-colors relative group">
            عن المنصة
            <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-primary group-hover:w-full transition-all" />
          </Link>
          <Link href="/contact" className="text-sm font-bold hover:text-primary transition-colors relative group">
            اتصل بنا
            <span className="absolute bottom-0 left-0 w-0 h-0.5 bg-primary group-hover:w-full transition-all" />
          </Link>
        </nav>

        {/* Right Actions */}
        <div className="flex items-center gap-4">
          <Button
            variant="ghost"
            size="icon"
            onClick={() => setIsDark(!isDark)}
            className="rounded-full hover:bg-primary/10 transition-colors"
          >
            {isDark ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
          </Button>

          <Link href="/login" className="hidden sm:block">
            <Button variant="ghost" className="text-sm font-bold">
              دخول
            </Button>
          </Link>
          <Link href="/register">
            <Button className="rounded-full px-6 h-10 text-sm font-bold shadow-lg shadow-primary/20 hover:shadow-xl transition-all">
              ابدأ الآن
            </Button>
          </Link>

          {/* Mobile Menu */}
          <Sheet>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon" className="lg:hidden">
                <Menu className="h-6 w-6" />
              </Button>
            </SheetTrigger>
            <SheetContent side="right" className="w-[300px] sm:w-[400px] text-right">
              <nav className="flex flex-col gap-6 mt-8">
                <Link href="/courses" className="text-lg font-bold hover:text-primary transition-colors">
                  الدورات التدريبية
                </Link>
                <Link href="/instructors" className="text-lg font-bold hover:text-primary transition-colors">
                  المدربون
                </Link>
                <Link href="/about" className="text-lg font-bold hover:text-primary transition-colors">
                  عن المنصة
                </Link>
                <Link href="/contact" className="text-lg font-bold hover:text-primary transition-colors">
                  اتصل بنا
                </Link>
                <Link href="/faq" className="text-lg font-bold hover:text-primary transition-colors">
                  الأسئلة الشائعة
                </Link>
                <div className="pt-6 border-t space-y-4">
                  <Link href="/login" className="block">
                    <Button variant="outline" className="w-full rounded-xl bg-transparent border-2">
                      تسجيل الدخول
                    </Button>
                  </Link>
                  <Link href="/register" className="block">
                    <Button className="w-full rounded-xl h-12">ابدأ التعلم الآن</Button>
                  </Link>
                </div>
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  )
}
