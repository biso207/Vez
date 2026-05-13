// Developed and Designed by Outly • 2026
// venue signup entry point.

import 'package:flutter/material.dart';

import '../../../models/account_type.dart';
import 'signup_flow_screen.dart';

// opens the venue signup flow.
class VenueSignupPage extends StatelessWidget {
  const VenueSignupPage({super.key});

  // builds the venue signup wrapper.
  @override
  Widget build(BuildContext context) {
    return const SignupFlowScreen(accountType: AccountType.venue);
  }
}
