import '../core/bookings/booking_status.dart';

DateTime? parseUtc(dynamic value) {
  if (value == null) return null;
  final parsed = DateTime.tryParse(value.toString());
  if (parsed == null) return null;
  return parsed.isUtc ? parsed : parsed.toUtc();
}

class TrainerCard {
  TrainerCard({
    required this.id,
    required this.displayName,
    this.headline,
    this.avatarUrl,
    this.ratingAverage = 0,
    this.ratingCount = 0,
    this.completedSessions = 0,
    this.studentsCount = 0,
    this.startingPrice,
    this.currency = 'USD',
    this.specialties = const [],
    this.subjects = const [],
    this.isAcceptingBookings = false,
    this.bio,
    this.badgeLabel,
    this.hoursCount = 0,
  });

  final String id;
  final String displayName;
  final String? headline;
  final String? avatarUrl;
  final double ratingAverage;
  final int ratingCount;
  final int completedSessions;
  final int studentsCount;
  final String? startingPrice;
  final String currency;
  final List<String> specialties;
  final List<String> subjects;
  final bool isAcceptingBookings;
  final String? bio;
  final String? badgeLabel;
  final int hoursCount;

  factory TrainerCard.fromJson(Map<String, dynamic> json) {
    final specs = (json['specialties'] as List?) ?? const [];
    return TrainerCard(
      id: json['id']?.toString() ?? '',
      displayName:
          json['display_name']?.toString() ?? json['name']?.toString() ?? '',
      headline: json['headline']?.toString() ?? json['title']?.toString(),
      avatarUrl: json['avatar_url']?.toString() ?? json['avatar']?.toString(),
      ratingAverage:
          double.tryParse('${json['rating_average'] ?? json['rating'] ?? 0}') ??
              0,
      ratingCount: int.tryParse('${json['rating_count'] ?? 0}') ?? 0,
      completedSessions:
          int.tryParse('${json['completed_sessions_count'] ?? 0}') ?? 0,
      studentsCount:
          int.tryParse('${json['students_count'] ?? json['students'] ?? 0}') ??
              0,
      startingPrice: json['starting_price']?.toString(),
      currency: 'USD',
      specialties: specs
          .map((item) {
            if (item is Map) return item['name']?.toString() ?? '';
            return item.toString();
          })
          .where((item) => item.isNotEmpty)
          .toList(),
      subjects: ((json['subjects'] as List?) ?? const [])
          .map((item) {
            if (item is Map) return item['name']?.toString() ?? '';
            return item.toString();
          })
          .where((item) => item.isNotEmpty)
          .toList(),
      isAcceptingBookings: json['is_accepting_bookings'] == true,
      bio: json['bio']?.toString(),
      badgeLabel: json['badge_label']?.toString(),
      hoursCount: int.tryParse('${json['hours_count'] ?? 0}') ?? 0,
    );
  }
}

class TrainerOffering {
  TrainerOffering({
    required this.id,
    required this.type,
    required this.title,
    this.description,
    required this.durationMinutes,
    required this.sessionCount,
    required this.price,
    this.discountPrice,
    required this.payable,
    required this.currency,
    this.courseId,
  });

  final String id;
  final String type;
  final String title;
  final String? description;
  final int durationMinutes;
  final int sessionCount;
  final String price;
  final String? discountPrice;
  final String payable;
  final String currency;
  final String? courseId;

  factory TrainerOffering.fromJson(Map<String, dynamic> json) {
    return TrainerOffering(
      id: json['id']?.toString() ?? '',
      type: json['type']?.toString() ?? 'single_session',
      title: json['title']?.toString() ?? '',
      description: json['description']?.toString(),
      durationMinutes: int.tryParse('${json['duration_minutes'] ?? 60}') ?? 60,
      sessionCount: int.tryParse('${json['session_count'] ?? 1}') ?? 1,
      price: json['price']?.toString() ?? '0.00',
      discountPrice: json['discount_price']?.toString(),
      payable:
          json['payable']?.toString() ?? json['price']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'USD',
      courseId: json['course_id']?.toString(),
    );
  }
}

class AvailabilitySlot {
  AvailabilitySlot({
    required this.slotId,
    required this.startsAtUtc,
    required this.endsAtUtc,
    required this.available,
  });

  final String slotId;
  final DateTime startsAtUtc;
  final DateTime endsAtUtc;
  final bool available;

  factory AvailabilitySlot.fromJson(Map<String, dynamic> json) {
    return AvailabilitySlot(
      slotId: json['slot_id']?.toString() ?? '',
      startsAtUtc: parseUtc(json['starts_at']) ?? DateTime.now().toUtc(),
      endsAtUtc: parseUtc(json['ends_at']) ?? DateTime.now().toUtc(),
      available: json['available'] == true,
    );
  }
}

class BookingQuote {
  BookingQuote({
    required this.quoteId,
    required this.expiresAtUtc,
    required this.subtotal,
    required this.discount,
    required this.total,
    required this.currency,
  });

  final String quoteId;
  final DateTime expiresAtUtc;
  final String subtotal;
  final String discount;
  final String total;
  final String currency;

  bool get isExpired => DateTime.now().toUtc().isAfter(expiresAtUtc);

