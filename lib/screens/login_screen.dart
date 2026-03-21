// Developed and Designed by Outly • © 2026
// Screen to manage the login process

// libraries
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

class _LoginPageState extends State<LoginPage> {
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  final RemoteDbService _dbService = RemoteDbService();
  String? errorMessage;
  bool isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [

          /// ================= BACKGROUND =================

          // 1. L'IMMAGINE (Nitida)
          Positioned(
            top: -80,
            left: 0,
            right: 0,
            bottom: 100, // Portiamola un po' più giù (prima era 150) per dare margine al gradiente
            child: ColorFiltered(
              // this matrix fix the brightness of the image (1 is original, >1 is brighter, <1 is darker)
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

          // 2. IL GRADIENTE (La "sfumatura dolce")
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withOpacity(0.3), // Scurisce il cielo per far leggere meglio i tasti in alto
                    Colors.transparent,            // Area di massima nitidezza (palazzi)
                    Colors.black.withOpacity(0.1), // Inizio impercettibile della sfumatura
                    Colors.black.withOpacity(0.6), // Sfumatura media
                    Colors.black.withOpacity(0.9), // Quasi nero dove l'immagine finisce
                    Colors.black,                  // Nero pece finale
                  ],
                  // Regoliamo gli stops: la magia avviene tra 0.4 e 0.8
                  stops: const [0.0, 0.2, 0.45, 0.65, 0.85, 1.0],
                ),
              ),
            ),
          ),

          /// ================= CONTENT =================
          SafeArea(
            child: SingleChildScrollView(
              // Rimuoviamo il padding bottom manuale perché useremo un'altezza dinamica
              child: SizedBox(
                // se la tastiera è aperta, l'altezza deve essere
                // quella dello schermo + l'altezza della tastiera per permettere lo scroll.
                height: (MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top) +
                    (MediaQuery.of(context).viewInsets.bottom > 0 ? 300 : 0),
                child: Column(
                  children: [
                    const SizedBox(height: 60),

                    /// HEADER
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          VezGlass.circleButton(
                            assetIcon: "assets/images/icons/icon_signup.png",
                            onTap: () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => const SignupPage()),
                            ),
                            size: 50,
                            iconSize: 30,
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Hey!",
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 30,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(width: 48), // Bilanciamento per il cerchio a sx
                        ],
                      ),
                    ),

                    const Spacer(),

                    /// CENTER
                    Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          VezGlass.textField(
                            controller: usernameController,
                            hint: "Username",
                            width: MediaQuery.of(context).size.width * 0.75,
                            height: 44,
                            radius: BorderRadius.circular(20),
                          ),

                          const SizedBox(height: 20),

                          VezGlass.textField(
                            controller: passwordController,
                            hint: "Password",
                            obscure: true,
                            width: MediaQuery.of(context).size.width * 0.75,
                            height: 44,
                            radius: BorderRadius.circular(20),
                          ),
                        ],
                      ),
                    ),

                    const Spacer(),

                    /// NAVIGATION & FOOTER
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [

                        VezGlass.circleButton(
                          assetIcon:
                          "assets/images/icons/icon_login.png",
                          iconSize: 30,
                          onTap: () {login();},
                        ),
                      ],
                    ),

                    const SizedBox(height: 60),

                    // AGGIUNGI QUESTO:
                    // Un piccolo spazio extra che appare solo quando la tastiera è fuori
                    SizedBox(height: MediaQuery.of(context).viewInsets.bottom),
                  ],
                ),
              ),
            ),
          )
        ],
      ),
    );
  }

  // todo: check the method, is not working
  // method to do the login process //
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

    int response = await _dbService.login(
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
    }
    else {
      setState(() => errorMessage = "Invalid credentials");
    }
  }

  @override
  void dispose() {
    usernameController.dispose();
    passwordController.dispose();
    super.dispose();
  }
}