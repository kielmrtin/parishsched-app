import 'package:flutter/material.dart';

import '../screens/account_screen.dart';
import '../theme/app_theme.dart';

/// AppBar shortcut to Account & Privacy (view / copy / delete your data).
class AccountButton extends StatelessWidget {
  const AccountButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      tooltip: 'Account & Privacy',
      icon: const Icon(Icons.person_outline, color: AppColors.ink),
      onPressed: () => Navigator.of(context).push(
        MaterialPageRoute(builder: (_) => const AccountScreen()),
      ),
    );
  }
}
