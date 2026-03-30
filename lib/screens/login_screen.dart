// Developed and Designed by Outly • © 2026
// Screen to manage the login process

import 'package:flutter/material.dart';
import 'package:vez/screens/signup_screen.dart';
import '../models/vez_glass.dart';
import '../services/remote_db_service.dart';
import 'home_screen.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> { // Rimosso SingleTickerProviderStateMixin
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RemoteDbService _dbService = RemoteDbService();
  String? errorMessage;
  bool isLoading = false;
  bool _showPassword = false;

  // Animazioni rimosse!

  @override
  void initState() {
    super.initState();
    // Non dobbiamo più inizializzare i controller dell'animazione
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }

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
                "assets/images/bg/bg_login.jpg",
                fit: BoxFit.cover,
              ),
            ),
          ),

          /// ================= ANIMATED CONTENT =================
          SafeArea(
            child: SizedBox(
              height:
                  (MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top) +
                  (MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
              child: Column(
                children: [
                  /// ====== 1) TOP: TITLE ======
                  const Spacer(),
                  const Center(
                    child: Text(
                      "Hey!",
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 34,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),

                  /// ====== 2) CENTRE: FORM ======
                  const Spacer(),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        VezGlass.textField(
                          controller: usernameController,
                          hint: "Username",
                          width: MediaQuery.of(context).size.width * 0.75,
                        ),
                        const SizedBox(height: 20),
                        VezGlass.textField(
                          controller: passwordController,
                          hint: "Password",
                          obscure: !_showPassword,
                          width: MediaQuery.of(context).size.width * 0.75,
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
                  ),

                  /// ====== 3) BOTTOM: ACTIONS ======
                  const Spacer(),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      VezGlass.circleButton(
                        assetIcon: "assets/images/icons/icon_login.png",
                        iconSize: 30,
                        onTap: login,
                      ),
                      const SizedBox(height: 24),
                      VezGlass.pillButton(
                        text: "Signup",
                        color: Colors.white.withOpacity(0.5),
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (_) => const SignupPage()),
                        ),
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

  // ── logic ──────────────────────────────────────────────────────────────────

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
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    } else {
      setState(() => errorMessage = "Invalid credentials");
    }
  }
}
