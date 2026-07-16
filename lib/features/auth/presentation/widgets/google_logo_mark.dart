import 'dart:math' as math;

import 'package:flutter/material.dart';

/// A geometric reproduction of Google's public four-color "G" glyph
/// (Google Identity branding guidelines).
///
/// `google_sign_in` ships no button widget for mobile (only the web SDK
/// renders one) — devs building a custom button are expected to reproduce
/// the asset from Google's brand kit. This paints an approximation (ring +
/// crossbar in the four official colors) since no bundled SVG/PNG asset is
/// available in this repo. **Pending**: swap for the certified asset from
/// https://developers.google.com/identity/branding-guidelines if/when design
/// drops one in `assets/`.
class GoogleLogoMark extends StatelessWidget {
  const GoogleLogoMark({this.size = 18, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => CustomPaint(
        size: Size.square(size),
        painter: _GoogleLogoPainter(),
      );
}

class _GoogleLogoPainter extends CustomPainter {
  static const _blue = Color(0xFF4285F4);
  static const _green = Color(0xFF34A853);
  static const _yellow = Color(0xFFFBBC05);
  static const _red = Color(0xFFEA4335);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final strokeWidth = radius * 0.62;
    final ringRect =
        Rect.fromCircle(center: center, radius: radius - strokeWidth / 2);

    final ring = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth;

    ring.color = _red;
    canvas.drawArc(ringRect, _deg(-160), _deg(95), false, ring);
    ring.color = _yellow;
    canvas.drawArc(ringRect, _deg(-65), _deg(65), false, ring);
    ring.color = _green;
    canvas.drawArc(ringRect, _deg(0), _deg(95), false, ring);
    ring.color = _blue;
    canvas.drawArc(ringRect, _deg(95), _deg(105), false, ring);

    final bar = Paint()..color = _blue;
    canvas.drawRect(
      Rect.fromLTWH(
        center.dx - strokeWidth * 0.1,
        center.dy - strokeWidth / 2,
        radius - strokeWidth * 0.1,
        strokeWidth,
      ),
      bar,
    );
  }

  double _deg(double degrees) => degrees * math.pi / 180;

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
