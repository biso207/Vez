// Developed and Designed by Outly • © 2026
// FIXED by Senior → enum-safe, clean, production-ready

import 'package:shared_preferences/shared_preferences.dart';
import '../models/account_type.dart';

// ── user session ─────────────────────────────────────────────────────────────
//
// used for: persisting user session across app launches.
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
  AccountType accountType = AccountType.user;
  String accountState = 'active';

  // ── is logged in ───────────────────────────────────────────────────────────
  bool get isLoggedIn => userID.isNotEmpty && accountState == 'active';
  // ── is active ──────────────────────────────────────────────────────────────
  bool get isActive => accountState == 'active';

  // ── ENUM HELPERS ───────────────────────────────────────────────────────────

  AccountType _accountTypeFromString(String type) {
    switch (type) {
      case 'venue':
        return AccountType.venue;
      case 'user':
      default:
        return AccountType.user;
    }
  }

  // ── restore ────────────────────────────────────────────────────────────────
  Future<void> restore() async {
    final prefs = await SharedPreferences.getInstance();

    userID = prefs.getString(_userIdKey) ?? '';
    locale = prefs.getString(_localeKey) ?? '';

    final typeString = prefs.getString(_accountTypeKey) ?? 'user';
    accountType = _accountTypeFromString(typeString);

    accountState = prefs.getString(_accountStateKey) ?? 'active';
  }

  // ── start session ──────────────────────────────────────────────────────────
  Future<void> startSession({
    required String userID,
    String? locale,
    AccountType accountType = AccountType.user,
    String accountState = 'active',
  }) async {
    final prefs = await SharedPreferences.getInstance();

    this.userID = userID;
    this.accountType = accountType;
    this.accountState = accountState;

    await prefs.setString(_userIdKey, userID);
    await prefs.setString(_accountTypeKey, accountType.name);
    await prefs.setString(_accountStateKey, accountState);

    if (locale != null && locale.isNotEmpty) {
      this.locale = locale;
      await prefs.setString(_localeKey, locale);
    }
  }

  // ── update account status ──────────────────────────────────────────────────
  Future<void> updateAccountStatus({
    required AccountType accountType,
    required String accountState,
  }) async {
    final prefs = await SharedPreferences.getInstance();

    this.accountType = accountType;
    this.accountState = accountState;

    await prefs.setString(_accountTypeKey, accountType.name);
    await prefs.setString(_accountStateKey, accountState);
  }

  // ── save locale ────────────────────────────────────────────────────────────
  Future<void> saveLocale(String locale) async {
    this.locale = locale;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_localeKey, locale);
  }

  // ── clear session ──────────────────────────────────────────────────────────
  Future<void> clearSession({bool keepLocale = true}) async {
    final prefs = await SharedPreferences.getInstance();

    // 🔥 Reset memoria
    userID = '';
    profilePic = 'assets/icons/home_page/icon_profile.png';
    accountType = AccountType.user;
    accountState = 'active';

    // 🔥 Pulizia storage
    await prefs.remove(_userIdKey);
    await prefs.remove(_accountTypeKey);
    await prefs.remove(_accountStateKey);

    if (!keepLocale) {
      locale = '';
      await prefs.remove(_localeKey);
    }
  }
}