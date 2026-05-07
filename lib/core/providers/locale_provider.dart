import 'package:flutter/material.dart';
import 'package:riverpod_annotation/riverpod_annotation.dart';

part 'locale_provider.g.dart';

@riverpod
class AppLocale extends _$AppLocale {
  @override
  Locale build() => const Locale('en');

  void setLocale(Locale locale) => state = locale;
}

const List<Map<String, dynamic>> supportedLocalesInfo = [
  {'locale': Locale('en'), 'nameKey': 'english', 'native': 'English', 'flag': '🇬🇧'},
  {'locale': Locale('fr'), 'nameKey': 'french', 'native': 'Français', 'flag': '🇫🇷'},
  {'locale': Locale('ar'), 'nameKey': 'arabic', 'native': 'العربية', 'flag': '🇸🇦'},
];
