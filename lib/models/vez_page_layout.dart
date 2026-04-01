// Developed and Designed by Outly • © 2026
// Class to manage the layout of the app's pages

import 'package:flutter/material.dart';

class VezPageLayout extends StatelessWidget {
  final Widget body;
  final Widget? topNavBar;
  final Widget? bottomNavBar;

  const VezPageLayout({
    super.key,
    required this.body,
    this.topNavBar,
    this.bottomNavBar,
  });

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF0E0E0E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          /// 1) Sfondo Globale: (Già impostato dal backgroundColor dello Scaffold)

          /// 2) Contenuto Centrale (Es. Scroll Eventi)
          Positioned.fill(child: body),

          /// 3) Overground: Gradienti Top e Bottom (Il "Fake Progressive Blur")
          // Gradiente Alto
          Positioned(
            top: 0, left: 0, right: 0,
            height: 150, // Altezza sfumatura
            child: IgnorePointer( // Non blocca i tocchi per lo scroll
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [bgColor, Colors.transparent],
                    stops: [0.3, 1.0], // Il colore solido copre fino al 30%, poi sfuma
                  ),
                ),
              ),
            ),
          ),

          // Gradiente Basso
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 150,
            child: IgnorePointer(
              child: Container(
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [bgColor, Colors.transparent],
                    stops: [0.2, 1.0],
                  ),
                ),
              ),
            ),
          ),

          /// 4) Navbars (Livello più alto)
          if (topNavBar != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 10,
              left: 20, right: 20,
              child: topNavBar!,
            ),

          if (bottomNavBar != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0,
              child: Center(child: bottomNavBar!),
            ),
        ],
      ),
    );
  }
}