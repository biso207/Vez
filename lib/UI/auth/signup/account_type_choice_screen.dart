// Developed and Designed by Outly • © 2026
// screen for choosing the account type before signup.

import 'dart:ui';

import 'package:flutter/material.dart';

import '../../../services/translation_service.dart';
import 'signup_widgets.dart';
import 'user_signup_screen.dart';
import 'venue_signup_screen.dart';

// ── account type choice page ──────────────────────────────────────────────────
//
//   shows the user and venue signup choices.
class AccountTypeChoicePage extends StatelessWidget {
  const AccountTypeChoicePage({super.key});

  // builds the account type choice screen.
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kAuthBlack,
      body: Stack(
        fit: StackFit.expand,
        children: [
          // background image
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg/main_signup.jpg',
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── top: title at fixed distance from safe-area ──────────────
                const SizedBox(height: kAuthTopPad),
                TitleBlock(
                  title: StringRes.at('top_title_signup'),
                  subtitle: StringRes.at('under_title_signup'),
                ),

                // ── center: account type choices ─────────────────────────────
                const Spacer(),
                _AccountTypeButton(
                  title: StringRes.at('account_type_user'),
                  subtitle: StringRes.at('account_type_user_hint'),
                  iconPath: 'assets/icons/auth/user.png', // TODO: modify the path here
                  onTap: () => Navigator.push(
                    context,
                    authFadeSlideRoute(const SignupPage()),
                  ),
                ),
                const SizedBox(height: 18),
                _AccountTypeButton(
                  title: StringRes.at('account_type_venue'),
                  subtitle: StringRes.at('account_type_venue_hint'),
                  iconPath: 'assets/icons/auth/venue.png', // TODO: modify the path here
                  onTap: () => Navigator.push(
                    context,
                    authFadeSlideRoute(const VenueSignupPage()),
                  ),
                ),
                const Spacer(),

                // ── bottom: back to login pill at fixed distance ──────────────
                AuthPillButton(
                  text: StringRes.at('login'),
                  onTap: () => Navigator.pop(context),
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

// ── account type button ───────────────────────────────────────────────────────
//
//   frosted-glass card the user taps to choose between user and venue signup.
//   title: white 100 %, bold, 30 pt.
//   subtitle: white 70 %, normal, 20 pt.
class _AccountTypeButton extends StatelessWidget {
  final String title;
  final String subtitle;
  final String iconPath;
  final VoidCallback onTap;

  const _AccountTypeButton({
    required this.title,
    required this.subtitle,
    required this.iconPath,
    required this.onTap,
  });

  // builds the account type frosted card.
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
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: kAuthWhite50, width: 2),
            ),
            child: Row(
              children: [
                Image.asset(
                  iconPath, // TODO: modify the path here
                  width: 60,
                  height: 60,
                  color: kAuthWhite,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // title: white 100 %, bold, 30 pt
                      Text(
                        title,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          color: kAuthWhite,          // white 100 %
                          fontSize: 30,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      // subtitle: white 70 %, normal, 20 pt
                      Text(
                        subtitle,
                        style: const TextStyle(
                          fontFamily: 'InstagramSans',
                          color: kAuthWhite70,         // white 70 %
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
