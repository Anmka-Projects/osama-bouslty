"use client"

import { m } from "framer-motion"
import Link from "next/link"
import { Phone, Mail, MapPin, Send, Download, MessageCircle } from "lucide-react"
import Image from "next/image"
import { usePlatformBranding } from "@/hooks/use-platform-branding"
import { Button } from "@/components/ui/button"
import { Input } from "@/components/ui/input"
import { useI18n } from "@/lib/i18n"
import { useThemeConfigOptional } from "@/components/providers/ThemeConfigProvider"
import { getCoursesBrowseHref, isTenantPageEnabled } from "@/lib/tenant-theme"
import { isManaraInstituteTenantConfig } from "@/lib/is-manara-institute-tenant"
import { manaraTenantCleanCopy } from "@/lib/manara-i18n-overrides"
import { siteContentLocaleText } from "@/lib/site-content-text"
import { resolveTenantDisplayPhones } from "@/lib/tenant-contact"
import { isGoalsTargetsTenant } from "@/lib/goals-targets"
import { isSpeakoraTenant } from "@/lib/is-speakora-tenant"
import { isPhysicsCodeTenant } from "@/lib/is-physics-code-tenant"
import { isMathapexTenant } from "@/lib/mathapex"
import { isDnesatTenantSkinActive } from "@/lib/is-dne-sat-tenant"
import { SpeakoraFooter } from "@/components/home/speakora/speakora-footer"
import { MathapexFooter } from "@/components/mathapex/mathapex-footer"
import { TmceduFooter } from "@/components/home/tmcedu/tmcedu-footer"
import { DnesatFooter } from "@/components/home/dnesat/dnesat-footer"
import { isTmceduTenant } from "@/lib/tmcedu"
import { isEngFahdmareyTenant } from "@/lib/is-eng-fahdmarey-tenant"
import { LogoPreviewTrigger } from "@/components/brand/logo-preview-trigger"
import { resolveTenantFooterLogoUrl } from "@/lib/tenant-branding"
import { cn } from "@/lib/utils"
import { isSayedMersalTenant } from "@/lib/is-sayed-mersal-tenant"
import {
  isCatalogFeatureEnabled,
  resolveCompanyProfilePdfUrl,
  triggerCatalogDownload,
} from "@/lib/catalog-download"
import { resolveWhatsAppHref } from "@/lib/whatsapp-href"
import { getSocialIcon } from "@/components/icons/social-icons"
import { TenantHighlightedText } from "@/components/tenant/tenant-highlighted-text"
import { motionVariants } from "@/lib/motion-variants"

const fadeUp = motionVariants({
  hidden: { opacity: 0, y: 24 },
  visible: (i: number) => ({
    opacity: 1,
    y: 0,
    transition: { duration: 0.5, delay: i * 0.1, ease: "easeOut" },
  }),
})

