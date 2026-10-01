import 'dart:async';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/auth_field.dart';
import '../widgets/auth_hero.dart';
import '../widgets/pill_button.dart';
import 'login_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  final _otp = TextEditingController();
  bool _loading = false;
  bool _sendingOtp = false;
  int _resendSeconds = 0;
  Timer? _resendTimer;

  @override
  void initState() {
    super.initState();
    _otp.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _address.dispose();
    _password.dispose();
    _confirm.dispose();
    _otp.dispose();
    _resendTimer?.cancel();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (_phone.text.trim().isEmpty) {
      showAppAlert(
        context,
        type: AppAlertType.warning,
        title: 'Phone Number Required',
        message: 'Enter your phone number first.',
      );
      return;
    }
    setState(() => _sendingOtp = true);
    try {
      await AuthService().sendRegisterOtp(_phone.text.trim());
      if (!mounted) return;
      showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'OTP Sent',
        message: 'A verification code was sent to your phone number.',
      );
      setState(() => _resendSeconds = 30);
      _resendTimer?.cancel();
      _resendTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }
        setState(() => _resendSeconds--);
        if (_resendSeconds <= 0) timer.cancel();
      });
    } catch (_) {
      _showError('Could Not Send Code', 'Please try again.');
    } finally {
      if (mounted) setState(() => _sendingOtp = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      final verified = await AuthService().verifyRegisterOtp(
        _phone.text.trim(),
        _otp.text.trim(),
      );
      if (!verified) {
        _showError(
          'Invalid Code',
          'That verification code is invalid or has expired. Please request a new one.',
        );
        return;
      }
      await AuthService().signUp(
        name: _name.text.trim(),
        email: _email.text.trim(),
        phone: _phone.text.trim(),
        address: _address.text.trim(),
        password: _password.text,
      );
      if (!mounted) return;
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Registration Successful',
        message: 'Your account has been created. You can now log in.',
        actions: [
          AppAlertAction(
            label: 'Continue to Login',
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      );
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } on AuthFailure catch (e) {
      _showError('Registration Failed', e.message);
    } catch (_) {
      _showError(
        'Registration Failed',
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
              flex: 5,
              child: AuthHero(
                imagePath: 'assets/images/sign_in.png',
                badgeIcon: Icons.groups,
                badgeLabel: 'JOIN THE COMMUNITY',
                headline: 'Join the Parish\ncommunity.',
                subtitle:
                    'Create your account and enjoy a seamless way to book sacraments and stay connected with the parish.',
              ),
            ),
            Expanded(
              flex: 9,
              child: Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 40, 24, 18),
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
                            controller: _name,
                            label: 'Full Name',
                            hint: 'Maria Santos',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Full name is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _email,
                            label: 'Email',
                            hint: 'you@email.com',
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Email is required';
                              }
                              if (!v.contains('@')) {
                                return 'Enter a valid email';
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _phone,
                            label: 'Phone Number',
                            hint: '09XX XXX XXXX',
                            keyboardType: TextInputType.phone,
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton(
                              onPressed: (_sendingOtp || _resendSeconds > 0)
                                  ? null
                                  : _sendOtp,
                              style: TextButton.styleFrom(
                                foregroundColor: AppColors.brand,
                              ),
                              child: Text(
                                _resendSeconds > 0
                                    ? 'Resend available in ${_resendSeconds}s'
                                    : (_sendingOtp ? 'Sending…' : 'Send OTP'),
                                style: const TextStyle(
                                  fontWeight: FontWeight.w700,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ),
                          AuthField(
                            controller: _otp,
                            label: 'Verification Code',
                            hint: '6-digit code',
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            validator: (v) =>
                                (v == null || v.trim().length != 6)
                                ? 'Enter the 6-digit code'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _address,
                            label: 'Home Address',
                            hint: 'Barangay, Municipality, Province',
                            validator: (v) => (v == null || v.trim().isEmpty)
                                ? 'Address is required'
                                : null,
                          ),
                          const SizedBox(height: 14),
                          AuthField(
                            controller: _password,
                            label: 'Password',
                            obscurable: true,
                            validator: (v) {
                              if (v == null || v.isEmpty) {
                                return 'Password is required';
                              }
                              if (v.length < 8) return 'At least 8 characters';
                              return null;
                            },
                          ),
                          const Padding(
                            padding: EdgeInsets.only(top: 3),
                            child: Text(
                              'At least 8 characters',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey,
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          AuthField(
                            controller: _confirm,
                            label: 'Confirm Password',
                            obscurable: true,
                            textInputAction: TextInputAction.done,
                            validator: (v) => v != _password.text
                                ? 'Passwords do not match'
                                : null,
                          ),
                          const SizedBox(height: 18),
                          PillButton(
                            label: 'Sign Up',
                            onPressed: _otp.text.trim().length == 6
                                ? _submit
                                : null,
                            loading: _loading,
                          ),
                          const SizedBox(height: 16),
                          Center(
                            child: GestureDetector(
                              onTap: () =>
                                  Navigator.of(context).pushReplacement(
                                    MaterialPageRoute(
                                      builder: (_) => const LoginScreen(),
                                    ),
                                  ),
                              child: RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                    color: Colors.grey.shade600,
                                    fontSize: 13,
                                  ),
                                  children: const [
                                    TextSpan(text: 'Already have an account? '),
                                    TextSpan(
                                      text: 'Sign in',
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
