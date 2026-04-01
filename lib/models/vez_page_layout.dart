import 'dart:ui';
import 'package:flutter/material.dart';

class VezPageLayout extends StatelessWidget {
  final Widget body;
  final Widget? topNavBar;
  final Widget? bottomNavBar;
  final double horizontalMargin; // <-- Il parametro della griglia

  const VezPageLayout({
    super.key,
    required this.body,
    this.topNavBar,
    this.bottomNavBar,
    this.horizontalMargin = 52, // <-- Margine standard di default (le tue linee blu)
  });

  @override
  Widget build(BuildContext context) {
    const Color bgColor = Color(0xFF0E0E0E);

    return Scaffold(
      backgroundColor: bgColor,
      body: Stack(
        children: [
          /// 1) Sfondo Globale: (Già impostato dal backgroundColor dello Scaffold)

          /// 2) Contenuto Centrale allineato alla Griglia
          Positioned(
            top: 0,
            bottom: 0,
            left: horizontalMargin,  // <-- Applica la linea blu di sinistra
            right: horizontalMargin, // <-- Applica la linea blu di destra
            child: body,
          ),

          /// 3) OVERGROUND: Blur Progressivo (Top) - Rimane a tutto schermo!
          Positioned(
            top: 0, left: 0, right: 0,
            height: 200,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.1, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [bgColor.withOpacity(0.8), Colors.transparent],
                        )
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// 4) OVERGROUND: Blur Progressivo (Bottom) - Rimane a tutto schermo!
          Positioned(
            bottom: 0, left: 0, right: 0,
            height: 200,
            child: IgnorePointer(
              child: ShaderMask(
                shaderCallback: (rect) {
                  return const LinearGradient(
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                    colors: [Colors.black, Colors.transparent],
                    stops: [0.1, 1.0],
                  ).createShader(rect);
                },
                blendMode: BlendMode.dstIn,
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [bgColor.withOpacity(0.8), Colors.transparent],
                        )
                    ),
                  ),
                ),
              ),
            ),
          ),

          /// 5) Navbars
          if (topNavBar != null)
            Positioned(
              top: MediaQuery.of(context).padding.top + 40,
              left: horizontalMargin,  // <-- Allineata alla griglia sx
              right: horizontalMargin, // <-- Allineata alla griglia dx
              child: topNavBar!,
            ),

          if (bottomNavBar != null)
            Positioned(
              bottom: MediaQuery.of(context).padding.bottom + 20,
              left: 0, right: 0, // Lasciato a 0 per permettere al Center di centrarla perfettamente nello schermo
              child: Center(child: bottomNavBar!),
            ),
        ],
      ),
    );
  }
}