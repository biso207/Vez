import '../l10n/en.dart';
import '../l10n/it.dart';

class StringRes {
  static String locale = 'en'; // default language

  static const Map<String, Map<String, String>> _localizedValues = {
    'en': en,
    'it': it,
  };

  // Funzione magica per ottenere la traduzione
  static String at(String key) {
    return _localizedValues[locale]?[key] ?? key;
  }

  static void setLocale(String newLocale) {
    if (_localizedValues.containsKey(newLocale)) {
      locale = newLocale;
    }
  }
}