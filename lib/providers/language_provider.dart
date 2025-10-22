import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Supported languages for Aroosi
enum SupportedLanguage {
  english('en', 'English', '🇺🇸'),
  dari('fa', 'Dari (فارسی)', '🇦🇫'),
  pashto('ps', 'Pashto (پښتو)', '🇦🇫');

  const SupportedLanguage(this.code, this.displayName, this.flag);

  final String code;
  final String displayName;
  final String flag;

  static SupportedLanguage fromCode(String code) {
    return SupportedLanguage.values.firstWhere(
      (lang) => lang.code == code,
      orElse: () => SupportedLanguage.english,
    );
  }
}

/// Riverpod provider for language management
final languageProvider = NotifierProvider<LanguageNotifier, SupportedLanguage>(
  LanguageNotifier.new,
);

class LanguageNotifier extends Notifier<SupportedLanguage> {
  static const _languageKey = 'selected_language';

  @override
  SupportedLanguage build() {
    _loadLanguage();
    return SupportedLanguage.english;
  }

  Future<void> _loadLanguage() async {
    final prefs = await SharedPreferences.getInstance();
    final languageCode = prefs.getString(_languageKey) ?? 'en';
    state = SupportedLanguage.fromCode(languageCode);
  }

  Future<void> setLanguage(SupportedLanguage language) async {
    if (state == language) return;

    state = language;

    // Save to SharedPreferences
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_languageKey, language.code);

    // Update locale
    await _updateLocale(language);
  }

  Future<void> _updateLocale(SupportedLanguage language) async {
    // This would typically be handled by a more sophisticated locale management system
    // For now, we'll just trigger a rebuild to apply the new locale
  }

  /// Get current locale for the app
  Locale get currentLocale => Locale(state.code);

  /// Get all supported languages
  List<SupportedLanguage> get supportedLanguages => SupportedLanguage.values;
}
