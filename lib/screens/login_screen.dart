import 'package:flutter/material.dart';
import 'package:vez/screens/signup_screen.dart';

// classe pagina di Login
class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

// UI
class _LoginPageState extends State<LoginPage> {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

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
            // campo per inserire l'email
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),

            const SizedBox(height: 20),

            // campo per inserire la password
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),

            const SizedBox(height: 30),

            // pulsante login per inviare le credenziali
            ElevatedButton(
              onPressed: login,
              child: const Text("Login"),
            ),

            // pulsante per passare alla pagina di registrazione
            TextButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => SignupPage(),
                  ),
                );
              },
              child: const Text("Create account"),
            )
          ],
        ),
      ),
    );
  }

  void login() {
    String email = emailController.text;
    String password = passwordController.text;

    // qui si possono richiamare le funzioni di autenticazione esterne alla classe LoginPage
    debugPrint(email);
    debugPrint(password);
  }
}