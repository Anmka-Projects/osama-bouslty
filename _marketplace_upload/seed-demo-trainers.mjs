import bcrypt from "bcryptjs"
import { PrismaClient } from "@prisma/client"

const prisma = new PrismaClient()
const passwordHash = await bcrypt.hash("Test@1234", 10)
const video = "https://commondatastorage.googleapis.com/gtv-videos-bucket/sample/ForBiggerBlazes.mp4"

const trainers = [
  {
    name: "سارة محمود",
    email: "sara.demo@bouslty.test",
    phone: "+20155501001",
    title: "معلمة رياضيات",
    bio: "معلمة رياضيات للمرحلة الثانوية، شرح مبسط ومراجعة للاختبارات.",
    specialty: "الرياضيات",
    single: 200,
    packPrice: 800,
    packDiscount: 700,
    sessions: 4,
  },
  {
    name: "ليلى الحربي",
    email: "layla.demo@bouslty.test",
    phone: "+20155501002",
    title: "معلمة لغة عربية",
    bio: "تأسيس ونحو وبلاغة للمرحلة الإعدادية والثانوية.",
    specialty: "اللغة العربية",
    single: 180,
    packPrice: 720,
    packDiscount: 640,
    sessions: 4,
  },
  {
    name: "عمر السالم",
    email: "omar.demo@bouslty.test",
    phone: "+20155501003",
    title: "معلم علوم",
    bio: "علوم للمرحلة الإعدادية بتجارب مبسطة وشرح مباشر.",
    specialty: "العلوم",
    single: 220,
    packPrice: 1200,
    packDiscount: 990,
    sessions: 6,
  },
  {
    name: "أحمد مصطفى",
    email: "mostafa.demo@bouslty.test",
    phone: "+20155501004",
    title: "معلم لغة إنجليزية",
    bio: "محادثة وقواعد للثانوي، جلسة مباشرة أونلاين.",
    specialty: "اللغة الإنجليزية",
    single: 250,
    packPrice: 1000,
    packDiscount: 880,
    sessions: 4,
  },
]

for (const trainer of trainers) {
  const user = await prisma.user.upsert({
    where: { email: trainer.email },
    update: {
      name: trainer.name,
      phone: trainer.phone,
      title: trainer.title,
      bio: trainer.bio,
      role: "instructor",
      status: "active",
    },
    create: {
      name: trainer.name,
      email: trainer.email,
      phone: trainer.phone,
      passwordHash,
      title: trainer.title,
      bio: trainer.bio,
      role: "instructor",
      status: "active",
    },
  })

  const profile = await prisma.trainerProfile.upsert({
    where: { userId: user.id },
    update: {
      displayName: trainer.name,
      headline: trainer.title,
      bio: trainer.bio,
      introVideoUrl: video,
      verificationStatus: "approved",
      isAcceptingBookings: true,
      languages: ["ar"],
    },
    create: {
      userId: user.id,
      displayName: trainer.name,
      headline: trainer.title,
      bio: trainer.bio,
      introVideoUrl: video,
      verificationStatus: "approved",
      isAcceptingBookings: true,
      languages: ["ar"],
      offerings: {
        create: [
          {
            type: "single_session",
            title: `جلسة ${trainer.specialty}`,
            description: "جلسة مباشرة واحدة لمدة 60 دقيقة.",
            durationMinutes: 60,
            sessionCount: 1,
            price: trainer.single,
            currency: "EGP",
            isActive: true,
          },
          {
            type: "package",
            title: `باقة ${trainer.sessions} جلسات`,
            description: `${trainer.sessions} جلسات مباشرة في ${trainer.specialty}.`,
            durationMinutes: 60,
            sessionCount: trainer.sessions,
            price: trainer.packPrice,
            discountPrice: trainer.packDiscount,
            currency: "EGP",
            isActive: true,
          },
        ],
      },
      specialties: { create: [{ name: trainer.specialty }] },
      availabilityRules: {
        create: [6, 0, 1, 2, 3, 4].map((weekday) => ({
          weekday,
          startMinute: 16 * 60,
          endMinute: 21 * 60,
        })),
      },
    },
  })

  const offeringCount = await prisma.trainerOffering.count({ where: { profileId: profile.id, isActive: true } })
  if (offeringCount === 0) {
    await prisma.trainerOffering.createMany({
      data: [
        {
          profileId: profile.id,
          type: "single_session",
          title: `جلسة ${trainer.specialty}`,
          description: "جلسة مباشرة واحدة لمدة 60 دقيقة.",
          durationMinutes: 60,
          sessionCount: 1,
          price: trainer.single,
          currency: "EGP",
          isActive: true,
        },
        {
          profileId: profile.id,
          type: "package",
          title: `باقة ${trainer.sessions} جلسات`,
          description: `${trainer.sessions} جلسات مباشرة في ${trainer.specialty}.`,
          durationMinutes: 60,
          sessionCount: trainer.sessions,
          price: trainer.packPrice,
          discountPrice: trainer.packDiscount,
          currency: "EGP",
          isActive: true,
        },
      ],
    })
  }
  const ruleCount = await prisma.trainerAvailabilityRule.count({ where: { profileId: profile.id } })
  if (ruleCount === 0) {
    await prisma.trainerAvailabilityRule.createMany({
      data: [6, 0, 1, 2, 3, 4].map((weekday) => ({
        profileId: profile.id,
        weekday,
        startMinute: 16 * 60,
        endMinute: 21 * 60,
      })),
    })
  }
  console.log(trainer.name, user.id, "offerings", offeringCount)
}

const visible = await prisma.trainerProfile.count({ where: { verificationStatus: "approved", isAcceptingBookings: true } })
console.log("approved accepting", visible)
await prisma.$disconnect()
