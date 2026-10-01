import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Per-sacrament accent shared across Schedule and Reservation: wedding is
/// pink, baptism is green, funeral is gray. 'all' (and anything
/// unrecognized) falls back to the brand red.
Color typeAccent(String key) => switch (key) {
  'wedding' => const Color(0xFFEC4899),
  'baptism' => const Color(0xFF16A34A),
  'funeral' => const Color(0xFF6B7280),
  _ => AppColors.brand,
};

Color typeBg(String key) => switch (key) {
  'wedding' => const Color(0xFFFCE7F3),
  'baptism' => const Color(0xFFDCFCE7),
  'funeral' => const Color(0xFFF3F4F6),
  _ => AppColors.brand.withValues(alpha: 0.1),
};

String typeLabel(String key) => switch (key) {
  'wedding' => 'Wedding',
  'baptism' => 'Baptism',
  'funeral' => 'Funeral',
  _ => 'All Schedules',
};

/// Baptism reads as a cross, funeral as a coffin (matching church-web's own
/// badge glyphs), wedding as a heart.
Widget typeIcon(String key, {required double size, required Color color}) {
  if (key == 'funeral') return CoffinIcon(size: size, color: color);
  if (key == 'baptism') return Icon(Icons.add, size: size, color: color);
  if (key == 'wedding') {
    return Icon(Icons.favorite_border, size: size, color: color);
  }
  return Icon(Icons.grid_view_rounded, size: size, color: color);
}

/// Hexagonal coffin silhouette, tracing church-web's own funeral badge SVG
/// path (`M8 2h8l4 4v12l-4 4H8l-4-4V6z`) in a 24x24 box.
class CoffinIcon extends StatelessWidget {
  final double size;
  final Color color;
  const CoffinIcon({super.key, required this.size, required this.color});

  @override
  Widget build(BuildContext context) {
    return CustomPaint(size: Size(size, size), painter: _CoffinPainter(color));
  }
}

class _CoffinPainter extends CustomPainter {
  final Color color;
  _CoffinPainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final s = size.width / 24;
    final path = Path()
      ..moveTo(8 * s, 2 * s)
      ..lineTo(16 * s, 2 * s)
      ..lineTo(20 * s, 6 * s)
      ..lineTo(20 * s, 18 * s)
      ..lineTo(16 * s, 22 * s)
      ..lineTo(8 * s, 22 * s)
      ..lineTo(4 * s, 18 * s)
      ..lineTo(4 * s, 6 * s)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _CoffinPainter oldDelegate) =>
      oldDelegate.color != color;
}
