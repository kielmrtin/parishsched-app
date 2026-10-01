import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../theme/app_theme.dart';
import '../widgets/app_bottom_nav.dart';
import '../widgets/hero_kicker.dart';
import '../widgets/hero_wave.dart';
import '../widgets/logout_button.dart';
import '../widgets/notification_bell.dart';
import 'inquire_screen.dart';

/// Content pulled from church-web's real About page (pages/about.blade.php):
/// same history, mission, pastoral team, and contact details.
class AboutScreen extends StatelessWidget {
  const AboutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('ParishSched'),
        automaticallyImplyLeading: false,
        actions: const [NotificationBell(), SizedBox(width: 4), LogoutButton()],
      ),
      bottomNavigationBar: const AppBottomNav(current: AppTab.about),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: const [
            _Hero(),
            _Section(
              pretitle: 'Our Heritage',
              title: 'Faith that grew alongside our town',
              paragraphs: [
                "Established by Franciscan missionaries in 1600 and originally dedicated to Santiago Apostle, the parish was rededicated to St. John the Baptist in 1794.",
                "Bombed during WWII in 1945, it was rebuilt from the ruins — the latest chapter in a church rebuilt several times since 1605.",
              ],
            ),
            _TimelineSection(),
            _MissionSection(),
            _TeamSection(),
            _CtaPanel(),
            _ContactSection(),
            SizedBox(height: 8),
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
          child: Image.asset(
            'assets/images/welcome_bg.jpg',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
          ),
        ),
        Positioned.fill(
          child: DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  const Color(0xFF0F0508).withValues(alpha: 0.72),
                  const Color(0xFF6E0F1C).withValues(alpha: 0.68),
                  const Color(0xFF0F0508).withValues(alpha: 0.92),
                ],
              ),
            ),
          ),
        ),
        SafeArea(
          top: false,
          bottom: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 26, 24, 46),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const HeroKicker(
                  icon: Icons.info_outline,
                  label: 'ABOUT THE PARISH',
                ),
                const SizedBox(height: 14),
                const Text(
                  'More than a century of steadfast faith and joyful service',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  "Our parish in Tiaong has journeyed with generations of families — celebrating sacraments, forming disciples, and extending Christ's compassion to every corner of the community.",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    height: 1.55,
                  ),
                ),
                const SizedBox(height: 22),
                _GlassCard(
                  padding: const EdgeInsets.fromLTRB(18, 18, 18, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        '"In every prayer, procession, and outreach effort, we recognize how the Holy Spirit continues to renew our parish family. Thank you for walking this mission with us."',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 13.5,
                          fontStyle: FontStyle.italic,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'Rev. Fr. Edwin Baruelo, E.V.',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 13,
                        ),
                      ),
                      Text(
                        'Parish Priest',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.65),
                          fontSize: 11.5,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  children: const [
                    Expanded(
                      child: _StatCard(
                        num: '100+',
                        label: 'Years serving Tiaong families',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        num: '35',
                        label: 'Active ministries & organizations',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: const [
                    Expanded(
                      child: _StatCard(
                        num: '500+',
                        label: 'Families gathered weekly',
                      ),
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: _StatCard(
                        num: '24',
                        label: 'Outreach programs a year',
                      ),
                    ),
                  ],
                ),
              ],
            ),
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

class _GlassCard extends StatelessWidget {
  final Widget child;
  final EdgeInsets padding;
  const _GlassCard({required this.child, required this.padding});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: child,
    );
  }
}

class _StatCard extends StatelessWidget {
  final String num;
  final String label;
  const _StatCard({required this.num, required this.label});

  @override
  Widget build(BuildContext context) {
    return _GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 8),
      child: Column(
        children: [
          Text(
            num,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w900,
              fontSize: 22,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.82),
              fontSize: 11.5,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionPretitle extends StatelessWidget {
  final String text;
  const _SectionPretitle(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 18, height: 2, color: AppColors.brand),
        const SizedBox(width: 8),
        Text(
          text.toUpperCase(),
          style: const TextStyle(
            color: AppColors.brand,
            fontWeight: FontWeight.w800,
            fontSize: 11,
            letterSpacing: 1.6,
          ),
        ),
      ],
    );
  }
}

