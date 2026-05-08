// Developed and Designed by Outly • © 2026
// screen to manage the app's loading process.

import 'package:flutter/material.dart';
import '../services/notification_service.dart';
import '../services/auth_service.dart';
import '../services/user_session.dart';
import 'home/home_screen.dart';
import '../services/translation_service.dart';
import 'auth/login_screen.dart';
import 'auth/venue_pending_screen.dart';

// ── loading page ─────────────────────────────────────────────────────────────
//
//   used for: standardizing the initial loading state of the app.
class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

// ── loading page state ───────────────────────────────────────────────────────
//
//   used for: handling app bootstrap, animations, and initial routing.
class _LoadingPageState extends State<LoadingPage> {
  bool _showLogo = false;
  bool _fadeOut = false;

  // ── init state ─────────────────────────────────────────────────────────────
  //
  //   used for: starting the bootstrap process.
  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  // ── bootstrap app ──────────────────────────────────────────────────────────
  //
  //   used for: initializing session, locale, and notifications.
  Future<void> _bootstrapApp() async {
    await UserSession().restore();

    if (UserSession().locale.isNotEmpty) {
      StringRes.setLocale(UserSession().locale);
    } else {
      StringRes.initLocale();
    }

    await NotificationService().syncTokenForCurrentUser();
    await RemoteDbService().refreshCurrentAccountStatus();

    await startAppAnimations();
  }

  // ── start app animations ───────────────────────────────────────────────────
  //
  //   used for: orchestrating the brand intro animation and navigation.
  Future<void> startAppAnimations() async {
    // 1. Initial pause
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 2. Start "all-in-one" animation
    setState(() {
      _showLogo = true;
    });

    // 3. Keep full "VEZ" logo visible
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // 4. Start fade-out with a slight zoom
    setState(() {
      _fadeOut = true;
    });

    // 5. Wait for disappearance animation to end
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final session = UserSession();
    final Widget destination = session.isLoggedIn
        ? session.accountType == 'venue' && session.accountState != 'active'
              ? const VenuePendingPage()
              : const HomePage()
        : const LoginPage();

    // 6. Navigate to correct initial screen
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => destination,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  // ── build ──────────────────────────────────────────────────────────────────
  //
  //   used for: rendering the animated splash screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 1000),
          opacity: _fadeOut ? 0.0 : (_showLogo ? 1.0 : 0.0),
          curve: Curves.easeInOut,
          child: AnimatedScale(
            duration: const Duration(milliseconds: 1000),
            scale: _fadeOut ? 1.3 : 1.0,
            curve: Curves.easeInOut,
            child: ClipRect(
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 1800),
                alignment: Alignment.centerLeft,
                widthFactor: _showLogo ? 1.0 : 0.0,
                curve: Curves.easeInOutQuart,
                child: const Text(
                  "Vez",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 200,
                    fontFamily: 'JollyLodger',
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
