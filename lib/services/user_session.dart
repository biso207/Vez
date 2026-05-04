// Developed and Designed by Outly • © 2026
// singleton class for managing the current user's session and preferences.

import 'package:shared_preferences/shared_preferences.dart';

// ── user session ─────────────────────────────────────────────────────────────
//
//   used for: persisting user ID and locale settings across app launches.
class UserSession {
  UserSession._internal();

  static final UserSession _instance = UserSession._internal();
  factory UserSession() => _instance;

  static const String _userIdKey = 'session_user_id';
  static const String _localeKey = 'session_locale';

  String userID = '';
  String profilePic = 'assets/icons/home_page/icon_profile.png';
  String locale = '';

  // ── is logged in ───────────────────────────────────────────────────────────
  //
  //   used for: determining if there is an active user session.
  bool get isLoggedIn => userID.isNotEmpty;

  // ── restore ────────────────────────────────────────────────────────────────
  //
  //   used for: loading session data from local storage at startup.
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();
    userID = prefs.getString(_userIdKey) ?? '';
    locale = prefs.getString(_localeKey) ?? '';
  }

  // ── start session ──────────────────────────────────────────────────────────
  //
  //   used for: initializing and persisting a new user session.
  Future<void> startSession({required String userID, String? locale}) async {
    final prefs = await SharedPreferences.getInstance();

    this.userID = userID;
    await prefs.setString(_userIdKey, userID);

    if (locale != null && locale.isNotEmpty) {
      this.locale = locale;
      await prefs.setString(_localeKey, locale);
    }
  }

  // ── save locale ────────────────────────────────────────────────────────────
  //
  //   used for: persisting the user's selected language.
  Future<void> saveLocale(String locale) async {
    this.locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  // ── clear session ──────────────────────────────────────────────────────────
  //
  //   used for: removing session data and optionally resetting the locale.
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
