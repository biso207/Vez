// Developed and Designed by Outly • © 2026
// Singleton class for managing the current user's session and preferences.

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
  static const String _accountTypeKey = 'session_account_type';
  static const String _accountStateKey = 'session_account_state';

  String userID = '';
  String profilePic = 'assets/icons/home_page/icon_profile.png';
  String locale = '';
  String accountType = 'user';
  String accountState = 'active';

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
    accountType = prefs.getString(_accountTypeKey) ?? 'user';
    accountState = prefs.getString(_accountStateKey) ?? 'active';
  }

  // ── start session ──────────────────────────────────────────────────────────
  //
  //   used for: initializing and persisting a new user session.
  Future<void> startSession({
    required String userID,
    String? locale,
    String accountType = 'user',
    String accountState = 'active',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    this.userID = userID;
    this.accountType = accountType;
    this.accountState = accountState;
    await prefs.setString(_userIdKey, userID);
    await prefs.setString(_accountTypeKey, accountType);
    await prefs.setString(_accountStateKey, accountState);

    if (locale != null && locale.isNotEmpty) {
      this.locale = locale;
      await prefs.setString(_localeKey, locale);
    }
  }

  Future<void> updateAccountStatus({
    required String accountType,
    required String accountState,
  }) async {
    this.accountType = accountType;
    this.accountState = accountState;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_accountTypeKey, accountType);
    await prefs.setString(_accountStateKey, accountState);
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
    accountType = 'user';
    accountState = 'active';
    await prefs.remove(_userIdKey);
    await prefs.remove(_accountTypeKey);
    await prefs.remove(_accountStateKey);

    if (!keepLocale) {
      locale = '';
      await prefs.remove(_localeKey);
    }
  }
}
