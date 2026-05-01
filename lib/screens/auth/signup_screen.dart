// developed and designed by outly • © 2026
// signup screen — 3-step flow: (1) avatar + username, (2) email + password,
//                               (3) date of birth + city.
//
// layout notes:
//   the bottom section (error slot → step-dots → action button → pill)
//   uses the EXACT same fixed heights as login_screen.dart so that
//   "action button" and "pill button" land at the same vertical position
//   on both screens regardless of screen size.

import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:connectivity_plus/connectivity_plus.dart';

import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../views/widgets/vez_glass.dart';
import '../home_screen.dart';

// ─────────────────────────────────────────────────────────────────────────────
// layout constants — keep in sync with login_screen.dart
// ─────────────────────────────────────────────────────────────────────────────

/// height always reserved for the error banner (visible or not)
const double _kErrorSlotH = 56.0;
/// height always reserved for the step-dots row
const double _kDotsSlotH  = 24.0;
/// vertical gap between fixed bottom items
const double _kGapH       = 20.0;
/// gap between the action button and the pill button
const double _kBelowBtnH  = 50.0;
/// bottom padding below the pill button
const double _kBottomPadH = 36.0;

// ─────────────────────────────────────────────────────────────────────────────
// stateful widget wrapper
// ─────────────────────────────────────────────────────────────────────────────

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

// ─────────────────────────────────────────────────────────────────────────────
// state
// ─────────────────────────────────────────────────────────────────────────────

class _SignupPageState extends State<SignupPage> {

  // ── controllers & services ─────────────────────────────────────────────────

  final TextEditingController _emailCtrl    = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _usernameCtrl = TextEditingController();
  final TextEditingController _cityCtrl     = TextEditingController();

  final PageController _pageCtrl = PageController();
  final ImagePicker    _picker   = ImagePicker();
  final RemoteDbService _db      = RemoteDbService();

  // ── form data ──────────────────────────────────────────────────────────────

  DateTime? _dob;            // date of birth
  File?     _profileImage;

  // ── ui state ───────────────────────────────────────────────────────────────

  int     _page         = 0;
  String? _error;
  bool    _loading      = false;
  bool    _showPassword = false;
  bool    _locatingCity = false;

  // ── lifecycle ──────────────────────────────────────────────────────────────

  @override
  void dispose() {
    _pageCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _usernameCtrl.dispose();
    _cityCtrl.dispose();
    super.dispose();
  }

  // ── step navigation ────────────────────────────────────────────────────────

  void _next() => _pageCtrl.nextPage(
    duration: const Duration(milliseconds: 300),
    curve:    Curves.easeInOut,
  );

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

          // ── background image ───────────────────────────────────────────
          Positioned.fill(
            child: Image.asset('assets/images/bg/bg_signup.jpg', fit: BoxFit.cover),
          ),

