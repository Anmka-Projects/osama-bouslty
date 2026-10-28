/// Resolves display price and free/paid state from course API maps.
///
/// Handles cases where `price` is 0 but `original_price` holds the real amount
/// and `is_free` is explicitly `false`.
class CoursePricing {
  final num displayPrice;
  final bool isFree;

  const CoursePricing({required this.displayPrice, required this.isFree});
}

class CoursePricingUtils {
  CoursePricingUtils._();

  static num? parseAmount(dynamic value) {
    if (value == null) return null;
    if (value is num) return value;
    if (value is String) return num.tryParse(value.trim());
    return null;
  }

  /// `true` / `false` when API sent a flag; `null` when absent.
  static bool? isFreeFlag(Map<String, dynamic> course) {
    final raw = course['is_free'] ?? course['isFree'];
    if (raw == true) return true;
    if (raw == false) return false;
    return null;
  }

  /// Best amount to show or charge: `price` → `original_price` → `display_price_egp`.
  static num effectivePrice(Map<String, dynamic> course) {
    final price = parseAmount(course['price']);
    if (price != null && price > 0) return price;

    final original = parseAmount(course['original_price']);
    if (original != null && original > 0) return original;

    final display = parseAmount(course['display_price_egp']);
    if (display != null && display > 0) return display;

    return price ?? 0;
  }

  static CoursePricing resolve(Map<String, dynamic> course) {
    final flag = isFreeFlag(course);
    if (flag == true) {
      return const CoursePricing(displayPrice: 0, isFree: true);
    }

    final amount = effectivePrice(course);
    if (flag == false) {
      return CoursePricing(displayPrice: amount, isFree: amount == 0);
    }

    // Legacy: no is_free flag — treat zero effective price as free.
    return CoursePricing(
      displayPrice: amount,
      isFree: amount == 0,
    );
  }
}
