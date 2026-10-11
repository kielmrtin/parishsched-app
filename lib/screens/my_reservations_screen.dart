import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_alert.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/hero_kicker.dart';
import '../widgets/hero_wave.dart';
import '../widgets/logout_button.dart';
import '../widgets/notification_bell.dart';
import '../widgets/sacrament_badge.dart';
import 'inquire_screen.dart';
import 'reservation_screen.dart';
import '../security/secure_screen.dart';
import '../security/app_lock.dart';
import '../widgets/account_button.dart';

/// Mirrors church-web's My Reservations page
/// (resources/views/reservation/my-reservations.blade.php): filter chips,
/// a colored-accent status card per reservation with a review-progress
/// stepper, and a cancellation-request action — read/written straight from
/// the shared `reservations` table. "Add to Calendar" is intentionally
/// left out of the app version.
class MyReservationsScreen extends StatefulWidget {
  const MyReservationsScreen({super.key});

  @override
  State<MyReservationsScreen> createState() => _MyReservationsScreenState();
}

class _MyReservationsScreenState extends State<MyReservationsScreen>
    with SecureScreenMixin {
  late Future<List<Map<String, dynamic>>> _future;
  String _filter = 'all';

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<List<Map<String, dynamic>>> _load() async {
    final customer = await AuthService().fetchCurrentCustomer();
    final customerId = customer?['id'];
    if (customerId == null) return [];
    final rows = await Supabase.instance.client
        .from('reservations')
        .select()
        .eq('customer_id', customerId)
        .order('created_at', ascending: false);
    return List<Map<String, dynamic>>.from(rows);
  }

  Future<void> _reload() async {
    final future = _load();
    setState(() => _future = future);
    await future;
  }

  void _goToReservation() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ReservationScreen()),
    );
  }

  void _contactParish() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const InquireScreen()),
    );
  }

  Future<void> _requestCancellation(Map<String, dynamic> reservation) async {
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => _CancelReasonDialog(),
    );
    if (reason == null) return; // dismissed
    // Sensitive action: confirm it's really the phone's owner.
    if (!await AppLock.confirm('Confirm cancellation request')) return;

    try {
      await Supabase.instance.client
          .from('reservations')
          .update({
            'cancellation_requested': true,
            'cancel_reason': reason.isEmpty ? null : reason,
          })
          .eq('id', reservation['id']);
      _reload();
      if (!mounted) return;
      await showAppAlert(
        context,
        type: AppAlertType.success,
        title: 'Request Sent',
        message: 'Your cancellation request has been submitted. The parish office will respond shortly.',
      );
    } catch (e) {
      if (!mounted) return;
      await showAppAlert(
        context,
        type: AppAlertType.error,
        title: 'Something Went Wrong',
        message: 'We could not submit your cancellation request. Please try again later.',
      );
    }
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
      bottomNavigationBar: const AppBottomNav(current: null),
      body: Column(
        children: [
          const _Hero(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: _reload,
              color: AppColors.brand,
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: _future,
                builder: (context, snapshot) {
                  if (snapshot.connectionState != ConnectionState.done) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: const [
                        Center(
                          heightFactor: 3,
                          child: CircularProgressIndicator(color: AppColors.brand),
                        ),
                      ],
                    );
                  }
                  final items = snapshot.data ?? [];
                  if (items.isEmpty) {
                    return ListView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      children: [_EmptyState(onReserve: _goToReservation)],
                    );
                  }

                  final pending = items.where((r) => (r['status'] as String?) == 'pending').length;
                  final approved = items.where((r) => (r['status'] as String?) == 'approved').length;
                  final declined = items.where((r) => (r['status'] as String?) == 'declined').length;

                  final visible = _filter == 'all'
                      ? items
                      : items.where((r) => (r['status'] as String?) == _filter).toList();

                  return ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(24),
                    children: [
                      _FilterChips(
                        selected: _filter,
                        total: items.length,
                        pending: pending,
                        approved: approved,
                        declined: declined,
                        onSelect: (f) => setState(() => _filter = f),
                      ),
                      const SizedBox(height: 18),
                      for (final r in visible) ...[
                        _ReservationCard(
                          data: r,
                          onRequestCancel: () => _requestCancellation(r),
                          onContactParish: _contactParish,
                        ),
                        const SizedBox(height: 14),
                      ],
                    ],
                  );
                },
              ),
            ),
          ),
        ],
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
          child: Image.asset('assets/images/my_reservations.png', fit: BoxFit.cover),
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
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 40),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const HeroKicker(icon: Icons.calendar_month_outlined, label: 'MY RESERVATIONS'),
              const SizedBox(height: 14),
              const Text(
                'Your reservations',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 26,
                  color: Colors.white,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Track the status of every sacrament you have requested with the parish.',
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

class _EmptyState extends StatelessWidget {
  final VoidCallback onReserve;
  const _EmptyState({required this.onReserve});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 60,
              height: 60,
              decoration: BoxDecoration(
                color: AppColors.brand.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.calendar_today_outlined, color: AppColors.brand, size: 26),
            ),
            const SizedBox(height: 16),
            const Text(
              'No reservations yet',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: AppColors.ink),
            ),
            const SizedBox(height: 8),
            const Text(
              "You haven't submitted any sacrament reservation requests. When you do, they'll appear here with their current status.",
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, height: 1.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onReserve,
              icon: const Icon(Icons.calendar_month_outlined, size: 16),
              label: const Text('Make a Reservation'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brand,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 13),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13),
                elevation: 0,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Interactive filter row — "All" is always solid red, the others always
