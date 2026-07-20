import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The brand "coin" — a small circle with a `$primary` → `$primary-deep`
/// gradient and a `$primary-light` ring (`Coin Glyph`, `U60Oq` in
/// `billetudo.pen`, `design-system/billetudo/pages/splash.md` +
/// `assets/branding/MARCA.md`).
///
/// It stands in for the dot of the "i" in `BrandWordmark` (over a dotless
/// `ı`), and is documented as reusable beyond that — e.g. a future AI
/// assistant avatar — so it lives in `core/widgets` rather than inside
/// `features/splash`.
class CoinGlyph extends StatelessWidget {
  const CoinGlyph({required this.size, super.key});

  final double size;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [colors.primary, colors.primaryDeep],
        ),
        border: Border.all(
          color: colors.primaryLight,
          // Ratio mirrors `U60Oq` (strokeWidth 3 on a 44px circle) and the
          // wordmark's own coin dot (strokeWidth 1 on 16px) in billetudo.pen.
          width: size * (3 / 44),
        ),
      ),
    );
  }
}
