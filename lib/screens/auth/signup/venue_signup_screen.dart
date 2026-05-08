import 'dart:ui';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

import '../../../services/auth_service.dart';
import '../../../services/translation_service.dart';
import '../../../views/widgets/vez_glass.dart';
import '../venue_pending_screen.dart';

const double _kErrorSlotH = 56.0;
const double _kDotsSlotH = 24.0;
const double _kGapH = 20.0;
const double _kBelowBtnH = 50.0;
const double _kBottomPadH = 36.0;

class VenueSignupPage extends StatefulWidget {
  const VenueSignupPage({super.key});

  @override
  State<VenueSignupPage> createState() => _VenueSignupPageState();
}

class _VenueSignupPageState extends State<VenueSignupPage> {
  final PageController _pageCtrl = PageController();
  final RemoteDbService _db = RemoteDbService();

  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _emailCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _venueNameCtrl = TextEditingController();
  final TextEditingController _legalNameCtrl = TextEditingController();
  final TextEditingController _vatCtrl = TextEditingController();
  final TextEditingController _addressCtrl = TextEditingController();
  final TextEditingController _cityCtrl = TextEditingController();
  final TextEditingController _countryCtrl = TextEditingController(text: 'IT');
  final TextEditingController _publicEmailCtrl = TextEditingController();
  final TextEditingController _publicPhoneCtrl = TextEditingController();
  final TextEditingController _websiteCtrl = TextEditingController();
  final TextEditingController _instagramCtrl = TextEditingController();

  int _page = 0;
  String? _error;
  bool _loading = false;
  bool _showPassword = false;

  @override
  void dispose() {
    _pageCtrl.dispose();
    _usernameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _venueNameCtrl.dispose();
    _legalNameCtrl.dispose();
    _vatCtrl.dispose();
    _addressCtrl.dispose();
    _cityCtrl.dispose();
    _countryCtrl.dispose();
    _publicEmailCtrl.dispose();
    _publicPhoneCtrl.dispose();
    _websiteCtrl.dispose();
    _instagramCtrl.dispose();
    super.dispose();
  }

