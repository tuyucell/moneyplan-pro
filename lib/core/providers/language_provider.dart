import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/material.dart';

class LanguageState {
  final Locale locale;
  final String name;
  final String flag;

  String get code => locale.languageCode;

  LanguageState(this.locale, this.name, this.flag);
}

class LanguageNotifier extends StateNotifier<LanguageState> {
  LanguageNotifier() : super(LanguageState(const Locale('tr', 'TR'), 'Türkçe', '🇹🇷'));

  void setLanguage(String code) {
    switch (code) {
      case 'en':
        state = LanguageState(const Locale('en', 'US'), 'English', '🇺🇸');
        break;
      case 'tr':
      default:
        state = LanguageState(const Locale('tr', 'TR'), 'Türkçe', '🇹🇷');
        break;
    }
  }
}

final languageProvider = StateNotifierProvider<LanguageNotifier, LanguageState>((ref) {
  return LanguageNotifier();
});
