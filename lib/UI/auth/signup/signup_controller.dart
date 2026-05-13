// Developed and Designed by Outly • 2026
// controller for the shared three-step signup flow.

import 'dart:io';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:geocoding/geocoding.dart';
import 'package:geolocator/geolocator.dart';
import 'package:image_picker/image_picker.dart';

import '../../../models/account_type.dart';
import '../../../services/auth_service.dart';
import '../../../services/translation_service.dart';

import 'package:supabase_flutter/supabase_flutter.dart';

// manages validation, location, otp, and persistence for signup screens.
class SignupFlowController extends ChangeNotifier {
  final AccountType accountType;
  final RemoteDbService _db = RemoteDbService();
  final ImagePicker _picker = ImagePicker();

  final PageController pageController = PageController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController phoneController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  final TextEditingController otpController = TextEditingController();

  File? profileImage;
  int page = 0;
  String? error;
  bool loading = false;
  bool locatingCity = false;
  bool showPassword = false;

  SignupFlowController({required this.accountType}) {
    phoneController.text = _defaultPhonePrefix();
    nameController.addListener(notifyListeners);
    phoneController.addListener(notifyListeners);
    passwordController.addListener(notifyListeners);
    cityController.addListener(notifyListeners);
    otpController.addListener(notifyListeners);
  }

  // releases controllers owned by the signup flow.
  @override
  void dispose() {
    pageController.dispose();
    nameController.dispose();
    phoneController.dispose();
    passwordController.dispose();
    cityController.dispose();
    otpController.dispose();
    super.dispose();
  }

  // updates the current page and clears transient errors.
  void setPage(int value) {
    page = value;
    error = null;
    notifyListeners();
  }

  // toggles password visibility.
  void togglePassword() {
    showPassword = !showPassword;
    notifyListeners();
  }

  // returns whether the current step can move forward.
  bool get canContinue {
    if (page == 0) {
      return profileImage != null && nameController.text.trim().length >= 3;
    }
    if (page == 1) {
      return _hasPhoneBody(phoneController.text.trim()) &&
          passwordController.text.isNotEmpty;
    }
    return cityController.text.trim().isNotEmpty &&
        otpController.text.trim().isNotEmpty;
  }

