import 'package:flutter/material.dart';
import '../services/remote_db_service.dart';

class SignupPage extends StatefulWidget {
  const SignupPage({super.key});

  @override
  State<SignupPage> createState() => _SignupPageState();
}

class _SignupPageState extends State<SignupPage> {
  final RemoteDbService _dbService = RemoteDbService();

  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final TextEditingController usernameController = TextEditingController();
  final TextEditingController nameController = TextEditingController();
  final TextEditingController surnameController = TextEditingController();
  final TextEditingController cityController = TextEditingController();
  DateTime? selectedDate;

  String? errorMessage;
  bool isLoading = false;

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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Signup")),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextField(
              controller: usernameController,
              decoration: const InputDecoration(labelText: "Username"),
            ),
            const SizedBox(height: 10),
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
            ListTile(
              title: Text(selectedDate == null
                  ? "Select Date of Birth"
                  : "DOB: ${selectedDate!.toLocal()}".split(' ')[0]),
              trailing: const Icon(Icons.calendar_today),
              onTap: () => _selectDate(context),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: cityController,
              decoration: const InputDecoration(labelText: "City"),
            ),
            const SizedBox(height: 20),
            if (errorMessage != null)
              Text(
                errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            const SizedBox(height: 20),
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

  void signup() async {
    final email = emailController.text.trim();
    final password = passwordController.text;
    final username = usernameController.text.trim();
    final name = nameController.text.trim();
    final surname = surnameController.text.trim();
    final city = cityController.text.trim();

    setState(() => errorMessage = null);

    if (username.isEmpty || name.isEmpty || surname.isEmpty || city.isEmpty || selectedDate == null) {
      setState(() => errorMessage = "Please fill all fields");
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => errorMessage = "Invalid email");
      return;
    }

    String? passwordError = _validatePassword(password);
    if (passwordError != null) {
      setState(() => errorMessage = passwordError);
      return;
    }

    setState(() => isLoading = true);

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

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Signup Successful!")),
      );
      // Navigate to login or home
    } else {
      setState(() => errorMessage = "Signup failed. Try again.");
    }
  }

  bool _isValidEmail(String email) {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email);
  }

  String? _validatePassword(String password) {
    if (password.length < 8) return "At least 8 characters";
    if (!RegExp(r'[A-Z]').hasMatch(password)) return "At least 1 uppercase letter";
    if (!RegExp(r'[a-z]').hasMatch(password)) return "At least 1 lowercase letter";
    if (!RegExp(r'[0-9]').hasMatch(password)) return "At least 1 number";
    if (!RegExp(r'[!@#\$&*~]').hasMatch(password)) return "At least 1 special char";
    return null;
  }
}
