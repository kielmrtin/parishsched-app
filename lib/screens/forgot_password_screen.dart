import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_hero.dart';
import '../widgets/pill_button.dart';

/// Mirrors church-web's Forgot Password page
/// (resources/views/auth/forgot-password.blade.php): same hero copy, same
/// benefits list, same form heading and neutral "if an account matches"
/// confirmation message. The website's own reset mechanism calls Supabase's
/// admin API with the service-role key (Laravel-only, never shippable in
/// this app) — this screen uses Supabase Auth's own `resetPasswordForEmail`
/// instead, which reaches the same outcome safely with just the anon key.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().sendPasswordReset(_email.text.trim());
    } catch (_) {
      // Fall through to the same neutral message either way — matching
      // the website, this never reveals whether the email exists.
    } finally {
      if (mounted) setState(() => _loading = false);
    }
    if (!mounted) return;
    await showAppAlert(
      context,
      type: AppAlertType.success,
      title: 'Check Your Email',
      message:
          "If an account matches that email address, we've sent a password reset link.",
    );
    if (!mounted) return;
    Navigator.of(context).pop();
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
                imagePath: 'assets/images/forgotpassword.png',
                badgeIcon: Icons.mail_outline,
                badgeLabel: 'RESET ACCESS',
                headline: "We'll help you\nget back in.",
                subtitle:
                    'Request a secure link to update your password and return to managing your sacramental reservations.',
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
                    borderRadius: BorderRadius.vertical(top: Radius.circular(26)),
                  ),
                  child: SingleChildScrollView(
                    padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Forgot your password?',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 20,
                              color: AppColors.ink,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            "Enter the email associated with your account and we'll send a reset link within moments.",
                            textAlign: TextAlign.center,
                            style: TextStyle(fontSize: 13, height: 1.5, color: Colors.grey.shade500),
                          ),
                          const SizedBox(height: 28),
                          AuthField(
                            controller: _email,
                            label: 'Email Address',
                            hint: 'name@example.com',
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter a valid email';
                              return null;
                            },
                          ),
                          const SizedBox(height: 22),
                          PillButton(
                            label: 'Send Reset Link',
                            onPressed: _submit,
                            loading: _loading,
                          ),
                          const SizedBox(height: 18),
                          Center(
                            child: GestureDetector(
                              onTap: () => Navigator.of(context).pop(),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.arrow_back, size: 14, color: AppColors.brand),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Remembered your password?',
                                    style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                                  ),
                                ],
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
