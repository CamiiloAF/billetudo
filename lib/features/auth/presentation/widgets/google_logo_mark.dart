import 'package:flutter/material.dart';

/// A faithful vector reproduction of Google's public four-color "G" glyph
/// (Google Identity branding guidelines), traced from the canonical 18x18
/// path data Google publishes for the `neutral`/`light` button style.
///
/// `google_sign_in` ships no button widget for mobile (only the web SDK
/// renders one) — devs building a custom button are expected to reproduce
/// the asset from Google's brand kit. This paints the real glyph paths
/// (not an approximated ring+bar) since no bundled SVG/PNG asset is
/// available in this repo.
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

  // Path data below is the canonical 18x18 Google "G" glyph.
  static Path _blueSwoosh() => Path()
    ..moveTo(17.64, 9.2045)
    ..cubicTo(17.64, 8.5664, 17.5827, 7.9527, 17.4764, 7.3636)
    ..lineTo(9, 7.3636)
    ..lineTo(9, 10.845)
    ..lineTo(13.8436, 10.845)
    ..cubicTo(13.635, 11.97, 13.0009, 12.9232, 12.0477, 13.5614)
    ..lineTo(12.0477, 15.8195)
    ..lineTo(14.9564, 15.8195)
    ..cubicTo(16.6582, 14.2527, 17.64, 11.9455, 17.64, 9.2045)
    ..close();

  static Path _greenBase() => Path()
    ..moveTo(9, 18)
    ..cubicTo(11.43, 18, 13.4673, 17.1936, 14.9564, 15.8182)
    ..lineTo(12.0477, 13.5601)
    ..cubicTo(11.2413, 14.1, 10.2109, 14.4191, 9, 14.4191)
    ..cubicTo(6.656, 14.4191, 4.6718, 12.836, 3.964, 10.7087)
    ..lineTo(0.9573, 10.7087)
    ..lineTo(0.9573, 13.0405)
    ..cubicTo(2.4382, 15.9832, 5.4818, 18, 9, 18)
    ..close();

  static Path _yellowSide() => Path()
    ..moveTo(3.964, 10.71)
    ..cubicTo(3.784, 10.17, 3.6818, 9.5932, 3.6818, 9)
    ..cubicTo(3.6818, 8.4068, 3.7841, 7.83, 3.9641, 7.29)
    ..lineTo(3.9641, 4.9582)
    ..lineTo(0.9573, 4.9582)
    ..cubicTo(0.3477, 6.1732, 0, 7.5477, 0, 9)
    ..cubicTo(0, 10.4523, 0.3477, 11.8268, 0.9573, 13.0418)
    ..lineTo(3.964, 10.71)
    ..close();

  static Path _redTop() => Path()
    ..moveTo(9, 3.5795)
    ..cubicTo(10.3214, 3.5795, 11.5077, 4.0336, 12.4405, 4.9255)
    ..lineTo(15.0218, 2.3441)
    ..cubicTo(13.4632, 0.8918, 11.4259, 0, 9, 0)
    ..cubicTo(5.4818, 0, 2.4382, 2.0168, 0.9573, 4.9582)
    ..lineTo(3.964, 7.29)
    ..cubicTo(4.6718, 5.1627, 6.656, 3.5795, 9, 3.5795)
    ..close();

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 18;
    canvas.save();
    canvas.scale(scale, scale);

    final paint = Paint()..style = PaintingStyle.fill;
    for (final (path, color) in [
      (_blueSwoosh(), _blue),
      (_greenBase(), _green),
      (_yellowSide(), _yellow),
      (_redTop(), _red),
    ]) {
      paint.color = color;
      canvas.drawPath(path, paint);
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant _GoogleLogoPainter oldDelegate) => false;
}
