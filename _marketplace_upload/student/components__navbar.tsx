"use client"

import Link from "next/link"
import { Button } from "@/components/ui/button"
import { Menu, Moon, Sun, User, LogOut, Bell, Calendar } from "lucide-react"
import { Sheet, SheetContent, SheetTrigger } from "@/components/ui/sheet"
import { DropdownMenu, DropdownMenuContent, DropdownMenuItem, DropdownMenuSeparator, DropdownMenuTrigger } from "@/components/ui/dropdown-menu"
import { Avatar, AvatarFallback, AvatarImage } from "@/components/ui/avatar"
import { useState, useEffect } from "react"
import { useRouter } from "next/navigation"
import { isAuthenticated, getStoredUser, clearAuthTokens, type User as UserType } from "@/lib/api"

export function Navbar({ isDark, setIsDark }: { isDark?: boolean; setIsDark?: (value: boolean) => void }) {
  const router = useRouter()
  const [user, setUser] = useState<UserType | null>(null)
  const [localDark, setLocalDark] = useState(false)

  useEffect(() => {
    // Initialize theme state from what the layout script already applied
    setLocalDark(document.documentElement.classList.contains("dark"))
    if (isAuthenticated()) {
      const storedUser = getStoredUser()
      if (storedUser) setUser(storedUser)
    }
  }, [])

  const dark = isDark ?? localDark
  const toggleDark = setIsDark ?? setLocalDark

  const handleLogout = () => {
    clearAuthTokens()
    setUser(null)
    router.push('/login')
  }

  return (
    <header className="sticky top-0 z-50 w-full glass-morphism border-b border-white/40 dark:border-white/10">
      <div className="container mx-auto flex h-20 items-center justify-between px-4">
        {/* Logo */}
        <div className="flex items-center gap-2">
          <Link href="/" className="flex items-center gap-3 group">
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/student-public/brand/logo-ar.png"
              alt="Bouslty | بوصلتي"
              className="h-11 w-auto object-contain transition-transform group-hover:scale-105 dark:hidden"
            />
            {/* eslint-disable-next-line @next/next/no-img-element */}
            <img
              src="/student-public/brand/logo-ar-reverse.png"
              alt="Bouslty | بوصلتي"
              className="h-11 w-auto object-contain transition-transform group-hover:scale-105 hidden dark:block"
            />
          </Link>
        </div>

        {/* Desktop Nav */}
        <nav className="hidden lg:flex items-center gap-8">
          <Link href="/instructors" className="text-sm font-bold hover:text-primary transition-colors relative group">
            احجز جلسة
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
            onClick={() => toggleDark(!dark)}
            className="rounded-full hover:bg-primary/10 transition-colors"
          >
            {dark ? <Sun className="h-5 w-5" /> : <Moon className="h-5 w-5" />}
          </Button>

          {user ? (
            <>
              <Link href="/dashboard/notifications" className="hidden sm:flex">
                <Button variant="ghost" size="icon" className="rounded-full hover:bg-primary/10"><Bell className="h-5 w-5" /></Button>
              </Link>
              <DropdownMenu>
                <DropdownMenuTrigger asChild>
                  <Button variant="ghost" className="relative h-10 w-10 rounded-full">
                    <Avatar className="h-10 w-10">
                      <AvatarImage src={user.avatar} alt={user.name} />
                      <AvatarFallback className="bg-primary text-white">{user.name?.charAt(0) || 'U'}</AvatarFallback>
                    </Avatar>
                  </Button>
                </DropdownMenuTrigger>
                <DropdownMenuContent className="w-56" align="end" forceMount>
                  <div className="flex items-center justify-start gap-2 p-2">
                    <div className="flex flex-col space-y-1 leading-none text-right w-full">
                      <p className="font-medium">{user.name}</p>
                      <p className="w-full truncate text-sm text-muted-foreground">{user.email}</p>
                    </div>
                  </div>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem asChild><Link href="/dashboard" className="flex items-center gap-2 flex-row-reverse cursor-pointer"><User className="h-4 w-4" />لوحة التحكم</Link></DropdownMenuItem>
                  <DropdownMenuItem asChild><Link href="/dashboard/bookings" className="flex items-center gap-2 flex-row-reverse cursor-pointer"><Calendar className="h-4 w-4" />حجوزات الجلسات</Link></DropdownMenuItem>
                  <DropdownMenuSeparator />
                  <DropdownMenuItem onClick={handleLogout} className="flex items-center gap-2 flex-row-reverse cursor-pointer text-red-600"><LogOut className="h-4 w-4" />تسجيل الخروج</DropdownMenuItem>
                </DropdownMenuContent>
              </DropdownMenu>
            </>
          ) : (
            <>
              <Link href="/login" className="hidden sm:block">
                <Button variant="ghost" className="text-sm font-bold">دخول</Button>
              </Link>
              <Link href="/register">
                <Button className="rounded-full px-6 h-10 text-sm font-bold shadow-lg shadow-primary/20 hover:shadow-xl transition-all">ابدأ الآن</Button>
              </Link>
            </>
          )}

          {/* Mobile Menu */}
          <Sheet>
            <SheetTrigger asChild>
              <Button variant="ghost" size="icon" className="lg:hidden">
                <Menu className="h-6 w-6" />
              </Button>
            </SheetTrigger>
            <SheetContent side="right" className="w-[300px] sm:w-[400px] text-right">
              <nav className="flex flex-col gap-6 mt-8">
                <Link href="/instructors" className="text-lg font-bold hover:text-primary transition-colors">
                  احجز جلسة
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
                {user && (
                  <div className="pt-4 border-t grid grid-cols-2 gap-3">
                    <Link href="/dashboard/bookings" className="text-sm font-bold hover:text-primary transition-colors">حجوزات الجلسات</Link>
                    <Link href="/dashboard/live" className="text-sm font-bold hover:text-primary transition-colors">الجلسات المباشرة</Link>
                    <Link href="/dashboard/chat" className="text-sm font-bold hover:text-primary transition-colors">المحادثات</Link>
                    <Link href="/dashboard/exams" className="text-sm font-bold hover:text-primary transition-colors">اختباراتي</Link>
                    <Link href="/dashboard/certificates" className="text-sm font-bold hover:text-primary transition-colors">شهاداتي</Link>
                    <Link href="/dashboard/wishlist" className="text-sm font-bold hover:text-primary transition-colors">المفضلة</Link>
                    <Link href="/dashboard/qr-code" className="text-sm font-bold hover:text-primary transition-colors">رمز الحضور</Link>
                  </div>
                )}
                <div className="pt-6 border-t space-y-4">
                  {user ? (
                    <>
                      <Link href="/dashboard" className="block">
                        <Button variant="outline" className="w-full rounded-xl bg-transparent border-2">لوحة التحكم</Button>
                      </Link>
                      <Button onClick={handleLogout} variant="destructive" className="w-full rounded-xl h-12">تسجيل الخروج</Button>
                    </>
                  ) : (
                    <>
                      <Link href="/login" className="block">
                        <Button variant="outline" className="w-full rounded-xl bg-transparent border-2">تسجيل الدخول</Button>
                      </Link>
                      <Link href="/register" className="block">
                        <Button className="w-full rounded-xl h-12">ابدأ التعلم الآن</Button>
                      </Link>
                    </>
                  )}
                </div>
              </nav>
            </SheetContent>
          </Sheet>
        </div>
      </div>
    </header>
  )
}