/// keep their own tint regardless of selection (matching church-web's
/// fixed per-chip CSS classes); the active chip gets a dark ring instead
/// of a color swap, mirroring `.res-summary-chip.is-active`.
class _FilterChips extends StatelessWidget {
  final String selected;
  final int total;
  final int pending;
  final int approved;
  final int declined;
  final ValueChanged<String> onSelect;
  const _FilterChips({
    required this.selected,
    required this.total,
    required this.pending,
    required this.approved,
    required this.declined,
    required this.onSelect,
  });

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        _chip(
          key: 'all',
          label: 'All',
          count: total,
          bg: AppColors.brand,
          fg: Colors.white,
          countBg: Colors.white.withValues(alpha: 0.28),
        ),
        if (pending > 0)
          _chip(
            key: 'pending',
            label: 'Pending',
            count: pending,
            bg: const Color(0xFFFFF8E1),
            fg: const Color(0xFFB45309),
            countBg: const Color(0xFFB45309).withValues(alpha: 0.16),
            dot: const Color(0xFFEAB308),
          ),
        if (approved > 0)
          _chip(
            key: 'approved',
            label: 'Approved',
            count: approved,
            bg: const Color(0xFFE6F9F0),
            fg: const Color(0xFF157A45),
            countBg: const Color(0xFF157A45).withValues(alpha: 0.16),
            dot: const Color(0xFF16A34A),
          ),
        if (declined > 0)
          _chip(
            key: 'declined',
            label: 'Declined',
            count: declined,
            bg: const Color(0xFFFDECEA),
            fg: const Color(0xFFB91C1C),
            countBg: const Color(0xFFB91C1C).withValues(alpha: 0.16),
            dot: const Color(0xFFDC2626),
          ),
      ],
    );
  }

  Widget _chip({
    required String key,
    required String label,
    required int count,
    required Color bg,
    required Color fg,
    required Color countBg,
    Color? dot,
  }) {
    final isActive = selected == key;
    return GestureDetector(
      onTap: () => onSelect(key),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(999),
          border: isActive ? Border.all(color: const Color(0x2E0F172A), width: 2) : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (dot != null) ...[
              Container(width: 7, height: 7, decoration: BoxDecoration(color: dot, shape: BoxShape.circle)),
              const SizedBox(width: 6),
            ],
            Text(label, style: TextStyle(fontWeight: FontWeight.w700, color: fg, fontSize: 13)),
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(color: countBg, borderRadius: BorderRadius.circular(999)),
              child: Text('$count', style: TextStyle(fontWeight: FontWeight.w800, color: fg, fontSize: 11.5)),
            ),
          ],
        ),
      ),
    );
  }
}

(Color, Color) _statusBadgeColors(String status) => switch (status) {
  'approved' => (const Color(0xFFE6F9F0), const Color(0xFF157A45)),
  'declined' => (const Color(0xFFFDECEA), const Color(0xFFB91C1C)),
  'booked' => (const Color(0xFFE8F0FE), const Color(0xFF1A56DB)),
  _ => (const Color(0xFFFFF8E1), const Color(0xFFB45309)),
};

/// The card's left accent bar and stepper "done" color — a brighter set
/// than the softer status-badge pair above, matching church-web's
/// `--accent` CSS variable.
Color _accentColor(String status) => switch (status) {
  'approved' => const Color(0xFF16A34A),
  'declined' => const Color(0xFFDC2626),
  'cancelled' => const Color(0xFF94A3B8),
  'booked' => const Color(0xFF1A56DB),
  _ => const Color(0xFFEAB308),
};

class _StepSpec {
  final String label;
  final _StepState state;
  const _StepSpec(this.label, this.state);
}

enum _StepState { done, current, upcoming, bad, muted }

