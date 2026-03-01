import 'package:flutter/material.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  String? errorMessage;
  bool isLoading = false;

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            /// EMAIL
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 20),

            /// PASSWORD
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 20),

            /// ERRORE
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),

            const SizedBox(height: 20),

            /// BUTTON
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: signup,
                    child: const Text("Signup"),
                  ),

            /// TORNA ALLA LOGIN
            TextButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
      ),
    );
  }

  /// ---------------- SIGNUP LOGIC ----------------
  void signup() async {
    String email = emailController.text.trim();
    String password = passwordController.text;

    setState(() => errorMessage = null);

    /// VALIDAZIONE EMAIL
    if (!_isValidEmail(email)) {
      setState(() => errorMessage = "Email non valida");
      return;
    }

    /// VALIDAZIONE PASSWORD
    String? passwordError = _validatePassword(password);

    if (passwordError != null) {
      setState(() => errorMessage = passwordError);
      return;
    }

    /// SIMULAZIONE CHIAMATA SERVER
    setState(() => isLoading = true);

    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() => isLoading = false);

    debugPrint("Signup OK: $email");
  }

  /// ---------------- VALIDATORS ----------------
  bool _isValidEmail(String email) {
    final emailRegex = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegex.hasMatch(email);
  }

  String? _validatePassword(String password) {
    if (password.length < 8) {
      return "At least 8 characters";
    }

    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "At least 1 uppercase letter";
    }

    if (!RegExp(r'[a-z]').hasMatch(password)) {
      return "At least 1 lowercase letter";
    }

    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "At least 1 number";
    }

    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) {
      return "At least 1 special char";
    }

    return null;
  }
}