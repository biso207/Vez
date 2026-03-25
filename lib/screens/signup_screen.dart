// Developed and Designed by Outly • © 2026
// Signup screen with 3-step navigation based on design mocks

import 'package:flutter/material.dart';
import '../models/vez_glass.dart';
import '../services/remote_db_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage>
    with SingleTickerProviderStateMixin {
  final RemoteDbService _dbService = RemoteDbService();

  // controllers
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

  // page navigation
  final PageController _pageController = PageController();
  int page = 0;

  // ── entrance animation ──────────────────────────────────────────────────────
  late final AnimationController _entranceCtrl;
  late final Animation<double>   _fadeAnim;
  late final Animation<Offset>   _slideAnim;

  @override
  void initState() {
    super.initState();
    _entranceCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
    _fadeAnim  = CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.06),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _entranceCtrl, curve: Curves.easeOut));
    _entranceCtrl.forward();
  }

  @override
  void dispose() {
    _entranceCtrl.dispose();
    _pageController.dispose();
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    cityController.dispose();
    super.dispose();
  }

  void next() => _pageController.nextPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  void back() => _pageController.previousPage(
    duration: const Duration(milliseconds: 350),
    curve: Curves.easeInOut,
  );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// ================= BACKGROUND =================

          Positioned.fill(
            child: ColorFiltered(
              colorFilter: const ColorFilter.matrix(<double>[
                1.2, 0, 0, 0, 0,
                0, 1.2, 0, 0, 0,
                0, 0, 1.2, 0, 0,
                0, 0, 0, 1.2, 0,
              ]),
              child: Image.asset(
                "assets/images/bg/bg_signup.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// ================= ANIMATED CONTENT =================
          FadeTransition(
            opacity: _fadeAnim,
            child: SlideTransition(
              position: _slideAnim,
              child: SafeArea(
                child: SizedBox(
                  height: (MediaQuery.of(context).size.height -
                      MediaQuery.of(context).padding.top) +
                      (MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
                  child: Column(
                    children: [
                      /// ====== 1) TOP: TITLE ======
                      const Spacer(),
                      const Center(
                        child: Text(
                          "Welcome",
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 34,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),

                      /// ====== 2) CENTRE: FORM ======
                      const Spacer(),
                      SizedBox(
                        height: 300,
                        child: PageView(
                          controller: _pageController,
                          physics: const NeverScrollableScrollPhysics(),
                          onPageChanged: (i) {
                            setState(() {
                              page = i;
                              errorMessage = null; // clear errors on step change
                            });
                          },
                          children: [
                            _stepOne(),
                            _stepTwo(),
                            _stepThree(),
                          ],
                        ),
                      ),

                      /// ====== 3) BOTTOM: ACTIONS ======
                      const Spacer(),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          _StepDots(currentPage: page, total: 3),
                          const SizedBox(height: 24),
                          _navigation(),
                          const SizedBox(height: 24),
                          VezGlass.pillButton(
                            text: "Login",
                            color: Colors.white.withOpacity(0.5),
                            onTap: () => Navigator.pop(context),
                          ),
                        ],
                      ),
                      const SizedBox(height: 60),
                      SizedBox(
                          height: MediaQuery.of(context).viewInsets.bottom),
                    ],
                  ),
                ),
              ),
            ),
          ),

          /// ================= ERROR BANNER (floating, no layout shift) =================
          Positioned(
            bottom: 220,
            left: 0,
            right: 0,
            child: AnimatedOpacity(
              opacity: errorMessage != null ? 1.0 : 0.0,
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeOut,
              child: errorMessage != null
                  ? Center(child: VezErrorBanner(message: errorMessage!))
                  : const SizedBox.shrink(),
            ),
          ),

          /// ================= LOADING OVERLAY =================
          if (isLoading) const VezLoadingOverlay(),
        ],
      ),
    );
  }

  // ── Step widgets ────────────────────────────────────────────────────────────
  // first page
  Widget _stepOne() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          /// Avatar picker
          GestureDetector(
            onTap: _pickImage,
            child: SizedBox(
              width: 110,
              height: 110,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  // Glass circle background
                  VezGlass.circleButton(
                    assetIcon: "assets/images/icons/icon_camera.png",
                    onTap: _pickImage,
                    size: 70,
                    iconSize: 60,
                  ),
                  // Profile photo on top when selected
                  if (_profileImage != null)
                    ClipOval(
                      child: Image.file(
                        _profileImage!,
                        width: 110,
                        height: 110,
                        fit: BoxFit.cover,
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
          ),
        ],
      ),
    );
  }

  // second page
  Widget _stepTwo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VezGlass.textField(
            controller: emailController,
            hint: "Email",
            width: MediaQuery.of(context).size.width * 0.75,
          ),

          const SizedBox(height: 20),

          VezGlass.textField(
            controller: passwordController,
            hint: "Password",
            obscure: !_showPassword,
            width:
            MediaQuery.of(context).size.width * 0.75,
            suffixIcon: GestureDetector(
              onTap: () => setState(
                      () => _showPassword = !_showPassword),
              child: Padding(
                padding: const EdgeInsets.only(right: 6),
                child: Icon(
                  !_showPassword
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  color: Colors.white70,
                  size: 20,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // third page
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
                      : "${selectedDate!.toLocal()}".split(' ')[0],
                ),
                hint: "Date Of Birth",
                width: MediaQuery.of(context).size.width * 0.75,
              ),
            ),
          ),
          const SizedBox(height: 20),
          VezGlass.textField(
            controller: cityController,
            hint: "City",
            width: MediaQuery.of(context).size.width * 0.75,
          ),
        ],
      ),
    );
  }

  // buttons to navigate thru the pages
  Widget _navigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (page > 0)
          VezGlass.circleButton(
            assetIcon: "assets/images/icons/icon_next.png",
            rotation: 3.1416,
            onTap: back,
          ),
        if (page > 0) const SizedBox(width: 40),
        VezGlass.circleButton(
          assetIcon: page == 2
              ? "assets/images/icons/icon_save.png"
              : "assets/images/icons/icon_next.png",
          onTap: () {
            if (page == 2) {
              signup();
            } else {
              next();
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

    setState(() => errorMessage = null);

    if (username.isEmpty ||
        password.isEmpty ||
        email.isEmpty ||
        city.isEmpty ||
        selectedDate == null ||
        _profileImage == null) {
      setState(() => errorMessage = "Please fill all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => errorMessage = "Invalid email");
      return;
    }

    final String? passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() => errorMessage = passwordError);
      return;
    }

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
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else if (response == 409) {
      setState(() => errorMessage = "User already exists");
    } else {
      setState(() => errorMessage = "Signup failed");
    }
  }

  // password error message
  String? _validatePassword(String password) {
    if (!_isValidPsw(password)) {
      return "Invalid Password - At least:\n"
          "• 8 characters\n"
          "• 1 uppercase letter\n"
          "• 1 lowercase letter\n"
          "• 1 number\n"
          "• 1 special character"; }
    return null;
  }

  // password validator
  bool _isValidPsw(String password) {
    if (password.length < 8 ||
        !RegExp(r'[A-Z]').hasMatch(password) ||
        !RegExp(r'[a-z]').hasMatch(password) ||
        !RegExp(r'[0-9]').hasMatch(password) ||
        !RegExp(r'[!@#\$&*~]').hasMatch(password)
    ) { return false; }
    return true;
  }

  // email validator
  bool _isValidEmail(String email) =>
      RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);

  // date selector
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }

  // image picker
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