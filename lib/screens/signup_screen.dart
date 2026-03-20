// Developed and Designed by Outly • © 2026
// Signup screen with 3-step navigation based on design mocks

// libraries
import 'package:flutter/material.dart';
import '../models/custom_widget.dart';
import '../services/remote_db_service.dart';
import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'home_screen.dart';

// todo: improve the UI

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final RemoteDbService _dbService = RemoteDbService();
  int _currentPage = 0; // current step handler

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. static background and gradient
          Positioned.fill(
            child: Container(
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
                      Colors.black.withOpacity(0.1),
                      Colors.black.withOpacity(0.4),
                      Colors.black,
                    ],
                    stops: const [0.0, 0.5, 0.9],
                  ),
                ),
              ),
            ),
          ),

          // 2. page content
          SafeArea(
            child: Column(
              children: [
                // spacer to push the header down from the very top
                const SizedBox(height: 30),

                // fixed header with login button and title
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.login_outlined, color: Colors.white, size: 28),
                        onPressed: () => Navigator.pop(context),
                      ),
                      const Expanded(
                        child: Center(
                          child: Text(
                            "Signup",
                            style: TextStyle(
                                color: Colors.white,
                                fontSize: 32,
                                fontWeight: FontWeight.bold
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 48), // balance for the back icon
                    ],
                  ),
                ),

                // spacers and dynamic content aligned to center height
                const Spacer(flex: 2),

                // dynamic area for the steps
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: _buildCurrentStep(),
                ),

                const Spacer(flex: 3),

                if (errorMessage != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: Text(errorMessage!, style: const TextStyle(color: Colors.redAccent)),
                  ),

                // 3. navigation footer pushed up from the bottom
                _buildNavigationFooter(),

                // bottom spacing to lift buttons as per mockups
                const SizedBox(height: 80),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // widgets switcher for each step
  Widget _buildCurrentStep() {
    switch (_currentPage) {
      case 0: return _stepOne();
      case 1: return _stepTwo();
      case 2: return _stepThree();
      default: return _stepOne();
    }
  }

  // --- step 1: photo and username ---
  Widget _stepOne() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            padding: const EdgeInsets.all(3),
            decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white70)
            ),
            child: CircleAvatar(
              radius: 55,
              backgroundColor: Colors.white10,
              backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
              child: _profileImage == null
                  ? const Icon(Icons.camera_alt, size: 35, color: Colors.white)
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 40),
        VezTextField(controller: usernameController, label: "Username"),
      ],
    );
  }

  // --- step 2: email and password ---
  Widget _stepTwo() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        VezTextField(controller: emailController, label: "Email"),
        const SizedBox(height: 25),
        VezTextField(controller: passwordController, label: "Password", obscureText: true),
      ],
    );
  }

  // --- step 3: personal data ---
  Widget _stepThree() {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        InkWell(
          onTap: () => _selectDate(context),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 15),
            decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Colors.white24))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  selectedDate == null ? "Date Of Birth" : "${selectedDate!.toLocal()}".split(' ')[0],
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                ),
                const Icon(Icons.calendar_today, color: Colors.white70, size: 20),
              ],
            ),
          ),
        ),

        const SizedBox(height: 20),
        VezTextField(controller: cityController, label: "City"),
      ],
    );
  }

  // --- footer with aligned circular buttons ---
  Widget _buildNavigationFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // back button
        if (_currentPage > 0)
          _navButton(
              icon: Icons.arrow_back,
              label: "Back",
              onTap: () => setState(() => _currentPage--)
          ),

        // spacing between buttons
        if (_currentPage > 0) const SizedBox(width: 40),

        // next or save button
        if (_currentPage < 2)
          _navButton(
              icon: Icons.arrow_forward,
              label: "Next",
              onTap: () => setState(() => _currentPage++)
          )
        else
          _navButton(
              icon: Icons.save,
              label: "Save",
              onTap: signup,
              isPrimary: true
          ),
      ],
    );
  }

  Widget _navButton({required IconData icon, required String label, required VoidCallback onTap, bool isPrimary = false}) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white, width: 1.5),
              color: isPrimary ? Colors.white.withOpacity(0.1) : Colors.transparent,
            ),
            child: Icon(icon, color: Colors.white, size: 28),
          ),
        ),
        const SizedBox(height: 8),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }

  // method to do the signup process //
  void signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final username = usernameController.text.trim();
    final city = cityController.text.trim();

    setState(() => errorMessage = null);

    // check if all fields are filled
    if (username.isEmpty || city.isEmpty || selectedDate == null) {
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