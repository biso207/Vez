// Developed and Designed by Outly • 2026
// reusable widgets for the authentication signup flow.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../services/translation_service.dart';

const Color kAuthWhite = Color.fromARGB(255, 255, 255, 255);
const Color kAuthWhite80 = Color.fromARGB(204, 255, 255, 255);
const Color kAuthWhite70 = Color.fromARGB(179, 255, 255, 255);
const Color kAuthWhite50 = Color.fromARGB(128, 255, 255, 255);
const Color kAuthWhite30 = Color.fromARGB(77, 255, 255, 255);
const Color kAuthBlack = Color.fromARGB(255, 0, 0, 0);
const Color kAuthBlack20 = Color.fromARGB(51, 0, 0, 0);
const Color kAuthBlack45 = Color.fromARGB(115, 0, 0, 0);
const Color kAuthRed = Color.fromARGB(255, 255, 92, 92);
const double kBlurValue = 5.0;

// ── title block ──────────────────────────────────────────────────────────────
//
//   used for: displaying page headers with a main title and subtitle.
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
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white,
            fontSize: 40,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white,
            fontSize: 25,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// renders a glass text field with stronger focus feedback.
class AuthGlassTextField extends StatefulWidget {
  final TextEditingController controller;
  final String hint;
  final double width;
  final bool obscure;
  final int? maxLength;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final Widget? suffix;
  final VoidCallback? onTap;
  final bool readOnly;
  final void Function(String)? onChanged;

  const AuthGlassTextField({
    super.key,
    required this.controller,
    required this.hint,
    required this.width,
    this.obscure = false,
    this.maxLength,
    this.keyboardType,
    this.inputFormatters,
    this.suffix,
    this.onTap,
    this.readOnly = false,
    this.onChanged,
  });

  // creates the text field state.
  @override
  State<AuthGlassTextField> createState() => _AuthGlassTextFieldState();
}

// tracks focus state for auth text fields.
class _AuthGlassTextFieldState extends State<AuthGlassTextField> {
  final FocusNode _focusNode = FocusNode();

