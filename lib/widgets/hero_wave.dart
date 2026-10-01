import 'package:flutter/material.dart';

/// The wavy divider church-web draws under its photo heroes
/// (`.schedule_intro_wave` SVG: `M0,56 L0,28 Q360,0 720,28 Q1080,56 1440,28
/// L1440,56 Z`) — an S-curve that softens the hard cut from a dark photo
/// hero into the white content below. Drop this at the bottom of any hero
/// `Stack` via `Positioned(left: 0, right: 0, bottom: -1, child: HeroWave())`.
class HeroWave extends StatelessWidget {
  final Color color;
  final double height;
  const HeroWave({super.key, this.color = Colors.white, this.height = 26});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: height,
      child: CustomPaint(size: Size.infinite, painter: _WavePainter(color)),
    );
  }
}

class _WavePainter extends CustomPainter {
  final Color color;
  _WavePainter(this.color);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final path = Path()
      ..moveTo(0, h * 0.5)
      ..quadraticBezierTo(w * 0.25, 0, w * 0.5, h * 0.5)
      ..quadraticBezierTo(w * 0.75, h, w, h * 0.5)
      ..lineTo(w, h)
      ..lineTo(0, h)
      ..close();
    canvas.drawPath(path, Paint()..color = color);
  }

  @override
  bool shouldRepaint(covariant _WavePainter oldDelegate) => oldDelegate.color != color;
}
