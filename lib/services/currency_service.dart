import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import '../core/api/api_client.dart';
import '../core/api/api_endpoints.dart';

/// Auto-detects the display currency from the user's country.
///
/// The device locale country code is sent to `GET /api/currency/detect`
/// (the backend falls back to GeoIP when no country is provided).
/// The response carries USD-based exchange `rates`, so any price can be
/// converted: `amount * rates[to] / rates[from]`.
///
/// If detection fails, everything falls back to the default currency (USD)
/// and amounts are shown unchanged.
class CurrencyService {
  CurrencyService._();

  static final CurrencyService instance = CurrencyService._();

  String code = 'USD';
  String symbol = '\$';
  String name = 'USD';
  String? country;
  bool isDefault = true;
  Map<String, double> rates = const {'USD': 1};

  bool _loaded = false;
  Future<void>? _pending;

  Future<void> init() {
    _pending ??= _load();
    return _pending!;
  }

  Future<void> _load() async {
    try {
      final locale =
          WidgetsBinding.instance.platformDispatcher.locale;
      final countryCode = locale.countryCode?.trim().toUpperCase();
      final query = (countryCode != null && countryCode.length == 2)
          ? '?country=$countryCode'
          : '';
      final response = await ApiClient.instance.get(
        '${ApiEndpoints.baseUrl}/currency/detect$query',
        requireAuth: false,
      );
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        final currency = data['currency'];
        if (currency is Map<String, dynamic> &&
            currency['code'] != null) {
          code = currency['code'].toString().toUpperCase();
          symbol = currency['symbol']?.toString() ?? code;
          name = currency['name']?.toString() ?? code;
        }
        country = data['country']?.toString();
        isDefault = data['is_default'] == true;
        final rawRates = data['rates'];
        if (rawRates is Map) {
          final parsed = <String, double>{};
          rawRates.forEach((key, value) {
            final rate = value is num
                ? value.toDouble()
                : double.tryParse(value?.toString() ?? '');
            if (rate != null && rate > 0) {
              parsed[key.toString().toUpperCase()] = rate;
            }
          });
          if (parsed.isNotEmpty) rates = parsed;
        }
      }
    } catch (e) {
      debugPrint('CurrencyService: detection failed, using defaults: $e');
    } finally {
      _loaded = true;
    }
  }

  bool get loaded => _loaded;

  /// Converts [amount] expressed in [from] currency to the detected currency.
  double convert(dynamic amount, String? from) {
    final value = amount is num
        ? amount.toDouble()
        : double.tryParse(amount?.toString() ?? '') ?? 0;
    final source = (from == null || from.trim().isEmpty)
        ? code
        : from.trim().toUpperCase();
    if (source == code) return value;
    final fromRate = rates[source];
    final toRate = rates[code];
    if (fromRate == null || toRate == null || fromRate <= 0) return value;
    return value * (toRate / fromRate);
  }

  /// Formats [amount] (in [from] currency) as "<amount> <detected code>".
  String format(dynamic amount, String? from) {
    final converted = convert(amount, from);
    final rounded = (converted * 100).round() / 100;
    final text = rounded == rounded.roundToDouble()
        ? rounded.toInt().toString()
        : rounded.toStringAsFixed(2);
    return '$text $code';
  }
}
