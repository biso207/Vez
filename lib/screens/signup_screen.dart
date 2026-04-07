// Developed and Designed by Outly • © 2026
// Signup screen with 3-step navigation based on design mocks

import 'package:intl/intl.dart';
import 'package:flutter/material.dart';
import '../models/vez_glass.dart';
import '../services/auth_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';
import 'package:geolocator/geolocator.dart';
import 'package:geocoding/geocoding.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final RemoteDbService _dbService = RemoteDbService();

  // Controllers for each form field
  final TextEditingController emailController    = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController cityController     = TextEditingController();
  DateTime? selectedDate;

  String? errorMessage;
  bool isLoading = false;
  bool _showPassword = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();

  // Page navigation
  final PageController _pageController = PageController();
  int page = 0;

  bool _isLocatingCity = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    cityController.dispose();
    super.dispose();
  }

  /// Advances to the next signup step
  void next() => _pageController.nextPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  /// Goes back to the previous signup step
  void back() => _pageController.previousPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  // --- PAGE LAYOUT ---
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// ================= BACKGROUND =================
          Positioned.fill(
            child: Image.asset(
              "assets/images/bg/bg_signup.jpg",
              fit: BoxFit.cover,
            ),
          ),

          /// ================= STATIC CONTENT =================
          SafeArea(
            child: SizedBox(
              height:
                (MediaQuery.of(context).size.height -
                MediaQuery.of(context).padding.top) +
                (MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
              child: Column(
                children: [
                  /// ====== 1) TOP: TITLE ======
                  const Spacer(flex: 2),
                  const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          "Welcome to Vez",
                          style: TextStyle(
                            fontFamily: 'InstagramSans',
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Create and Enjoy real life events",
                          style: TextStyle(
                            fontFamily: 'InstagramSans',
                            color: Colors.white,
                            fontSize: 25,
                            fontWeight: FontWeight.normal,
                          ),
                        ),
                      ],
                    ),
                  ),

                  /// ====== 2) CENTRE: FORM ======
                  const Spacer(flex: 3),
                  SizedBox(
                    height: 300,
                    child: PageView(
                      controller: _pageController,
                      physics: const NeverScrollableScrollPhysics(),
                      onPageChanged: (i) {
                        setState(() {
                          page = i;
                          errorMessage = null; // Clear errors on step change
                        });
                      },
                      children: [
                        _stepOne(),
                        _stepTwo(),
                        _stepThree(),
                      ],
                    ),
                  ),

                  /// ================= ERROR BANNER =================
                  /// Fix: replaced the fixed-height [SizedBox] (which clipped
                  /// multi-line messages) with [AnimatedSize] so the area
                  /// grows/shrinks smoothly to fit the full banner content.
                  /// [AnimatedOpacity] handles the fade-in/out independently.
                  const Spacer(flex: 3),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 30),
                    child: AnimatedSize(
                      duration: const Duration(milliseconds: 300),
                      curve: Curves.easeOut,
                      child: AnimatedOpacity(
                        opacity: errorMessage != null ? 1.0 : 0.0,
                        duration: const Duration(milliseconds: 300),
                        curve: Curves.easeOut,
                        // When null: zero-size placeholder so the layout stays
                        // stable while the opacity animation plays out.
                        child: errorMessage != null
                            ? VezErrorBanner(message: errorMessage!)
                            : const SizedBox.shrink(),
                      ),
                    ),
                  ),

                  /// ====== 3) BOTTOM: ACTIONS ======
                  const Spacer(flex: 3),
                  _StepDots(currentPage: page, total: 3),
                  const Spacer(flex: 3),
                  _navigation(),
                  const SizedBox(height: 60),
                  VezGlass.pillButton(
                    text: "I'M BACK",
                    color: Colors.white38,
                    onTap: () => Navigator.pop(context),
                  ),
                  const SizedBox(height: 48),
                ],
              ),
            ),
          ),

          /// ================= LOADING OVERLAY =================
          if (isLoading) const VezLoadingOverlay(),
        ],
      ),
    );
  }

  // ── Step widgets ────────────────────────────────────────────────────────────

  // First page: avatar + username
  Widget _stepOne() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Avatar picker
          GestureDetector(
            onTap: _pickImage,
            child: SizedBox(
              width: 100,
              height: 100,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glass circle background
                  VezGlass.circleButton(
                    assetIcon: "assets/icons/auth/icon_camera_90x90.png",
                    onTap: _pickImage,
                    size: 100,
                    iconSize: 50
                  ),

                  // Profile photo on top when selected
                  if (_profileImage != null)
                    Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: Colors.white10,
                          width: 3,
                        ),
                      ),
                      child: ClipOval(
                        child: Image.file(
                          _profileImage!,
                          width: 100,
                          height: 100,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 20),

          VezGlass.textField(
            controller: usernameController,
            hint: "Username",
            width: MediaQuery.of(context).size.width * 0.75,
            color: Colors.white54,
          ),
        ],
      ),
    );
  }

  // Second page: email + password
  Widget _stepTwo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VezGlass.textField(
            controller: emailController,
            hint: "Email",
            width: MediaQuery.of(context).size.width * 0.75,
            color: Colors.white54,
          ),

          const SizedBox(height: 20),

          VezGlass.textField(
            controller: passwordController,
            hint: "Password",
            obscure: !_showPassword, // icon show/not show psw
            width: MediaQuery.of(context).size.width * 0.75,
            color: Colors.white54,

            // Detector for the tap on the eye icon
            suffixIcon: GestureDetector(
              onTap: () => setState(
                      () => _showPassword = !_showPassword),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  !_showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white54,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // Third page: date of birth + city
  Widget _stepThree() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _selectDate(context),
            child: AbsorbPointer(
              child: VezGlass.textField(
                controller: TextEditingController(
                  text: selectedDate == null
                      ? ""
                      : DateFormat.yMd(Localizations.localeOf(context).toString()).format(selectedDate!),
                ),
                hint: "Date Of Birth",
                width: MediaQuery.of(context).size.width * 0.75,
                color: Colors.white54,
              ),
            ),
          ),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: _fetchUserCity, // Tapping starts GPS lookup
            child: AbsorbPointer(
              // AbsorbPointer blocks inner taps so the keyboard never opens
              child: Stack(
                alignment: Alignment.centerRight,
                children: [
                  VezGlass.textField(
                    controller: cityController,
                    // Hint changes while locating
                    hint: _isLocatingCity ? "Locating your city..." : "Tap to set City",
                    width: MediaQuery.of(context).size.width * 0.75,
                    color: Colors.white54,
                  ),
                  // Show a spinner inside the field while locating
                  if (_isLocatingCity)
                    const Padding(
                      padding: EdgeInsets.only(right: 15.0),
                      child: SizedBox(
                        width: 20, height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      ),
                    ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  // Buttons to navigate through the steps
  Widget _navigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Back button — only visible from step 2 onwards
        if (page > 0)
          VezGlass.circleButton(
            assetIcon: "assets/icons/auth/icon_next.png",
            rotation: 3.1416,
            onTap: back,
          ),
        if (page > 0) const SizedBox(width: 40),
        VezGlass.circleButton(
          assetIcon: page == 2
              ? "assets/icons/auth/icon_save.png"
              : "assets/icons/auth/icon_next.png",
          onTap: () {
              // Clear any previous error
              setState(() => errorMessage = null);

              final username = usernameController.text.trim();
              final email    = emailController.text.trim();
              final password = passwordController.text;
              final city     = cityController.text.trim();

              switch (page) {
                case 0:
                  // username not digitated
                  if (username.isEmpty) {
                    setState(() => errorMessage = "Please choose a username");
                    return;
                  }

                  if (_profileImage == null) {
                    setState(() => errorMessage = "Please choose a profile photo");
                    return;
                  }

                  // Username must be at least 3 characters
                  if (username.length < 3) {
                    setState(() => errorMessage = "Username is too short (Min. 3 chars)");
                    return;
                  }

                  // Username must be less than 15 characters
                  if (username.length > 15) {
                    setState(() => errorMessage = "Username is too long (Max 15 chars)");
                    return;
                  }

                  next();
                  break;

                case 1:
                  // Check that all fields on step 2 are filled
                  if (page == 1 && (password.isEmpty || email.isEmpty)) {
                    setState(() => errorMessage = "Please fill all fields");
                    return;
                  }

                  // Validate email format
                  if (!_isValidEmail(email)) {
                    setState(() => errorMessage = "Invalid email");
                    return;
                  }

                  // Validate password strength
                  final String? passwordError = _validatePassword(password);
                  if (passwordError != null) {
                    setState(() => errorMessage = passwordError);
                    return;
                  }

                  next();
                  break;

                case 2:
                  // Check that all fields on step 3 are filled
                  if (city.isEmpty || selectedDate == null) {
                    setState(() => errorMessage = "Please fill all fields");
                    return;
                  }

                  signup();
                  break;

                default:
                  setState(() => errorMessage = "Something went wrong");
            }
          },
        ),
      ],
    );
  }

  // ── Logic ───────────────────────────────────────────────────────────────────

  void signup() async {
    final username = usernameController.text.trim();
    final email    = emailController.text.trim();
    final password = passwordController.text;
    final city     = cityController.text.trim();

    setState(() => isLoading = true);

    final int response = await _dbService.signup(
      email: email,
      password: password,
      username: username,
      name: "",
      surname: "",
      dateOfBirth: selectedDate!,
      city: city,
      profileImage: _profileImage,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response == 200 || response == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Successful!")),
      );
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else if (response == 409) {
      setState(() => errorMessage = "User already exists");
    } else {
      setState(() => errorMessage = "Signup failed\n${response.toString()}");
    }
  }

  /// Returns a formatted error string if the password does not meet the rules,
  /// or null if the password is valid.
  String? _validatePassword(String password) {
    if (!_isValidPsw(password)) {
      return "Invalid Password.\nNeed 8 chars, 1 uppercase, 1 lowercase, 1 number, 1 special.";
    }
    return null;
  }

  /// Returns true only if [password] satisfies all strength requirements.
  bool _isValidPsw(String password) {
    if (password.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#$&*~£€?§+]').hasMatch(password)
    ) { return false; }
    return true;
  }

  /// Returns true if [email] matches a standard email pattern.
  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  /// Opens the system date picker and stores the selected date.
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  /// Opens the gallery to let the user pick a profile photo.
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 512,
      maxHeight: 512,
      imageQuality: 75,
    );
    if (pickedFile != null) {
      setState(() => _profileImage = File(pickedFile.path));
    }
  }

  /// Uses the device GPS to automatically fill the city field.
  Future<void> _fetchUserCity() async {
    // Show the user that we are searching
    setState(() {
      _isLocatingCity = true;
      errorMessage = null; // Clear any previous error
    });

    try {
      // 1. Check whether the device location service is enabled
      bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
      if (!serviceEnabled) {
        throw Exception("Please enable location services on your device.");
      }

      // 2. Check and request location permission
      LocationPermission permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        if (permission == LocationPermission.denied) {
          throw Exception("Location permissions are denied.");
        }
      }
      if (permission == LocationPermission.deniedForever) {
        throw Exception("Location permissions are permanently denied. Change it in settings.");
      }

      // 3. Obtain the precise coordinates
      Position position = await Geolocator.getCurrentPosition(
          desiredAccuracy: LocationAccuracy.high
      );

      // 4. Reverse geocoding: coordinates → city name
      List<Placemark> placemarks = await placemarkFromCoordinates(
          position.latitude, position.longitude
      );

      if (placemarks.isNotEmpty) {
        Placemark place = placemarks.first;
        // 'locality' is usually the main city; fall back to sub-administrative area
        String cityName = place.locality ?? place.subAdministrativeArea ?? "Unknown City";

        setState(() {
          cityController.text = cityName; // Auto-fill the field
        });
      }
    } catch (e) {
      // Show any error in the banner
      setState(() {
        errorMessage = e.toString().replaceAll("Exception: ", "");
      });
    } finally {
      // Always stop the loading indicator
      setState(() {
        _isLocatingCity = false;
      });
    }
  }
}

// ── Step dots indicator ──────────────────────────────────────────────────────

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
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeInOut,
          margin: const EdgeInsets.symmetric(horizontal: 5),
          width: active ? 22 : 8,
          height: 8,
          decoration: BoxDecoration(
            color: active
                ? Colors.white
                : Colors.white.withOpacity(0.35),
            borderRadius: BorderRadius.circular(4),
          ),
        );
      }),
    );
  }
}
