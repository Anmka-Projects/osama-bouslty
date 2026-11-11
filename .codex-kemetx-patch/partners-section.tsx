"use client"

import { motion } from "framer-motion"
import { Handshake } from "lucide-react"
import { Badge } from "@/components/ui/badge"
import { useI18n } from "@/lib/i18n"
import { useThemeConfigOptional } from "@/components/providers/ThemeConfigProvider"
import { sectionSurfaceStyle } from "@/lib/section-surface-style"
import { parsePartnersGrid, partnerResolvedColor, type BilingualPartner } from "@/lib/site-content-grids"

function displayPartner(p: BilingualPartner, isAr: boolean) {
  return {
    name: isAr ? (p.name_ar || p.name_en) : (p.name_en || p.name_ar),
    subtitle: isAr ? (p.subtitle_ar || p.subtitle_en) : (p.subtitle_en || p.subtitle_ar),
    initials: p.initials || "•",
    color: p.color,
  }
}

function partnerAccentStyles(color: string): { backgroundColor: string } {
  if (color.startsWith("var(")) {
    return { backgroundColor: `color-mix(in srgb, ${color} 14%, transparent)` }
  }
  return { backgroundColor: `${color}10` }
}

export default function PartnersSection() {
  const { locale } = useI18n()
  const isAr = locale === "ar"
  const themeCtx = useThemeConfigOptional()
  const sc = themeCtx?.config?.siteContent

  const partners = parsePartnersGrid(sc?.partners_grid_json).filter(
    (p) => Boolean((p.name_ar || p.name_en || "").trim())
  )

  return (
    <section
      className="relative py-20 bg-[var(--color-body-bg)] overflow-hidden"
      style={sectionSurfaceStyle(sc, "partners")}
    >
      <div className="pointer-events-none absolute inset-0">
        <div
          className="absolute inset-0 opacity-[0.02]"
          style={{
            backgroundImage: `radial-gradient(circle at 1px 1px, var(--color-primary) 0.5px, transparent 0)`,
            backgroundSize: "40px 40px",
          }}
        />
      </div>

      <div className="container relative mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-50px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-14"
        >
          <Badge className="mb-4 border-medex-red/20 bg-red-50 text-medex-red hover:bg-red-50 px-4 py-1.5 text-sm font-semibold">
            <Handshake className="w-4 h-4 me-1.5" />
            {isAr ? (sc?.partners_title || "شركاؤنا") : (sc?.partners_title_en || "Our Partners")}
          </Badge>
          <h2 className="text-3xl sm:text-4xl font-bold text-body-theme mb-4">
            {isAr
              ? (sc?.partners_section_headline || "شركاء وبرامج نفتخر بها")
              : (sc?.partners_section_headline_en || "Partners & programmes we highlight")}
          </h2>
          <p className="text-body-theme-muted max-w-xl mx-auto">
            {isAr
              ? (sc?.partners_section_body || "جهات ومسارات تدعم رحلتك التعليمية في تخصصك.")
              : (sc?.partners_section_body_en || "Organisations and paths that support your learning in your field.")}
          </p>
        </motion.div>

        {partners.length === 0 ? (
          <p className="text-center text-sm text-body-theme-muted py-6">
            {isAr
              ? "شغّل توليد المحتوى بالذكاء الاصطناعي لملء قسم الشركاء حسب تخصص منصتك."
              : "Run AI content generation to fill this section for your niche."}
          </p>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-5 gap-4 sm:gap-6 max-w-5xl mx-auto">
            {partners.map((partner, i) => {
              const d = displayPartner(partner, isAr)
              const color = partnerResolvedColor(d.color, i)
              return (
                <motion.div
                  key={`${d.name}-${i}`}
                  initial={{ opacity: 0, y: 20, scale: 0.95 }}
                  whileInView={{ opacity: 1, y: 0, scale: 1 }}
                  viewport={{ once: true, margin: "-30px" }}
                  transition={{ duration: 0.5, delay: i * 0.08 }}
                  whileHover={{ y: -6, scale: 1.03 }}
                  className="group relative flex flex-col items-center rounded-2xl border border-gray-200/60 bg-white p-6 sm:p-8 shadow-sm transition-all duration-300 hover:shadow-xl hover:border-medex-red/20"
                >
                  <div
                    className="flex h-20 w-20 items-center justify-center rounded-2xl mb-5 transition-transform duration-300 group-hover:scale-110"
                    style={partnerAccentStyles(color)}
                  >
                    <span className="text-2xl font-black tracking-tight" style={{ color }}>
                      {d.initials}
                    </span>
                  </div>
                  <h3 className="text-base font-bold text-medex-dark text-center mb-1 group-hover:text-medex-red transition-colors">
                    {d.name}
                  </h3>
                  <p className="text-xs text-gray-400 text-center leading-relaxed">{d.subtitle}</p>
                  <div
                    className="absolute bottom-0 left-1/2 -translate-x-1/2 h-1 w-0 rounded-t-full transition-all duration-300 group-hover:w-12"
                    style={{ backgroundColor: color }}
                  />
                </motion.div>
              )
            })}
          </div>
        )}
      </div>
    </section>
  )
}
