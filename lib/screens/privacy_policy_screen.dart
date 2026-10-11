import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// In-app privacy notice (MASVS-PRIVACY: be transparent about data
/// collection). Written for the Philippine Data Privacy Act of 2012
/// (RA 10173). Keep in sync with what the app and website actually collect.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const lastUpdated = 'October 2026';

  static const _sections = <(String, List<String>)>[
    (
      'Who we are',
      [
        'ParishSched is the reservation app of St. John the Baptist Parish, '
            'Tiaong, Quezon. The parish is responsible for the personal '
            'information collected through this app and its website, '
            'stjohnbaptistparish.org.',
      ],
    ),
    (
      'What we collect',
      [
        'Your account: full name, email address, mobile number, home address '
            'and password (the password is stored only as a secure hash).',
        'Reservations: the sacrament, date and time you choose, and the '
            "details the form asks for - e.g. the child's name, date of birth "
            "and parents' names for a baptism, the couple's names and seminar "
            'date for a wedding, or the name and marital status of the deceased '
            'for a funeral Mass - plus the documents you upload.',
        'Inquiries you send through the Inquire form.',
        'Basic security signals about your phone (for example, whether it is '
            'rooted or the app has been modified), used only to protect your '
            'account.',
      ],
    ),
    (
      'Why we use it',
      [
        'To create and secure your account, process and schedule your '
            'reservations, contact you about them by email or text message, '
            'answer your inquiries, and keep the app safe from misuse. We do '
            'not sell your information or use it for advertising.',
      ],
    ),
    (
      'Who processes it for us',
      [
        'Supabase (secure database, login and file storage), Hostinger (the '
            'parish website and email), Gmail (email notifications), iProg Tech '
            '(SMS verification codes and status texts) and Talsec freeRASP (app '
            'security checks). They handle your information only to provide '
            'these services to the parish.',
      ],
    ),
    (
      'How we protect it',
      [
        'All connections are encrypted (HTTPS). On your phone, your login is '
            'stored encrypted with a key held by Android, screens with personal '
            'information block screenshots, and the app can be unlocked only '
            "with your phone's fingerprint or PIN.",
      ],
    ),
    (
      'How long we keep it',
      [
        'For as long as you have an account. When you delete your account, your '
            'profile, reservations and uploaded documents are deleted from '
            'ParishSched. Sacraments that were already celebrated remain recorded '
            "in the parish's official registry books, as Church law requires.",
      ],
    ),
    (
      'Your rights',
      [
        'Under the Data Privacy Act you may access, correct or delete your '
            'personal information, object to its processing, and file a '
            'complaint with the National Privacy Commission. In the app, open '
            'the account icon to see your data, copy it, or delete your account. '
            'For corrections or questions, contact the parish office.',
      ],
    ),
    (
      'Contact',
      [
        'St. John the Baptist Parish Office, Tiaong, Quezon - (042) 545-9244 - '
            'or through the Inquire page of the app or website.',
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Privacy Policy')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(22, 8, 22, 32),
        children: [
          const Text(
            'Last updated: $lastUpdated',
            style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
          ),
          for (final (title, paragraphs) in _sections) ...[
            const SizedBox(height: 20),
            Text(
              title,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.ink),
            ),
            for (final p in paragraphs) ...[
              const SizedBox(height: 8),
              Text(p, style: const TextStyle(fontSize: 14, height: 1.55, color: AppColors.ink)),
            ],
          ],
        ],
      ),
    );
  }
}
