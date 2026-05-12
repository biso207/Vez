// Developed and Designed by Outly • © 2026
// login screen — lets the user authenticate with username + password.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';
import '../../views/widgets/vez_glass.dart';
import '../home/home_screen.dart';
import 'signup/account_type_choice_screen.dart';
import 'venue_pending_screen.dart';

// ── layout constants ─────────────────────────────────────────────────────────
const double _kErrorSlotH = 56.0;
const double _kDotsSlotH = 24.0;
const double _kGapH = 20.0;
const double _kBelowBtnH = 50.0;
const double _kBottomPadH = 36.0;

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

  // ── dispose ────────────────────────────────────────────────────────────────
  //
  //   used for: disposing text controllers.
  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────
  //
  //   used for: rendering the login screen UI.
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    final double pt = MediaQuery.of(context).padding.top;
    final double kb = MediaQuery.of(context).viewInsets.bottom;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset('assets/images/bg/login.jpg', fit: BoxFit.cover),
          ),

          SafeArea(
            child: SizedBox(
              height: (sh - pt) + (kb > 0 ? 300 : 0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _TitleBlock(
                    top: StringRes.at('top_title_login'),
                    bottom: StringRes.at('under_title_login'),
                  ),

                  const Spacer(flex: 3),
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VezGlass.textField(
                            controller: _usernameCtrl,
                            hint: StringRes.at('username'),
                            width: sw * 0.75,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 20),
                          VezGlass.textField(
                            controller: _passwordCtrl,
                            hint: StringRes.at('password'),
                            obscure: !_showPassword,
                            width: sw * 0.75,
                            color: Colors.white54,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(
                                () => _showPassword = !_showPassword,
                              ),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Image.asset(
                                  _showPassword
                                      ? 'assets/icons/auth/eye.png'
                                      : 'assets/icons/auth/eye_off.png',
                                  color: Colors.white54,
                                  width: 20,
                                  height: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const Spacer(),

                  _ErrorSlot(message: _error),
                  const SizedBox(height: _kGapH),
                  const SizedBox(height: _kDotsSlotH),
                  const SizedBox(height: _kGapH),

                  VezGlass.circleButton(
                    assetIcon: 'assets/icons/auth/icon_login.png',
                    iconSize: 30,
                    onTap: _login,
                  ),

                  const SizedBox(height: _kBelowBtnH),

                  _AuthPillButton(
                    text: StringRes.at('signup'),
                    onTap: () {
                      setState(() => _error = null);
                      Navigator.push(
                        context,
                        _fadeSlideRoute(const AccountTypeChoicePage()),
                      );
                    },
                  ),

                  const SizedBox(height: _kBottomPadH),
                ],
              ),
            ),
          ),

          if (_loading) const VezLoadingOverlay(),
        ],
      ),
    );
  }

  // ── has internet ───────────────────────────────────────────────────────────
  //
  //   used for: checking connectivity before authentication attempts.
  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ── login ──────────────────────────────────────────────────────────────────
  //
  //   used for: validating inputs and executing the login request.
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
                session.accountType == 'venue' &&
                    session.accountState != 'active'
                ? const VenuePendingPage()
                : const HomePage(),
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

// ── title block ──────────────────────────────────────────────────────────────
//
//   used for: displaying page headers with a main title and subtitle.
class _TitleBlock extends StatelessWidget {
  final String top;
  final String bottom;

  const _TitleBlock({required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          top,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bottom,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ── error slot ───────────────────────────────────────────────────────────────
//
//   used for: providing a reserved space for error banners to avoid layout shifts.
class _ErrorSlot extends StatelessWidget {
  final String? message;

  const _ErrorSlot({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        height: _kErrorSlotH,
        child: AnimatedOpacity(
          opacity: message != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: message != null
              ? VezErrorBanner(message: message!)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ── auth pill button ─────────────────────────────────────────────────────────
//
//   used for: navigating between login and signup screens.
class _AuthPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _AuthPillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width * 0.40;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: w,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(51, 255, 255, 255),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white54, width: 3),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'InstagramSans',
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── fade slide route ─────────────────────────────────────────────────────────
//
//   used for: creating a smooth transition between auth pages.
Route<T> _fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
