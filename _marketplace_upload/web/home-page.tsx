import type { Metadata } from "next"
import { LandingPage } from "@/components/landing/landing-page"
import { BRAND_NAME, BRAND_TAGLINE_AR } from "@/lib/branding"
import "./landing.css"

export const metadata: Metadata = {
  title: `${BRAND_NAME} — كورسات مجانية`,
  description: `تعلّم مهاراتك مجاناً مع ${BRAND_NAME}. شاهد الكورسات والدروس بدون تسجيل.`,
  openGraph: {
    title: `${BRAND_NAME} — كورسات مجانية`,
    description: `${BRAND_NAME} — ${BRAND_TAGLINE_AR} · كورسات مجانية 100%`,
    type: "website",
    locale: "ar_EG",
  },
  twitter: {
    card: "summary_large_image",
  },
}

export default function Home() {
  return <LandingPage />
}

// Always serve fresh HTML after deploys — avoids stale chunk references in CDN/browser
export const dynamic = "force-dynamic"
