import 'package:flutter/foundation.dart';
import 'dart:ui' as ui;
import '../l10n/de.dart';
import '../l10n/en.dart';
import '../l10n/es.dart';
import '../l10n/fr.dart';
import '../l10n/it.dart';
import '../l10n/zh.dart';
import 'user_session.dart';

class LocaleRefreshNotifier extends ChangeNotifier {
  void refresh() => notifyListeners();
}

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

  /// Auto-detect device language and set locale.
  /// Call this once at app startup (e.g. in main or loading screen).
  static void initLocale() {
    // get the device's primary language code (e.g. "it", "en", "fr")
    final String deviceLang = ui.PlatformDispatcher.instance.locale.languageCode.toLowerCase();
    if (_localizedValues.containsKey(deviceLang)) {
      locale = deviceLang;
    } else {
      locale = 'en'; // fallback
    }
    UserSession().locale = locale;
    localeNotifier.refresh();
  }

  // function to get the translation for each text displayed in the app
  static String at(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  // to set the user language for his session
  static void setLocale(String newLocale) {
    final String normalizedLocale = newLocale.toLowerCase().split(RegExp(r'[-_]')).first;
    if (!_localizedValues.containsKey(normalizedLocale)) return;

    locale = normalizedLocale;
    UserSession().locale = normalizedLocale;
    localeNotifier.refresh();
  }
}