class _Section extends StatelessWidget {
  final String pretitle;
  final String title;
  final List<String> paragraphs;
  const _Section({
    required this.pretitle,
    required this.title,
    required this.paragraphs,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 40, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SectionPretitle(pretitle),
          const SizedBox(height: 10),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 14),
          for (final p in paragraphs) ...[
            Text(
              p,
              style: const TextStyle(
                fontSize: 13.5,
                height: 1.75,
                color: AppColors.inkSoft,
              ),
            ),
            const SizedBox(height: 12),
          ],
        ],
      ),
    );
  }
}

class _TimelineSection extends StatelessWidget {
  const _TimelineSection();

  static const _items = [
    (
      '1920s',
      'The faithful of Tiaong build the first chapel honoring St. John the Baptist.',
    ),
    (
      '1954',
      'Worship space expands; catechetical teams prepare hundreds for First Communion.',
    ),
    (
      '1987',
      'Lay ministers open outreach missions offering medical aid to nearby barangays.',
    ),
    (
      '2005',
      'A new pastoral center opens for small faith communities and music ministries.',
    ),
    (
      'Today',
      'Digital initiatives — like this app — carry the parish into its next century.',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionPretitle('Milestones'),
          const SizedBox(height: 10),
          const Text(
            'A timeline of grace-filled moments',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 22),
          for (var i = 0; i < _items.length; i++)
            _TimelineTile(
              year: _items[i].$1,
              text: _items[i].$2,
              isLast: i == _items.length - 1,
            ),
        ],
      ),
    );
  }
}

class _TimelineTile extends StatelessWidget {
  final String year;
  final String text;
  final bool isLast;
  const _TimelineTile({
    required this.year,
    required this.text,
    required this.isLast,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 20,
            child: Column(
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 3),
                  child: _PulsingDot(),
                ),
                if (!isLast)
                  Expanded(child: Container(width: 2, color: AppColors.border)),
              ],
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 22),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    year,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 13,
                      color: AppColors.brand,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    text,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.55,
                      color: AppColors.inkSoft,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Pulsing ring around the timeline dot, matching church-web's own
/// `@keyframes tm-pulse` on `.timeline-marker`.
class _PulsingDot extends StatefulWidget {
  const _PulsingDot();

  @override
  State<_PulsingDot> createState() => _PulsingDotState();
}

class _PulsingDotState extends State<_PulsingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final t = _controller.value;
        final spread = 8 * t;
        final alpha = (0.45 * (1 - t)).clamp(0.0, 0.45);
        return Container(
          width: 11,
          height: 11,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.white,
            border: Border.all(color: AppColors.brand, width: 2.5),
            boxShadow: [
              BoxShadow(
                color: AppColors.brand.withValues(alpha: alpha),
                spreadRadius: spread,
              ),
            ],
          ),
        );
      },
    );
  }
}

class _MissionSection extends StatelessWidget {
  const _MissionSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionPretitle("Why We're Here"),
          const SizedBox(height: 10),
          const Text(
            'Mission, vision & values',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 18),
          const _MissionCard(
            icon: Icons.favorite_border,
            title: 'Our Mission',
            text:
                'A welcoming Catholic community that worships through Word and Sacrament, forms disciples, and serves our neighbors through justice and charity.',
          ),
          const SizedBox(height: 14),
          const _MissionCard(
            icon: Icons.lightbulb_outline,
            title: 'Our Vision',
            text:
                "Rooted in the Gospel, radiating Christ's love — nurturing families, empowering youth, and reaching the vulnerable with hope.",
          ),
          const SizedBox(height: 14),
          const _MissionCard(
            icon: Icons.water_drop_outlined,
            title: 'Our Values',
            text:
                'Prayer, stewardship, and service guide every ministry — caring for creation and lifting one another up in Christ.',
          ),
        ],
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String text;
  const _MissionCard({
    required this.icon,
    required this.title,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
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
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15.5,
              color: AppColors.ink,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            text,
            style: const TextStyle(
              fontSize: 12.8,
              height: 1.65,
              color: AppColors.inkSoft,
            ),
          ),
        ],
      ),
    );
  }
}

