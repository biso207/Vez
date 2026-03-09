// Developed and Designed by Outly • © 2026
// Screen to manage the signup process

// libraries
import 'package:flutter/material.dart';
import '../models/custom_widget.dart';
import '../services/remote_db_service.dart';
import 'dart:io'; // library to manage files
import 'package:image_picker/image_picker.dart';

import 'home_screen.dart'; // selector for the photos


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final RemoteDbService _dbService = RemoteDbService(); // instance of RemoteDbService
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Controller for text fields
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  DateTime? selectedDate;

  String? errorMessage;
  bool isLoading = false;

  File? _profileImage; // Variabile per memorizzare la foto scelta
  final ImagePicker _picker = ImagePicker();

  // UI of the page //
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Fondo nero per il blend
      body: Stack(
        children: [
          // 1. Immagine di sfondo con sfumatura verso il nero
          Positioned(
            child: Container(
              height: MediaQuery.of(context).size.height * 0.6,
              width: double.infinity,
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/bg/bg_signup.jpg'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.0),
                      Colors.black.withOpacity(0.5),
                      Colors.black,
                    ],
                  ),
                ),
              ),
            ),
          ),

          // 2. Contenuto della pagina
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 20),
              child: Column(
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    "Signup",
                    style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 30),

                  // Selettore Foto Profilo (modernizzato)
                  GestureDetector(
                    onTap: _pickImage,
                    child: Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white24, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 50,
                        backgroundColor: Colors.white10,
                        backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                        child: _profileImage == null
                            ? const Icon(Icons.camera_alt_outlined, size: 35, color: Colors.white)
                            : null,
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Campi di input usando il model personalizzato
                  VezTextField(controller: usernameController, label: "Username"),
                  const SizedBox(height: 15),
                  VezTextField(controller: passwordController, label: "Password", obscureText: true),
                  const SizedBox(height: 15),
                  VezTextField(controller: emailController, label: "Email"),
                  const SizedBox(height: 15),
                  VezTextField(controller: nameController, label: "Name"),
                  const SizedBox(height: 15),
                  VezTextField(controller: surnameController, label: "Surname"),

                  const SizedBox(height: 15),
                  // Data di Nascita stilizzata come i campi
                  InkWell(
                    onTap: () => _selectDate(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 15),
                      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24))),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            selectedDate == null ? "Date of Birth" : "${selectedDate!.toLocal()}".split(' ')[0],
                            style: TextStyle(color: selectedDate == null ? Colors.white70 : Colors.white, fontWeight: FontWeight.bold),
                          ),
                          const Icon(Icons.calendar_today, color: Colors.white70, size: 18),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 15),
                  VezTextField(controller: cityController, label: "City"),
                  const SizedBox(height: 40),

                  if (errorMessage != null) ...[
                    Text(errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                    const SizedBox(height: 20),
                  ],

                  // Pulsante Signup Liquid Glass
                  GlassButton(
                    text: "Enter",
                    isLoading: isLoading,
                    onPressed: signup,
                  ),

                  const SizedBox(height: 20),
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text("Already have an account? Login", style: TextStyle(color: Colors.white70)),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // method to do the signup process //
  void signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final username = usernameController.text.trim();
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final city = cityController.text.trim();

    setState(() => errorMessage = null);

    // check if all fields are filled
    if (username.isEmpty || name.isEmpty || surname.isEmpty || city.isEmpty || selectedDate == null) {
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
      name: name,
      surname: surname,
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

  // release resources
  @override
  void dispose() {
    emailController.dispose();
    passwordController.dispose();
    usernameController.dispose();
    nameController.dispose();
    surnameController.dispose();
    cityController.dispose();
    super.dispose();
  }

  // method to select the date of birth
  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
      firstDate: DateTime(1900),
      lastDate: DateTime.now(),
    );
    if (picked != null && picked != selectedDate) {
      setState(() {
        selectedDate = picked;
      });
    }
  }

  // method to pick the profile photo
  Future<void> _pickImage() async {
    final XFile? pickedFile = await _picker.pickImage(
      source: ImageSource.gallery, // O ImageSource.camera
      maxWidth: 512, // resizing to 512x512 (in the db is lighter)
      maxHeight: 512,
      imageQuality: 75,
    );

    if (pickedFile != null) {
      setState(() {
        _profileImage = File(pickedFile.path);
      });
    }
  }
}
