import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/content_service.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/hero_wave.dart';
import '../widgets/logout_button.dart';
import '../widgets/notification_bell.dart';
import 'about_screen.dart';
import 'inquire_screen.dart';
import 'my_reservations_screen.dart';
import 'reservation_screen.dart';
import 'schedule_screen.dart';

/// Mirrors church-web's real home page (resources/views/home.blade.php):
/// welcome hero, quick parish info, live announcements from Supabase
/// (same `announcements` table, `show_on_home = true`), parish pillars,
/// and a closing call to action.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  late Future<List<Map<String, dynamic>>> _announcementsFuture;
  String _displayName = '';

  @override
  void initState() {
    super.initState();
    _announcementsFuture = ContentService().fetchHomeAnnouncements();
    _loadDisplayName();
  }

  Future<void> _refresh() async {
    final future = ContentService().fetchHomeAnnouncements();
    setState(() => _announcementsFuture = future);
    await future;
    await _loadDisplayName();
  }

  Future<void> _loadDisplayName() async {
    final user = AuthService().currentUser;
    final metaName = (user?.userMetadata?['full_name'] as String?)?.trim();
    if (metaName != null && metaName.isNotEmpty) {
      setState(() => _displayName = metaName);
      return;
    }
    // Older accounts may not have `full_name` in Auth metadata — fall back
    // to the `customers` table, which always has a name.
    final customer = await AuthService().fetchCurrentCustomer();
    final dbName = (customer?['name'] as String?)?.trim();
    if (!mounted) return;
    setState(
      () => _displayName = (dbName != null && dbName.isNotEmpty)
          ? dbName
          : (user?.email ?? ''),
    );
  }

  void _goToSchedule() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const ScheduleScreen()),
    );
  }

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

  void _goToMyReservations() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const MyReservationsScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ParishSched'),
        actions: const [NotificationBell(), SizedBox(width: 4), LogoutButton()],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        color: AppColors.brand,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _Hero(
              name: _displayName,
              onMyReservations: _goToMyReservations,
              onReserve: _goToReservation,
            ),
            const _InfoStrip(),
            const _AboutPreview(),
            _AnnouncementsSection(
              future: _announcementsFuture,
              onSchedule: _goToSchedule,
              onContact: _goToInquire,
            ),
            const _PillarsSection(),
            _CtaPanel(
              onReserve: _goToReservation,
              onContact: _goToInquire,
            ),
            const SizedBox(height: 8),
          ],
          ),
        ),
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.home),
    );
  }
}

class _Hero extends StatelessWidget {
  final String name;
  final VoidCallback onMyReservations;
  final VoidCallback onReserve;
  const _Hero({required this.name, required this.onMyReservations, required this.onReserve});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset('assets/images/home_page.png', fit: BoxFit.cover),
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
          padding: const EdgeInsets.fromLTRB(24, 34, 24, 38),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (name.isNotEmpty)
                Text(
                  'Signed in as $name',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              const SizedBox(height: 14),
              const Text(
                'Welcome to St. John the Baptist Parish',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 23,
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 14),
              const Text(
                'Serving the faithful of Tiaong with joyful worship, heartfelt sacraments, and a thriving community centered on Christ.',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 13.5,
                  height: 1.6,
                ),
              ),
              const SizedBox(height: 26),
              Row(
                children: [
                  Expanded(
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
                      child: const Text('RESERVE NOW'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: onMyReservations,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        side: const BorderSide(
                          color: Colors.white70,
                          width: 1.3,
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(999),
                        ),
                        textStyle: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 12.5,
                        ),
                      ),
                      child: const Text('MY RESERVATIONS'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Positioned(
          left: 0,
          right: 0,
          bottom: -1,
          child: HeroWave(),
        ),
      ],
    );
  }
}

