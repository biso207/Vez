// Developed and Designed by Outly • 2026
// user signup entry point.

import 'package:flutter/material.dart';

import '../../../models/account_type.dart';
import 'signup_flow_screen.dart';

// opens the user signup flow.
class SignupPage extends StatelessWidget {
  const SignupPage({super.key});

  // builds the user signup wrapper.
  @override
  Widget build(BuildContext context) {
    return const SignupFlowScreen(accountType: AccountType.user);
  }
}