List<_StepSpec> _stepperFor(String status) => switch (status) {
  'approved' => const [
      _StepSpec('Submitted', _StepState.done),
      _StepSpec('Reviewed', _StepState.done),
      _StepSpec('Confirmed', _StepState.done),
    ],
  'declined' => const [
      _StepSpec('Submitted', _StepState.done),
      _StepSpec('Reviewed', _StepState.done),
      _StepSpec('Declined', _StepState.bad),
    ],
  'cancelled' => const [
      _StepSpec('Submitted', _StepState.done),
      _StepSpec('Reviewed', _StepState.done),
      _StepSpec('Cancelled', _StepState.muted),
    ],
  'booked' => const [
      _StepSpec('Submitted', _StepState.done),
      _StepSpec('Reviewed', _StepState.done),
      _StepSpec('Booked', _StepState.done),
    ],
  _ => const [
      _StepSpec('Submitted', _StepState.done),
      _StepSpec('Under Review', _StepState.current),
      _StepSpec('Decision', _StepState.upcoming),
    ],
};

Color _stepColor(_StepState s) => switch (s) {
  _StepState.done => const Color(0xFF16A34A),
  _StepState.current => const Color(0xFFEAB308),
  _StepState.upcoming => const Color(0xFFE2E8F0),
  _StepState.bad => const Color(0xFFDC2626),
  _StepState.muted => const Color(0xFF94A3B8),
};

Color _stepTextColor(_StepState s) => switch (s) {
  _StepState.done => const Color(0xFF16A34A),
  _StepState.current => const Color(0xFFB45309),
  _StepState.upcoming => const Color(0xFFCBD5E1),
  _StepState.bad => const Color(0xFFDC2626),
  _StepState.muted => const Color(0xFF94A3B8),
};

class _ReservationCard extends StatelessWidget {
  final Map<String, dynamic> data;
  final VoidCallback onRequestCancel;
  final VoidCallback onContactParish;
  const _ReservationCard({
    required this.data,
    required this.onRequestCancel,
    required this.onContactParish,
  });

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  static const _weekdays = [
    'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday',
  ];

