import 'dart:ui';
import 'package:flutter/material.dart';

/// =======================================================
/// VEZ GLASS DESIGN SYSTEM
/// Reusable components across the whole app
/// =======================================================

class VezGlass {

  /// default blur used everywhere
  static const double blur = 20;

  /// border style (1px white 50%)
  static Border border = Border.all(
    color: Colors.white.withOpacity(.5),
    width: 1,
  );

  /// ---------------------------------------------------
  /// Glass container (background blur)
  /// ---------------------------------------------------
  static Widget container({
    required Widget child,
    BorderRadius radius = const BorderRadius.all(Radius.circular(30)),
    EdgeInsets padding = const EdgeInsets.symmetric(
        horizontal: 18, vertical: 14),
  }) {
    return ClipRRect(
      borderRadius: radius,
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          padding: padding,
          decoration: BoxDecoration(
            borderRadius: radius,
            border: border,
            color: Colors.white.withOpacity(.05),
          ),
          child: child,
        ),
      ),
    );
  }

  /// ---------------------------------------------------
  /// Glass circular button
  /// ---------------------------------------------------
  static Widget circleButton({
    required String assetIcon,
    required VoidCallback onTap,
    double size = 48,
    double iconSize = 22,
    double rotation = 0,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: border,
              color: Colors.white.withOpacity(.05),
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: Image.asset(
                  assetIcon,
                  width: iconSize,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------------------------------------------
  /// Glass text field
  /// ---------------------------------------------------
  static Widget textField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,

    double? width,
    double height = 48,

    /// NEW
    BorderRadius? radius,

    EdgeInsets padding =
    const EdgeInsets.symmetric(horizontal: 18),
    })
  {
    final BorderRadius finalRadius =
        radius ?? BorderRadius.circular(height / 2);

    return SizedBox(
      width: width,
      height: height,
      child: container(
        radius: finalRadius,
        padding: padding,
        child: Center(
          child: TextField(
            controller: controller,
            obscureText: obscure,
            style: const TextStyle(color: Colors.white),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle:
              const TextStyle(color: Colors.white70),
            ),
          ),
        ),
      ),
    );
  }
}