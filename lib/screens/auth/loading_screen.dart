// Developed and Designed by Outly • © 2026
// Screen to manage the app's loading process

import 'package:flutter/material.dart';
import '../../services/user_session.dart';
import '../home_screen.dart';
import '../../services/translation_service.dart';
import 'login_screen.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  // Variabili per gestire gli stati dell'animazione
  bool _showLogo = false;
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    _bootstrapApp();
  }

  Future<void> _bootstrapApp() async {
    await UserSession().restore();

    if (UserSession().locale.isNotEmpty) {
      StringRes.setLocale(UserSession().locale);
    } else {
      StringRes.initLocale();
    }

    await startAppAnimations();
  }

  Future<void> startAppAnimations() async {
    // 1. Pausa iniziale
    await Future.delayed(const Duration(milliseconds: 500));
    if (!mounted) return;

    // 2. Avvia l'animazione "all-in-one"
    setState(() {
      _showLogo = true;
    });

    // 3. Mantieni visibile il logo completo "VEZ"
    await Future.delayed(const Duration(milliseconds: 2500));
    if (!mounted) return;

    // 4. Inizia a far sparire tutto (fade-out) con un leggero zoom
    setState(() {
      _fadeOut = true;
    });

    // 5. Attendi la fine dell'animazione di scomparsa
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    final Widget destination = UserSession().isLoggedIn
        ? const HomePage()
        : const LoginPage();

    // 6. Naviga verso la schermata iniziale corretta
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

  // --- PAGE LAYOUT ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sfondo tutto nero
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
                // Effetto "da sinistra a destra": allineiamo a sinistra e espandiamo il width factor.
                // Questo fa sì che il logo appaia gradualmente dalla sinistra verso la destra.
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
