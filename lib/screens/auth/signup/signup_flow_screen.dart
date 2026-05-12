// Developed and Designed by Outly • 2026
// main screen that assembles the shared user and venue signup flow.

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../models/signup_account_type.dart';
import '../../../services/translation_service.dart';
import '../../../views/widgets/vez_popup.dart';
import '../../home/home_screen.dart';
import 'signup_controller.dart';
import 'signup_widgets.dart';

// displays the three-step signup flow for one account type.
class SignupFlowScreen extends StatefulWidget {
  final SignupAccountType accountType;

  const SignupFlowScreen({super.key, required this.accountType});

  // creates the signup flow state.
  @override
  State<SignupFlowScreen> createState() => _SignupFlowScreenState();
}

// coordinates the signup controller with the screen lifecycle.
class _SignupFlowScreenState extends State<SignupFlowScreen> {
  late final SignupFlowController _controller;

  // creates the controller for the selected account type.
  @override
  void initState() {
    super.initState();
    _controller = SignupFlowController(accountType: widget.accountType);
    _controller.addListener(_refresh);
  }

  // releases the controller when the screen closes.
  @override
  void dispose() {
    _controller.removeListener(_refresh);
    _controller.dispose();
    super.dispose();
  }

  // rebuilds the screen when the controller changes.
  void _refresh() {
    if (mounted) setState(() {});
  }

  // builds the signup flow screen.
  @override
  Widget build(BuildContext context) {
    final Size size = MediaQuery.of(context).size;
    final double fieldWidth = size.width * 0.75;

    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: kAuthBlack,
      body: Stack(
        children: [
          // background image
          Positioned.fill(
            child: Image.asset(widget.accountType.backgroundAsset, fit: BoxFit.cover),
          ),

          SafeArea(
            child: Padding(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  SizedBox(
                    height: 148,
                    child: Stack(
                      children: [
                        Align(
                          alignment: Alignment.topRight,
                          child: Padding(
                            padding: const EdgeInsets.only(top: 6, right: 18),
                            child: AuthCircleButton(
                              assetPath: 'assets/icons/auth/close.png',
                              onTap: _confirmCancel,
                              size: 50,
                              iconSize: 40,
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.bottomCenter,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 24),
                            child: AuthTitleBlock(
                              title: widget.accountType.title,
                              subtitle: widget.accountType.subtitle,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
                  SizedBox(
                    height: 218,
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 28),
                          child: AuthErrorSlot(message: _controller.error),
                        ),
                        const SizedBox(height: 18),
                        AuthStepDots(currentPage: _controller.page, total: 3),
                        const SizedBox(height: 18),
                        _BottomNavigation(
                          controller: _controller,
                          onComplete: _handleComplete,
                        ),
                        const SizedBox(height: 12),
                        if (_controller.page == 2)
                          AuthResendOtpButton(onTap: _controller.requestOtp),
                      ],
                    ),
                  ),
                ],
              ),
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

// renders profile photo and name input.
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

// renders phone and password input.
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
          const SizedBox(height: 18),
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
                      ? 'assets/icons/auth/eye.png'
                      : 'assets/icons/auth/eye_off.png',
                  width: 20,
                  height: 20,
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

// renders city and otp input.
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
          const SizedBox(height: 18),
          AuthGlassTextField(
            controller: controller.otpController,
            hint: StringRes.at('otp_code'),
            width: fieldWidth,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            maxLength: 6,
          ),
        ],
      ),
    );
  }
}

// renders back and next controls for the signup flow.
class _BottomNavigation extends StatelessWidget {
  final SignupFlowController controller;
  final VoidCallback onComplete;

  const _BottomNavigation({required this.controller, required this.onComplete});

  // builds the bottom navigation buttons.
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (controller.page > 0) ...[
          AuthCircleButton(
            assetPath: 'assets/icons/auth/icon_next.png',
            rotation: 3.1416,
            onTap: controller.back,
          ),
          const SizedBox(width: 40),
        ],
        AuthCircleButton(
          assetPath: controller.page == 2
              ? 'assets/icons/auth/icon_save.png'
              : 'assets/icons/auth/icon_next.png',
          enabled: controller.canContinue,
          onTap: onComplete,
        ),
      ],
    );
  }
}
