import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'coin_glyph.dart';

/// billetudo's wordmark, built from real text (not a pasted image): "b" +
/// a dotless "ı" (U+0131) topped by a [CoinGlyph] standing in for its dot +
/// "lletudo" (`Logo Wordmark`, `y5JJtf` in billetudo.pen —
/// `assets/branding/MARCA.md`, `design-system/billetudo/pages/splash.md`).
///
/// `MARCA.md` forbids ever filling the "i" with both its natural dot and the
/// coin at once — only the dotless glyph is used here, precisely to avoid
/// that.
///
/// [fontSize] scales the whole glyph (default fits a compact/inline use;
/// splash uses the protagonist size of 56 per its spec). Tracking follows
/// MASTER.md's `letterSpacing: -0.04em`.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({this.fontSize = 32, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final style = TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: fontSize,
      fontWeight: FontWeight.w800,
      letterSpacing: fontSize * -0.04,
      color: colors.textPrimary,
      height: 1,
    );

    // Proportions lifted from the reference frame in billetudo.pen: a 16px
    // coin dot offset (x:-2, y:3) at a 56px font size.
    const referenceFontSize = 56.0;
    final scale = fontSize / referenceFontSize;
    final coinSize = 16 * scale;
    final coinOffsetX = -2 * scale;
    final coinOffsetY = 3 * scale;

    final l10n = AppLocalizations.of(context);

    // Split across three `Text`s (backed by their own AppLocalizations keys,
    // invariant across locales since this is the brand name, not a
    // translation) so the coin glyph can stand in for the "i"'s dot.
    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(l10n.brandWordmarkPrefix, style: style),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Text(l10n.brandWordmarkDotlessI, style: style),
            Positioned(
              left: coinOffsetX,
              top: coinOffsetY,
              child: CoinGlyph(size: coinSize),
            ),
          ],
        ),
        Text(l10n.brandWordmarkSuffix, style: style),
      ],
    );
  }
}
