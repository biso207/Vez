// Developed and Designed by Outly • © 2026
// Screen to manage the app's loading process

import 'package:flutter/material.dart';
import 'login_screen.dart';

class LoadingPage extends StatefulWidget {
  const LoadingPage({super.key});

  @override
  State<LoadingPage> createState() => _LoadingPageState();
}

class _LoadingPageState extends State<LoadingPage> {
  // Variabili per gestire gli stati dell'animazione
  bool _showEz = false;
  bool _fadeOut = false;

  @override
  void initState() {
    super.initState();
    startAppAnimations();
  }

  Future<void> startAppAnimations() async {
    // 1. Pausa iniziale: mostra solo la "V" per una frazione di secondo
    await Future.delayed(const Duration(milliseconds: 600));
    if (!mounted) return;

    // 2. Rivela la scritta "ez"
    setState(() {
      _showEz = true;
    });

    // 3. Mantieni visibile il logo completo "Vez" per farglielo leggere
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    // 4. Inizia a far sparire tutto (fade-out) con un leggero zoom
    setState(() {
      _fadeOut = true;
    });

    // 5. Attendi la fine dell'animazione di scomparsa
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;

    // 6. Naviga verso la LoginPage con una transizione in dissolvenza (fade)
    Navigator.pushReplacement(
      context,
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => const LoginPage(),
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Sfondo tutto nero
      body: Center(
        // Gestisce la scomparsa finale
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 800),
          opacity: _fadeOut ? 0.0 : 1.0,
          curve: Curves.easeInOut,
          // Crea un effetto dinamico ingrandendo leggermente mentre sparisce
          child: AnimatedScale(
            duration: const Duration(milliseconds: 800),
            scale: _fadeOut ? 1.3 : 1.0,
            curve: Curves.easeInOut,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // --- IL TUO LOGO "V" ---
                // Sostituisci questo Text con il tuo asset immagine, ad esempio:
                // Image.asset('assets/images/logo_v.png', height: 80),
                const Text(
                  'V',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 80,
                    fontWeight: FontWeight.bold,
                  ),
                ),

                // --- ANIMATION OF "ez" TEXT ---
                // ClipRect hide the text until the width is 0
                ClipRect(
                  child: AnimatedAlign(
                    duration: const Duration(milliseconds: 800),
                    curve: Curves.easeOutQuart, // animation curve
                    alignment: Alignment.centerLeft,
                    widthFactor: _showEz ? 1.0 : 0.0,
                    child: const Text(
                      'ez',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 80,
                        fontWeight: FontWeight.bold,
                      ),
                      maxLines: 1,
                      softWrap: false, // no new line
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}