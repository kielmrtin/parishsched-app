import 'package:flutter/material.dart';
import '../data/sacrament_windows.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/hero_kicker.dart';
import '../widgets/hero_wave.dart';
import '../widgets/logout_button.dart';
import '../widgets/notification_bell.dart';
import '../widgets/sacrament_badge.dart';
import 'inquire_screen.dart';
import 'reservation_screen.dart';

/// Mirrors church-web's static Schedule page
/// (resources/views/schedule/index.blade.php): the same sacrament time
/// windows, filterable by type. There's no backing table on the website
/// either — the schedule is fixed content, not Supabase-driven.
class ScheduleScreen extends StatefulWidget {
  const ScheduleScreen({super.key});

  @override
  State<ScheduleScreen> createState() => _ScheduleScreenState();
}

class _ScheduleFilter {
  final String key;
  final String label;
  const _ScheduleFilter(this.key, this.label);
}

class _ScheduleScreenState extends State<ScheduleScreen> {
  String _filter = 'all';

  static const _filters = [
    _ScheduleFilter('all', 'All Schedules'),
    _ScheduleFilter('wedding', 'Weddings'),
    _ScheduleFilter('baptism', 'Baptisms'),
    _ScheduleFilter('funeral', 'Funerals'),
  ];

  void _goToInquire() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InquireScreen()),
    );
  }

  void _goToReservation() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ReservationScreen()),
    );
  }

  /// The Reservation screen needs one [SacramentWindow] per distinct
  /// bookable time (so e.g. 1:00 PM and 2:00 PM are independently
  /// available/booked), but that would show as several near-duplicate
  /// cards here — same title/details, differing only in time. Group
  /// same-title windows back into a single display card listing all of
  /// their times together.
  List<SacramentWindow> _groupForDisplay(List<SacramentWindow> list) {
    final grouped = <String, SacramentWindow>{};
    final order = <String>[];
    for (final w in list) {
      final key = '${w.type}|${w.title}';
      final existing = grouped[key];
      if (existing == null) {
        grouped[key] = w;
        order.add(key);
      } else {
        grouped[key] = SacramentWindow(
          type: existing.type,
          weekdays: existing.weekdays,
          dayChip: existing.dayChip,
          time: '${existing.time} · ${w.time}',
          title: existing.title,
          details: existing.details,
        );
      }
    }
    return [for (final key in order) grouped[key]!];
  }

  @override
  Widget build(BuildContext context) {
    final items = _groupForDisplay(
      _filter == 'all'
          ? sacramentWindows
          : sacramentWindows.where((i) => i.type == _filter).toList(),
    );

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ParishSched'),
        automaticallyImplyLeading: false,
        actions: const [NotificationBell(), SizedBox(width: 4), LogoutButton()],
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.schedule),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const _Intro(),
            _FilterBar(
              filters: _filters,
              selected: _filter,
              onSelect: (key) => setState(() => _filter = key),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 10, 24, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Available Time Windows',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 21,
                      color: AppColors.ink,
                      height: 1.28,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'These are the regular sacrament schedules at our parish. Contact the parish office to confirm availability for your preferred date.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(height: 20),
                  for (final item in items) ...[
                    _ScheduleCard(item: item),
                    const SizedBox(height: 14),
                  ],
                ],
              ),
            ),
            _CtaPanel(onReserve: _goToReservation, onContact: _goToInquire),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

class _Intro extends StatelessWidget {
  const _Intro();

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/sched_main.png', fit: BoxFit.cover),
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
                icon: Icons.calendar_today_outlined,
                label: 'PARISH SCHEDULE',
              ),
              const SizedBox(height: 14),
              const Text(
                'Sacrament Schedule',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Browse available time windows for Weddings, Baptisms, and Funeral Masses celebrated at St. John the Baptist Parish.',
                style: TextStyle(
                  fontSize: 13.5,
                  height: 1.6,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 24),
              Row(
                children: const [
                  Expanded(
                    child: _StatBlock(num: '3', label: 'Sacrament Types'),
                  ),
                  _StatDivider(),
                  Expanded(
                    child: _StatBlock(num: '5', label: 'Time Windows'),
                  ),
                  _StatDivider(),
                  Expanded(
                    child: _StatBlock(num: '6', label: 'Days a Week'),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(left: 0, right: 0, bottom: -1, child: HeroWave()),
      ],
    );
  }
}

class _StatBlock extends StatelessWidget {
  final String num;
  final String label;
  const _StatBlock({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          num,
          style: const TextStyle(
            fontWeight: FontWeight.w900,
            fontSize: 22,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 10.5, color: Colors.white70, height: 1.3),
        ),
      ],
    );
  }
}

class _StatDivider extends StatelessWidget {
  const _StatDivider();

  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 30, color: Colors.white24);
}

class _FilterBar extends StatelessWidget {
  final List<_ScheduleFilter> filters;
  final String selected;
  final ValueChanged<String> onSelect;
  const _FilterBar({
    required this.filters,
    required this.selected,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 0, 6),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            for (final f in filters) ...[
              _FilterChip(
                filter: f,
                active: f.key == selected,
                onTap: () => onSelect(f.key),
              ),
              const SizedBox(width: 10),
            ],
          ],
        ),
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  final _ScheduleFilter filter;
  final bool active;
  final VoidCallback onTap;
  const _FilterChip({
    required this.filter,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final accent = typeAccent(filter.key);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: active ? accent : Colors.white,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: active ? accent : AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            typeIcon(
              filter.key,
              size: 14,
              color: active ? Colors.white : accent,
            ),
            const SizedBox(width: 6),
            Text(
              filter.label,
              style: TextStyle(
                color: active ? Colors.white : AppColors.ink,
                fontWeight: FontWeight.w700,
                fontSize: 12.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ScheduleCard extends StatelessWidget {
  final SacramentWindow item;
  const _ScheduleCard({required this.item});

  @override
  Widget build(BuildContext context) {
    final accent = typeAccent(item.type);
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 5,
                ),
                decoration: BoxDecoration(
                  color: typeBg(item.type),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    typeIcon(item.type, size: 12, color: accent),
                    const SizedBox(width: 5),
                    Text(
                      typeLabel(item.type),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
              ),
              Text(
                item.dayChip,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            item.time,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 10),
          Container(width: 32, height: 3, color: accent),
          const SizedBox(height: 10),
          Text(
            item.title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          for (final d in item.details)
            Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle,
                      size: 4,
                      color: AppColors.inkSoft,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      d,
                      style: const TextStyle(
                        fontSize: 12.5,
                        height: 1.55,
                        color: AppColors.inkSoft,
                      ),
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

class _CtaPanel extends StatelessWidget {
  final VoidCallback onReserve;
  final VoidCallback onContact;
  const _CtaPanel({required this.onReserve, required this.onContact});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 18, 24, 0),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          borderRadius: BorderRadius.all(Radius.circular(22)),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandDeep, AppColors.brand],
          ),
        ),
        child: Column(
          children: [
            const Text(
              'Ready to proceed?',
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Reserve your sacrament with our parish office',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 17,
                height: 1.3,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Submit a reservation request online and our pastoral team will reach out to confirm your preferred schedule and walk you through the requirements.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: onReserve,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: AppColors.brand,
                  padding: const EdgeInsets.symmetric(vertical: 13),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(999),
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 12.5,
                  ),
                  elevation: 0,
                ),
                child: const Text('BOOK A RESERVATION'),
              ),
            ),
            const SizedBox(height: 12),
            GestureDetector(
              onTap: onContact,
              child: const Text(
                'Contact the parish office →',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