          // ── main content ───────────────────────────────────────────────
          SafeArea(
            child: SizedBox(
              // extend height when keyboard is open so content stays visible
              height: (sh - pt) + (kb > 0 ? 300 : 0),
              child: Column(
                children: [

                  // ── title block ─────────────────────────────────────────
                  const Spacer(flex: 2),
                  _TitleBlock(
                    top:    StringRes.at('top_title_signup'),
                    bottom: StringRes.at('under_title_signup'),
                  ),

                  // ── form area (fixed height, same as login) ─────────────
                  const Spacer(flex: 3),
                  SizedBox(
                    height: 300,
                    child: PageView(
                      controller: _pageCtrl,
                      // disable manual swipe — navigation is controlled via buttons
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) => setState(() {
                        _page  = i;
                        _error = null;   // clear errors when changing step
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
                          emailCtrl:    _emailCtrl,
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

                  // ── elastic spacer fills the remaining vertical room ─────
                  const Spacer(),

                  // ═══════════════════════════════════════════════════════
                  // FIXED BOTTOM BLOCK — identical structure to login_screen
                  // so action button + pill button land at the same Y position
                  // ═══════════════════════════════════════════════════════

                  // error banner slot — always the same height; only opacity changes
                  _ErrorSlot(message: _error),

                  const SizedBox(height: _kGapH),

                  // step-dots row — fixed height matches login's placeholder
                  SizedBox(
                    height: _kDotsSlotH,
                    child: _StepDots(currentPage: _page, total: 3),
                  ),

                  const SizedBox(height: _kGapH),

                  // action button — next / submit depending on current step
                  _StepNavButtons(
                    page:    _page,
                    onBack:  _back,
                    onNext:  _handleNext,
                  ),

                  const SizedBox(height: _kBelowBtnH),

                  // navigate pill — go back to login
                  _AuthPillButton(
                    text:  StringRes.at('login'),
                    onTap: () => Navigator.pop(context),
                  ),

                  const SizedBox(height: _kBottomPadH),
                ],
              ),
            ),
          ),

          // ── loading overlay ────────────────────────────────────────────
          if (_loading) const VezLoadingOverlay(),
        ],
      ),
    );
  }

  // ── step validation & progression ─────────────────────────────────────────

  void _handleNext() {
    // clear any previous error first
    setState(() => _error = null);

    final String username = _usernameCtrl.text.trim();
    final String email    = _emailCtrl.text.trim();
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
        if (email.isEmpty || password.isEmpty) {
          setState(() => _error = StringRes.at('fill_all_fields'));
          return;
        }
        if (!_isValidEmail(email)) {
          setState(() => _error = StringRes.at('invalid_email'));
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

  // ── logic ──────────────────────────────────────────────────────────────────

  /// returns true if the device has an active internet connection
  Future<bool> _hasInternet() async {
    final result = await Connectivity().checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  Future<void> _signup() async {
    if (!await _hasInternet()) {
      setState(() => _error = StringRes.at('no_internet_connection'));
      return;
    }

    setState(() => _loading = true);

    try {
      final int res = await _db.signup(
        email:       _emailCtrl.text.trim(),
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
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (_) => HomePage()));
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

  /// validates password strength; returns a localized error string or null
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

  /// opens the system date picker and stores the selected date of birth
  Future<void> _pickDate() async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate:   DateTime(1900),
      lastDate:    DateTime.now(),
    );
    if (picked != null) setState(() => _dob = picked);
  }

  /// opens the gallery so the user can pick a profile photo
  Future<void> _pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512, maxHeight: 512, imageQuality: 75,
    );
    if (file != null) setState(() => _profileImage = File(file.path));
  }

  /// uses device GPS + reverse geocoding to auto-fill the city field
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

// ─────────────────────────────────────────────────────────────────────────────
// step widgets (stateless, receive all data + callbacks from the parent state)
// ─────────────────────────────────────────────────────────────────────────────

// ── step 1: avatar picker + username field ────────────────────────────────────

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
          // avatar picker circle
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
                  // overlay selected photo when available
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

          // username field with live character counter
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

// ── step 2: email + password ──────────────────────────────────────────────────

class _StepTwo extends StatelessWidget {
  final double sw;
  final TextEditingController emailCtrl;
  final TextEditingController passwordCtrl;
  final bool showPassword;
  final VoidCallback onTogglePass;

  const _StepTwo({
    required this.sw,
    required this.emailCtrl,
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
            controller: emailCtrl,
            hint:  StringRes.at('email'),
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

// ── step 3: date of birth + city (with GPS auto-fill) ────────────────────────

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
          // date of birth field — tapping opens the date picker
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

          // city field — tapping triggers GPS lookup instead of keyboard
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
                  // spinner shown while the GPS is working
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

// ── _StepNavButtons — back arrow (from step 2+) + next/save arrow ────────────

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
        // back button — hidden on step 0 so it doesn't shift the "next" button
        if (page > 0) ...[
          VezGlass.circleButton(
            assetIcon: 'assets/icons/auth/icon_next.png',
            rotation:  3.1416,   // flip the arrow icon to point left
            onTap:     onBack,
          ),
          const SizedBox(width: 40),
        ],

        // next / save button
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

// ─────────────────────────────────────────────────────────────────────────────
// shared auth-screen sub-widgets
// ─────────────────────────────────────────────────────────────────────────────

// ── _TitleBlock — large bold title + lighter subtitle ────────────────────────

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

// ── _ErrorSlot — fixed-height container; content fades in/out via opacity ─────
//
// using a fixed SizedBox instead of AnimatedSize prevents the error banner
// from shifting the action button and pill button when it appears or disappears.

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

// ── _AuthPillButton — frosted-glass pill button where text scales to fit ──────
//
// ClipRRect + BackdropFilter creates the blur effect against the background.
// FittedBox with BoxFit.scaleDown shrinks the label when translations are long.

class _AuthPillButton extends StatelessWidget {
  final String text;
  final VoidCallback onTap;

  const _AuthPillButton({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final double w = MediaQuery.of(context).size.width * 0.40;
    return GestureDetector(
      onTap: onTap,
      // ClipRRect must wrap BackdropFilter so the blur is clipped to the pill shape
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
            // FittedBox scales the text down if wider than available space
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

// ── _StepDots — animated progress indicator for the 3 signup steps ────────────

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
