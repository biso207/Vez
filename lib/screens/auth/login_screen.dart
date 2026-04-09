// Developed and Designed by Outly • © 2026
// Screen to manage the login process

import 'package:flutter/material.dart';
import 'package:vez/screens/auth/signup_screen.dart';
import 'dart:ui';
import '../../models/vez_glass.dart';
import '../../models/vez_popup.dart';
import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../home_screen.dart';

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
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          StringRes.at("top_title_login"),
                          style: TextStyle(
                            fontFamily: 'InstagramSans',
                            color: Colors.white,
                            fontSize: 40,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          StringRes.at("under_title_login"),
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
                            hint: StringRes.at("username"),
                            width: MediaQuery.of(context).size.width * 0.75,
                            color: Colors.white54,
                          ),
                          const SizedBox(height: 20),
                          VezGlass.textField(
                            controller: passwordController,
                            hint: StringRes.at("password"),
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
                        text: StringRes.at("login"),
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

          /// ================= LANGUAGE SELECTOR =================
          SafeArea(
            child: Align(
              alignment: Alignment.topRight,
              child: Padding(
                padding: const EdgeInsets.only(top: 10, right: 16),
                child: GestureDetector(
                  onTap: _showLanguagePopup,
                  child: ClipOval(
                    child: BackdropFilter(
                      filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                      child: Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.white.withOpacity(0.15),
                          border: Border.all(color: Colors.white24, width: 1.5),
                        ),
                        child: Text(
                          StringRes.locale == 'it' ? '🇮🇹' : '🇬🇧',
                          style: const TextStyle(fontSize: 22),
                        ),
                      ),
                    ),
                  ),
                ),
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

  void _showLanguagePopup() {
    VezPopup.show(
      context: context,
      width: MediaQuery.of(context).size.width * 0.55,
      backgroundColor: const Color.fromARGB(200, 14, 14, 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            StringRes.at("select_language"),
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 18),
          ),
          const SizedBox(height: 15),
          _buildLanguageOption('🇬🇧', StringRes.at("lang_en"), 'en'),
          const SizedBox(height: 8),
          _buildLanguageOption('🇮🇹', StringRes.at("lang_it"), 'it'),
        ],
      ),
    );
  }

  Widget _buildLanguageOption(String flag, String label, String localeCode) {
    final bool isSelected = StringRes.locale == localeCode;
    return GestureDetector(
      onTap: () {
        StringRes.setLocale(localeCode);
        Navigator.pop(context);
        setState(() {}); // rebuild UI with new language
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          color: isSelected ? Colors.white.withOpacity(0.15) : Colors.transparent,
          borderRadius: BorderRadius.circular(15),
          border: isSelected ? Border.all(color: Colors.white24, width: 1.5) : null,
        ),
        child: Row(
          children: [
            Text(flag, style: const TextStyle(fontSize: 24)),
            const SizedBox(width: 12),
            Text(
              label,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
              ),
            ),
            const Spacer(),
            if (isSelected)
              const Icon(Icons.check_circle, color: Colors.white, size: 20),
          ],
        ),
      ),
    );
  }

  void login() async {
    final username = usernameController.text.trim();
    final password = passwordController.text;

    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = StringRes.at("fill_all_fields"));
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
      setState(() => errorMessage = StringRes.at("invalid_credentials"));
      // Reset fields on failed login
      usernameController.clear();
      passwordController.clear();
    }
  }
}
