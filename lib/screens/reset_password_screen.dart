import 'dart:ui';

import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/boxed_field.dart';

/// Shown when the app catches the `parishsched://reset-callback` deep link
/// from the password-reset email. supabase_flutter has already exchanged the
/// link for a temporary recovery session by the time this is shown (see the
/// `passwordRecovery` listener in main.dart) — this just collects the new
/// password and applies it to that session.
///
/// Presented as a hovering modal on top of whatever screen is currently
/// showing, mirroring the "Set New Password" overlay church-web's own login
/// page shows when it detects a `reset_token` query param.
Future<void> showResetPasswordDialog(BuildContext context) {
  return showGeneralDialog(
    context: context,
    barrierDismissible: false,
    barrierLabel: 'Set New Password',
    barrierColor: const Color(0xBF060D1A),
    transitionDuration: const Duration(milliseconds: 220),
    pageBuilder: (context, anim1, anim2) => const SizedBox.shrink(),
    transitionBuilder: (context, anim, secondaryAnim, child) {
      return BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 3 * anim.value, sigmaY: 3 * anim.value),
        child: FadeTransition(
          opacity: anim,
          child: ScaleTransition(
            scale: Tween(
              begin: 0.92,
              end: 1.0,
            ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutBack)),
            child: const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 28),
                child: _ResetPasswordCard(),
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _ResetPasswordCard extends StatefulWidget {
  const _ResetPasswordCard();

  @override
  State<_ResetPasswordCard> createState() => _ResetPasswordCardState();
}

class _ResetPasswordCardState extends State<_ResetPasswordCard> {
  final _formKey = GlobalKey<FormState>();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await AuthService().updatePassword(_password.text);
      if (!mounted) return;
      Navigator.of(context).pop();
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Password Updated',
        message: 'Your password has been updated. You can now use it to sign in.',
      );
    } catch (e) {
      if (!mounted) return;
      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'Update Failed',
        message: e is AuthFailure ? e.message : 'Something went wrong. Please try again.',
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Container(
        width: double.infinity,
        constraints: const BoxConstraints(maxWidth: 380),
        padding: const EdgeInsets.fromLTRB(22, 24, 22, 22),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.22),
              blurRadius: 40,
              offset: const Offset(0, 20),
            ),
          ],
        ),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.brand.withValues(alpha: 0.1),
                    border: Border.all(color: AppColors.brand.withValues(alpha: 0.3), width: 1.5),
                  ),
                  child: const Icon(Icons.lock_reset, color: AppColors.brand, size: 24),
                ),
              ),
              const SizedBox(height: 16),
              const Text(
                'Set New Password',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 19,
                  fontWeight: FontWeight.w900,
                  color: AppColors.ink,
                  letterSpacing: -0.3,
                ),
              ),
              const SizedBox(height: 6),
              const Text(
                'Enter and confirm your new password below.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 20),
              BoxedField(
                controller: _password,
                label: 'New Password',
                hint: 'Min. 8 characters',
                obscureText: true,
                textInputAction: TextInputAction.next,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'Must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: 14),
              BoxedField(
                controller: _confirm,
                label: 'Confirm Password',
                hint: 'Repeat password',
                obscureText: true,
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v != _password.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _loading ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 13),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(11)),
                    elevation: 0,
                  ),
                  child: _loading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white),
                        )
                      : const Text(
                          'Update Password',
                          style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                        ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
