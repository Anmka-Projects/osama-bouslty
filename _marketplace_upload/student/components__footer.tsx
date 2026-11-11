import Link from "next/link"
import {
  Facebook, Twitter, Instagram, Linkedin, Mail, Phone, MessageCircle,
  GraduationCap, Radio,
} from "lucide-react"
import { Button } from "@/components/ui/button"

const GOOGLE_PLAY_URL = "https://play.google.com/store/apps/details?id=com.pointcourse.courseapp"
const WHATSAPP_URL = "https://wa.me/201019108541"

export function Footer() {
  return (
    <footer dir="rtl" className="relative overflow-hidden bg-gradient-to-b from-[#083B41] to-[#041D20] text-white">
      {/* Decorative glows */}
      <div className="absolute top-0 right-0 w-96 h-96 bg-primary/20 rounded-full blur-[120px] pointer-events-none" />
      <div className="absolute bottom-0 left-0 w-80 h-80 bg-secondary/10 rounded-full blur-[100px] pointer-events-none" />
      <div className="absolute top-0 inset-x-0 h-px bg-gradient-to-l from-transparent via-secondary/50 to-transparent" />

      <div className="relative container mx-auto px-4 pt-16 pb-8">
        <div className="grid grid-cols-1 sm:grid-cols-2 lg:grid-cols-5 gap-10 lg:gap-8 mb-14">
          {/* Brand — rightmost column in RTL */}
          <div className="lg:col-span-2 space-y-5">
            <Link href="/" className="inline-block group">
              {/* eslint-disable-next-line @next/next/no-img-element */}
              <img
                src="/student-public/brand/logo-ar-reverse.png"
                alt="Bouslty | بوصلتي"
                className="h-14 w-auto object-contain transition-transform group-hover:scale-105"
              />
            </Link>
            <p className="text-sm text-white/60 leading-7 max-w-sm">
            منصة بوصلتي — جلسات مباشرة وباقات مع المدرسين، على الويب والموبايل.
            </p>
            <div className="flex items-center gap-2.5">
              {[
                { icon: Facebook, href: "#", label: "Facebook" },
                { icon: Twitter, href: "#", label: "Twitter" },
                { icon: Instagram, href: "#", label: "Instagram" },
                { icon: Linkedin, href: "#", label: "LinkedIn" },
                { icon: MessageCircle, href: WHATSAPP_URL, label: "WhatsApp" },
              ].map(({ icon: Icon, href, label }) => (
                <a
                  key={label}
                  href={href}
                  aria-label={label}
                  target={href.startsWith("http") ? "_blank" : undefined}
                  rel="noopener noreferrer"
                  className="h-10 w-10 rounded-xl bg-white/10 border border-white/15 flex items-center justify-center text-white/70 hover:bg-secondary hover:text-secondary-foreground hover:border-secondary hover:-translate-y-0.5 transition-all"
                >
                  <Icon className="h-4.5 w-4.5" />
                </a>
              ))}
            </div>
          </div>

          {/* Quick links */}
          <div className="space-y-5">
            <h3 className="text-sm font-black tracking-wide text-secondary">روابط سريعة</h3>
            <ul className="space-y-3 text-sm">
              {[
                { label: "الرئيسية", href: "/" },
                { label: "احجز جلسة", href: "/instructors" },
                { label: "المدرسون", href: "/instructors" },
                { label: "عن المنصة", href: "/about" },
                { label: "اتصل بنا", href: "/contact" },
              ].map(({ label, href }) => (
                <li key={label}>
                  <Link href={href} className="text-white/60 hover:text-secondary font-medium transition-colors inline-flex items-center gap-2 group">
                    <span className="h-1 w-1 rounded-full bg-secondary/50 group-hover:bg-secondary transition-colors" />
                    {label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Learning */}
          <div className="space-y-5">
            <h3 className="text-sm font-black tracking-wide text-secondary">رحلة التعلم</h3>
            <ul className="space-y-3 text-sm">
              {[
                { label: "لوحة التحكم", href: "/dashboard", icon: GraduationCap },
                { label: "حجوزات الجلسات", href: "/dashboard/bookings", icon: Radio },
                { label: "المدربون", href: "/instructors", icon: GraduationCap },
              ].map(({ label, href, icon: Icon }) => (
                <li key={label}>
                  <Link href={href} className="text-white/60 hover:text-secondary font-medium transition-colors inline-flex items-center gap-2">
                    <Icon className="h-4 w-4 text-secondary/60" />
                    {label}
                  </Link>
                </li>
              ))}
            </ul>
          </div>

          {/* Contact + app */}
          <div className="space-y-5">
            <h3 className="text-sm font-black tracking-wide text-secondary">تواصل معنا</h3>
            <ul className="space-y-3 text-sm">
              <li>
                <a href={`mailto:support@bouslty.anmka.com`} className="flex items-center gap-3 text-white/60 hover:text-secondary transition-colors">
                  <Mail className="h-4 w-4 text-secondary/60 shrink-0" />
                  <span dir="ltr">support@bouslty.anmka.com</span>
                </a>
              </li>
              <li>
                <a href={WHATSAPP_URL} target="_blank" rel="noopener noreferrer" className="flex items-center gap-3 text-white/60 hover:text-secondary transition-colors">
                  <Phone className="h-4 w-4 text-secondary/60 shrink-0" />
                  <span dir="ltr">+20 101 910 8541</span>
                </a>
              </li>
            </ul>
            <div className="pt-3 space-y-3">
              <p className="text-xs font-bold text-white/50">حمّل التطبيق</p>
              <a href={GOOGLE_PLAY_URL} target="_blank" rel="noopener noreferrer" className="inline-block transition-transform hover:-translate-y-0.5">
                {/* eslint-disable-next-line @next/next/no-img-element */}
                <img src="/landing/google-play-badge.png" alt="Get it on Google Play" className="h-11 w-auto rounded-lg" />
              </a>
            </div>
          </div>
        </div>

        {/* Bottom bar */}
        <div className="pt-6 border-t border-white/10 flex flex-col sm:flex-row items-center justify-between gap-4">
          <p className="text-xs text-white/50 font-medium">
            © {new Date().getFullYear()} منصة بوصلتي — جميع الحقوق محفوظة.
          </p>
          <div className="flex items-center gap-5 text-xs text-white/50">
            <Link href="/privacy" className="hover:text-secondary transition-colors">سياسة الخصوصية</Link>
            <Link href="/terms" className="hover:text-secondary transition-colors">الشروط والأحكام</Link>
            <Link href="/faq" className="hover:text-secondary transition-colors">الأسئلة الشائعة</Link>
          </div>
        </div>
      </div>
    </footer>
  )
}
