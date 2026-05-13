// Developed and Designed by Outly • © 2026
// shared widgets, constants and tokens for every authentication screen.

import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/translation_service.dart';

// ── global layout constants ──────────────────────────────────────────────────
//   fixed spacing values shared across every auth screen.

/// vertical space from safe-area top edge down to the title block.
const double kAuthTopPad = 60.0;

/// vertical space from the last bottom button down to the screen bottom.
const double kAuthBottomPad = 50.0;

/// horizontal padding used for full-width sections and error slots.
const double kAuthHPad = 28.0;

/// vertical gap between stacked input fields.
const double kAuthFieldGap = 18.0;

/// vertical gap between elements in the bottom control row.
const double kAuthBottomGap = 18.0;

/// reserved slot height for the step-dots row (keeps login aligned with signup).
const double kAuthDotsSlotH = 24.0;

/// reserved slot height for the error banner (prevents layout jumps).
const double kAuthErrorSlotH = 56.0;

/// backdrop blur sigma applied uniformly to every glass button.
const double kBlurValue = 5.0;

// ── color tokens ─────────────────────────────────────────────────────────────
const Color kAuthBlack    = Color.fromARGB(255, 0,   0,   0  );
const Color kAuthWhite    = Color.fromARGB(255, 255, 255, 255);
const Color kAuthWhite70  = Color.fromARGB(178, 255, 255, 255); // 70 % opacity
const Color kAuthWhite50  = Color.fromARGB(128, 255, 255, 255); // 50 % opacity
const Color kAuthBlack20  = Color.fromARGB(51,  0,   0,   0  ); // black  20 %
const Color kAuthWhite20  = Color.fromARGB(51,  255, 255, 255); // white  20 % – OTP only

// ── title block ──────────────────────────────────────────────────────────────
//
//   renders the page header (big title + descriptive subtitle).
//   font sizes are fixed: title → 40 bold, subtitle → 25 normal.
class TitleBlock extends StatelessWidget {
  final String title;
  final String subtitle;

  const TitleBlock({super.key, required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontSize: 40,
            fontWeight: FontWeight.bold,
            color: kAuthWhite,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontSize: 25,
            fontWeight: FontWeight.normal,
            color: kAuthWhite,
          ),
        ),
      ],
    );
  }
}

