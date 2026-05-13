// Developed and Designed by Outly • © 2026
// blocked account screen shown when a suspended user tries to access the app.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/translation_service.dart';
import 'login_screen.dart';

// ── blocked account page ─────────────────────────────────────────────────────
//
//   used for: displaying a locked access state for blocked accounts.
class BlockedAccount extends StatelessWidget {
  const BlockedAccount({super.key});

  // builds the blocked account screen.
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: const Color.fromARGB(255, 0, 0, 0),
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg/blocked_account.jpg',
              fit: BoxFit.cover,
            ),
          ),

          // dark overlay for better readability
          Positioned.fill(
            child: Container(
              color: const Color.fromARGB(90, 0, 0, 0),
            ),
          ),

          SafeArea(
            child: SizedBox(
              width: sw,
              height: sh,
              child: Column(
                children: [
                  const SizedBox(height: 70),

                  // title section
                  Text(
                    StringRes.at('blocked_account'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'InstagramSans',
                      fontSize: 38,
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 255, 255, 255),
                    ),
                  ),

                  const SizedBox(height: 10),

                  Text(
                    StringRes.at('this_account_is_blocked'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontFamily: 'InstagramSans',
                      fontSize: 18,
                      fontWeight: FontWeight.w400,
                      color: Color.fromARGB(220, 255, 255, 255),
                    ),
                  ),

                  const Spacer(),

                  // support section
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 35),
                    child: Column(
                      children: [
                        Text(
                          StringRes.at('write_to'),
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'InstagramSans',
                            fontSize: 20,
                            fontWeight: FontWeight.w500,
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),

                        const SizedBox(height: 10),

                        Text(
                          'outly.services@gmail.com',
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontFamily: 'InstagramSans',
                            fontSize: 19,
                            fontWeight: FontWeight.bold,
                            color: Color.fromARGB(255, 255, 255, 255),
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
                            color: Color.fromARGB(255, 255, 255, 255),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  // close button
                  _CloseButton(
                    onTap: () {
                      Navigator.pushAndRemoveUntil(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const LoginPage(),
                        ),
                            (_) => false,
                      );
                    },
                  ),

                  const SizedBox(height: 55),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── glass close button ───────────────────────────────────────────────────────
//
//   used for: closing the blocked account screen and returning to login.
class _CloseButton extends StatelessWidget {
  final VoidCallback onTap;

  const _CloseButton({required this.onTap});

  // builds the bottom glass styled button.
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: 10,
            sigmaY: 10,
          ),
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
                  color: Color.fromARGB(255, 255, 255, 255),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}