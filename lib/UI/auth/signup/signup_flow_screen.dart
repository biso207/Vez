// Developed and Designed by Outly • © 2026
// main screen that assembles the shared user and venue signup flow.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/account_type.dart';
import '../../../services/translation_service.dart';
import '../../../views/widgets/vez_popup.dart';
import '../../home/home_screen.dart';
import 'signup_controller.dart';
import 'signup_widgets.dart';

// ── signup flow screen ────────────────────────────────────────────────────────
//
//   displays the three-step signup flow for one account type.
class SignupFlowScreen extends StatefulWidget {
  final AccountType accountType;

  const SignupFlowScreen({super.key, required this.accountType});

  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

// ── signup flow screen state ──────────────────────────────────────────────────
//
//   coordinates the signup controller with the screen lifecycle.
class _SignupFlowScreenState extends State<SignupFlowScreen> {
  late final SignupFlowController _controller;

  // creates the controller for the selected account type.
  @override
  void initState() {
    super.initState();
    _controller = SignupFlowController(accountType: widget.accountType);
    _controller.addListener(_refresh);
  }

  // releases the controller when the screen is disposed.
  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  // triggers a rebuild when the controller state changes.
  void _refresh() {
    if (mounted) setState(() {});
  }

  // builds the signup flow screen.
  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double fieldWidth = sw * 0.75;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kAuthBlack,
      body: Stack(
        children: [
          // background image for the current account type
          Positioned.fill(
            child: Image.asset(
              widget.accountType.backgroundAsset,
              fit: BoxFit.cover,
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                // ── top header: close button + title ────────────────────────
                //   close button overlaps top-right; title sits at kAuthTopPad.
                SizedBox(
                  height: kAuthTopPad + 80, // enough room for title block
                  child: Stack(
                    children: [
                      // close button pinned to top-right
                      Positioned(
                        top: 6,
                        right: 18,
                        child: AuthCircleButton(
                          assetPath: 'assets/icons/auth/close.png', // TODO: modify the path here
                          onTap: _confirmCancel,
                          size: 50,
                          iconSize: 40,
                        ),
                      ),
                      // title block placed at kAuthTopPad from the top
                      Positioned(
                        top: kAuthTopPad,
                        left: kAuthHPad,
                        right: kAuthHPad,
                        child: TitleBlock(
                          title: widget.accountType.title,
                          subtitle: widget.accountType.subtitle,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── center: paged content steps ──────────────────────────────
                Expanded(
                  child: PageView(
                    controller: _controller.pageController,
                    physics: const NeverScrollableScrollPhysics(),
                    onPageChanged: _controller.setPage,
                    children: [
                      _SignupStepOne(
                        controller: _controller,
                        fieldWidth: fieldWidth,
                      ),
                      _SignupStepTwo(
                        controller: _controller,
                        fieldWidth: fieldWidth,
                      ),
                      _SignupStepThree(
                        controller: _controller,
                        fieldWidth: fieldWidth,
                      ),
                    ],
                  ),
                ),

                // ── bottom: error · dots · nav buttons ───────────────────────
                AuthErrorSlot(message: _controller.error),
                const SizedBox(height: kAuthBottomGap),
                AuthStepDots(currentPage: _controller.page, total: 3),
                const SizedBox(height: kAuthBottomGap),
                _BottomNavigation(
                  controller: _controller,
                  onComplete: _handleComplete,
                ),
                const SizedBox(height: kAuthBottomPad),
              ],
            ),
          ),

          if (_controller.loading) const AuthLoadingOverlay(),
        ],
      ),
    );
  }

  // advances the flow or finishes registration.
  Future<void> _handleComplete() async {
    final int? result = await _controller.next();
    if (!mounted || result == null) return;
    if (result == 200 || result == 201) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
        (_) => false,
      );
    }
  }

  // asks the user to confirm signup cancellation.
  Future<void> _confirmCancel() async {
    await VezPopup.show<void>(
      context: context,
      width: MediaQuery.of(context).size.width * 0.78,
      child: AuthCancelPopupContent(
        onCancel: () => Navigator.pop(context),
        onConfirm: () {
          Navigator.pop(context);
          Navigator.pop(context);
        },
      ),
    );
  }
}

// ── step 1: profile photo + name ──────────────────────────────────────────────
//
//   renders the profile photo picker and name / venue-name input.
class _SignupStepOne extends StatelessWidget {
  final SignupFlowController controller;
  final double fieldWidth;

