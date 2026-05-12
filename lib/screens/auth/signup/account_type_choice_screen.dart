// Developed and Designed by Outly • 2026
// screen for choosing the account type before signup.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/translation_service.dart';
import 'signup_widgets.dart';
import 'user_signup_screen.dart';
import 'venue_signup_screen.dart';

// shows the user and venue signup choices.
class AccountTypeChoicePage extends StatelessWidget {
  const AccountTypeChoicePage({super.key});

  // builds the account type choice screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kAuthBlack,
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset('assets/images/bg/main_signup.jpg', fit: BoxFit.cover),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child:Column(
                children: [
                  const Spacer(flex: 2),
                  AuthTitleBlock(
                    title: StringRes.at('top_title_signup'),
                    subtitle: StringRes.at('under_title_signup'),
                  ),
                  const Spacer(flex: 3),
                  _ChoiceButton(
                    title: StringRes.at('account_type_user'),
                    subtitle: StringRes.at('account_type_user_hint'),
                    iconPath: 'assets/icons/auth/user.png',
                    onTap: () => Navigator.push(
                      context,
                      _fadeSlideRoute(const SignupPage()),
                    ),
                  ),
                  const SizedBox(height: 18),
                  _ChoiceButton(
                    title: StringRes.at('account_type_venue'),
                    subtitle: StringRes.at('account_type_venue_hint'),
                    iconPath: 'assets/icons/auth/venue.png',
                    onTap: () => Navigator.push(
                      context,
                      _fadeSlideRoute(const VenueSignupPage()),
                    ),
                  ),
                  const Spacer(flex: 4),
                  _AuthPillButton(
                    text: StringRes.at('login'),
                    onTap: () {
                      Navigator.pop(context);
                    },
                  ),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── auth pill button ─────────────────────────────────────────────────────────
//
//   used for: navigating between login and signup screens.
class _AuthPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _AuthPillButton({required this.text, required this.onTap});

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
              border: Border.all(color: Colors.white54, width: 3),
            ),
            child: FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                text,
                style: const TextStyle(
                  fontFamily: 'InstagramSans',
                  color: Colors.white,
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

// renders a blurred signup account choice button.
class _ChoiceButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final VoidCallback onTap;

  const _ChoiceButton({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.onTap,
  });

  // builds the account choice button.
  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.78;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: kBlurValue, sigmaY: kBlurValue),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 15),
            decoration: BoxDecoration(
              color: kAuthBlack20,
              borderRadius: BorderRadius.circular(30),
              border: Border.all(color: kAuthWhite50, width: 2),
            ),
            child: Row(
              children: [
                Image.asset(
                  iconPath,
                  width: 50,
                  height: 50,
                  color: kAuthWhite,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          color: kAuthWhite,
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          color: kAuthWhite70,
                          fontSize: 20,
                          fontWeight: FontWeight.normal,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// creates the shared auth route transition.
Route<T> _fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final Animation<Offset> slide = Tween<Offset>(
        begin: const Offset(0.06, 0),
        end: Offset.zero,
      ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOut));
      final Animation<double> fade = CurvedAnimation(
        parent: animation,
        curve: Curves.easeOut,
      );
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}
