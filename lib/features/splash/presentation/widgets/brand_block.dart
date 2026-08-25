import 'package:flutter/material.dart';

import '../../../../core/widgets/brand_wordmark.dart';

/// App icon + wordmark, laid out as a single horizontal unit (`Brand Block`,
/// `Ditt8` in billetudo.pen: `gap:14`, vertically centered) — see
/// `design-system/billetudo/pages/splash.md`.
///
/// The icon is the real app asset (`assets/branding/ic_launcher_master.png`),
/// clipped to a corner radius proportional to `App Icon Tile`'s
/// `cornerRadius:24` at its 96px source size (24/96 = 0.25 → 12px at 48px).
class BrandBlock extends StatelessWidget {
  const BrandBlock({super.key});

  static const _iconSize = 48.0;
  static const _iconCornerRadius = 12.0;
  static const _gap = 14.0;
  static const _wordmarkFontSize = 44.0;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(_iconCornerRadius),
          child: Image.asset(
            'assets/branding/ic_launcher_master.png',
            width: _iconSize,
            height: _iconSize,
          ),
        ),
        const SizedBox(width: _gap),
        const BrandWordmark(fontSize: _wordmarkFontSize),
      ],
    );
  }
}
