import 'package:flutter/material.dart';
import '../screens/about_screen.dart';
import '../screens/home_screen.dart';
import '../screens/inquire_screen.dart';
import '../screens/schedule_screen.dart';
import '../theme/app_theme.dart';

enum AppTab { home, about, schedule, inquire }

/// Site-wide nav (Home / About / Schedule / Inquire), matching
/// church-web's own header nav minus Login/Create Account — those are
/// already their own screens here, not something you re-navigate to.
class AppBottomNav extends StatelessWidget {
  /// The tab to highlight, or null when this bar is shown on a page that
  /// isn't one of the four tabs (e.g. Reservation, My Reservations) — in
  /// that case none of the icons are highlighted.
  final AppTab? current;
  const AppBottomNav({super.key, required this.current});

  void _go(BuildContext context, AppTab tab) {
    if (tab == current) return;
    switch (tab) {
      case AppTab.home:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const HomeScreen()),
        );
      case AppTab.about:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AboutScreen()),
        );
      case AppTab.schedule:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const ScheduleScreen()),
        );
      case AppTab.inquire:
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const InquireScreen()),
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        color: Colors.white,
        border: const Border(top: BorderSide(color: AppColors.border)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Row(
            children: [
              _item(context, AppTab.home, Icons.home_outlined, 'Home'),
              _item(context, AppTab.about, Icons.info_outline, 'About'),
              _item(
                context,
                AppTab.schedule,
                Icons.calendar_month_outlined,
                'Schedule',
              ),
              _item(
                context,
                AppTab.inquire,
                Icons.chat_bubble_outline,
                'Inquire',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _item(BuildContext context, AppTab tab, IconData icon, String label) {
    final active = tab == current;
    final color = active ? AppColors.brand : Colors.grey.shade500;
    return Expanded(
      child: InkWell(
        onTap: () => _go(context, tab),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: TextStyle(
                  color: color,
                  fontSize: 10.5,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