class _TeamSection extends StatelessWidget {
  const _TeamSection();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 32, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionPretitle('Meet the Team'),
          const SizedBox(height: 10),
          const Text(
            'Our pastoral team',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 18),
          const _TeamCard(
            name: 'Rev. Fr. Edwin Baruelo, E.V.',
            role: 'Parish Priest',
            text:
                'Shepherds the parish community, presides at the sacraments, and leads pastoral care for families.',
          ),
          const SizedBox(height: 14),
          const _TeamCard(
            name: 'Rev. Fr. Norman Jalla',
            role: 'Parish Priest',
            text:
                'Organizes medical missions, livelihood programs, and parish relief operations across the barangays.',
          ),
        ],
      ),
    );
  }
}

class _TeamCard extends StatelessWidget {
  final String name;
  final String role;
  final String text;
  const _TeamCard({required this.name, required this.role, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColors.border),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              gradient: const LinearGradient(
                colors: [Color(0xFFFFF1F2), Color(0xFFFECACA)],
              ),
              border: Border.all(
                color: AppColors.brand.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
            child: const Icon(Icons.add, color: AppColors.brand),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: const TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.ink,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  role.toUpperCase(),
                  style: const TextStyle(
                    color: AppColors.brand,
                    fontWeight: FontWeight.w800,
                    fontSize: 10.5,
                    letterSpacing: 0.6,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  text,
                  style: const TextStyle(
                    fontSize: 12.5,
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

class _CtaPanel extends StatelessWidget {
  const _CtaPanel();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 34, 24, 0),
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
          boxShadow: [
            BoxShadow(
              color: AppColors.brand.withValues(alpha: 0.4),
              blurRadius: 30,
              offset: const Offset(0, 16),
            ),
          ],
        ),
        child: Column(
          children: [
            const Text(
              'Journey with us in faith',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 18,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              "Whether you're returning to the sacraments or looking for ways to serve, there's a place for you here.",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.85),
                fontSize: 13,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 18),
            GestureDetector(
              onTap: () => Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (_) => const InquireScreen()),
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 22,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'CONNECT WITH OUR TEAM',
                  style: TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ContactSection extends StatelessWidget {
  const _ContactSection();

  Future<void> _openMaps() async {
    final uri = Uri.parse(
      'https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent('St. John The Baptist Parish Tiaong Quezon')}',
    );
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 52, 24, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionPretitle('Visit Us'),
          const SizedBox(height: 10),
          const Text(
            'Our location',
            style: TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 21,
              color: AppColors.ink,
              height: 1.28,
            ),
          ),
          const SizedBox(height: 18),
          const _ContactRow(
            icon: Icons.location_on_outlined,
            text: 'Maharlika Highway, Barangay Poblacion II, Tiaong, Quezon',
          ),
          const SizedBox(height: 14),
          const _ContactRow(icon: Icons.call_outlined, text: '(042) 545-9244'),
          const SizedBox(height: 14),
          const _ContactRow(
            icon: Icons.mail_outline,
            text: 'stjohnbaptisttiaongparish@gmail.com',
          ),
          const SizedBox(height: 14),
          const _ContactRow(
            icon: Icons.access_time_outlined,
            text: 'Office hours: Tue–Sun, 8:00 AM–5:00 PM',
          ),
          const SizedBox(height: 22),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _openMaps,
              icon: const Icon(Icons.map_outlined, size: 18),
              label: const Text('Open in Maps'),
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
    );
  }
}

class _ContactRow extends StatelessWidget {
  final IconData icon;
  final String text;
  const _ContactRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 17, color: AppColors.brand),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13.5,
              height: 1.5,
              color: AppColors.ink,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
