// Developed and Designed by Outly • © 2026
// signup screen — 3-step flow for user registration.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../../services/auth_service.dart';
import '../../../services/translation_service.dart';
import '../../../views/widgets/vez_glass.dart';
import '../../home/home_screen.dart';

// ── layout constants ─────────────────────────────────────────────────────────
const double _kErrorSlotH = 56.0;
const double _kDotsSlotH  = 24.0;
const double _kGapH       = 20.0;
const double _kBelowBtnH  = 50.0;
const double _kBottomPadH = 36.0;

// ── signup page ──────────────────────────────────────────────────────────────
//
//   used for: handling multi-step user registration.
class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

// ── signup page state ────────────────────────────────────────────────────────
//
//   used for: managing the registration flow and data validation.
class _SignupPageState extends State<SignupPage> {
  final TextEditingController _phoneCtrl    = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _cityCtrl     = TextEditingController();

  final PageController _pageCtrl = PageController();
  final ImagePicker    _picker   = ImagePicker();
  final RemoteDbService _db      = RemoteDbService();

  DateTime? _dob;
  File?     _profileImage;

  int     _page         = 0;
  String? _error;
  bool    _loading      = false;
  bool    _showPassword = false;
  bool    _locatingCity = false;

  // ── dispose ────────────────────────────────────────────────────────────────
  @override
  void dispose() {
    _pageCtrl.dispose();
    _phoneCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ── next ───────────────────────────────────────────────────────────────────
  void _next() => _pageCtrl.nextPage(
    duration: const Duration(milliseconds: 300),
    curve:    Curves.easeInOut,
  );

  // ── back ───────────────────────────────────────────────────────────────────
  void _back() => _pageCtrl.previousPage(
    duration: const Duration(milliseconds: 300),
    curve:    Curves.easeInOut,
  );

  // ── build ──────────────────────────────────────────────────────────────────
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
            child: Image.asset('assets/images/bg/bg_signup.jpg', fit: BoxFit.cover),
          ),

