import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../widgets/pill_button.dart';
import 'login_screen.dart';
import 'register_screen.dart';

class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Parish photo background.
          Image.asset('assets/images/welcome_bg.jpg', fit: BoxFit.cover),
          // Dark red tint over the photo, matching the site's #dc2626 brand red, kept dark enough for white text to stay legible.
          Container(color: AppColors.photoTint),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32),
              child: Column(
                children: [
                  Expanded(
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          ClipOval(
                            child: Image.asset(
                              'assets/images/welcome_logo.jpg',
                              width: 92,
                              height: 92,
                              fit: BoxFit.cover,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'ParishSched',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w800,
                              fontSize: 22,
                              letterSpacing: 0.3,
                            ),
                          ),
                          const SizedBox(height: 14),
                          Text(
                            'Book sacraments and stay close to your parish, right from your phone.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.85),
                              fontSize: 14,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.only(bottom: 56),
                    child: Column(
                      children: [
                        PillButton(
                          label: 'Sign In',
                          outline: true,
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const LoginScreen(),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        PillButton(
                          label: 'Create Account',
                          onPressed: () => Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const RegisterScreen(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
