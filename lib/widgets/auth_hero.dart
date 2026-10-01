import 'dart:ui';

import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import 'hero_bullet.dart';

/// Photo hero used at the top of the auth screens: background photo, dark
/// red tint (matches church-web's auth-photo-side overlay), a frosted-glass
/// badge, headline, subtitle, and a short bullet list.
class AuthHero extends StatelessWidget {
  final String imagePath;
  final IconData badgeIcon;
  final String badgeLabel;
  final String headline;
  final String subtitle;
  final List<String> bullets;

  const AuthHero({
    super.key,
    required this.imagePath,
    required this.badgeIcon,
    required this.badgeLabel,
    required this.headline,
    required this.subtitle,
    this.bullets = const [],
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(
          imagePath,
          fit: BoxFit.cover,
          alignment: Alignment.topCenter,
        ),
        Container(color: AppColors.photoTint),
        Padding(
          padding: const EdgeInsets.fromLTRB(24, 56, 24, 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: BackdropFilter(
                  filter: ImageFilter.blur(sigmaX: 8, sigmaY: 8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.26),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(badgeIcon, size: 12, color: AppColors.brand),
                        const SizedBox(width: 8),
                        Text(
                          badgeLabel,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11,
                            fontWeight: FontWeight.w800,
                            letterSpacing: 0.6,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                headline,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 30,
                  fontWeight: FontWeight.w800,
                  height: 1.12,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                subtitle,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 13.5,
                  height: 1.45,
                ),
              ),
              if (bullets.isNotEmpty) const SizedBox(height: 22),
              for (var i = 0; i < bullets.length; i++) ...[
                if (i > 0) const SizedBox(height: 12),
                HeroBullet(bullets[i]),
              ],
            ],
          ),
        ),
      ],
    );
  }
}