  void _next() => _pageCtrl.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  void _back() => _pageCtrl.previousPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeInOut,
  );

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    final double sh = MediaQuery.of(context).size.height;
    final double pt = MediaQuery.of(context).padding.top;
    final double kb = MediaQuery.of(context).viewInsets.bottom;

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
            child: SizedBox(
              height: (sh - pt) + (kb > 0 ? 300 : 0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _TitleBlock(
                    top: StringRes.at('venue_signup_title'),
                    bottom: StringRes.at('venue_signup_subtitle'),
                  ),
                  const Spacer(flex: 3),
                  SizedBox(
                    height: 330,
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() {
                        _page = i;
                        _error = null;
                      }),
                      children: [
                        _VenueAccountStep(
                          sw: sw,
                          usernameCtrl: _usernameCtrl,
                          emailCtrl: _emailCtrl,
                          passwordCtrl: _passwordCtrl,
                          showPassword: _showPassword,
                          onTogglePassword: () {
                            setState(() => _showPassword = !_showPassword);
                          },
                        ),
                        _VenueBusinessStep(
                          sw: sw,
                          venueNameCtrl: _venueNameCtrl,
                          legalNameCtrl: _legalNameCtrl,
                          vatCtrl: _vatCtrl,
                        ),
                        _VenueContactStep(
                          sw: sw,
                          addressCtrl: _addressCtrl,
                          cityCtrl: _cityCtrl,
                          countryCtrl: _countryCtrl,
                          publicEmailCtrl: _publicEmailCtrl,
                          publicPhoneCtrl: _publicPhoneCtrl,
                        ),
                        _VenueLinksStep(
                          sw: sw,
                          websiteCtrl: _websiteCtrl,
                          instagramCtrl: _instagramCtrl,
                        ),
                      ],
                    ),
                  ),
                  const Spacer(),
                  _ErrorSlot(message: _error),
                  const SizedBox(height: _kGapH),
                  SizedBox(
                    height: _kDotsSlotH,
                    child: _StepDots(currentPage: _page, total: 4),
                  ),
                  const SizedBox(height: _kGapH),
                  _StepNavButtons(
                    page: _page,
                    onBack: _back,
                    onNext: _handleNext,
                  ),
                  const SizedBox(height: _kBelowBtnH),
                  _AuthPillButton(
                    text: StringRes.at('login'),
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: _kBottomPadH),
                ],
              ),
            ),
          ),
          if (_loading) const VezLoadingOverlay(),
        ],
      ),
    );
  }

  void _handleNext() {
    setState(() => _error = null);

    switch (_page) {
      case 0:
        if (_usernameCtrl.text.trim().isEmpty ||
            _emailCtrl.text.trim().isEmpty ||
            _passwordCtrl.text.isEmpty) {
          setState(() => _error = StringRes.at('fill_all_fields'));
          return;
        }
        if (!_isValidEmail(_emailCtrl.text.trim())) {
          setState(() => _error = StringRes.at('invalid_email'));
          return;
        }
        final String? passwordError = _validatePassword(_passwordCtrl.text);
        if (passwordError != null) {
          setState(() => _error = passwordError);
          return;
        }
        _next();

      case 1:
        if (_venueNameCtrl.text.trim().isEmpty ||
            _legalNameCtrl.text.trim().isEmpty ||
            _vatCtrl.text.trim().isEmpty) {
          setState(() => _error = StringRes.at('fill_all_fields'));
          return;
        }
        _next();

      case 2:
        if (_addressCtrl.text.trim().isEmpty ||
            _cityCtrl.text.trim().isEmpty ||
            _countryCtrl.text.trim().isEmpty ||
            _publicEmailCtrl.text.trim().isEmpty) {
          setState(() => _error = StringRes.at('fill_all_fields'));
          return;
        }
        if (!_isValidEmail(_publicEmailCtrl.text.trim())) {
          setState(() => _error = StringRes.at('invalid_email'));
          return;
        }
        _next();

      case 3:
        _signupVenue();
    }
  }

  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> _signupVenue() async {
    if (!await _hasInternet()) {
      setState(() => _error = StringRes.at('no_internet_connection'));
      return;
    }

    setState(() => _loading = true);
    final int res = await _db.signupVenue(
      username: _usernameCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      password: _passwordCtrl.text,
      venueName: _venueNameCtrl.text.trim(),
      legalName: _legalNameCtrl.text.trim(),
      vatNumber: _vatCtrl.text.trim(),
      address: _addressCtrl.text.trim(),
      city: _cityCtrl.text.trim(),
      country: _countryCtrl.text.trim().toUpperCase(),
      publicEmail: _publicEmailCtrl.text.trim(),
      publicPhone: _publicPhoneCtrl.text.trim(),
      websiteUrl: _websiteCtrl.text.trim(),
      instagramUrl: _instagramCtrl.text.trim(),
    );

    if (!mounted) return;
    setState(() => _loading = false);

    if (res == 200 || res == 201) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const VenuePendingPage()),
      );
    } else if (res == 409) {
      setState(() => _error = StringRes.at('user_already_exists'));
    } else {
      setState(() => _error = '${StringRes.at("signup_failed")}\n$res');
    }
  }

  String? _validatePassword(String password) =>
      _isValidPsw(password) ? null : StringRes.at('invalid_password');

  bool _isValidPsw(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(p) &&
      RegExp(r'[a-z]').hasMatch(p) &&
      RegExp(r'[0-9]').hasMatch(p) &&
      RegExp(r'[!@#$&*~£€?§+]').hasMatch(p);

  bool _isValidEmail(String e) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(e);
}

class _VenueAccountStep extends StatelessWidget {
  const _VenueAccountStep({
    required this.sw,
    required this.usernameCtrl,
    required this.emailCtrl,
    required this.passwordCtrl,
    required this.showPassword,
    required this.onTogglePassword,
  });

