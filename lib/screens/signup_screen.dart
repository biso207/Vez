// Developed and Designed by Outly • © 2026
// Signup screen with 3-step navigation based on design mocks

// libraries
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

// todo: add to the 'save' button the command to do the signup process

class _SignupPageState extends State<SignupPage> {
  final RemoteDbService _dbService = RemoteDbService();

  // controllers for text fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  DateTime? selectedDate;

  String? errorMessage;
  bool isLoading = false;
  File? _profileImage;
  final ImagePicker _picker = ImagePicker();


  final PageController controller = PageController();
  int page = 0;

  void next() => controller.nextPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

  void back() => controller.previousPage(
    duration: const Duration(milliseconds: 300),
    curve: Curves.easeOut,
  );

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
                            assetIcon: "assets/images/icons/icon_login.png",
                            onTap: () => Navigator.pop(context),
                            size: 50,
                            iconSize: 30,
                          ),
                          const Expanded(
                            child: Center(
                              child: Text(
                                "Welcome",
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

                    /// ================= SLIDES (IL CENTRO) =================
                    SizedBox(
                      height: 440,
                      child: PageView(
                        controller: controller,
                        onPageChanged: (i) => setState(() => page = i),
                        children: [
                          stepOne(),
                          stepTwo(),
                          stepThree(),
                        ],
                      ),
                    ),

                    const Spacer(),

                    /// NAVIGATION & FOOTER
                    navigation(),

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

  /// ---------------- STEP 1 ----------------
  Widget stepOne() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: _pickImage,
            child: ClipOval(
              child: Container(
                width: 110,
                height: 110,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [

                    /// GLASS BUTTON BACKGROUND
                    VezGlass.circleButton(
                      assetIcon: "assets/images/icons/icon_camera.png",
                      onTap: _pickImage,
                      size: 60,
                      iconSize: 40,
                    ),

                    /// CONTENT
                    _profileImage != null
                        ? ClipOval(
                      child: Image.file(
                        _profileImage!,
                        width: 100,
                        height: 100,
                        fit: BoxFit.cover,
                      ),
                    )
                        : Image.asset(
                      "assets/images/icons/icon_camera.png",
                      width: 40,
                      height: 40,
                    ),
                  ],
                ),
              ),
            ),
          ),

          const SizedBox(height: 40),

          VezGlass.textField(
            controller: usernameController,
            hint: "Username",
            width: MediaQuery.of(context).size.width * 0.75,
            height: 44,
            radius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }

  /// ---------------- STEP 2 ----------------
  Widget stepTwo() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          VezGlass.textField(
            controller: emailController,
            hint: "Email",
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
    );
  }

  /// ---------------- STEP 3 ----------------
  Widget stepThree() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () => _selectDate(context),
            child: AbsorbPointer( // Impedisce al TextField interno di prendere il focus
              child: VezGlass.textField(
                // Usiamo il controller per mostrare la data selezionata
                controller: TextEditingController(
                  text: selectedDate == null
                      ? ""
                      : "${selectedDate!.toLocal()}".split(' ')[0],
                ),
                hint: "Date Of Birth",
                width: MediaQuery.of(context).size.width * 0.75,
                height: 44,
                radius: BorderRadius.circular(20),
                // Se VezGlass lo supporta, aggiungi l'icona qui
                // suffixIcon: const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
              ),
            ),
          ),

          const SizedBox(height: 20),

          VezGlass.textField(
            controller: cityController,
            hint: "City",
            width: MediaQuery.of(context).size.width * 0.75,
            height: 44,
            radius: BorderRadius.circular(20),
          ),
        ],
      ),
    );
  }

  /// ---------------- NAVIGATION ----------------
  Widget navigation() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [

        if (page > 0)
          VezGlass.circleButton(
            assetIcon:
            "assets/images/icons/icon_next.png",
            rotation: 3.1416,
            onTap: back,
          ),

        if (page > 0) const SizedBox(width: 40),

        VezGlass.circleButton(
          assetIcon: page == 2
              ? "assets/images/icons/icon_save.png"
              : "assets/images/icons/icon_next.png",
          onTap: () {
            if (page == 2) { signup(); } // signup process
            else { next(); } // next page
          },
        ),
      ],
    );
  }

  // method to do the signup process //
  void signup() async {
    final username = usernameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text;
    final city = cityController.text.trim();

    setState(() => errorMessage = null);

    // check if all fields are filled
    if (username.isEmpty || password.isEmpty || email.isEmpty || city.isEmpty || selectedDate == null) {
      setState(() => errorMessage = "Please fill all fields");
      return;
    }

    // email validation
    if (!_isValidEmail(email)) {
      setState(() => errorMessage = "Invalid email");
      return;
    }
    // password validation
    String? passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() => errorMessage = passwordError);
      return;
    }

    setState(() => isLoading = true);

    // POST request to the db => creation of a new user
    int response = await _dbService.signup(
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

    // data correctly sent to the db
    if (response == 200 || response == 201) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Successful!")),
      );

      // next step -> navigate home
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => const HomePage(),
        ), // next page is the home page
      );
    }
    else if (response == 409) {
      setState(() => errorMessage = "Username already in use");
    }
    else {
      setState(() => errorMessage = "Signup failed");
    }
  }

  // regex to check  and validate the email
  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }
  // regex to check and validate the psw
  String? _validatePassword(String password) {
    if (password.length < 8) return "At least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(password)) return "At least 1 uppercase letter";
    if (!RegExp(r'[a-z]').hasMatch(password)) return "At least 1 lowercase letter";
    if (!RegExp(r'[0-9]').hasMatch(password)) return "At least 1 number";
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) return "At least 1 special char";
    return null;
  }

  // method to select the date of birth
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => selectedDate = picked);
  }
  // method to select the profile photo
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery, maxWidth: 512, maxHeight: 512, imageQuality: 75);
    if (pickedFile != null) setState(() => _profileImage = File(pickedFile.path));
  }

  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    cityController.dispose();
    super.dispose();
  }
}