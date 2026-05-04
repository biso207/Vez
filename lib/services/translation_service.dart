// Developed and Designed by Outly • © 2026
// service for managing multi-language support and localization.

import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../l10n/de.dart';
import '../l10n/en.dart';
import '../l10n/es.dart';
import '../l10n/fr.dart';
import '../l10n/it.dart';
import '../l10n/zh.dart';
import 'user_session.dart';

// ── locale refresh notifier ──────────────────────────────────────────────────
//
//   used for: notifying the app when the language has changed.
class LocaleRefreshNotifier extends ChangeNotifier {
  // ── refresh ────────────────────────────────────────────────────────────────
  //
  //   used for: triggering a UI rebuild across the entire app.
  void refresh() => notifyListeners();
}

// ── string res ───────────────────────────────────────────────────────────────
//
//   used for: accessing localized strings based on the current locale.
class StringRes {
  static String locale = 'en'; // default language
  static final LocaleRefreshNotifier localeNotifier = LocaleRefreshNotifier();

  static const Map<String, Map<String, String>> _localizedValues = {
    'de': de,
    'en': en,
    'es': es,
    'fr': fr,
    'it': it,
    'zh': zh,
  };

  // ── init locale ────────────────────────────────────────────────────────────
  //
  //   used for: auto-detecting device language and setting the initial locale.
  static void initLocale() {
    // get the device's primary language code (e.g. "it", "en", "fr")
    final String deviceLang = ui.PlatformDispatcher.instance.locale.languageCode
        .toLowerCase();
    if (_localizedValues.containsKey(deviceLang)) {
      locale = deviceLang;
    } else {
      locale = 'en'; // fallback
    }
    UserSession().locale = locale;
    UserSession().saveLocale(locale);
    localeNotifier.refresh();
  }

  // ── at ─────────────────────────────────────────────────────────────────────
  //
  //   used for: retrieving a localized string by its key.
  static String at(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  // ── set locale ─────────────────────────────────────────────────────────────
  //
  //   used for: manually changing the app's language and persisting the choice.
  static void setLocale(String newLocale) {
    final String normalizedLocale = newLocale
        .toLowerCase()
        .split(RegExp(r'[-_]'))
        .first;
    if (!_localizedValues.containsKey(normalizedLocale)) return;

    locale = normalizedLocale;
    UserSession().locale = normalizedLocale;
    UserSession().saveLocale(normalizedLocale);
    localeNotifier.refresh();
  }
}
