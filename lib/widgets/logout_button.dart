import 'package:flutter/material.dart';
import '../screens/welcome_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';

/// Flat red boxed "LOGOUT" action for the AppBar — same sharp-cornered
/// button look as church-web's header nav button (`.boxed-btn3`), just
/// relabeled for the signed-in state instead of Login/Create Account.
class LogoutButton extends StatelessWidget {
  const LogoutButton({super.key});

  Future<void> _signOut(BuildContext context) async {
    await AuthService().signOut();
    if (!context.mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const WelcomeScreen()),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 16),
      child: Center(
        child: GestureDetector(
          onTap: () => _signOut(context),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 6),
            color: AppColors.brand,
            child: const Text(
              'LOGOUT',
              style: TextStyle(
                color: Colors.white,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                letterSpacing: 1.4,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
