import 'dart:ui';
import 'package:flutter/material.dart';

class VezPopup {
  static Future<T?> show<T>({
    required BuildContext context,
    required Widget child,
    double? width,
    double? height,
    Alignment alignment = Alignment.center, // spawn in the centre of the page
    Color? backgroundColor,
    Color? borderColor,
  }) {
    return showGeneralDialog<T>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'Dismiss',
      barrierColor: Colors.black.withOpacity(0.4),
      transitionDuration: const Duration(milliseconds: 350),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: alignment,
          child: Padding(
            padding: EdgeInsets.zero,
            child: Material(
              color: Colors.transparent,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: width,
                  height: height,
                  padding: const EdgeInsets.symmetric(vertical: 0, horizontal: 0), // Padding interno
                  decoration: BoxDecoration(
                    color: backgroundColor ?? const Color(0xFF0E0E0E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: borderColor ?? Colors.white54,
                      width: 2,
                    ),
                  ),
                  child: child,
                ),
              ),
            ),
          ),
        );
      },

      transitionBuilder: (context, animation, secondaryAnimation, child) {
        // 2. Curva con "rimbalzo" per la scala
        final scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOutBack, // Questo fa il "salto" in avanti e torna indietro
          ),
        );

        // 3. Dissolvenza leggermente più veloce
        final fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
          CurvedAnimation(
            parent: animation,
            curve: Curves.easeOut,
          ),
        );

        return FadeTransition(
          opacity: fadeAnimation,
          child: ScaleTransition(
            scale: scaleAnimation,
            child: child,
          ),
        );
      },
    );
  }
}