import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../services/auth_service.dart';
import '../theme/app_theme.dart';
import 'sacrament_badge.dart';

/// Bell icon shown next to [LogoutButton] on every main screen. Fetches the
/// signed-in customer's approved/declined reservations and shows a red
/// badge for the ones updated since the customer last opened the panel
/// (tracked locally via SharedPreferences — there's no separate
/// notifications table, this just reads `reservations.updated_at`).
class NotificationBell extends StatefulWidget {
  const NotificationBell({super.key});

  @override
  State<NotificationBell> createState() => _NotificationBellState();
}

class _NotificationBellState extends State<NotificationBell> {
  List<Map<String, dynamic>> _updates = [];
  int _unseenCount = 0;
  bool _loading = true;
  dynamic _customerId;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final customer = await AuthService().fetchCurrentCustomer();
      final customerId = customer?['id'];
      if (customerId == null) {
        if (mounted) setState(() => _loading = false);
        return;
      }
      final rows = await Supabase.instance.client
          .from('reservations')
          .select('id,event_type,reservation_date,status,admin_note,updated_at')
          .eq('customer_id', customerId)
          .inFilter('status', ['approved', 'declined'])
          .order('updated_at', ascending: false)
          .limit(20);
      final updates = List<Map<String, dynamic>>.from(rows);

      final prefs = await SharedPreferences.getInstance();
      final lastSeenStr = prefs.getString('notif_last_seen_$customerId');
      final lastSeen = lastSeenStr != null ? DateTime.tryParse(lastSeenStr) : null;

      var unseen = 0;
      for (final u in updates) {
        final updatedAt = DateTime.tryParse((u['updated_at'] as String?) ?? '');
        if (updatedAt != null && (lastSeen == null || updatedAt.isAfter(lastSeen))) {
          unseen++;
        }
      }

      if (!mounted) return;
      setState(() {
        _updates = updates;
        _unseenCount = unseen;
        _customerId = customerId;
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _markSeen() async {
    if (_customerId == null) return;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('notif_last_seen_$_customerId', DateTime.now().toIso8601String());
    if (mounted) setState(() => _unseenCount = 0);
  }

  void _openPanel() {
    _markSeen();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => _NotificationPanel(updates: _updates),
    );
  }

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: _loading ? null : _openPanel,
      icon: Stack(
        clipBehavior: Clip.none,
        children: [
          const Icon(Icons.notifications_outlined, color: AppColors.ink),
          if (_unseenCount > 0)
            Positioned(
              right: -2,
              top: -2,
              child: Container(
                padding: const EdgeInsets.all(3),
                constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                decoration: const BoxDecoration(color: Colors.red, shape: BoxShape.circle),
                child: Text(
                  _unseenCount > 9 ? '9+' : '$_unseenCount',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.white, fontSize: 9, fontWeight: FontWeight.w800),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

(Color, Color) _statusColors(String status) => switch (status) {
  'approved' => (const Color(0xFFE6F9F0), const Color(0xFF157A45)),
  'declined' => (const Color(0xFFFDECEA), const Color(0xFFB91C1C)),
  _ => (const Color(0xFFFFF8E1), const Color(0xFFB45309)),
};

class _NotificationPanel extends StatelessWidget {
  final List<Map<String, dynamic>> updates;
  const _NotificationPanel({required this.updates});

  static const _months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  String _formatDate(String? raw) {
    if (raw == null) return '—';
    final d = DateTime.tryParse(raw);
    if (d == null) return '—';
    return '${_months[d.month - 1]} ${d.day}, ${d.year}';
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
        padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.border,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Notifications',
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.ink),
            ),
            const SizedBox(height: 4),
            const Text(
              'Updates on your sacrament reservations.',
              style: TextStyle(fontSize: 12.5, color: AppColors.inkSoft),
            ),
            const SizedBox(height: 16),
            if (updates.isEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 30),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 36, color: Colors.grey.shade400),
                    const SizedBox(height: 10),
                    Text(
                      'No updates yet',
                      style: TextStyle(fontSize: 13.5, color: Colors.grey.shade500, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              )
            else
              Flexible(
                child: ListView.separated(
                  shrinkWrap: true,
                  itemCount: updates.length,
                  separatorBuilder: (context, index) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final u = updates[index];
                    final type = ((u['event_type'] as String?) ?? 'other').toLowerCase();
                    final status = ((u['status'] as String?) ?? '').toLowerCase();
                    final adminNote = (u['admin_note'] as String?)?.trim();
                    final (statusBg, statusFg) = _statusColors(status);
                    final accent = typeAccent(type);

                    return Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: AppColors.scaffold,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(color: typeBg(type), shape: BoxShape.circle),
                            child: Center(child: typeIcon(type, size: 16, color: accent)),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        '${typeLabel(type)} · ${_formatDate(u['reservation_date'] as String?)}',
                                        style: const TextStyle(
                                          fontWeight: FontWeight.w800,
                                          fontSize: 13,
                                          color: AppColors.ink,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                      decoration: BoxDecoration(
                                        color: statusBg,
                                        borderRadius: BorderRadius.circular(999),
                                      ),
                                      child: Text(
                                        status.isEmpty ? '' : status[0].toUpperCase() + status.substring(1),
                                        style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: statusFg),
                                      ),
                                    ),
                                  ],
                                ),
                                if (adminNote != null && adminNote.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Text(
                                    adminNote,
                                    style: const TextStyle(fontSize: 12, height: 1.4, color: AppColors.inkSoft),
                                  ),
                                ],
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
