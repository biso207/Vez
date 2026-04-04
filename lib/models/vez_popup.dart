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
      transitionDuration: const Duration(milliseconds: 300),
      pageBuilder: (context, animation, secondaryAnimation) {
        return Align(
          alignment: alignment,
          child: Padding(
            padding: const EdgeInsets.only(bottom: 100), // Lo solleva un po' dal fondo se usi bottomCenter
            child: Material(
              color: Colors.transparent,
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Container(
                  width: width,
                  height: height,
                  padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 10), // Padding interno
                  decoration: BoxDecoration(
                    color: backgroundColor ?? const Color(0xFF0E0E0E).withOpacity(0.8),
                    borderRadius: BorderRadius.circular(40),
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
        // Animazione di comparsa morbida (fade + leggero zoom)
        return FadeTransition(
          opacity: animation,
          child: ScaleTransition(
            scale: Tween<double>(begin: 0.95, end: 1.0).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)
            ),
            child: child,
          ),
        );
      },
    );
  }
}