// ── auth glass text field ─────────────────────────────────────────────────────
//
//   frosted-glass input field used on every auth step.
//   background is black-20 by default; set isOtp=true for the OTP field (white-20).
//   font is always 20 / bold per design spec.
class AuthGlassTextField extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final double width;
  final bool obscure;
  final bool readOnly;
  final bool isOtp;             // white-20 background instead of black-20
  final Widget? suffix;
  final TextInputType keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final VoidCallback? onTap;

  const AuthGlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.width,
    this.obscure = false,
    this.readOnly = false,
    this.isOtp = false,
    this.suffix,
    this.keyboardType = TextInputType.text,
    this.inputFormatters,
    this.maxLength,
    this.onTap,
  });

  // chooses fill color based on field type.
  Color get _fillColor => isOtp ? kAuthWhite20 : kAuthBlack20;

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(40),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: SizedBox(
          width: width,
          child: TextField(
            controller: controller,
            obscureText: obscure,
            readOnly: readOnly,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            onTap: onTap,
            style: const TextStyle(
              fontFamily: 'InstagramSans',
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: kAuthWhite,
            ),
            textAlign: TextAlign.center,
            decoration: InputDecoration(
              hintText: hint,
              hintStyle: const TextStyle(
                fontFamily: 'InstagramSans',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: kAuthWhite50,
              ),
              counterText: '',
              suffixIcon: suffix,
              filled: true,
              fillColor: _fillColor,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(40),
                borderSide: BorderSide.none,
              ),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 24,
                vertical: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── auth profile picker ───────────────────────────────────────────────────────
//
//   circular photo picker shown on step 1 of the signup flow.
//   always uses icon_camera.png as placeholder icon.
class AuthProfilePicker extends StatelessWidget {
  final dynamic image; // File? or XFile? depending on project setup
  final VoidCallback onTap;
  final double size;

  const AuthProfilePicker({
    super.key,
    required this.image,
    required this.onTap,
    this.size = 100,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: kAuthBlack20,
              border: Border.all(color: kAuthWhite50, width: 2),
            ),
            child: image != null
                ? ClipOval(
                    // renders the selected photo.
                    child: Image.file(image, fit: BoxFit.cover),
                  )
                : Center(
                    child: Image.asset(
                      'assets/icons/icon_camera.png', // TODO: modify the path here
                      width: size * 0.45,
                      height: size * 0.45,
                      color: kAuthWhite70,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

// ── auth circle button ────────────────────────────────────────────────────────
//
//   round frosted-glass icon button used for navigation (next, back, close).
class AuthCircleButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback onTap;
  final double size;
  final double iconSize;
  final double rotation;  // radians; 0 = no rotation
  final bool enabled;

  const AuthCircleButton({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.size = 62,
    this.iconSize = 28,
    this.rotation = 0,
    this.enabled = true,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: ClipOval(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            width: size,
            height: size,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: enabled
                  ? kAuthWhite20
                  : const Color.fromARGB(25, 255, 255, 255),
              border: Border.all(
                color: enabled ? kAuthWhite50 : kAuthWhite20,
                width: 2,
              ),
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: Image.asset(
                  assetPath, // TODO: modify the path here
                  width: iconSize,
                  height: iconSize,
                  color: enabled ? kAuthWhite : kAuthWhite50,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── auth pill button ──────────────────────────────────────────────────────────
//
//   wide pill-shaped frosted-glass button used to switch between login/signup.
class AuthPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const AuthPillButton({super.key, required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width * 0.40;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            width: w,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(51, 255, 255, 255),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: kAuthWhite50, width: 3),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'InstagramSans',
                  color: kAuthWhite,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── auth error slot ───────────────────────────────────────────────────────────
//
//   fixed-height container that reserves space for error banners.
//   animates in/out to prevent layout shifts.
class AuthErrorSlot extends StatelessWidget {
  final String? message;

  const AuthErrorSlot({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: kAuthHPad),
      child: SizedBox(
        height: kAuthErrorSlotH,
        child: AnimatedOpacity(
          opacity: message != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: message != null
              ? _ErrorBanner(message: message!)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// renders the frosted error pill banner.
class _ErrorBanner extends StatelessWidget {
  final String message;

  const _ErrorBanner({required this.message});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: BoxDecoration(
            color: const Color.fromARGB(80, 200, 50, 50),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color.fromARGB(120, 255, 80, 80),
              width: 1.5,
            ),
          ),
          child: Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'InstagramSans',
              fontSize: 15,
              fontWeight: FontWeight.w500,
              color: kAuthWhite,
            ),
          ),
        ),
      ),
    );
  }
}

// ── auth step dots ────────────────────────────────────────────────────────────
//
//   page indicator used in the multi-step signup flow.
class AuthStepDots extends StatelessWidget {
  final int currentPage;
  final int total;

  const AuthStepDots({
    super.key,
    required this.currentPage,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: kAuthDotsSlotH,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: List.generate(total, (i) {
          final bool active = i == currentPage;
          return AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            margin: const EdgeInsets.symmetric(horizontal: 5),
            width: active ? 22 : 8,
            height: 8,
            decoration: BoxDecoration(
              color: active ? kAuthWhite : kAuthWhite50,
              borderRadius: BorderRadius.circular(4),
            ),
          );
        }),
      ),
    );
  }
}

// ── auth resend otp button ────────────────────────────────────────────────────
//
//   small text button that lets the user resend the OTP code.
class AuthResendOtpButton extends StatelessWidget {
  final VoidCallback onTap;

  const AuthResendOtpButton({super.key, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        StringRes.at('resend_otp'),
        style: const TextStyle(
          fontFamily: 'InstagramSans',
          fontSize: 16,
          fontWeight: FontWeight.w500,
          color: kAuthWhite70,
          decoration: TextDecoration.underline,
          decorationColor: kAuthWhite70,
        ),
      ),
    );
  }
}

// ── auth cancel popup content ─────────────────────────────────────────────────
//
//   content shown inside a popup when the user taps the close button mid-signup.
class AuthCancelPopupContent extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const AuthCancelPopupContent({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          StringRes.at('cancel_signup_title'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: kAuthWhite,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          StringRes.at('cancel_signup_body'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            fontSize: 16,
            fontWeight: FontWeight.normal,
            color: kAuthWhite70,
          ),
        ),
        const SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _PopupAction(
              label: StringRes.at('cancel'),
              onTap: onCancel,
              primary: false,
            ),
            _PopupAction(
              label: StringRes.at('confirm'),
              onTap: onConfirm,
              primary: true,
            ),
          ],
        ),
      ],
    );
  }
}

// renders a single popup action button.
class _PopupAction extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  final bool primary;

  const _PopupAction({
    required this.label,
    required this.onTap,
    required this.primary,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(30),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 10),
            decoration: BoxDecoration(
              color: primary
                  ? const Color.fromARGB(80, 200, 50, 50)
                  : kAuthWhite20,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: primary
                    ? const Color.fromARGB(160, 255, 80, 80)
                    : kAuthWhite50,
                width: 1.5,
              ),
            ),
            child: Text(
              label,
              style: const TextStyle(
                fontFamily: 'InstagramSans',
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: kAuthWhite,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── auth loading overlay ──────────────────────────────────────────────────────
//
//   full-screen frosted overlay shown during async operations.
class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
        child: Container(
          color: const Color.fromARGB(80, 0, 0, 0),
          child: const Center(
            child: CircularProgressIndicator(
              color: kAuthWhite,
              strokeWidth: 2.5,
            ),
          ),
        ),
      ),
    );
  }
}

// ── fade-slide page route ─────────────────────────────────────────────────────
//
//   shared page transition for navigating between auth screens.
Route<T> authFadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (_, animation, __) => page,
    transitionsBuilder: (_, animation, __, child) {
      final slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
