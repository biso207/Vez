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
    // get the device's primary language code (e.g. "it", "en", "fr")
    String deviceLang = ui.PlatformDispatcher.instance.locale.languageCode;
    if (_localizedValues.containsKey(deviceLang)) {
      locale = deviceLang;
    } else {
      locale = 'en'; // fallback
    }
    UserSession().locale = locale;
  }

  // function to get the translation for each text displayed in the app
  static String at(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  // to set the user language for his session
  static void setLocale(String newLocale) {
    if (_localizedValues.containsKey(newLocale)) {
      locale = newLocale;
      UserSession().locale = newLocale;
    }
  }
}
