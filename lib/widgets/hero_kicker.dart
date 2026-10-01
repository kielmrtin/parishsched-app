import 'package:flutter/material.dart';

/// Small translucent pill badge used as the eyebrow on photo heroes
/// (About/Schedule/Inquire) — an icon plus a bold, letter-spaced label.
class HeroKicker extends StatelessWidget {
  final IconData icon;
  final String label;
  const HeroKicker({super.key, required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white),
          const SizedBox(width: 7),
          Text(
            label,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 1.4,
            ),
          ),
        ],
      ),
    );
  }
}
