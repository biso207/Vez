// Developed and Designed by Outly • © 2026
// login screen — lets the user authenticate with username + password.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';
import '../home/home_screen.dart';
import 'blocked_screen.dart';
import 'signup/account_type_choice_screen.dart';
import 'signup/signup_widgets.dart';
import 'venue_pending_screen.dart';

// ── login page ───────────────────────────────────────────────────────────────
//
//   used for: handling user login credentials and authentication.
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// ── login page state ─────────────────────────────────────────────────────────
//
//   used for: managing the login form state and authentication logic.
class _LoginPageState extends State<LoginPage> {
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final RemoteDbService _db = RemoteDbService();

  String? _error;
  bool _loading = false;
  bool _showPassword = false;

  // disposes text controllers on unmount.
  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // builds the login screen.
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double fieldWidth = sw * 0.75;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kAuthBlack,
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg/login.jpg',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── top: title at fixed distance from safe-area ──────────────
                const SizedBox(height: kAuthTopPad),
                TitleBlock(
                  title: StringRes.at('top_title_login'),
                  subtitle: StringRes.at('under_title_login'),
                ),

                // ── center: input fields ─────────────────────────────────────
                Expanded(
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        AuthGlassTextField(
                          controller: _usernameCtrl,
                          hint: StringRes.at('username'),
                          width: fieldWidth,
                        ),
                        const SizedBox(height: kAuthFieldGap),
                        AuthGlassTextField(
                          controller: _passwordCtrl,
                          hint: StringRes.at('password'),
                          width: fieldWidth,
                          obscure: !_showPassword,
                          suffix: GestureDetector(
                            onTap: () =>
                                setState(() => _showPassword = !_showPassword),
                            child: Padding(
                              padding: const EdgeInsets.only(right: 6),
                              child: Image.asset(
                                _showPassword
                                    ? 'assets/icons/auth/eye.png'      // TODO: modify the path here
                                    : 'assets/icons/auth/eye_off.png', // TODO: modify the path here
                                color: kAuthWhite50,
                                width: 22,
                                height: 22,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ── bottom: error · dots-slot · login button · pill ──────────
                AuthErrorSlot(message: _error),
                const SizedBox(height: kAuthBottomGap),

                // reserved dots slot — keeps vertical rhythm identical to signup.
                const SizedBox(height: kAuthDotsSlotH),
                const SizedBox(height: kAuthBottomGap),

                // login action button
                AuthCircleButton(
                  assetPath: 'assets/icons/auth/icon_login.png', // TODO: modify the path here
                  iconSize: 30,
                  onTap: _login,
                ),
                const SizedBox(height: kAuthBottomGap),

                // navigate to signup
                AuthPillButton(
                  text: StringRes.at('signup'),
                  onTap: () {
                    setState(() => _error = null);
                    Navigator.push(
                      context,
                      authFadeSlideRoute(const AccountTypeChoicePage()),
                    );
                  },
                ),

                const SizedBox(height: kAuthBottomPad),
              ],
            ),
          ),

          if (_loading) const AuthLoadingOverlay(),
        ],
      ),
    );
  }

  // checks network reachability before login.
  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // validates inputs and executes the login request.
  Future<void> _login() async {
    final String username = _usernameCtrl.text.trim();
    final String password = _passwordCtrl.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => _error = StringRes.at('fill_all_fields'));
      return;
    }

    if (!await _hasInternet()) {
      setState(() => _error = StringRes.at('no_internet_connection'));
      return;
    }

    setState(() {
      _error = null;
      _loading = true;
    });

    try {
      final int res = await _db.login(username: username, password: password);
      if (!mounted) return;
      setState(() => _loading = false);

      if (res == 200 || res == 201) {
        final session = UserSession();
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (_) =>
                session.isActive ? const HomePage() : const BlockedAccount(),
          ),
        );
      } else if (res == 401) {
        setState(() => _error = StringRes.at('invalid_credentials'));
      } else {
        setState(() => _error = '${StringRes.at("login_failed")}\n$res');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = StringRes.at('no_internet_connection');
      });
    }
  }
}