class _InfoStrip extends StatelessWidget {
  const _InfoStrip();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 0),
      child: Column(
        children: const [
          _InfoRow(
            icon: Icons.location_on_outlined,
            label: 'Visit Us',
            value: 'San Agustin St., Poblacion 1, Tiaong, Quezon',
          ),
          SizedBox(height: 14),
          _InfoRow(
            icon: Icons.access_time_outlined,
            label: 'Parish Office Hours',
            value: 'Monday – Saturday · 8:00 AM – 5:00 PM',
          ),
          SizedBox(height: 14),
          _InfoRow(
            icon: Icons.forum_outlined,
            label: 'Need Assistance?',
            value: 'Call (042) 545 9244 or message us on Facebook',
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppColors.brand.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, color: AppColors.brand, size: 18),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 12.5,
                  color: AppColors.ink,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.45,
                  color: AppColors.inkSoft,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AboutPreview extends StatelessWidget {
  const _AboutPreview();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.scaffold,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(width: 18, height: 2, color: AppColors.brand),
                const SizedBox(width: 8),
                const Text(
                  'OUR PARISH FAMILY',
                  style: TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 11,
                    letterSpacing: 1.4,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            const Text(
              'Faithful, welcoming, and centered on Christ',
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 17,
                color: AppColors.ink,
                height: 1.28,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'St. John the Baptist Parish stands at the heart of Tiaong, Quezon as a home for prayer, celebration, and service — a place to receive the sacraments and walk together in faith.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.6,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 14),
            GestureDetector(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const AboutScreen()),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Discover Our Story',
                    style: TextStyle(
                      color: AppColors.brand,
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(width: 6),
                  Icon(Icons.arrow_forward, color: AppColors.brand, size: 15),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnnouncementsSection extends StatelessWidget {
  final Future<List<Map<String, dynamic>>> future;
  final VoidCallback onSchedule;
  final VoidCallback onContact;
  const _AnnouncementsSection({
    required this.future,
    required this.onSchedule,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 2, color: AppColors.brand),
              const SizedBox(width: 8),
              const Text(
                'PARISH NEWS & UPDATES',
                style: TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Announcements from our parish team',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 18),
          FutureBuilder<List<Map<String, dynamic>>>(
            future: future,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 30),
                  child: Center(
                    child: CircularProgressIndicator(color: AppColors.brand),
                  ),
                );
              }
              if (snapshot.hasError) {
                return Text(
                  "Couldn't load announcements right now.",
                  style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
                );
              }
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return _EmptyAnnouncements(
                  onSchedule: onSchedule,
                  onContact: onContact,
                );
              }
              return Column(
                children: [
                  for (final ann in items) ...[
                    _AnnouncementCard(data: ann),
                    const SizedBox(height: 14),
                  ],
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EmptyAnnouncements extends StatelessWidget {
  final VoidCallback onSchedule;
  final VoidCallback onContact;
  const _EmptyAnnouncements({
    required this.onSchedule,
    required this.onContact,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.scaffold,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.campaign_outlined,
              color: AppColors.brand,
              size: 24,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Announcements are coming soon',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Our team is preparing new updates about upcoming Masses and parish events. Please check back shortly.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.5,
              height: 1.55,
              color: AppColors.inkSoft,
            ),
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onSchedule,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.brand,
                    side: const BorderSide(color: AppColors.brand),
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                  ),
                  child: const Text('VIEW SCHEDULE'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton(
                  onPressed: onContact,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brand,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 11),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(11),
                    ),
                    textStyle: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 11.5,
                    ),
                    elevation: 0,
                  ),
                  child: const Text('CONTACT US'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AnnouncementCard extends StatelessWidget {
  final Map<String, dynamic> data;
  const _AnnouncementCard({required this.data});

  static const _months = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  String? _formatDate(String? raw) {
    if (raw == null) return null;
    final dt = DateTime.tryParse(raw);
    if (dt == null) return null;
    return '${_months[dt.month - 1]} ${dt.day}, ${dt.year}';
  }

  @override
  Widget build(BuildContext context) {
    final title = data['title'] as String? ?? 'Announcement';
    final body = data['body'] as String? ?? '';
    final category = data['category'] as String?;
    final date = _formatDate(data['created_at'] as String?);
    final imagePath = data['image_path'] as String?;
    final imageUrl = (imagePath != null && imagePath.isNotEmpty)
        ? ContentService().announcementImageUrl(imagePath)
        : null;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (imageUrl != null)
            Image.network(
              imageUrl,
              height: 140,
              width: double.infinity,
              fit: BoxFit.cover,
            )
          else
            Container(height: 6, color: AppColors.brand),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.campaign_outlined,
                      size: 13,
                      color: AppColors.brand,
                    ),
                    const SizedBox(width: 5),
                    const Text(
                      'ANNOUNCEMENT',
                      style: TextStyle(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.brand,
                        letterSpacing: 0.5,
                      ),
                    ),
                    if (category != null) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: AppColors.brand.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(999),
                        ),
                        child: Text(
                          category,
                          style: const TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: AppColors.brand,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 15,
                    color: AppColors.ink,
                  ),
                ),
                if (date != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                  ),
                ],
                if (body.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(
                    body,
                    maxLines: 3,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 12.5,
                      height: 1.55,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PillarsSection extends StatelessWidget {
  const _PillarsSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 36, 24, 0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(width: 18, height: 2, color: AppColors.brand),
              const SizedBox(width: 8),
              const Text(
                'PARISH PILLARS',
                style: TextStyle(
                  color: AppColors.brand,
                  fontWeight: FontWeight.w800,
                  fontSize: 11,
                  letterSpacing: 1.4,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'Rooted in faith, animated by service',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 19,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 18),
          GridView.count(
            crossAxisCount: 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
            childAspectRatio: 0.98,
            children: const [
              _PillarCard(
                icon: Icons.wb_sunny_outlined,
                title: 'Worship',
                text:
                    'Celebrate the Eucharist reverently, with sacred music and prayerful participation.',
              ),
              _PillarCard(
                icon: Icons.school_outlined,
                title: 'Formation',
                text:
                    'Nurture disciples through catechesis, Bible studies, and gatherings for all ages.',
              ),
              _PillarCard(
                icon: Icons.favorite_border,
                title: 'Service',
                text:
                    'Reach out to families in need with compassionate programs and parish missions.',
              ),
              _PillarCard(
                icon: Icons.groups_outlined,
                title: 'Community',
                text:
                    'Gather for fellowship, support, and joyful celebrations throughout the year.',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PillarCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _PillarCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
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
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppColors.brand.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.brand, size: 17),
          ),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 13.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 5),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.inkSoft,
              ),
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
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(22),
          gradient: const LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [AppColors.brandDeep, AppColors.brand],
          ),
        ),
        child: Column(
          children: [
            const Text(
              "We're here for you",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 10.5,
                letterSpacing: 1.2,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Ready to celebrate a sacrament or need prayers?',
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
              'Our parish team is ready to welcome you with open doors and joyful hearts. Reach out today and let us journey with you.',
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
                'Message the parish office →',
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