  // starts focus change listening.
  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() => setState(() {}));
  }

  // releases the focus node.
  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  // builds the focused glass text field.
  @override
  Widget build(BuildContext context) {
    final Color borderColor = _focusNode.hasFocus ? kAuthWhite80 : kAuthWhite50;
    return ClipRRect(
      borderRadius: BorderRadius.circular(22),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 160),
          width: widget.width,
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: kAuthBlack20,
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: borderColor, width: 2),
          ),
          child: Center(
            child: TextField(
              controller: widget.controller,
              focusNode: _focusNode,
              obscureText: widget.obscure,
              readOnly: widget.readOnly,
              maxLength: widget.maxLength,
              keyboardType: widget.keyboardType,
              inputFormatters: widget.inputFormatters,
              onTap: widget.onTap,
              onChanged: widget.onChanged,
              cursorColor: kAuthWhite,
              style: const TextStyle(
                fontFamily: 'InstagramSans',
                color: kAuthWhite,
                fontSize: 17,
                fontWeight: FontWeight.bold,
              ),
              decoration: InputDecoration(
                isCollapsed: true,
                border: InputBorder.none,
                counterText: '',
                hintText: widget.hint,
                hintStyle: const TextStyle(
                  fontFamily: 'InstagramSans',
                  color: kAuthWhite70,
                  fontSize: 17,
                  fontWeight: FontWeight.w600,
                ),
                suffixIcon: widget.suffix,
                suffixIconConstraints: const BoxConstraints(),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// shows a glass circular icon button.
class AuthCircleButton extends StatelessWidget {
  final String assetPath;
  final VoidCallback? onTap;
  final double size;
  final double iconSize;
  final double rotation;
  final bool enabled;

  const AuthCircleButton({
    super.key,
    required this.assetPath,
    required this.onTap,
    this.size = 48,
    this.iconSize = 24,
    this.rotation = 0,
    this.enabled = true,
  });

  // builds the circular glass button.
  @override
  Widget build(BuildContext context) {
    final Color borderColor = enabled ? kAuthWhite50 : kAuthWhite30;
    final Color iconColor = enabled ? kAuthWhite : kAuthWhite50;
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
              color: kAuthBlack20,
              border: Border.all(color: borderColor, width: 1.5),
            ),
            child: Center(
              child: Transform.rotate(
                angle: rotation,
                child: Image.asset(
                  assetPath,
                  width: iconSize,
                  height: iconSize,
                  color: iconColor,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// shows the chosen profile photo or a camera action.
class AuthProfilePicker extends StatelessWidget {
  final File? image;
  final VoidCallback onTap;

  const AuthProfilePicker({
    super.key,
    required this.image,
    required this.onTap,
  });

  // builds the profile picker.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 96,
        height: 96,
        child: Stack(
          alignment: Alignment.center,
          children: [
            AuthCircleButton(
              assetPath: 'assets/icons/auth/icon_camera_90x90.png',
              onTap: onTap,
              size: 96,
              iconSize: 50,
            ),
            if (image != null)
              ClipOval(
                child: Image.file(
                  image!,
                  width: 96,
                  height: 96,
                  fit: BoxFit.cover,
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// shows the signup progress dots.
class AuthStepDots extends StatelessWidget {
  final int currentPage;
  final int total;

  const AuthStepDots({
    super.key,
    required this.currentPage,
    required this.total,
  });

  // builds the progress indicator dots.
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (int index) {
        final bool active = index == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 260),
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? kAuthWhite : kAuthWhite30,
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// reserves a stable area for auth errors.
class AuthErrorSlot extends StatelessWidget {
  final String? message;

  const AuthErrorSlot({super.key, required this.message});

  // builds the animated error area.
  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 56,
      child: AnimatedOpacity(
        opacity: message == null ? 0 : 1,
        duration: const Duration(milliseconds: 220),
        child: message == null
            ? const SizedBox.shrink()
            : AuthErrorBanner(message: message!),
      ),
    );
  }
}

// renders a compact glass error banner.
class AuthErrorBanner extends StatelessWidget {
  final String message;

  const AuthErrorBanner({super.key, required this.message});

  // builds the error banner content.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
            decoration: BoxDecoration(
              color: kAuthBlack45,
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kAuthWhite50, width: 1.5),
            ),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontFamily: 'InstagramSans',
                color: kAuthWhite,
                fontSize: 14,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// shows a tappable underlined resend otp action.
class AuthResendOtpButton extends StatelessWidget {
  final VoidCallback onTap;

  const AuthResendOtpButton({super.key, required this.onTap});

  // builds the resend otp text button.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Text(
        StringRes.at('resend_otp_code'),
        style: const TextStyle(
          fontFamily: 'InstagramSans',
          color: kAuthWhite70,
          fontSize: 20,
          fontWeight: FontWeight.bold,
          decoration: TextDecoration.underline,
          decorationColor: kAuthWhite70,
        ),
      ),
    );
  }
}

// blocks interaction while the auth flow is loading.
class AuthLoadingOverlay extends StatelessWidget {
  const AuthLoadingOverlay({super.key});

  // builds the loading overlay.
  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Container(
        color: kAuthBlack45,
        child: const Center(
          child: CircularProgressIndicator(color: kAuthWhite, strokeWidth: 2),
        ),
      ),
    );
  }
}

// shows the cancellation confirmation content.
class AuthCancelPopupContent extends StatelessWidget {
  final VoidCallback onCancel;
  final VoidCallback onConfirm;

  const AuthCancelPopupContent({
    super.key,
    required this.onCancel,
    required this.onConfirm,
  });

  // builds the popup content.
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            StringRes.at('cancel_signup_title'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'InstagramSans',
              color: kAuthWhite,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            StringRes.at('cancel_signup_message'),
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontFamily: 'InstagramSans',
              color: kAuthWhite70,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 22),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AuthCircleButton(
                assetPath: 'assets/icons/event/cancel.png',
                onTap: onCancel,
              ),
              const SizedBox(width: 32),
              AuthCircleButton(
                assetPath: 'assets/icons/event/confirm.png',
                onTap: onConfirm,
              ),
            ],
          ),
        ],
      ),
    );
  }
}
