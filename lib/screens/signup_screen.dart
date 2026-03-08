import 'package:flutter/material.dart';
import '../services/remote_db_service.dart';
import 'dart:io'; // library to manage files
import 'package:image_picker/image_picker.dart'; // selector for the photos


class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final RemoteDbService _dbService = RemoteDbService(); // instance of RemoteDbService

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
      appBar: AppBar(title: const Text("Signup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [

            // --- profile photo selector --- //
            GestureDetector(
              onTap: _pickImage,
              child: CircleAvatar(
                radius: 50,
                backgroundColor: Colors.grey[300],
                backgroundImage: _profileImage != null ? FileImage(_profileImage!) : null,
                child: _profileImage == null
                    ? const Icon(Icons.camera_alt, size: 40, color: Colors.white)
                    : null,
              ),
            ),

            // --- username text field --- //
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 10),
            // --- email and password text fields --- //
            TextField(
              controller: emailController,
              decoration: const InputDecoration(labelText: "Email"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: passwordController,
              obscureText: true,
              decoration: const InputDecoration(labelText: "Password"),
            ),
            const SizedBox(height: 10),
            // --- name and surname fields --- //
            TextField(
              controller: nameController,
              decoration: const InputDecoration(labelText: "Name"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: surnameController,
              decoration: const InputDecoration(labelText: "Surname"),
            ),
            const SizedBox(height: 10),

            // --- date of birth field --- //
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Date of Birth"
                  : "DOB: ${selectedDate!.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 10),

            // --- city field --- //
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
            const SizedBox(height: 20),

            // --- error message --- //
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),

            // --- signup button --- //
            isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: signup,
                    child: const Text("Signup"),
                  ),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Already have an account? Login"),
            ),
          ],
        ),
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
    bool success = await _dbService.signup(
      email: email,
      password: password,
      username: username,
      name: name,
      surname: surname,
      dateOfBirth: selectedDate!,
      city: city,
    );

    if (!mounted) return;
    setState(() => isLoading = false);

    // data correctly sent to the db
    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Successful!")),
      );

      // next step -> navigate home
    } else {
      setState(() => errorMessage = "Signup failed. Try again.");
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