  const _SignupStepOne({required this.controller, required this.fieldWidth});

  // builds the first signup step.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // profile photo picker — icon is always icon_camera.png
          AuthProfilePicker(
            image: controller.profileImage,
            onTap: controller.pickImage,
          ),
          const SizedBox(height: 22),
          AuthGlassTextField(
            controller: controller.nameController,
            hint: controller.accountType.nameHint,
            width: fieldWidth,
            maxLength: 20,
          ),
        ],
      ),
    );
  }
}

// ── step 2: phone + password ──────────────────────────────────────────────────
//
//   renders the phone number and password inputs.
class _SignupStepTwo extends StatelessWidget {
  final SignupFlowController controller;
  final double fieldWidth;

  const _SignupStepTwo({required this.controller, required this.fieldWidth});

  // builds the second signup step.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AuthGlassTextField(
            controller: controller.phoneController,
            hint: StringRes.at('phone'),
            width: fieldWidth,
            keyboardType: TextInputType.phone,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'[0-9+\s()-]')),
            ],
          ),
          const SizedBox(height: kAuthFieldGap),
          AuthGlassTextField(
            controller: controller.passwordController,
            hint: StringRes.at('password'),
            width: fieldWidth,
            obscure: !controller.showPassword,
            suffix: GestureDetector(
              onTap: controller.togglePassword,
              child: Padding(
                padding: const EdgeInsets.only(left: 8),
                child: Image.asset(
                  controller.showPassword
                      ? 'assets/icons/auth/eye.png'      // TODO: modify the path here
                      : 'assets/icons/auth/eye_off.png', // TODO: modify the path here
                  width: 22,
                  height: 22,
                  color: kAuthWhite70,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── step 3: city + OTP ───────────────────────────────────────────────────────
//
//   renders the city picker and the OTP input.
//   the OTP field uses isOtp=true → white-20 background instead of black-20.
class _SignupStepThree extends StatelessWidget {
  final SignupFlowController controller;
  final double fieldWidth;

  const _SignupStepThree({required this.controller, required this.fieldWidth});

  // builds the third signup step.
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // city field with optional location spinner
          Stack(
            alignment: Alignment.centerRight,
            children: [
              AuthGlassTextField(
                controller: controller.cityController,
                hint: controller.locatingCity
                    ? StringRes.at('locating_the_city')
                    : StringRes.at('city'),
                width: fieldWidth,
                readOnly: true,
                onTap: controller.fetchCity,
              ),
              if (controller.locatingCity)
                const Padding(
                  padding: EdgeInsets.only(right: 14),
                  child: SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(
                      color: kAuthWhite,
                      strokeWidth: 2,
                    ),
                  ),
                ),
            ],
          ),

          const SizedBox(height: kAuthFieldGap),

          // OTP field — white-20 background to visually distinguish it.
          AuthGlassTextField(
            controller: controller.otpController,
            hint: StringRes.at('otp_code'),
            width: fieldWidth,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
            isOtp: true, // ← white-20 fill instead of black-20
          ),

          const SizedBox(height: kAuthFieldGap),

          if (controller.page == 2)
            AuthResendOtpButton(onTap: controller.requestOtp),
        ],
      ),
    );
  }
}

// ── bottom navigation ─────────────────────────────────────────────────────────
//
//   renders back and next/save controls for the signup flow.
class _BottomNavigation extends StatelessWidget {
  final SignupFlowController controller;
  final VoidCallback onComplete;

  const _BottomNavigation({
    required this.controller,
    required this.onComplete,
  });

  // builds the bottom navigation row.
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (controller.page > 0) ...[
          AuthCircleButton(
            assetPath: 'assets/icons/auth/icon_next.png', // TODO: modify the path here
            rotation: 3.1416,                              // flipped = back arrow
            onTap: controller.back,
          ),
          const SizedBox(width: 40),
        ],
        AuthCircleButton(
          assetPath: controller.page == 2
              ? 'assets/icons/auth/icon_save.png' // TODO: modify the path here
              : 'assets/icons/auth/icon_next.png', // TODO: modify the path here
          enabled: controller.canContinue,
          onTap: onComplete,
        ),
      ],
    );
  }
}
