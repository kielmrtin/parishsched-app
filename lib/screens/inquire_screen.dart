import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:url_launcher/url_launcher.dart';
import '../config/api_config.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/boxed_field.dart';
import '../widgets/hero_kicker.dart';
import '../widgets/hero_wave.dart';
import '../widgets/logout_button.dart';
import '../widgets/notification_bell.dart';
import '../security/input_validation.dart';
import '../widgets/account_button.dart';

/// Mirrors church-web's Contact/Inquire page (resources/views/contact.blade.php):
/// same hero copy, message form, and parish office details. Submitting posts
/// to church-web's `/api/mobile-contact` (ContactController::mobileSend),
/// which sends the same branded `emails.contact-message` email the
/// website's own contact form uses — this app has no Supabase table to
/// write an inquiry to, so it's a direct Laravel call instead, same as
/// every other endpoint the app calls being direct-to-Supabase.
class InquireScreen extends StatefulWidget {
  const InquireScreen({super.key});

  @override
  State<InquireScreen> createState() => _InquireScreenState();
}

class _InquireScreenState extends State<InquireScreen> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _message = TextEditingController();
  bool _sending = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _message.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    if (!(_formKey.currentState?.validate() ?? false)) return;
    setState(() => _sending = true);
    try {
      final response = await http
          .post(
            Uri.parse('${ApiConfig.baseUrl}/api/mobile-contact'),
            headers: {'Content-Type': 'application/json', 'Accept': 'application/json'},
            body: jsonEncode({
              'name': _name.text.trim(),
              'email': _email.text.trim(),
              'phone': _phone.text.trim().isEmpty ? null : _phone.text.trim(),
              'message': _message.text.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (!mounted) return;
      final ok = response.statusCode >= 200 && response.statusCode < 300;
      await showAppAlert(
        context,
        type: ok ? AppAlertType.success : AppAlertType.error,
        title: ok ? 'Message Sent' : 'Something Went Wrong',
        message: ok
            ? "Thank you! Your message has been sent. Our parish team will respond within one business day."
            : 'We could not send your message right now. Please try again later.',
      );
      if (ok) {
        _name.clear();
        _email.clear();
        _phone.clear();
        _message.clear();
      }
    } catch (_) {
      if (!mounted) return;
      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'Connection Problem',
        message: 'We could not reach the parish server. Please check your connection and try again.',
      );
    } finally {
      if (mounted) setState(() => _sending = false);
    }
  }

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('St. John The Baptist Parish Tiaong Quezon')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ParishSched'),
        automaticallyImplyLeading: false,
        actions: const [AccountButton(), NotificationBell(), SizedBox(width: 4), LogoutButton()],
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.inquire),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Hero(),
            _FormSection(
              formKey: _formKey,
              name: _name,
              email: _email,
              phone: _phone,
              message: _message,
              sending: _sending,
              onSend: _send,
            ),
            _DetailsSection(onOpenMaps: _openMaps),
            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }
}

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/inquire_pg.png', fit: BoxFit.cover),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F0508).withValues(alpha: 0.82),
                  const Color(0xFF6E0F1C).withValues(alpha: 0.78),
                  const Color(0xFF0F0508).withValues(alpha: 0.95),
                ],
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 44),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroKicker(
                icon: Icons.send_outlined,
                label: 'PARISH INQUIRIES',
              ),
              const SizedBox(height: 14),
              const Text(
                'We are here to listen, guide, and pray with you',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 25,
                  color: Colors.white,
                  height: 1.25,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Share your intentions, plan a celebration, or simply say hello. Our parish team in Tiaong is ready to accompany you with warmth and compassion.',
                style: TextStyle(fontSize: 13.5, height: 1.6, color: Colors.white),
              ),
            ],
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: -1, child: HeroWave()),
      ],
    );
  }
}

class _FormSection extends StatelessWidget {
  final GlobalKey<FormState> formKey;
  final TextEditingController name;
  final TextEditingController email;
  final TextEditingController phone;
  final TextEditingController message;
  final bool sending;
  final VoidCallback onSend;
  const _FormSection({
    required this.formKey,
    required this.name,
    required this.email,
    required this.phone,
    required this.message,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 0),
      child: Form(
        key: formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Send us a message',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 21,
                color: AppColors.ink,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Let us know how we can support you. Messages go directly to our parish staff, who respond within one business day.',
              style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 22),
            BoxedField(
              controller: name,
              label: 'NAME',
              required: true,
              hint: 'Full name',
              textInputAction: TextInputAction.next,
              validator: (v) => (v == null || v.trim().isEmpty)
                  ? 'Please enter your name.'
                  : InputValidation.name(v),
            ),
            const SizedBox(height: 18),
            BoxedField(
              controller: email,
              label: 'EMAIL',
              required: true,
              hint: 'name@example.com',
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: InputValidation.email,
            ),
            const SizedBox(height: 18),
            BoxedField(
              controller: phone,
              label: 'PHONE',
              hint: '(042) 545-9244',
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              // Optional here (church-web: phone nullable), but checked if given.
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? null : InputValidation.phone(v),
            ),
            const SizedBox(height: 18),
            BoxedField(
              controller: message,
              label: 'MESSAGE',
              required: true,
              hint: 'How can we help you?',
              maxLines: 5,
              textInputAction: TextInputAction.done,
              validator: InputValidation.message,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: sending ? null : onSend,
                icon: sending
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Icon(Icons.send, size: 16),
                label: Text(sending ? 'SENDING…' : 'SEND MESSAGE'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.brand,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(13),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                  elevation: 0,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailsSection extends StatelessWidget {
  final VoidCallback onOpenMaps;
  const _DetailsSection({required this.onOpenMaps});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visit the parish office',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Find us along Maharlika Highway near the Tiaong town plaza. Tricycles and jeepneys pass the church regularly, and parking is available beside the parish hall.',
            style: TextStyle(fontSize: 13, height: 1.6, color: AppColors.inkSoft),
          ),
          const SizedBox(height: 20),
          const _DetailCard(
            icon: Icons.location_on_outlined,
            title: 'Our Address',
            body: 'Maharlika Highway, Barangay Poblacion II,\nTiaong, Quezon, Philippines',
          ),
          const SizedBox(height: 14),
          const _DetailCard(
            icon: Icons.call_outlined,
            title: 'Call or Message',
            body: '(042) 545-9244\nstjohnbaptisttiaongparish@gmail.com',
          ),
          const SizedBox(height: 14),
          const _DetailCard(
            icon: Icons.access_time_outlined,
            title: 'Office Hours',
            body: 'Tuesday – Sunday\n8:00 AM – 5:00 PM (or by appointment)',
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onOpenMaps,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Open in Maps'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(13),
                ),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                elevation: 0,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String body;
  const _DetailCard({required this.icon, required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(icon, color: AppColors.brand, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14.5,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  body,
                  style: const TextStyle(
                    fontSize: 12.8,
                    height: 1.6,
                    color: AppColors.inkSoft,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
