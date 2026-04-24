// developed and designed by outly • © 2026
// login screen — lets the user authenticate with username + password.
//
// layout notes:
//   the bottom section (error slot → dots placeholder → action button → pill)
//   uses the EXACT same fixed heights as signup_screen.dart so that
//   "action button" and "pill button" land at the same vertical position
//   on both screens regardless of screen size.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../models/vez_glass.dart';
import '../../models/vez_popup.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../home_screen.dart';
import 'signup_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// layout constants — keep in sync with signup_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

/// height always reserved for the error banner (visible or not)
const double _kErrorSlotH  = 56.0;
/// height always reserved for the step-dots row (login has no dots → placeholder)
const double _kDotsSlotH   = 24.0;
/// vertical gap between fixed bottom items
const double _kGapH        = 20.0;
/// gap between the action button and the pill button
const double _kBelowBtnH   = 50.0;
/// bottom padding below the pill button
const double _kBottomPadH  = 36.0;

// ─────────────────────────────────────────────────────────────────────────────
// stateful widget wrapper
// ─────────────────────────────────────────────────────────────────────────────

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// state
// ─────────────────────────────────────────────────────────────────────────────

class _LoginPageState extends State<LoginPage> {

  // ── controllers & services ─────────────────────────────────────────────────

  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final RemoteDbService _db = RemoteDbService();

  // ── ui state ───────────────────────────────────────────────────────────────

  String? _error;
  bool    _loading      = false;
  bool    _showPassword = false;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _usernameCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  // ── build ──────────────────────────────────────────────────────────────────

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

          // ── background image ───────────────────────────────────────────
          Positioned.fill(
            child: Image.asset('assets/images/bg/bg_login.jpg', fit: BoxFit.cover),
          ),

          // ── main content ───────────────────────────────────────────────
          SafeArea(
            child: SizedBox(
              // extend height when keyboard is open so content stays visible
              height: (sh - pt) + (kb > 0 ? 300 : 0),
              child: Column(
                children: [

                  // ── title block ─────────────────────────────────────────
                  const Spacer(flex: 2),
                  _TitleBlock(
                    top:    StringRes.at('top_title_login'),
                    bottom: StringRes.at('under_title_login'),
                  ),

                  // ── form area (fixed height, same as signup) ────────────
                  const Spacer(flex: 3),
                  SizedBox(
                    height: 300,
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VezGlass.textField(
                            controller: _usernameCtrl,
                            hint:  StringRes.at('username'),
                            width: sw * 0.75,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 20),
                          VezGlass.textField(
                            controller: _passwordCtrl,
                            hint:    StringRes.at('password'),
                            obscure: !_showPassword,
                            width:   sw * 0.75,
                            color:   Colors.white54,
                            suffixIcon: GestureDetector(
                              onTap: () => setState(() => _showPassword = !_showPassword),
                              child: Padding(
                                padding: const EdgeInsets.only(right: 6),
                                child: Icon(
                                  _showPassword
                                      ? Icons.visibility_outlined
                                      : Icons.visibility_off_outlined,
                                  color: Colors.white54, size: 20,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // ── elastic spacer fills the remaining vertical room ─────
                  const Spacer(),

                  // ═══════════════════════════════════════════════════════
                  // FIXED BOTTOM BLOCK — identical structure to signup_screen
                  // so action button + pill button land at the same Y position
                  // ═══════════════════════════════════════════════════════

                  // error banner slot — always the same height; only opacity changes
                  _ErrorSlot(message: _error),

                  const SizedBox(height: _kGapH),

                  // dots placeholder — same height as signup's step-dots row
                  // (login has no dots, but we reserve the space for alignment)
                  const SizedBox(height: _kDotsSlotH),

                  const SizedBox(height: _kGapH),

                  // action button — login submit
                  VezGlass.circleButton(
                    assetIcon: 'assets/icons/auth/icon_login.png',
                    iconSize:  30,
                    onTap:     _login,
                  ),

                  const SizedBox(height: _kBelowBtnH),

                  // navigate pill — go to signup
                  _AuthPillButton(
                    text:  StringRes.at('signup'),
                    onTap: () {
                      setState(() => _error = null);
                      Navigator.push(context, _fadeSlideRoute(const SignupPage()));
                    },
                  ),

                  const SizedBox(height: _kBottomPadH),
                ],
              ),
            ),
          ),

          // ── loading overlay ────────────────────────────────────────────
          if (_loading) const VezLoadingOverlay(),
        ],
      ),
    );
  }

  // ── logic ──────────────────────────────────────────────────────────────────

  /// returns true if the device has an active internet connection
  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

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

    setState(() { _error = null; _loading = true; });

    try {
      final int res = await _db.login(username: username, password: password);
      if (!mounted) return;
      setState(() => _loading = false);

      if (res == 200 || res == 201) {
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
      } else if (res == 401) {
        setState(() => _error = StringRes.at('invalid_credentials'));
      } else {
        setState(() => _error = '${StringRes.at("login_failed")}\n$res');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = StringRes.at('no_internet_connection'); });
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// shared auth-screen sub-widgets
// (defined here; signup_screen.dart imports them or redeclares its own copies)
// ─────────────────────────────────────────────────────────────────────────────

// ── _TitleBlock — large bold title + lighter subtitle ────────────────────────

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
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bottom,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white, fontSize: 25, fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ── _ErrorSlot — fixed-height container; content fades in/out via opacity ─────
//
// using a fixed SizedBox instead of AnimatedSize prevents the error banner
// from shifting the action button and pill button when it appears or disappears.

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
          opacity:  message != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve:    Curves.easeOut,
          child: message != null
              ? VezErrorBanner(message: message!)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ── _AuthPillButton — frosted-glass pill button where text scales to fit ──────
//
// ClipRRect + BackdropFilter creates the blur effect against the background.
// FittedBox with BoxFit.scaleDown shrinks the label when translations are long.

class _AuthPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _AuthPillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width * 0.40;
    return GestureDetector(
      onTap: onTap,
      // ClipRRect must wrap BackdropFilter so the blur is clipped to the pill shape
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
            // FittedBox scales the text down if wider than available space
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'InstagramSans',
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _fadeSlideRoute — lightweight custom page transition (fade + subtle slide)
//
// much lighter than the default MaterialPageRoute hero animation, works well
// on older devices. used for login ↔ signup navigation.
// ─────────────────────────────────────────────────────────────────────────────

Route<T> _fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration:        const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, __, ___) => page,
    transitionsBuilder: (_, animation, __, child) {
      // a very small x-offset keeps the motion subtle and cheap to render
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end:   Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));

      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);

      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