export function Footer() {
  const { dir, t, locale } = useI18n()
  const { branding } = usePlatformBranding()
  const isAr = locale === "ar"
  const themeCtx = useThemeConfigOptional()
  const tenantReady = themeCtx?.ready ?? true
  const sc = themeCtx?.config?.siteContent
  const manaraTenant = isManaraInstituteTenantConfig(themeCtx?.config)
  const tenantHost =
    typeof window !== "undefined" ? window.location.host.toLowerCase() : ""
  const tenantBusinessName = (themeCtx?.config?.business_name || "")
    .toLowerCase()
    .trim()
  const isEmbryobloomTenant =
    tenantHost.includes("embryobloom-academy.e.anmka.com") ||
    tenantBusinessName.includes("embryobloom")
  const goalsTargetsTenant = isGoalsTargetsTenant(tenantHost, themeCtx?.config?.business_name, sc?.site_name)
  const speakoraTenant = isSpeakoraTenant(themeCtx?.config, tenantHost)
  const tmceduTenant = isTmceduTenant(tenantHost, themeCtx?.config?.business_name, sc?.site_name)
  const mathapexTenant = isMathapexTenant(tenantHost, themeCtx?.config?.business_name, sc?.site_name)
  const physicsCodeTenant = isPhysicsCodeTenant(tenantHost, themeCtx?.config)
  const dnesatTenant = isDnesatTenantSkinActive(themeCtx?.config, tenantHost)
  const fahdmareyTenant = isEngFahdmareyTenant(themeCtx?.config, tenantHost)
  const sayedMersalUx = isSayedMersalTenant(themeCtx?.config, tenantHost)
  const footerLogoSrc = sayedMersalUx
    ? (themeCtx?.config?.logo_url || branding.logo || "").trim() ||
      resolveTenantFooterLogoUrl(themeCtx?.config) ||
      branding.logo ||
      ""
    : resolveTenantFooterLogoUrl(themeCtx?.config) || branding.logo || ""
  const showBranding = Boolean(footerLogoSrc && branding.platformName)

  if (dnesatTenant) {
    return <DnesatFooter />
  }
  if (speakoraTenant) {
    return <SpeakoraFooter />
  }
  if (tmceduTenant) {
    return <TmceduFooter />
  }
  if (mathapexTenant) {
    return <MathapexFooter />
  }
  const footerHighContrast = sc?.footer_high_contrast === "true"
  const footerMutedText = footerHighContrast ? "text-white/85" : "text-white/40"
  const footerSoftText = footerHighContrast ? "text-white/75" : "text-white/30"
  const footerPoweredText = footerHighContrast ? "text-white/70 hover:text-white" : "text-white/25 hover:text-medex-red"
  const footerHeadingText = footerHighContrast ? "text-white/95" : "text-white/70"
  const footerIconText = footerHighContrast ? "text-white/85" : "text-white/50"
  const tenantSocial = themeCtx?.config?.socialMedia || []
  const showFooterEmail = themeCtx?.config?.generalSettings?.footer_email_visible !== false
  const tenantContact = {
    phone: (themeCtx?.config?.contactPhone || "").trim() || undefined,
    email: showFooterEmail ? (themeCtx?.config?.contactEmail || "").trim() || undefined : undefined,
    whatsapp: (themeCtx?.config?.whatsapp || "").trim() || undefined,
    address: (themeCtx?.config?.address || branding.contactAddress || "").trim() || undefined,
  }
  const displayPhones = resolveTenantDisplayPhones(
    tenantContact.phone,
    sc?.footer_phones_json,
  )
  const whatsappHref = tenantContact.whatsapp ? resolveWhatsAppHref(tenantContact.whatsapp) : ""
  const phoneDigits = (tenantContact.phone || "").replace(/\D/g, "")
  const whatsappDigits = (tenantContact.whatsapp || "").replace(/\D/g, "")
  const showWhatsappInFooter =
    Boolean(tenantContact.whatsapp) &&
    Boolean(whatsappHref) &&
    (!phoneDigits || whatsappDigits !== phoneDigits)

  const coursesPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "courses")
  const storePageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "store")
  const blogPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "blog")
  const recommendationsPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "recommendations")
  const plansPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "plans")
  const aboutPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "about")
  const contactPageEnabled = isTenantPageEnabled(themeCtx?.config?.pageConfig, "contact")
  const coursesFeatureEnabled = themeCtx?.isFeatureEnabled("courses") ?? true
  const certificatesFeatureEnabled = themeCtx?.isFeatureEnabled("certificates") ?? true
  const blogFeatureEnabled = themeCtx?.isFeatureEnabled("blog") ?? true
  const recommendationsFeatureEnabled = themeCtx?.isFeatureEnabled("recommendations") ?? true
  const subscriptionsFeatureEnabled = themeCtx?.isFeatureEnabled("subscriptions") ?? false
  const coursesBrowseHref = getCoursesBrowseHref(themeCtx?.config?.pageConfig)
  const catalogFeatureOn = isCatalogFeatureEnabled(sc)
  const companyProfilePdfUrl = resolveCompanyProfilePdfUrl(sc)
  const showCatalogFooterLink = catalogFeatureOn && Boolean(companyProfilePdfUrl)
  const catalogLinkLabel = isAr ? "الملف التعريفي / الكتالوج" : "Company Profile / Catalog"

  const socialLinks = tenantSocial
    .filter((s) => typeof s.url === "string" && s.url.trim() && !s.url.trim().startsWith("#"))
    .map((s) => ({
      icon: getSocialIcon(s.platform),
      href: s.url.trim(),
      label: s.platform,
    }))

  return (
    <footer
      dir={dir}
      className="relative overflow-hidden pb-24 lg:pb-0"
      style={{
        backgroundColor: "var(--color-footer-bg)",
        color: "var(--color-footer-text, #ffffff)",
      }}
    >
      <div className="absolute top-0 left-1/4 w-[500px] h-[500px] rounded-full blur-[140px] pointer-events-none bg-medex-red/[0.05]" />
      <div className="absolute bottom-0 right-1/4 w-[400px] h-[400px] rounded-full blur-[120px] pointer-events-none bg-white/[0.02]" />

      <div className="relative container mx-auto px-4 sm:px-6 lg:px-8">
        {isEmbryobloomTenant && (
          <m.div
            initial="hidden"
            whileInView="visible"
            viewport={{ once: true, margin: "-50px" }}
            variants={fadeUp}
            custom={0}
            className="pt-10"
          >
            <div className="rounded-2xl border border-white/15 bg-white/[0.04] p-6 sm:p-8 flex flex-col sm:flex-row gap-4 sm:items-center sm:justify-between">
              <div>
                <h3 className="text-lg sm:text-xl font-bold font-display text-white">
                  {isAr ? "ابدأ رحلتك المهنية في علم الأجنة" : "Start Your IVF Career Journey"}
                </h3>
                <p className="text-sm text-white/60 mt-1">
                  {isAr
                    ? "انضم إلى برامجنا المتخصصة وابدأ بخطوة واضحة نحو الاحتراف."
                    : "Join our specialized programs and take a clear next step toward professional practice."}
                </p>
              </div>
              <Button
                asChild
                className="h-11 px-6 rounded-xl bg-medex-red hover:bg-medex-red-dark text-white font-semibold shadow-lg shadow-red-500/20"
              >
                <Link href={coursesBrowseHref}>
                  {isAr ? "استعرض البرامج الآن" : "Explore Programs"}
                </Link>
              </Button>
            </div>
          </m.div>
        )}

        {/* Newsletter */}
        <m.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true, margin: "-50px" }}
          variants={fadeUp}
          custom={0}
          className="py-12 lg:py-16 border-b border-white/10"
        >
          <div className="max-w-2xl mx-auto text-center">
            <h3 className="text-xl sm:text-2xl font-bold mb-2 font-display">
              {isAr ? (sc?.newsletter_title || `ابق على اطلاع مع ${branding.platformName}`) : (sc?.newsletter_title_en || `Stay Updated with ${branding.platformName}`)}
            </h3>
            <p className={cn(footerMutedText, "text-sm sm:text-base mb-6")}>
              {isAr ? (sc?.newsletter_subtitle || "اشترك لتحصل على أحدث الدورات والعروض الحصرية") : (sc?.newsletter_subtitle_en || "Subscribe for the latest courses and exclusive offers")}
            </p>
            <div className="flex gap-2 max-w-md mx-auto">
              <Input
                type="email"
                placeholder={isAr ? "أدخل بريدك الإلكتروني" : "Enter your email"}
                className={cn(
                  "flex-1 h-11",
                  footerHighContrast
                    ? "bg-white/95 border-white/80 text-slate-900 placeholder:text-slate-500 focus-visible:ring-white/40 focus-visible:border-white"
                    : "bg-white/10 border-white/15 text-white placeholder:text-white/30 focus-visible:ring-medex-red/30 focus-visible:border-medex-red/40"
                )}
                dir={dir}
              />
              <Button className="bg-medex-red text-white shadow-lg shadow-red-500/20 h-11 px-5 shrink-0 hover:bg-medex-red-dark transition-colors font-semibold">
                <Send className="w-4 h-4 me-2" />
                {isAr ? "اشترك" : "Subscribe"}
              </Button>
            </div>
          </div>
        </m.div>

        {/* Main Grid */}
        <div className="py-12 lg:py-16">
          <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-12 gap-10 lg:gap-8">
            {/* Brand */}
            <m.div
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
              variants={fadeUp}
              custom={0}
              className="lg:col-span-4"
            >
              <Link
                href="/"
                className={`inline-flex items-center ${isEmbryobloomTenant ? "gap-3" : "gap-2.5"} group mb-5`}
              >
                <>
                  <LogoPreviewTrigger enabled={fahdmareyTenant} src={footerLogoSrc} alt={branding.platformName}>
                    <div
                      className={`relative ${isEmbryobloomTenant ? "w-14 h-14" : "w-10 h-10"} overflow-hidden rounded-xl shadow-lg transition-shadow group-hover:shadow-xl ring-1 ring-white/15`}
                    >
                      {showBranding ? (
                        <Image
                          src={footerLogoSrc}
                          alt={branding.platformName}
                          fill
                          className="object-contain"
                          sizes={isEmbryobloomTenant ? "56px" : "40px"}
                        />
                      ) : (
                        <div className="h-full w-full animate-pulse bg-white/10" />
                      )}
                    </div>
                  </LogoPreviewTrigger>
                  <div>
                    <span className={`${isEmbryobloomTenant ? "text-xl" : "text-lg"} font-bold tracking-tight text-white font-medex block`}>
                      {showBranding ? branding.platformName : "..."}
                    </span>
                    {(() => {
                      const logoSubtitle = siteContentLocaleText(sc, locale, "navbar_logo_subtitle", "navbar_logo_subtitle_en")
                      return logoSubtitle ? (
                        <span className="text-[10px] font-medium text-medex-red uppercase tracking-[0.15em]">
                          <TenantHighlightedText>{logoSubtitle}</TenantHighlightedText>
                        </span>
                      ) : null
                    })()}
                  </div>
                </>
              </Link>
              {(() => {
                const footerDescription = manaraTenant
                  ? manaraTenantCleanCopy(
                      siteContentLocaleText(sc, locale, "footer_description", "footer_description_en"),
                      "",
                      { tenantCfg: themeCtx?.config }
                    )
                  : siteContentLocaleText(sc, locale, "footer_description", "footer_description_en")
                return footerDescription ? (
                  <p className={cn(footerMutedText, "text-sm leading-relaxed max-w-sm mb-6")}>
                    <TenantHighlightedText>{footerDescription}</TenantHighlightedText>
                  </p>
                ) : null
              })()}
              {socialLinks.length > 0 && (
                <div className="flex gap-2.5 flex-wrap">
                  {socialLinks.map((social) => (
                    <a
                      key={`${social.label}-${social.href}`}
                      href={social.href}
                      target="_blank"
                      rel="noopener noreferrer"
                      aria-label={social.label}
                      className={cn("w-9 h-9 rounded-xl bg-white/10 flex items-center justify-center hover:bg-medex-red hover:text-white transition-all duration-200", footerIconText)}
                    >
                      <social.icon className="w-4 h-4" />
                    </a>
                  ))}
                </div>
              )}
            </m.div>

            <>
              {/* Quick Links */}
              <m.div
                  initial="hidden"
                  whileInView="visible"
                  viewport={{ once: true }}
                  variants={fadeUp}
                  custom={1}
                  className="lg:col-span-2"
                >
                  <h4 className={cn("text-sm font-semibold uppercase tracking-wider mb-4", footerHeadingText)}>{isAr ? "روابط سريعة" : "Quick Links"}</h4>
                  <ul className="space-y-3">
                    {[
                      { label: isAr ? "الرئيسية" : "Home", href: "/" },
                      ...(storePageEnabled && !goalsTargetsTenant ? [{ label: isAr ? "المنتجات" : "Products", href: "/store" }] : []),
                      ...(coursesPageEnabled && coursesFeatureEnabled
                        ? [{ label: isAr ? "الدورات" : "Courses", href: "/courses" }]
                        : [{ label: isAr ? "التصنيفات" : "Categories", href: "/categories" }]),
                      ...(goalsTargetsTenant
                        ? [
                            ...(recommendationsPageEnabled && recommendationsFeatureEnabled
                              ? [{ label: isAr ? "التوصيات" : "Recommendations", href: "/recommendations" }]
                              : []),
                          ]
                        : []),
                      ...(aboutPageEnabled ? [{ label: isAr ? "من نحن" : "About Us", href: "/about" }] : []),
                      ...(!goalsTargetsTenant && plansPageEnabled && subscriptionsFeatureEnabled
                        ? [{ label: isAr ? "الاشتراكات" : "Plans", href: "/plans" }]
                        : []),
                      ...(contactPageEnabled ? [{ label: isAr ? "تواصل معنا" : "Contact", href: "/contact" }] : []),
                      ...(certificatesFeatureEnabled
                        ? [{ label: isAr ? "التحقق من الشهادة" : "Verify certificate", href: "/verify-certificate" }]
                        : []),
                      ...(physicsCodeTenant
                        ? [
                            { label: isAr ? "سياسة الخصوصية" : "Privacy Policy", href: "/privacy" },
                            { label: isAr ? "الشروط والأحكام" : "Terms & Conditions", href: "/terms" },
                          ]
                        : []),
                    ].map((link) => (
                      <li key={link.href}>
                        <Link href={link.href} className={cn("text-sm hover:text-white transition-colors duration-200", footerMutedText)}>
                          {link.label}
                        </Link>
                      </li>
                    ))}
                    {showCatalogFooterLink && (
                      <li>
                        <button
                          type="button"
                          onClick={() => triggerCatalogDownload(companyProfilePdfUrl)}
                          className={cn(
                            "inline-flex items-center gap-2 text-sm hover:text-white transition-colors duration-200 text-start",
                            footerMutedText
                          )}
                        >
                          <Download className="w-3.5 h-3.5 shrink-0 text-medex-red" />
                          {catalogLinkLabel}
                        </button>
                      </li>
                    )}
                  </ul>
                </m.div>

                <m.div
                  initial="hidden"
                  whileInView="visible"
                  viewport={{ once: true }}
                  variants={fadeUp}
                  custom={2}
                  className="lg:col-span-3"
                >
                  <h4 className={cn("text-sm font-semibold uppercase tracking-wider mb-4", footerHeadingText)}>{isAr ? "عن المنصة" : "About Platform"}</h4>
                  <p className={cn("text-sm leading-relaxed", footerMutedText)}>
                    <TenantHighlightedText>
                      {manaraTenant
                        ? manaraTenantCleanCopy(
                            isAr ? sc?.about_description : (sc?.about_description_en || sc?.about_description),
                            branding.platformName,
                            { tenantCfg: themeCtx?.config }
                          )
                        : isAr
                          ? (sc?.about_description || branding.platformName)
                          : (sc?.about_description_en || branding.platformName)}
                    </TenantHighlightedText>
                  </p>
                </m.div>
            </>

            {/* Contact */}
            <m.div
              initial="hidden"
              whileInView="visible"
              viewport={{ once: true }}
              variants={fadeUp}
              custom={3}
              className="lg:col-span-3"
            >
              <h4 className={cn("text-sm font-semibold uppercase tracking-wider mb-4", footerHeadingText)}>{isAr ? (sc?.contact_title || "تواصل معنا") : (sc?.contact_title_en || "Contact Us")}</h4>
              <div className="space-y-4">
                {displayPhones.map((phone) => (
                  <a
                    key={phone}
                    href={`tel:${phone.replace(/\s/g, "")}`}
                    className={cn("flex items-start gap-3 text-sm hover:text-white transition-colors group", footerMutedText)}
                  >
                    <Phone className="w-4 h-4 mt-0.5 text-medex-red shrink-0" />
                    <span dir="ltr">{phone}</span>
                  </a>
                ))}
                {showWhatsappInFooter && (
                  <a
                    href={whatsappHref}
                    target="_blank"
                    rel="noopener noreferrer"
                    className={cn("flex items-start gap-3 text-sm hover:text-white transition-colors group", footerMutedText)}
                  >
                    <MessageCircle className="w-4 h-4 mt-0.5 text-medex-red shrink-0" />
                    <span dir="ltr">{tenantContact.whatsapp}</span>
                  </a>
                )}
                {tenantContact.email && (
                  <a href={`mailto:${tenantContact.email}`} className={cn("flex items-start gap-3 text-sm hover:text-white transition-colors group", footerMutedText)}>
                    <Mail className="w-4 h-4 mt-0.5 text-medex-red shrink-0" />
                    <span>{tenantContact.email}</span>
                  </a>
                )}
                {tenantContact.address && (
                  <div className={cn("flex items-start gap-3 text-sm", footerMutedText)}>
                    <MapPin className="w-4 h-4 mt-0.5 text-medex-red shrink-0" />
                    <span>{tenantContact.address}</span>
                  </div>
                )}
                {!displayPhones.length && !showWhatsappInFooter && !tenantContact.email && !tenantContact.address && !tenantReady && (
                  <div className={cn("text-sm", footerSoftText)}>...</div>
                )}
              </div>
            </m.div>
          </div>
        </div>

        {/* Bottom */}
        <m.div
          initial="hidden"
          whileInView="visible"
          viewport={{ once: true }}
          variants={fadeUp}
          custom={0}
          className="py-6 border-t border-white/10"
        >
          <div className="flex flex-col items-center justify-center gap-2">
            <p className={cn("text-xs", footerSoftText)}>
              &copy; {new Date().getFullYear()} {showBranding ? branding.platformName : "..."}. {isAr ? (sc?.copyright_text || "جميع الحقوق محفوظة") : (sc?.copyright_text_en || "All rights reserved")}.
            </p>
            <a href="https://anmka.com" target="_blank" rel="noopener noreferrer" className={cn("text-[11px] transition-colors", footerPoweredText)}>
              {isAr ? "بواسطة" : "Powered by"} anmka.com
            </a>
          </div>
        </m.div>
      </div>
    </footer>
  )
}
