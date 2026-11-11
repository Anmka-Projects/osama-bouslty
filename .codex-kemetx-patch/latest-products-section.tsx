"use client"

import { useState, useEffect } from "react"
import Link from "next/link"
import Image from "next/image"
import { motion } from "framer-motion"
import { ShoppingBag, ArrowRight, Tag, Package } from "lucide-react"
import { Button } from "@/components/ui/button"
import { Badge } from "@/components/ui/badge"
import { api } from "@/hooks/use-api"
import { usePlatformCurrency } from "@/hooks/use-platform-currency"
import { useI18n } from "@/lib/i18n"
import { useThemeConfigOptional } from "@/components/providers/ThemeConfigProvider"
import { sectionSurfaceStyle } from "@/lib/section-surface-style"

interface Product {
  id: string
  title: string
  titleAr?: string
  description?: string
  thumbnail?: string
  price: number
  currency?: string
  type?: string
  category?: string
  stock?: number | null
}

const API_BASE = process.env.NEXT_PUBLIC_API_URL || "https://kemetxinst.anmka.com/api"

export default function LatestProductsSection() {
  const [products, setProducts] = useState<Product[]>([])
  const [loading, setLoading] = useState(true)
  const { formatCurrency } = usePlatformCurrency()
  const { locale } = useI18n()
  const isAr = locale === "ar"
  const themeCtx = useThemeConfigOptional()
  const sc = themeCtx?.config?.siteContent

  useEffect(() => {
    api.request("/marketplace/products?limit=8")
      .then((res) => {
        if (res.success) {
          const data = res.data as Product[] | { data: Product[] }
          const items = Array.isArray(data) ? data : (data as { data: Product[] })?.data || []
          setProducts(items.slice(0, 8))
        }
      })
      .catch(() => {})
      .finally(() => setLoading(false))
  }, [])

  if (!loading && products.length === 0) return null

  return (
    <section
      className="relative py-20 bg-[var(--color-body-bg)] overflow-hidden"
      style={sectionSurfaceStyle(sc, "latest_products")}
    >
      <div className="container relative mx-auto px-4 sm:px-6 lg:px-8">
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true, margin: "-50px" }}
          transition={{ duration: 0.6 }}
          className="text-center mb-12"
        >
          <Badge className="mb-4 border-medex-red/20 bg-red-50 text-medex-red hover:bg-red-50 px-4 py-1.5 text-sm font-semibold">
            <ShoppingBag className="w-4 h-4 me-1.5" />
            {isAr ? "المتجر" : "Store"}
          </Badge>
          <h2 className="text-3xl sm:text-4xl font-bold text-body-theme mb-4">
            {isAr ? "أحدث المنتجات" : "Latest Products"}
          </h2>
          <p className="text-body-theme-muted max-w-xl mx-auto">
            {isAr
              ? "اكتشف أحدث المنتجات والموارد التعليمية"
              : "Discover the latest educational products and resources"}
          </p>
        </motion.div>

        {loading ? (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-6">
            {Array.from({ length: 8 }).map((_, i) => (
              <div key={i} className="rounded-2xl bg-gray-100 animate-pulse h-64" />
            ))}
          </div>
        ) : (
          <div className="grid grid-cols-2 sm:grid-cols-3 lg:grid-cols-4 gap-4 sm:gap-6">
            {products.map((product, i) => {
              const title = isAr && product.titleAr ? product.titleAr : product.title
              const imgSrc = product.thumbnail
                ? product.thumbnail.startsWith("http")
                  ? product.thumbnail
                  : product.thumbnail.startsWith("/")
                    ? `${API_BASE.replace(/\/api$/, "")}${product.thumbnail}`
                    : product.thumbnail
                : null

              return (
                <motion.div
                  key={product.id}
                  initial={{ opacity: 0, y: 20 }}
                  whileInView={{ opacity: 1, y: 0 }}
                  viewport={{ once: true, margin: "-30px" }}
                  transition={{ duration: 0.4, delay: i * 0.05 }}
                >
                  <Link href={`/store/${product.id}`} className="group block">
                    <div className="rounded-2xl border border-gray-200/60 bg-white overflow-hidden shadow-sm transition-all duration-300 hover:shadow-xl hover:border-medex-red/20 hover:-translate-y-1">
                      <div className="relative aspect-square bg-gray-50 overflow-hidden">
                        {imgSrc ? (
                          <Image
                            src={imgSrc}
                            alt={title}
                            fill
                            unoptimized
                            className="object-cover transition-transform duration-500 group-hover:scale-105"
                          />
                        ) : (
                          <div className="flex h-full items-center justify-center">
                            <Package className="w-12 h-12 text-gray-200" />
                          </div>
                        )}
                        {product.category && (
                          <span className="absolute top-2 start-2 rounded-lg bg-medex-red/90 px-2 py-0.5 text-[10px] font-semibold text-white backdrop-blur-sm uppercase">
                            {product.category}
                          </span>
                        )}
                      </div>
                      <div className="p-3 sm:p-4">
                        <h3 className="text-sm font-bold text-medex-dark line-clamp-2 mb-2 group-hover:text-medex-red transition-colors leading-snug">
                          {title}
                        </h3>
                        <div className="flex items-center justify-between">
                          <span className="text-lg font-bold text-medex-red">
                            {formatCurrency(product.price)}
                          </span>
                          {product.stock != null && product.stock <= 10 && product.stock > 0 && (
                            <span className="text-[10px] font-medium text-amber-600 bg-amber-50 px-1.5 py-0.5 rounded">
                              {isAr ? `${product.stock} متبقي` : `${product.stock} left`}
                            </span>
                          )}
                        </div>
                      </div>
                    </div>
                  </Link>
                </motion.div>
              )
            })}
          </div>
        )}

        <motion.div
          initial={{ opacity: 0, y: 10 }}
          whileInView={{ opacity: 1, y: 0 }}
          viewport={{ once: true }}
          transition={{ duration: 0.5, delay: 0.3 }}
          className="text-center mt-10"
        >
          <Link href="/store">
            <Button
              size="lg"
              className="rounded-xl bg-medex-red text-white hover:bg-medex-red-dark font-semibold px-8 h-12 gap-2 shadow-lg shadow-red-500/20"
            >
              <ShoppingBag className="w-4 h-4" />
              {isAr ? "تصفح كل المنتجات" : "Browse All Products"}
              <ArrowRight className="w-4 h-4" />
            </Button>
          </Link>
        </motion.div>
      </div>
    </section>
  )
}