  String? _formatFullDate(String? raw) {
    if (raw == null) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return '${_weekdays[d.weekday - 1]}, ${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  String? _formatShortDate(String? raw) {
    if (raw == null) return null;
    final d = DateTime.tryParse(raw);
    if (d == null) return null;
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    final type = ((data['event_type'] as String?) ?? 'other').toLowerCase();
    final status = ((data['status'] as String?) ?? 'pending').toLowerCase();
    final date = _formatFullDate(data['reservation_date'] as String?) ?? '—';
    final submitted = _formatShortDate(data['created_at'] as String?);
    final time = data['reservation_time'] as String?;
    final name = data['name'] as String?;
    final adminNote = (data['admin_note'] as String?)?.trim();
    final cancellationRequested = data['cancellation_requested'] == true;
    final accent = typeAccent(type);
    final (statusBg, statusFg) = _statusBadgeColors(status);
    final cardAccent = _accentColor(status);
    final steps = _stepperFor(status);
    final canCancel = (status == 'pending' || status == 'approved') && !cancellationRequested;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.05), blurRadius: 16, offset: const Offset(0, 6)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: cardAccent),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 18, 18, 18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(color: typeBg(type), borderRadius: BorderRadius.circular(14)),
                          child: Center(child: typeIcon(type, size: 20, color: accent)),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${typeLabel(type) == 'All Schedules' ? 'Reservation' : typeLabel(type)} Reservation',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: AppColors.ink),
                              ),
                              if (name != null && name.isNotEmpty) ...[
                                const SizedBox(height: 2),
                                Text(
                                  'Requested by $name',
                                  style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(color: statusBg, borderRadius: BorderRadius.circular(999)),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(width: 6, height: 6, decoration: BoxDecoration(color: statusFg, shape: BoxShape.circle)),
                              const SizedBox(width: 5),
                              Text(
                                status[0].toUpperCase() + status.substring(1),
                                style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: statusFg, letterSpacing: 0.3),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (submitted != null) ...[
                      const SizedBox(height: 6),
                      Text(
                        'Submitted $submitted',
                        style: TextStyle(fontSize: 11.5, color: Colors.grey.shade500),
                      ),
                    ],
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey.shade500),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            date,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                          ),
                        ),
                      ],
                    ),
                    if (time != null && time.isNotEmpty) ...[
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time, size: 13, color: Colors.grey.shade500),
                          const SizedBox(width: 6),
                          Text(
                            time,
                            style: const TextStyle(fontSize: 12.5, color: AppColors.inkSoft, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 16),
                    _Stepper(steps: steps),
                    if (adminNote != null && adminNote.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.scaffold,
                          borderRadius: const BorderRadius.horizontal(right: Radius.circular(10)),
                          border: Border(left: BorderSide(color: cardAccent, width: 3)),
                        ),
                        child: Text.rich(
                          TextSpan(
                            children: [
                              const TextSpan(
                                text: 'Parish office note: ',
                                style: TextStyle(fontWeight: FontWeight.w800, color: AppColors.ink, fontSize: 12.5),
                              ),
                              TextSpan(
                                text: adminNote,
                                style: const TextStyle(color: AppColors.inkSoft, fontSize: 12.5, height: 1.5),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 10),
                    _StatusLine(status: status),
                    if (status == 'declined' || canCancel) ...[
                      const SizedBox(height: 14),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          if (status == 'declined')
                            ElevatedButton.icon(
                              onPressed: onContactParish,
                              icon: const Icon(Icons.call, size: 14),
                              label: const Text('Contact Parish Office'),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFFDC2626),
                                foregroundColor: Colors.white,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(9)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12),
                                elevation: 0,
                              ),
                            ),
                          if (canCancel)
                            OutlinedButton.icon(
                              onPressed: onRequestCancel,
                              icon: const Icon(Icons.close, size: 14),
                              label: const Text('Request Cancellation'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.inkSoft,
                                side: const BorderSide(color: AppColors.border),
                                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                textStyle: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                              ),
                            ),
                        ],
                      ),
                    ],
                    if ((status == 'pending' || status == 'approved') && cancellationRequested) ...[
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF8E1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Text(
                          'Cancellation request pending — awaiting parish office review',
                          style: TextStyle(fontSize: 11.5, color: Color(0xFFB45309), fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Icon + colored line explaining what the current status means —
/// mirrors the per-status helper paragraph on church-web's card.
class _StatusLine extends StatelessWidget {
  final String status;
  const _StatusLine({required this.status});

  @override
  Widget build(BuildContext context) {
    final (icon, color, text) = switch (status) {
      'pending' => (
          Icons.info_outline,
          Colors.grey.shade500,
          'Your request is being reviewed. You will receive an email once the parish office responds.',
        ),
      'approved' => (
          Icons.check_circle_outline,
          const Color(0xFF157A45),
          'Your reservation is confirmed. Please contact the parish office for next steps.',
        ),
      'declined' => (
          Icons.call_outlined,
          const Color(0xFFB91C1C),
          'Your request was not approved. Please contact the parish office for assistance.',
        ),
      'cancelled' => (
          Icons.cancel_outlined,
          Colors.grey.shade500,
          'This reservation has been cancelled.',
        ),
      _ => (null, null, null),
    };
    if (text == null) return const SizedBox.shrink();
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        Expanded(
          child: Text(text, style: TextStyle(fontSize: 11.5, height: 1.5, color: color)),
        ),
      ],
    );
  }
}

class _Stepper extends StatelessWidget {
  final List<_StepSpec> steps;
  const _Stepper({required this.steps});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          _StepDot(step: steps[i]),
          if (i < steps.length - 1)
            Expanded(
              child: Container(height: 2, margin: const EdgeInsets.symmetric(horizontal: 6), color: _stepColor(steps[i + 1].state)),
            ),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final _StepSpec step;
  const _StepDot({required this.step});

  @override
  Widget build(BuildContext context) {
    final color = _stepColor(step.state);
    Widget dotChild;
    switch (step.state) {
      case _StepState.done:
        dotChild = const Icon(Icons.check, size: 12, color: Colors.white);
      case _StepState.bad:
        dotChild = const Icon(Icons.close, size: 12, color: Colors.white);
      case _StepState.current:
        dotChild = Container(
          width: 7,
          height: 7,
          decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
        );
      case _StepState.upcoming:
      case _StepState.muted:
        dotChild = const SizedBox.shrink();
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 22,
          height: 22,
          alignment: Alignment.center,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          child: dotChild,
        ),
        const SizedBox(height: 4),
        Text(
          step.label,
          style: TextStyle(fontSize: 9.5, fontWeight: FontWeight.w700, color: _stepTextColor(step.state)),
        ),
      ],
    );
  }
}

class _CancelReasonDialog extends StatefulWidget {
  @override
  State<_CancelReasonDialog> createState() => _CancelReasonDialogState();
}

class _CancelReasonDialogState extends State<_CancelReasonDialog> {
  final _reason = TextEditingController();

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Request Cancellation'),
      content: TextField(
        controller: _reason,
        maxLines: 3,
        decoration: const InputDecoration(
          hintText: 'Reason (optional)',
          border: OutlineInputBorder(),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Back'),
        ),
        ElevatedButton(
          style: ElevatedButton.styleFrom(backgroundColor: AppColors.brand, foregroundColor: Colors.white),
          onPressed: () => Navigator.of(context).pop(_reason.text.trim()),
          child: const Text('Submit'),
        ),
      ],
    );
  }
}
