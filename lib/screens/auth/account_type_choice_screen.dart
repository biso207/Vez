import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/translation_service.dart';
import '../../views/widgets/vez_glass.dart';
import 'signup/user_signup_screen.dart';
import 'signup/venue_signup_screen.dart';

class AccountTypeChoicePage extends StatelessWidget {
  const AccountTypeChoicePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg/bg_signup.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                const Spacer(flex: 2),
                Text(
                  StringRes.at('choose_account_type'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'InstagramSans',
                    color: Colors.white,
                    fontSize: 36,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  StringRes.at('choose_account_type_hint'),
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontFamily: 'InstagramSans',
                    color: Colors.white70,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(flex: 3),
                _ChoiceCard(
                  title: StringRes.at('account_type_user'),
                  subtitle: StringRes.at('account_type_user_hint'),
                  icon: Icons.person_rounded,
                  onTap: () => Navigator.push(
                    context,
                    _fadeSlideRoute(const SignupPage()),
                  ),
                ),
                const SizedBox(height: 18),
                _ChoiceCard(
                  title: StringRes.at('account_type_venue'),
                  subtitle: StringRes.at('account_type_venue_hint'),
                  icon: Icons.storefront_rounded,
                  onTap: () => Navigator.push(
                    context,
                    _fadeSlideRoute(const VenueSignupPage()),
                  ),
                ),
                const Spacer(flex: 4),
                VezGlass.circleButton(
                  assetIcon: 'assets/icons/auth/icon_next.png',
                  rotation: 3.1416,
                  onTap: () => Navigator.pop(context),
                ),
                const SizedBox(height: 36),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String subtitle;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double width = MediaQuery.of(context).size.width * 0.78;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(28),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: width,
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
            decoration: BoxDecoration(
              color: const Color.fromARGB(51, 255, 255, 255),
              borderRadius: BorderRadius.circular(28),
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: Row(
              children: [
                Icon(icon, color: Colors.white, size: 36),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        title,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        subtitle,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: Colors.white70),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Route<T> _fadeSlideRoute<T>(Widget page) {
  return PageRouteBuilder<T>(
    transitionDuration: const Duration(milliseconds: 280),
    reverseTransitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, animation, secondaryAnimation) => page,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
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
