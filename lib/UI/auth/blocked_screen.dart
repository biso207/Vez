// Developed and Designed by Outly • © 2026
// blocked account screen shown when a suspended user tries to access the app.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/translation_service.dart';
import 'login_screen.dart';
import 'signup/signup_widgets.dart';

// ── blocked account page ──────────────────────────────────────────────────────
//
//   displays a locked-access state for suspended accounts.
class BlockedAccount extends StatelessWidget {
  const BlockedAccount({super.key});

  // builds the blocked account screen.
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;

    return Scaffold(
      backgroundColor: kAuthBlack,
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg/blocked_account.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // dark overlay to improve text legibility
          Positioned.fill(
            child: Container(color: const Color.fromARGB(90, 0, 0, 0)),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── top: title at fixed distance from safe-area ──────────────
                const SizedBox(height: kAuthTopPad),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kAuthHPad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        StringRes.at('blocked_account'),
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
                        StringRes.at('this_account_is_blocked'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          fontSize: 25,
                          fontWeight: FontWeight.normal,
                          color: kAuthWhite,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── center: support contact info ─────────────────────────────
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: kAuthHPad),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        StringRes.at('write_to'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: kAuthWhite,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        'outly.services@gmail.com',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: kAuthWhite,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        StringRes.at('request_unlock_account'),
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: kAuthWhite,
                        ),
                      ),
                    ],
                  ),
                ),
                const Spacer(),

                // ── bottom: close button at fixed distance from bottom ────────
                _CloseButton(
                  onTap: () {
                    Navigator.pushAndRemoveUntil(
                      context,
                      MaterialPageRoute(builder: (_) => const LoginPage()),
                      (_) => false,
                    );
                  },
                ),
                const SizedBox(height: kAuthBottomPad),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── close button ──────────────────────────────────────────────────────────────
//
//   frosted-glass pill button that returns the user to the login screen.
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  // builds the glass close button.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            width: 130,
            height: 52,
            decoration: BoxDecoration(
              color: const Color.fromARGB(70, 255, 255, 255),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(
                color: const Color.fromARGB(170, 255, 255, 255),
                width: 2.2,
              ),
            ),
            child: Center(
              child: Text(
                StringRes.at('close'),
                style: const TextStyle(
                  fontFamily: 'InstagramSans',
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: kAuthWhite,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
