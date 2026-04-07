// Developed and Designed by Outly • © 2026
// Screen to manage the login process

import 'package:flutter/material.dart';
import 'package:vez/screens/signup_screen.dart';
import '../models/vez_glass.dart';
import '../services/auth_service.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RemoteDbService _dbService = RemoteDbService();
  String? errorMessage;
  bool isLoading = false;
  bool _showPassword = false;

  @override
  void initState() {
    super.initState();
    setState(() => errorMessage = null);
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
              "assets/images/bg/bg_login.jpg",
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
                          "Hey!",
                          style: TextStyle(
                            fontFamily: 'InstagramSans',
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        SizedBox(height: 8),
                        Text(
                          "Welcome Back to Vez",
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
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VezGlass.textField(
                            controller: usernameController,
                            hint: "Username",
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
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VezGlass.circleButton(
                        assetIcon: "assets/icons/auth/icon_login.png",
                        iconSize: 30,
                        onTap: login,
                      ),
                      const SizedBox(height: 60),
                      VezGlass.pillButton(
                        text: "I'M NEW",
                        color: Colors.white.withOpacity(0.5),
                        onTap: () {
                          // 1. Rimuove il banner di errore
                          setState(() => errorMessage = null);

                          // 2. Naviga alla pagina di Signup
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                                builder: (_) => const SignupPage()),
                          );
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 32),
                  SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
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

  // ── Logic ──────────────────────────────────────────────────────────────────

  void login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Please fill all fields");
      return;
    }

    setState(() {
      errorMessage = null;
      isLoading = true;
    });

    final int response = await _dbService.login(
      username: username,
      password: password,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    if (response == 200 || response == 201) {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => HomePage()),
      );
    } else {
      setState(() => errorMessage = "Invalid credentials");
      // Reset fields on failed login
      usernameController.clear();
      passwordController.clear();
    }
  }
}
