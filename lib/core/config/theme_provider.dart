import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Provider to manage app theme (dark mode) and language
class ThemeProvider extends ChangeNotifier {
  static const String _darkModeKey = 'dark_mode';
  static const String _languageKey = 'app_language';

  static ThemeProvider? _instance;

  static ThemeProvider get instance {
    _instance ??= ThemeProvider._();
    return _instance!;
  }

  bool _isDarkMode = false;
  Locale _locale = const Locale('en');

  bool get isDarkMode => _isDarkMode;
  Locale get locale => _locale;
  ThemeMode get themeMode => _isDarkMode ? ThemeMode.dark : ThemeMode.light;

  bool _isInitialized = false;

  ThemeProvider._() {
    _initialize();
  }

  /// Initialize and load saved preferences
  Future<void> _initialize() async {
    if (_isInitialized) return;
    await _loadPreferences();
    _isInitialized = true;
  }

  /// Load saved preferences
  Future<void> _loadPreferences() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _isDarkMode = prefs.getBool(_darkModeKey) ?? false;
      final savedLanguage = prefs.getString(_languageKey) ?? 'en';
      _locale = savedLanguage == 'ar' ? const Locale('ar') : const Locale('en');
      notifyListeners();
    } catch (e) {
      // Use defaults if loading fails
      _isDarkMode = false;
      _locale = const Locale('en');
    }
  }

  /// Ensure preferences are loaded (call this before using the provider)
  Future<void> ensureInitialized() async {
    if (!_isInitialized) {
      await _initialize();
    }
  }

  /// Toggle dark mode
  Future<void> toggleDarkMode() async {
    _isDarkMode = !_isDarkMode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Set dark mode
  Future<void> setDarkMode(bool value) async {
    if (_isDarkMode == value) return;
    _isDarkMode = value;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_darkModeKey, _isDarkMode);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Set app language and persist preference.
  Future<void> setLanguage(Locale locale) async {
    final nextLocale =
        locale.languageCode == 'ar' ? const Locale('ar') : const Locale('en');
    if (_locale == nextLocale) return;

    _locale = nextLocale;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_languageKey, _locale.languageCode);
    } catch (e) {
      // Ignore save errors
    }
  }

  /// Get language display name
  String getLanguageName() => _locale.languageCode == 'ar' ? 'العربية' : 'English';
}