          SafeArea(
            child: SizedBox(
              height: (sh - pt) + (kb > 0 ? 300 : 0),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  _TitleBlock(
                    top:    StringRes.at('top_title_signup'),
                    bottom: StringRes.at('under_title_signup'),
                  ),

                  const Spacer(flex: 3),
                  SizedBox(
                    height: 300,
                    child: PageView(
                      controller: _pageCtrl,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() {
                        _page  = i;
                        _error = null;
                      }),
                      children: [
                        _StepOne(
                          sw:           sw,
                          profileImage: _profileImage,
                          ctrl:         _usernameCtrl,
                          onPickImage:  _pickImage,
                          onChanged:    () => setState(() {}),
                        ),
                        _StepTwo(
                          sw:           sw,
                          phoneCtrl:    _phoneCtrl,
                          passwordCtrl: _passwordCtrl,
                          showPassword: _showPassword,
                          onTogglePass: () => setState(() => _showPassword = !_showPassword),
                        ),
                        _StepThree(
                          sw:           sw,
                          dob:          _dob,
                          cityCtrl:     _cityCtrl,
                          locating:     _locatingCity,
                          onPickDate:   () => _pickDate(),
                          onFetchCity:  _fetchCity,
                        ),
                      ],
                    ),
                  ),

                  const Spacer(),

                  _ErrorSlot(message: _error),
                  const SizedBox(height: _kGapH),
                  SizedBox(
                    height: _kDotsSlotH,
                    child: _StepDots(currentPage: _page, total: 3),
                  ),
                  const SizedBox(height: _kGapH),

                  _StepNavButtons(
                    page:    _page,
                    onBack:  _back,
                    onNext:  _handleNext,
                  ),

                  const SizedBox(height: _kBelowBtnH),

                  _AuthPillButton(
                    text:  StringRes.at('login'),
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

  // ── handle next ────────────────────────────────────────────────────────────
  void _handleNext() {
    setState(() => _error = null);

    final String username = _usernameCtrl.text.trim();
    final String phone    = _phoneCtrl.text.trim();
    final String password = _passwordCtrl.text;
    final String city     = _cityCtrl.text.trim();

    switch (_page) {
      case 0:
        if (username.isEmpty) {
          setState(() => _error = StringRes.at('choose_username'));
          return;
        }
        if (_profileImage == null) {
          setState(() => _error = StringRes.at('choose_profile_photo'));
          return;
        }
        if (username.length < 3) {
          setState(() => _error = StringRes.at('username_too_short'));
          return;
        }
        _next();

      case 1:
        if (phone.isEmpty || password.isEmpty) {
          setState(() => _error = StringRes.at('fill_all_fields'));
          return;
        }
        if (!_isValidPhone(phone)) {
          setState(() => _error = StringRes.at('invalid_phone'));
          return;
        }
        final String? pswError = _validatePassword(password);
        if (pswError != null) {
          setState(() => _error = pswError);
          return;
        }
        _next();

      case 2:
        if (city.isEmpty || _dob == null) {
          setState(() => _error = StringRes.at('fill_all_fields'));
          return;
        }
        _signup();

      default:
        setState(() => _error = StringRes.at('something_went_wrong'));
    }
  }

  // ── has internet ───────────────────────────────────────────────────────────
  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // ── signup ─────────────────────────────────────────────────────────────────
  Future<void> _signup() async {
    if (!await _hasInternet()) {
      setState(() => _error = StringRes.at('no_internet_connection'));
      return;
    }

    setState(() => _loading = true);

    try {
      final int res = await _db.signup(
        phone:       _phoneCtrl.text.trim(),
        password:    _passwordCtrl.text,
        username:    _usernameCtrl.text.trim(),
        dateOfBirth: _dob!,
        city:        _cityCtrl.text.trim(),
        profileImage: _profileImage,
      );

      if (!mounted) return;
      setState(() => _loading = false);

      if (res == 200 || res == 201) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(StringRes.at('signup_successful'))));
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => const HomePage()));
      } else if (res == 409) {
        setState(() => _error = StringRes.at('user_already_exists'));
      } else {
        setState(() => _error = '${StringRes.at("signup_failed")}\n$res');
      }
    } catch (_) {
      if (!mounted) return;
      setState(() { _loading = false; _error = StringRes.at('no_internet_connection'); });
    }
  }

  // ── validate password ──────────────────────────────────────────────────────
  String? _validatePassword(String password) =>
      _isValidPsw(password) ? null : StringRes.at('invalid_password');

  // ── is valid password ──────────────────────────────────────────────────────
  bool _isValidPsw(String p) =>
      p.length >= 8 &&
      RegExp(r'[A-Z]').hasMatch(p) &&
      RegExp(r'[a-z]').hasMatch(p) &&
      RegExp(r'[0-9]').hasMatch(p) &&
      RegExp(r'[!@#$&*~£€?§+]').hasMatch(p);

  // ── is valid phone ─────────────────────────────────────────────────────────
  bool _isValidPhone(String e) {
    final cleanPhone = e.replaceAll(RegExp(r'[\s\-()]+'), '');

    // regex for a clean number:
    // - ^(\+?[0-9]{1,4})? : internation prefix (es. +39, 39, 0039) up to 4 chars
    // - [0-9]{9,11}$       : real number (between 9 and 11 chars)
    return RegExp(r'^(\+?[0-9]{1,4})?[0-9]{9,11}$').hasMatch(cleanPhone);
  }

  // ── pick date ──────────────────────────────────────────────────────────────
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate:   DateTime(1900),
      lastDate:    DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  // ── pick image ─────────────────────────────────────────────────────────────
  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, maxHeight: 512, imageQuality: 75,
    );
    if (file != null) setState(() => _profileImage = File(file.path));
  }

  // ── fetch city ─────────────────────────────────────────────────────────────
  Future<void> _fetchCity() async {
    setState(() { _locatingCity = true; _error = null; });

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(StringRes.at('enable_location_services'));
      }

      LocationPermission perm = await Geolocator.checkPermission();
      if (perm == LocationPermission.denied) {
        perm = await Geolocator.requestPermission();
        if (perm == LocationPermission.denied) {
          throw Exception(StringRes.at('location_permissions_denied'));
        }
      }
      if (perm == LocationPermission.deniedForever) {
        throw Exception(StringRes.at('location_permissions_permanently_denied'));
      }

      final Position pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high,
      );

      final List<Placemark> marks =
          await placemarkFromCoordinates(pos.latitude, pos.longitude);

      if (marks.isNotEmpty) {
        final String city =
            marks.first.locality ??
            marks.first.subAdministrativeArea ??
            StringRes.at('unknown_city');
        setState(() => _cityCtrl.text = city);
      }
    } catch (e) {
      setState(() => _error = e.toString().replaceAll('Exception: ', ''));
    } finally {
      setState(() => _locatingCity = false);
    }
  }
}

// ── step 1: avatar picker + username field ───────────────────────────────────
class _StepOne extends StatelessWidget {
  final double sw;
  final File?  profileImage;
  final TextEditingController ctrl;
  final VoidCallback onPickImage;
  final VoidCallback onChanged;