  final double sw;
  final TextEditingController usernameCtrl;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool showPassword;
  final VoidCallback onTogglePassword;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      children: [
        VezGlass.textField(
          controller: usernameCtrl,
          hint: StringRes.at('username'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
        const SizedBox(height: 16),
        VezGlass.textField(
          controller: emailCtrl,
          hint: StringRes.at('email'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
        const SizedBox(height: 16),
        VezGlass.textField(
          controller: passwordCtrl,
          hint: StringRes.at('password'),
          obscure: !showPassword,
          width: sw * 0.75,
          color: Colors.white54,
          suffixIcon: GestureDetector(
            onTap: onTogglePassword,
            child: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Icon(
                showPassword
                    ? Icons.visibility_outlined
                    : Icons.visibility_off_outlined,
                color: Colors.white54,
                size: 20,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _VenueBusinessStep extends StatelessWidget {
  const _VenueBusinessStep({
    required this.sw,
    required this.venueNameCtrl,
    required this.legalNameCtrl,
    required this.vatCtrl,
  });

  final double sw;
  final TextEditingController venueNameCtrl;
  final TextEditingController legalNameCtrl;
  final TextEditingController vatCtrl;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      children: [
        VezGlass.textField(
          controller: venueNameCtrl,
          hint: StringRes.at('venue_name'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
        const SizedBox(height: 16),
        VezGlass.textField(
          controller: legalNameCtrl,
          hint: StringRes.at('venue_legal_name'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
        const SizedBox(height: 16),
        VezGlass.textField(
          controller: vatCtrl,
          hint: StringRes.at('venue_vat_number'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
      ],
    );
  }
}

class _VenueContactStep extends StatelessWidget {
  const _VenueContactStep({
    required this.sw,
    required this.addressCtrl,
    required this.cityCtrl,
    required this.countryCtrl,
    required this.publicEmailCtrl,
    required this.publicPhoneCtrl,
  });

  final double sw;
  final TextEditingController addressCtrl;
  final TextEditingController cityCtrl;
  final TextEditingController countryCtrl;
  final TextEditingController publicEmailCtrl;
  final TextEditingController publicPhoneCtrl;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      children: [
        VezGlass.textField(
          controller: addressCtrl,
          hint: StringRes.at('venue_address'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            VezGlass.textField(
              controller: cityCtrl,
              hint: StringRes.at('city'),
              width: sw * 0.48,
              color: Colors.white54,
            ),
            const SizedBox(width: 10),
            VezGlass.textField(
              controller: countryCtrl,
              hint: StringRes.at('venue_country'),
              width: sw * 0.20,
              color: Colors.white54,
              maxLength: 2,
            ),
          ],
        ),
        const SizedBox(height: 14),
        VezGlass.textField(
          controller: publicEmailCtrl,
          hint: StringRes.at('venue_public_email'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
        const SizedBox(height: 14),
        VezGlass.textField(
          controller: publicPhoneCtrl,
          hint: StringRes.at('venue_public_phone'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
      ],
    );
  }
}

class _VenueLinksStep extends StatelessWidget {
  const _VenueLinksStep({
    required this.sw,
    required this.websiteCtrl,
    required this.instagramCtrl,
  });

  final double sw;
  final TextEditingController websiteCtrl;
  final TextEditingController instagramCtrl;

  @override
  Widget build(BuildContext context) {
    return _StepShell(
      children: [
        Text(
          StringRes.at('venue_links_hint'),
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 18),
        VezGlass.textField(
          controller: websiteCtrl,
          hint: StringRes.at('venue_website'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
        const SizedBox(height: 16),
        VezGlass.textField(
          controller: instagramCtrl,
          hint: StringRes.at('venue_instagram'),
          width: sw * 0.75,
          color: Colors.white54,
        ),
      ],
    );
  }
}

class _StepShell extends StatelessWidget {
  const _StepShell({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        child: Column(mainAxisSize: MainAxisSize.min, children: children),
      ),
    );
  }
}

class _TitleBlock extends StatelessWidget {
  const _TitleBlock({required this.top, required this.bottom});

  final String top;
  final String bottom;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          top,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white,
            fontSize: 38,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bottom,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

class _ErrorSlot extends StatelessWidget {
  const _ErrorSlot({required this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        height: _kErrorSlotH,
        child: AnimatedOpacity(
          opacity: message != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve: Curves.easeOut,
          child: message != null
              ? VezErrorBanner(message: message!)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

class _StepDots extends StatelessWidget {
  const _StepDots({required this.currentPage, required this.total});

  final int currentPage;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final bool active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withValues(alpha: 0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

class _StepNavButtons extends StatelessWidget {
  const _StepNavButtons({
    required this.page,
    required this.onBack,
    required this.onNext,
  });

  final int page;
  final VoidCallback onBack;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (page > 0) ...[
          VezGlass.circleButton(
            assetIcon: 'assets/icons/auth/icon_next.png',
            rotation: 3.1416,
            onTap: onBack,
          ),
          const SizedBox(width: 40),
        ],
        VezGlass.circleButton(
          assetIcon: page == 3
              ? 'assets/icons/auth/icon_save.png'
              : 'assets/icons/auth/icon_next.png',
          onTap: onNext,
        ),
      ],
    );
  }
}

class _AuthPillButton extends StatelessWidget {
  const _AuthPillButton({required this.text, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width * 0.40;
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(40),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            width: w,
            padding: const EdgeInsets.symmetric(vertical: 3, horizontal: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(51, 255, 255, 255),
              borderRadius: BorderRadius.circular(40),
              border: Border.all(color: Colors.white54, width: 1.5),
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
