import 'dart:ui' as ui;
import '../l10n/en.dart';
import '../l10n/it.dart';
import 'user_session.dart';

class StringRes {
  static String locale = 'en'; // default language

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': en,
    'it': it,
  };

  /// Auto-detect device language and set locale.
  /// Call this once at app startup (e.g. in main or loading screen).
  static void initLocale() {
    // Get the device's primary language code (e.g. "it", "en", "fr")
    String deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
    if (_localizedValues.containsKey(deviceLang)) {
      locale = deviceLang;
    } else {
      locale = 'en'; // fallback
    }
    UserSession().locale = locale;
  }

  // Funzione magica per ottenere la traduzione
  static String at(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  static void setLocale(String newLocale) {
    if (_localizedValues.containsKey(newLocale)) {
      locale = newLocale;
      UserSession().locale = newLocale;
    }
  }
}