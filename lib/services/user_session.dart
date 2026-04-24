// services/user_session.dart

import 'package:shared_preferences/shared_preferences.dart';

class UserSession {
  UserSession._internal();

  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;

  static const String _userIdKey = 'session_user_id';
  static const String _localeKey = 'session_locale';

  String userID = '';
  String profilePic = 'assets/icons/home_page/icon_profile.png';
  String locale = '';

  bool get isLoggedIn => userID.isNotEmpty;

  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString(_userIdKey) ?? '';
    locale = prefs.getString(_localeKey) ?? '';
  }

  Future<void> startSession({required String userID, String? locale}) async {
    final prefs = await SharedPreferences.getInstance();

    this.userID = userID;
    await prefs.setString(_userIdKey, userID);

    if (locale != null && locale.isNotEmpty) {
      this.locale = locale;
      await prefs.setString(_localeKey, locale);
    }
  }

  Future<void> saveLocale(String locale) async {
    this.locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  Future<void> clearSession({bool keepLocale = true}) async {
    final prefs = await SharedPreferences.getInstance();

    userID = '';
    profilePic = 'assets/icons/home_page/icon_profile.png';
    await prefs.remove(_userIdKey);

    if (!keepLocale) {
      locale = '';
      await prefs.remove(_localeKey);
    }
  }
}
