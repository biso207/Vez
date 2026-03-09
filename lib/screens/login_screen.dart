// Developed and Designed by Outly • © 2026
// Screen to manage the login process

// libraries
import 'package:flutter/material.dart';
import 'package:vez/screens/signup_screen.dart';

import '../services/remote_db_service.dart';
import 'home_screen.dart';

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

  final RemoteDbService _dbService = RemoteDbService();
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

  // todo: check here the login process 'cause the POST request is not working
  // method to do the login process //
  void login() async {
    final username = emailController.text.trim();
    final password = passwordController.text;

    setState(() => errorMessage = null);

    // check if all fields are filled
    if (username.isEmpty || password.isEmpty) {
      setState(() => errorMessage = "Please fill all fields");
      return;
    }

    setState(() => isLoading = true);

    // POST request to the db => creation of a new user
    int response = await _dbService.login(
      username: username,
      password: password,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    // data correctly sent to the db
    if (response == 200 || response == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Login Successful!")),
      );

      // next step -> navigate home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ), // next page is the home page
      );
    }
    else if (response == 401) {
      setState(() => errorMessage = "Invalid Credentials");
    }
    else {
      setState(() => errorMessage = "Server error during login: $response");
    }
  }
}