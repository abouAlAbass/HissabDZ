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
  {
    'locale': Locale('en'),
    'nameKey': 'english',
    'native': 'English',
    'flag': '\u{1F1EC}\u{1F1E7}',
  },
  {
    'locale': Locale('fr'),
    'nameKey': 'french',
    'native': 'Fran\u00e7ais',
    'flag': '\u{1F1EB}\u{1F1F7}',
  },
  {
    'locale': Locale('ar'),
    'nameKey': 'arabic',
    'native': '\u0627\u0644\u0639\u0631\u0628\u064a\u0629',
    'flag': '\u{1F1F8}\u{1F1E6}',
  },
];
