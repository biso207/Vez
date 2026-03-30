import 'dart:ui';
import 'package:flutter/material.dart';

/// =======================================================
/// VEZ GLASS DESIGN SYSTEM
/// Reusable components across the whole app
/// =======================================================

class VezGlass {

  /// default blur used everywhere
  static const double blur = 5;

  /// border style (2px white 50%)
  static Border border = Border.all(
    color: Colors.white.withOpacity(.5),
    width: 2,
  );

  /// ---------------------------------------------------
  /// Glass container (background blur)
  /// ---------------------------------------------------
  static Widget container({
    required Widget child,
    BorderRadius radius = const BorderRadius.all(Radius.circular(30)),
    EdgeInsets padding = const EdgeInsets.symmetric(
        horizontal: 18, vertical: 14),
    Color? color,
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
            color: color ?? Colors.black.withOpacity(.5),
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
    double size = 50,
    double iconSize = 30,
    double rotation = 0,
    Color? color,
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
              color: color ?? Colors.black.withOpacity(.5),
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
  /// Glass pill button for page switching
  /// ---------------------------------------------------
  static Widget pillButton({
    required String text,
    required VoidCallback onTap,
    Color? color,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 100,
        height: 30,
        child: container(
          color: color ?? Colors.black.withOpacity(.5),
          padding: EdgeInsets.zero,
          radius: BorderRadius.circular(15),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// ---------------------------------------------------
  /// Glass text field
  /// ---------------------------------------------------
  static Widget textField(
      {
        required TextEditingController controller,
        required String hint,
        bool obscure = false,

        double? width,
        double height = 44,
        BorderRadius? radius,

        double fontSize = 20,
        FontWeight fontWeight = FontWeight.bold,

        EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 18),

        Widget? suffixIcon, required Color color, // optional trailing widget (e.g. eye toggle)
      }
    )
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
            style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: fontWeight
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              hintText: hint,
              hintStyle: TextStyle(
                  color: Colors.white,
                  fontSize: fontSize,
                  fontWeight: fontWeight
              ),
              suffixIcon: suffixIcon,
              suffixIconConstraints: const BoxConstraints(),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Shared UI Widgets ───────────────────────────────────────────────────────

/// Glassy inline error banner with a leading error icon.
/// Wrap in [AnimatedSize] for smooth height transitions.
class VezErrorBanner extends StatelessWidget {
  final String message;
  const VezErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return VezGlass.container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      radius: BorderRadius.circular(20),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, color: Colors.redAccent, size: 18),
          const SizedBox(width: 8),
          Text(
            message,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}

/// Full-screen semi-transparent loading overlay with a white spinner.
class VezLoadingOverlay extends StatelessWidget {
  const VezLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: Colors.black.withOpacity(0.45),
        child: const Center(
          child: CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          ),
        ),
      ),
    );
  }
}
