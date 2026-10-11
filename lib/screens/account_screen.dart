import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../security/app_lock.dart';
import '../security/secure_screen.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import 'auth_gate.dart';
import 'privacy_policy_screen.dart';

/// "Account & Privacy": lets users see everything ParishSched holds about
/// them, take a copy of it, read the privacy policy, and delete their
/// account (MASVS-PRIVACY: user control over their data).
class AccountScreen extends StatefulWidget {
  const AccountScreen({super.key});

  @override
  State<AccountScreen> createState() => _AccountScreenState();
}

class _AccountScreenState extends State<AccountScreen> with SecureScreenMixin {
  final _auth = AuthService();
  late Future<Map<String, dynamic>> _data = _auth.fetchMyData();
  bool _deleting = false;

  Future<void> _copyData(Map<String, dynamic> data) async {
    if (!await AppLock.confirm('Copy your personal data')) return;
    await Clipboard.setData(
      ClipboardData(text: const JsonEncoder.withIndent('  ').convert(data)),
    );
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your data was copied. Paste it somewhere safe.')),
    );
  }

  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Delete your account?'),
        content: const Text(
          'This permanently deletes your ParishSched account, your past '
          'reservations and the documents you uploaded. This cannot be undone.\n\n'
          'Upcoming reservations must be cancelled first.',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(c, false), child: const Text('Keep account')),
          TextButton(
            onPressed: () => Navigator.pop(c, true),
            style: TextButton.styleFrom(foregroundColor: AppColors.brand),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    if (!await AppLock.confirm('Confirm account deletion')) return;

    setState(() => _deleting = true);
    try {
      await _auth.deleteAccount();
      if (!mounted) return;
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Account Deleted',
        message: 'Your account and data have been deleted. Thank you for using ParishSched.',
      );
      if (!mounted) return;
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => const AuthGate()),
        (_) => false,
      );
    } on AuthFailure catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      await showAppAlert(context, type: AppAlertType.error, title: 'Not Deleted', message: e.message);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Account & Privacy')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _data,
        builder: (context, snap) {
          if (snap.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) {
            return Center(
              child: TextButton(
                onPressed: () => setState(() => _data = _auth.fetchMyData()),
                child: const Text('Could not load your data. Tap to retry.'),
              ),
            );
          }
          final data = snap.data!;
          final profile = (data['profile'] as Map<String, dynamic>?) ?? {};
          final reservations = (data['reservations'] as List?) ?? [];
          return ListView(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
            children: [
              const _Heading('Your information'),
              _InfoRow('Name', profile['name']),
              _InfoRow('Email', profile['email'] ?? _auth.currentUser?.email),
              _InfoRow('Phone', profile['phone']),
              _InfoRow('Address', profile['address']),
              _InfoRow('Reservations on file', '${reservations.length}'),
              const SizedBox(height: 6),
              const Text(
                'To correct your details, contact the parish office.',
                style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
              ),
              const SizedBox(height: 22),
              const _Heading('Your data'),
              _ActionTile(
                icon: Icons.copy_all_outlined,
                title: 'Copy my data',
                subtitle: 'Everything above plus your reservation details, as text.',
                onTap: () => _copyData(data),
              ),
              _ActionTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                subtitle: 'What we collect, why, and your rights.',
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const PrivacyPolicyScreen()),
                ),
              ),
              const SizedBox(height: 22),
              const _Heading('Delete account'),
              _ActionTile(
                icon: Icons.delete_forever_outlined,
                title: _deleting ? 'Deleting…' : 'Delete my account',
                subtitle: 'Permanently remove your account and data.',
                danger: true,
                onTap: _deleting ? null : _deleteAccount,
              ),
            ],
          );
        },
      ),
    );
  }
}

class _Heading extends StatelessWidget {
  const _Heading(this.text);
  final String text;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10),
        child: Text(
          text.toUpperCase(),
          style: const TextStyle(
            fontSize: 12,
            letterSpacing: 1.2,
            fontWeight: FontWeight.w800,
            color: AppColors.brand,
          ),
        ),
      );
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final Object? value;

  @override
  Widget build(BuildContext context) {
    final text = (value == null || '$value'.trim().isEmpty) ? '—' : '$value';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 130,
            child: Text(label, style: const TextStyle(fontSize: 13.5, color: AppColors.inkSoft)),
          ),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.ink),
            ),
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.danger = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final bool danger;

  @override
  Widget build(BuildContext context) {
    final color = danger ? AppColors.brand : AppColors.ink;
    return Card(
      elevation: 0,
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: const BorderSide(color: AppColors.border),
      ),
      child: ListTile(
        leading: Icon(icon, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.w700, color: color)),
        subtitle: Text(subtitle, style: const TextStyle(fontSize: 12.5)),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }
}
