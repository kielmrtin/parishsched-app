import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_hero.dart';
import '../widgets/pill_button.dart';
import 'forgot_password_screen.dart';
import 'home_screen.dart';
import 'register_screen.dart';
import '../security/input_validation.dart';
import '../security/secure_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SecureScreenMixin {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().signIn(
        email: _email.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      // Matches CustomerAuthController::login's own
      // 'Login Successful' / 'Welcome back!' notification.
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Login Successful',
        message: 'Welcome back!',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
        (route) => false,
      );
    } on AuthFailure catch (e) {
      _showError('Login Failed', e.message);
    } catch (_) {
      _showError(
        'Login Failed',
        'Something went wrong. Please check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _showError(String title, String message) {
    showAppAlert(
      context,
      type: AppAlertType.error,
      title: title,
      message: message,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Column(
          children: [
            const Expanded(
              flex: 6,
              child: AuthHero(
                imagePath: 'assets/images/sign_up.png',
                badgeIcon: Icons.lock,
                badgeLabel: 'WELCOME BACK',
                headline: 'Effortless\nreservations.',
                subtitle:
                    'Sign in to manage your sacramental reservations with ease and stay connected with the parish.',
              ),
            ),
            Expanded(
              flex: 8,
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 20),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.vertical(
                      top: Radius.circular(26),
                    ),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(
                      bottom: MediaQuery.of(context).viewInsets.bottom,
                    ),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          AuthField(
                            controller: _email,
                            label: 'Email',
                            keyboardType: TextInputType.emailAddress,
                            validator: InputValidation.email,
                          ),
                          const SizedBox(height: 16),
                          AuthField(
                            controller: _password,
                            label: 'Password',
                            obscurable: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Password is required'
                                : null,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const ForgotPasswordScreen(),
                                ),
                              ),
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.brand,
                              ),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 8),
                          PillButton(
                            label: 'Sign In',
                            onPressed: _submit,
                            loading: _loading,
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const RegisterScreen(),
                                    ),
                                  ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                  children: const [
                                    TextSpan(text: "Don't have an account? "),
                                    TextSpan(
                                      text: 'Sign up',
                                      style: TextStyle(
                                        color: AppColors.brand,
                                        fontWeight: FontWeight.w800,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