  // moves to the previous signup step.
  Future<void> back() async {
    if (page == 0) return;
    await pageController.previousPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // validates the current step and performs its next action.
  Future<int?> next() async {
    error = null;
    notifyListeners();

    if (page == 0) {
      final String name = nameController.text.trim();
      if (profileImage == null) {
        error = StringRes.at('choose_profile_photo');
      } else if (name.length <= 3) {
        error = StringRes.at('username_too_short');
      } else {
        await _goNext();
      }
      notifyListeners();
      return null;
    }

    if (page == 1) {
      final String? passwordError = _validatePassword(passwordController.text);
      if (!_isValidPhone(phoneController.text.trim())) {
        error = StringRes.at('invalid_phone');
      } else if (passwordError != null) {
        error = passwordError;
      } else {
        final bool otpReady = await requestOtp();
        if (otpReady) await _goNext();
      }
      notifyListeners();
      return null;
    }

    return completeSignup();
  }

  // picks a local profile image from the gallery.
  Future<void> pickImage() async {
    final XFile? file = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (file == null) return;
    profileImage = File(file.path);
    notifyListeners();
  }

  // requests the current city from device location.
  Future<void> fetchCity() async {
    locatingCity = true;
    error = null;
    notifyListeners();

    try {
      if (!await Geolocator.isLocationServiceEnabled()) {
        throw Exception(StringRes.at('enable_location_services'));
      }

      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied) {
        throw Exception(StringRes.at('location_permissions_denied'));
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          StringRes.at('location_permissions_permanently_denied'),
        );
      }

      final Position position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      final List<Placemark> marks = await placemarkFromCoordinates(
        position.latitude,
        position.longitude,
      );
      if (marks.isNotEmpty) {
        cityController.text =
            marks.first.locality ??
            marks.first.subAdministrativeArea ??
            StringRes.at('unknown_city');
      }
    } catch (e) {
      error = e.toString().replaceAll('Exception: ', '');
    } finally {
      locatingCity = false;
      notifyListeners();
    }
  }

  // requests a new otp using supabase phone auth.
  //
  // used for:
  // sending a verification sms to the user's phone number.
  //
  // design:
  // relies entirely on supabase auth instead of custom otp tables.
  // supabase automatically handles otp generation, expiration,
  // security, rate limiting and verification.
  Future<bool> requestOtp() async {
    if (!await _hasInternet()) {
      error = StringRes.at('no_internet_connection');
      notifyListeners();
      return false;
    }

    final String phone = phoneController.text.trim();

    if (phone.isEmpty) {
      error = StringRes.at('fill_all_fields');
      notifyListeners();
      return false;
    }

    loading = true;
    error = null;
    notifyListeners();

    try {
      await Supabase.instance.client.auth.signInWithOtp(
        phone: phone,
      );

      loading = false;
      notifyListeners();
      return true;
    } on AuthException catch (e) {
      loading = false;
      error = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      loading = false;
      error = StringRes.at('something_went_wrong');
      notifyListeners();
      return false;
    }
  }

  // verifies the otp and completes the signup flow.
  //
  // used for:
  // verifying the sms code and creating the user profile.
  //
  // design:
  // supabase auth handles authentication and session persistence,
  // while the custom "users" table stores profile data.
  Future<int> completeSignup() async {
    if (!canContinue) {
      error = StringRes.at('fill_all_fields');
      notifyListeners();
      return 0;
    }

    loading = true;
    notifyListeners();

    try {
      final result = await _db.completeSignup(
        accountType: accountType,
        username: nameController.text.trim(),
        phone: phoneController.text.trim(),
        password: passwordController.text.trim(),
        city: cityController.text.trim(),
        profileImage: profileImage,
      );

      loading = false;
      notifyListeners();
      return result;

    } catch (e) {
      loading = false;
      error = StringRes.at('something_went_wrong');
      notifyListeners();
      return 500;
    }
  }

  // moves to the next signup page.
  Future<void> _goNext() async {
    await pageController.nextPage(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  // checks if the device has internet connectivity.
  Future<bool> _hasInternet() async {
    final List<ConnectivityResult> result = await Connectivity()
        .checkConnectivity();
    return !result.contains(ConnectivityResult.none);
  }

  // validates the password with the app's existing requirements.
  String? _validatePassword(String password) {
    final bool valid =
        password.length >= 8 &&
        RegExp(r'[A-Z]').hasMatch(password) &&
        RegExp(r'[a-z]').hasMatch(password) &&
        RegExp(r'[0-9]').hasMatch(password) &&
        RegExp('[!@#\\\$&*~\\u00a3\\u20ac?\\u00a7+]').hasMatch(password);
    return valid ? null : StringRes.at('invalid_password');
  }

  // validates a phone number with an optional international prefix.
  bool _isValidPhone(String phone) {
    final String cleanPhone = phone.replaceAll(RegExp(r'[\s\-()]+'), '');
    return RegExp(r'^(\+?[0-9]{1,4})?[0-9]{9,11}$').hasMatch(cleanPhone);
  }

  // returns whether the phone contains digits after the prefix.
  bool _hasPhoneBody(String phone) {
    final String digits = phone.replaceAll(RegExp(r'[^0-9]'), '');
    return digits.length > _defaultPhonePrefix().replaceAll('+', '').length;
  }

  // returns a default phone prefix from the app locale.
  String _defaultPhonePrefix() {
    return switch (StringRes.locale) {
      'it' => '+39 ',
      'de' => '+49 ',
      'fr' => '+33 ',
      'es' => '+34 ',
      'zh' => '+86 ',
      _ => '+1 ',
    };
  }
}