  factory BookingQuote.fromJson(Map<String, dynamic> json) {
    return BookingQuote(
      quoteId: json['quote_id']?.toString() ?? '',
      expiresAtUtc: parseUtc(json['expires_at']) ?? DateTime.now().toUtc(),
      subtotal: json['subtotal']?.toString() ?? '0.00',
      discount: json['discount']?.toString() ?? '0.00',
      total: json['total']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'USD',
    );
  }
}

class SessionBooking {
  SessionBooking({
    required this.id,
    required this.status,
    required this.paymentStatus,
    required this.scheduledAtUtc,
    required this.endsAtUtc,
    required this.amount,
    required this.currency,
    required this.scheduleVersion,
    required this.canJoin,
    required this.canCancel,
    required this.canReschedule,
    required this.canReview,
    this.offeringTitle,
    this.trainerName,
    this.trainerId,
    this.studentName,
    this.conversationId,
    this.studentNotes,
    this.joinBlockReason,
    this.paymentMethod,
    this.packagePurchaseId,
    this.sessionsRemaining = 0,
  });

  final String id;
  final BookingStatus status;
  final BookingPaymentStatus paymentStatus;
  final DateTime scheduledAtUtc;
  final DateTime endsAtUtc;
  final String amount;
  final String currency;
  final int scheduleVersion;
  final bool canJoin;
  final bool canCancel;
  final bool canReschedule;
  final bool canReview;
  final String? offeringTitle;
  final String? trainerName;
  final String? trainerId;
  final String? studentName;
  final String? conversationId;
  final String? studentNotes;
  final String? joinBlockReason;
  final String? paymentMethod;
  final String? packagePurchaseId;
  final int sessionsRemaining;

  factory SessionBooking.fromJson(Map<String, dynamic> json) {
    final offering = json['offering'];
    final trainer = json['trainer_summary'];
    final student = json['student_summary'];
    return SessionBooking(
      id: json['id']?.toString() ?? '',
      status: BookingStatus.parse(json['status']?.toString()),
      paymentStatus:
          BookingPaymentStatus.parse(json['payment_status']?.toString()),
      scheduledAtUtc: parseUtc(json['scheduled_at']) ?? DateTime.now().toUtc(),
      endsAtUtc: parseUtc(json['ends_at']) ?? DateTime.now().toUtc(),
      amount: json['amount']?.toString() ?? '0.00',
      currency: json['currency']?.toString() ?? 'USD',
      scheduleVersion: int.tryParse('${json['schedule_version'] ?? 1}') ?? 1,
      canJoin: json['can_join'] == true,
      canCancel: json['can_cancel'] == true,
      canReschedule: json['can_reschedule'] == true,
      canReview: json['can_review'] == true,
      offeringTitle: offering is Map ? offering['title']?.toString() : null,
      trainerName: trainer is Map ? trainer['display_name']?.toString() : null,
      trainerId: trainer is Map ? trainer['id']?.toString() : null,
      studentName: student is Map ? student['name']?.toString() : null,
      conversationId: json['conversation_id']?.toString(),
      studentNotes: json['student_notes']?.toString(),
      joinBlockReason: json['join_block_reason']?.toString(),
      paymentMethod: json['payment_method']?.toString(),
      packagePurchaseId: (json['package_purchase'] is Map)
          ? (json['package_purchase'] as Map)['id']?.toString()
          : json['package_purchase_id']?.toString(),
      sessionsRemaining: json['package_purchase'] is Map
          ? int.tryParse(
                  '${(json['package_purchase'] as Map)['sessions_remaining'] ?? 0}') ??
              0
          : 0,
    );
  }
}

class TrainerProfileDetail {
  TrainerProfileDetail({
    required this.card,
    this.bio,
    this.yearsExperience,
    this.qualifications = const [],
    this.offerings = const [],
    this.reviews = const [],
    this.languages = const [],
    this.introVideoUrl,
  });

  final TrainerCard card;
  final String? bio;
  final int? yearsExperience;
  final List<String> qualifications;
  final List<TrainerOffering> offerings;
  final List<Map<String, dynamic>> reviews;
  final List<String> languages;
  final String? introVideoUrl;

  factory TrainerProfileDetail.fromJson(Map<String, dynamic> json) {
    final quals = (json['qualifications'] as List?) ?? const [];
    final offerings = (json['offerings'] as List?) ?? const [];
    final reviews = (json['reviews'] as List?) ?? const [];
    final languages = (json['languages'] as List?) ?? const [];
    return TrainerProfileDetail(
      card: TrainerCard.fromJson(json),
      bio: json['bio']?.toString(),
      yearsExperience: int.tryParse('${json['years_experience'] ?? ''}'),
      qualifications: quals
          .map((item) {
            if (item is Map) return item['title']?.toString() ?? '';
            return item.toString();
          })
          .where((item) => item.isNotEmpty)
          .toList(),
      offerings: offerings
          .whereType<Map>()
          .map((item) =>
              TrainerOffering.fromJson(Map<String, dynamic>.from(item)))
          .toList(),
      reviews: reviews
          .whereType<Map>()
          .map((item) => Map<String, dynamic>.from(item))
          .toList(),
      languages: languages.map((item) => item.toString()).toList(),
      introVideoUrl: json['intro_video_url']?.toString(),
    );
  }
}