  const _StepOne({
    required this.sw,
    required this.profileImage,
    required this.ctrl,
    required this.onPickImage,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: onPickImage,
            child: SizedBox(
              width: 100, height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  VezGlass.circleButton(
                    assetIcon: 'assets/icons/auth/icon_camera_90x90.png',
                    onTap: onPickImage,
                    size: 100, iconSize: 50,
                  ),
                  if (profileImage != null)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white10, width: 3),
                      ),
                      child: ClipOval(
                        child: Image.file(
                          profileImage!,
                          width: 100, height: 100, fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          VezGlass.textField(
            controller: ctrl,
            hint:  StringRes.at('username'),
            color: Colors.white54,
            width: sw * 0.75,
            maxLength: 15,
            onChanged: (_) => onChanged(),
            suffixIcon: Padding(
              padding: const EdgeInsets.only(right: 6),
              child: Text(
                '${ctrl.text.length}/15',
                style: const TextStyle(
                  color: Colors.white54, fontWeight: FontWeight.bold, fontSize: 15,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── step 2: phone + password ─────────────────────────────────────────────────
class _StepTwo extends StatelessWidget {
  final double sw;
  final TextEditingController phoneCtrl;
  final TextEditingController passwordCtrl;
  final bool showPassword;
  final VoidCallback onTogglePass;

  const _StepTwo({
    required this.sw,
    required this.phoneCtrl,
    required this.passwordCtrl,
    required this.showPassword,
    required this.onTogglePass,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VezGlass.textField(
            controller: phoneCtrl,
            hint:  StringRes.at('phone'),
            width: sw * 0.75,
            color: Colors.white54,
          ),
          const SizedBox(height: 20),
          VezGlass.textField(
            controller: passwordCtrl,
            hint:    StringRes.at('password'),
            obscure: !showPassword,
            width:   sw * 0.75,
            color:   Colors.white54,
            suffixIcon: GestureDetector(
              onTap: onTogglePass,
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  showPassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: Colors.white54, size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── step 3: date of birth + city ─────────────────────────────────────────────
class _StepThree extends StatelessWidget {
  final double sw;
  final DateTime?  dob;
  final TextEditingController cityCtrl;
  final bool locating;
  final VoidCallback onPickDate;
  final VoidCallback onFetchCity;

  const _StepThree({
    required this.sw,
    required this.dob,
    required this.cityCtrl,
    required this.locating,
    required this.onPickDate,
    required this.onFetchCity,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: onPickDate,
            child: AbsorbPointer(
              child: VezGlass.textField(
                controller: TextEditingController(
                  text: dob == null
                      ? ''
                      : DateFormat.yMd(
                          Localizations.localeOf(context).toString(),
                        ).format(dob!),
                ),
                hint:  StringRes.at('date_of_birth'),
                width: sw * 0.75,
                color: Colors.white54,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: onFetchCity,
            child: AbsorbPointer(
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  VezGlass.textField(
                    controller: cityCtrl,
                    hint:  locating
                        ? StringRes.at('locating_the_city')
                        : StringRes.at('set_city'),
                    width: sw * 0.75,
                    color: Colors.white54,
                  ),
                  if (locating)
                    const Padding(
                      padding: EdgeInsets.only(right: 15),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── step nav buttons ─────────────────────────────────────────────────────────
class _StepNavButtons extends StatelessWidget {
  final int page;
  final VoidCallback onBack;
  final VoidCallback onNext;

  const _StepNavButtons({
    required this.page,
    required this.onBack,
    required this.onNext,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (page > 0) ...[
          VezGlass.circleButton(
            assetIcon: 'assets/icons/auth/icon_next.png',
            rotation:  3.1416,
            onTap:     onBack,
          ),
          const SizedBox(width: 40),
        ],
        VezGlass.circleButton(
          assetIcon: page == 2
              ? 'assets/icons/auth/icon_save.png'
              : 'assets/icons/auth/icon_next.png',
          onTap: onNext,
        ),
      ],
    );
  }
}

// ── step dots ────────────────────────────────────────────────────────────────
class _StepDots extends StatelessWidget {
  final int currentPage;
  final int total;

  const _StepDots({required this.currentPage, required this.total});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(total, (i) {
        final bool active = i == currentPage;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 280),
          curve:    Curves.easeInOut,
          margin:   const EdgeInsets.symmetric(horizontal: 5),
          width:    active ? 22 : 8,
          height:   8,
          decoration: BoxDecoration(
            color: active ? Colors.white : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}

// ── title block ──────────────────────────────────────────────────────────────
class _TitleBlock extends StatelessWidget {
  final String top;
  final String bottom;

  const _TitleBlock({required this.top, required this.bottom});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          top,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white, fontSize: 40, fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          bottom,
          style: const TextStyle(
            fontFamily: 'InstagramSans',
            color: Colors.white, fontSize: 25, fontWeight: FontWeight.normal,
          ),
        ),
      ],
    );
  }
}

// ── error slot ───────────────────────────────────────────────────────────────
class _ErrorSlot extends StatelessWidget {
  final String? message;

  const _ErrorSlot({required this.message});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 30),
      child: SizedBox(
        height: _kErrorSlotH,
        child: AnimatedOpacity(
          opacity:  message != null ? 1.0 : 0.0,
          duration: const Duration(milliseconds: 250),
          curve:    Curves.easeOut,
          child: message != null
              ? VezErrorBanner(message: message!)
              : const SizedBox.shrink(),
        ),
      ),
    );
  }
}

// ── auth pill button ─────────────────────────────────────────────────────────
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
                  color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
