import 'dart:ui';

import 'package:flutter/material.dart';

import '../../services/auth_service.dart';
import '../../services/translation_service.dart';
import '../../services/user_session.dart';
import '../../views/widgets/vez_glass.dart';
import '../home/home_screen.dart';
import 'login_screen.dart';

class VenuePendingPage extends StatefulWidget {
  const VenuePendingPage({super.key});

  @override
  State<VenuePendingPage> createState() => _VenuePendingPageState();
}

class _VenuePendingPageState extends State<VenuePendingPage> {
  final TextEditingController _codeCtrl = TextEditingController();
  final RemoteDbService _db = RemoteDbService();

  bool _loading = false;
  String? _message;

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final String code = _codeCtrl.text.trim().toUpperCase();
    if (code.isEmpty) {
      setState(() {
        _message = StringRes.at('fill_all_fields');
      });
      return;
    }

    setState(() {
      _loading = true;
      _message = null;
    });

    final int res = await _db.verifyVenueCode(code);
    if (!mounted) return;

    setState(() {
      _loading = false;
      _message = res == 200
          ? StringRes.at('venue_code_confirmed')
          : StringRes.at('venue_code_invalid');
    });
  }

  Future<void> _refreshStatus() async {
    setState(() => _loading = true);
    await _db.refreshCurrentAccountStatus();
    if (!mounted) return;
    setState(() => _loading = false);

    if (UserSession().accountType == 'venue' &&
        UserSession().accountState == 'active') {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (_) => const HomePage()),
      );
    }
  }

  Future<void> _logout() async {
    await _db.logout();
    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (_) => const LoginPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final double sw = MediaQuery.of(context).size.width;
    return Scaffold(
      resizeToAvoidBottomInset: false,
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          Positioned.fill(
            child: Image.asset(
              'assets/images/bg/bg_login.jpg',
              fit: BoxFit.cover,
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 28),
              child: Column(
                children: [
                  const Spacer(flex: 2),
                  const Icon(
                    Icons.storefront_rounded,
                    color: Colors.white,
                    size: 56,
                  ),
                  const SizedBox(height: 18),
                  Text(
                    StringRes.at('venue_pending_title'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 30,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    StringRes.at('venue_pending_body'),
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      color: Colors.white70,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const Spacer(flex: 2),
                  VezGlass.textField(
                    controller: _codeCtrl,
                    hint: 'VZ-48291',
                    width: sw * 0.74,
                    color: Colors.white54,
                    maxLength: 8,
                    onChanged: (value) {
                      final upper = value.toUpperCase();
                      if (upper != value) {
                        _codeCtrl.value = _codeCtrl.value.copyWith(
                          text: upper,
                          selection: TextSelection.collapsed(
                            offset: upper.length,
                          ),
                        );
                      }
                    },
                  ),
                  const SizedBox(height: 18),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      VezGlass.circleButton(
                        assetIcon: 'assets/icons/event/check.png',
                        onTap: _verifyCode,
                      ),
                      const SizedBox(width: 24),
                      VezGlass.circleButton(
                        assetIcon: 'assets/icons/auth/icon_next.png',
                        onTap: _refreshStatus,
                      ),
                    ],
                  ),
                  const SizedBox(height: 22),
                  SizedBox(
                    height: 52,
                    child: _message == null
                        ? const SizedBox.shrink()
                        : VezErrorBanner(message: _message!),
                  ),
                  const Spacer(flex: 2),
                  _LogoutPill(onTap: _logout),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
          if (_loading) const VezLoadingOverlay(),
        ],
      ),
    );
  }
}

class _LogoutPill extends StatelessWidget {
  const _LogoutPill({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 5, sigmaY: 5),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 8),
            decoration: BoxDecoration(
              color: const Color.fromARGB(51, 255, 255, 255),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: Colors.white54, width: 2),
            ),
            child: Text(
              StringRes.at('logout'),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
