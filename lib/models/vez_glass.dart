// Developed and Designed by Outly • © 2026
// Graphic models to create the UI elements of the app

import 'dart:ui';
import 'package:flutter/material.dart';

/// =======================================================
/// VEZ GLASS DESIGN SYSTEM
/// Reusable components across the whole app
/// =======================================================

class VezGlass {

  /// Default blur applied to every glass element
  static const double blur = 5;

  /// Shared border style: 3 px white at 50% opacity
  static Border border = Border.all(
    color: Colors.white54,
    width: 2,
  );

  /// ---------------------------------------------------
  /// Glass container (background blur)
  /// ---------------------------------------------------
  static Widget container({
    required Widget child,
    BorderRadius radius = const BorderRadius.all(Radius.circular(30)),
    EdgeInsets padding = const EdgeInsets.symmetric(
        horizontal: 30, vertical: 7),
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
            color: color ?? Color.fromARGB(51, 0, 0, 0),
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
    double? iconSize = 90,
    double rotation = 0,
    Color? color,
    bool isProfile = false, // Flag to handle profile photo rendering
  }) {
    final bool isRemote = assetIcon.startsWith('http');
    final bool isEmpty = assetIcon.isEmpty;

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
              color: color ?? const Color.fromARGB(102, 0, 0, 0),
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: isProfile
                    ? (isRemote
                        ? Image.network(
                            assetIcon,
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, stackTrace) =>
                                Image.asset("assets/icons/home_page/profile_photo.png", color: Colors.white),
                          )
                        : Image.asset(
                            isEmpty ? "assets/icons/home_page/profile_photo.png" : assetIcon,
                            width: size,
                            height: size,
                            fit: BoxFit.cover,
                            color: isEmpty ? Colors.white : null,
                          ))
                    : Image.asset(
                        isEmpty ? "assets/icons/home_page/profile_photo.png" : assetIcon,
                        width: iconSize,
                        color: (isEmpty || !assetIcon.contains('bg')) ? Colors.white : null,
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
    Color? color, int? fontSize,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 180,
        height: 50,
        child: container(
          color: color ?? Colors.black.withOpacity(.3),
          padding: EdgeInsets.zero,
          radius: BorderRadius.circular(40),
          child: Center(
            child: Text(
              text,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
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
  static Widget textField({
    required TextEditingController controller,
    required String hint,
    bool obscure = false,

    double? width,
    double height = 44,
    BorderRadius? radius,

    double fontSize = 20,
    FontWeight fontWeight = FontWeight.bold,

    EdgeInsets padding = const EdgeInsets.symmetric(horizontal: 18),

    Widget? prefixIcon,
    Widget? suffixIcon,
    required Color color,
    int? maxLength,
    void Function(String)? onChanged,
  }) {
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
            maxLength: maxLength, // 2. <-- PASSALO AL WIDGET NATIVO
            onChanged: onChanged, // 3. <-- PASSALO AL WIDGET NATIVO
            style: TextStyle(
                fontSize: fontSize,
                fontWeight: fontWeight,
                color: Colors.white
            ),
            decoration: InputDecoration(
              isCollapsed: true,
              border: InputBorder.none,
              counterText: "", // 4. <-- NASCONDE IL COUNTER DI DEFAULT SOTTO LA RIGA
              hintText: hint,
              hintStyle: TextStyle(
                  fontSize: fontSize,
                  fontWeight: fontWeight,
                  color: Colors.white60
              ),
              prefixIcon: prefixIcon,
              prefixIconConstraints: const BoxConstraints(),
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

/// Glassy error banner that grows to fit any number of lines.
///
/// Fix: replaced [IntrinsicWidth] + [Expanded] (incompatible combination that
/// prevented text from wrapping) with a plain [Row] using [Flexible] for the
/// [Text] child.  [Flexible] lets the text shrink/grow within the available
/// horizontal space without requiring an intrinsic-size pass.
class VezErrorBanner extends StatelessWidget {
  final String message;
  const VezErrorBanner({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return VezGlass.container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
      radius: BorderRadius.circular(35),
      child: Row(
        // Shrink-wrap horizontally but allow the text to fill remaining space
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start, // Align icon to first line
        children: [
          // Error icon pinned to the top of the first text line
          const Padding(
            padding: EdgeInsets.only(top: 2),
            child: Icon(Icons.error_outline, color: Colors.redAccent, size: 20),
          ),
          const SizedBox(width: 12),
          // [Flexible] (not [Expanded]) allows the text to wrap onto multiple
          // lines without conflicting with the parent's intrinsic-width layout.
          Flexible(
            child: Text(
              message,
              textAlign: TextAlign.left,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.w600,
                height: 1.3, // Comfortable line spacing for multi-line text
              ),
              softWrap: true,
              maxLines: null, // Unlimited lines — never truncate
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
