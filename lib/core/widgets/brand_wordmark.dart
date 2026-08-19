import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// billetudo's wordmark, built from real text (not a pasted image):
/// "Billetudo" set flat, with no floating elements (`Logo Wordmark`, `y5JJtf`
/// in billetudo.pen — `assets/branding/MARCA.md`,
/// `design-system/billetudo/pages/splash.md`).
///
/// The brand is always written with a capital B; the previous lowercase
/// wordmark whose "i" was dotted by a coin belonged to the retired identity
/// direction (see `docs/branding.md`).
///
/// [fontSize] scales the whole wordmark (default fits a compact/inline use;
/// splash uses the protagonist size of 56 per its spec). Tracking follows
/// `MARCA.md`'s `-0.045em`.
class BrandWordmark extends StatelessWidget {
  const BrandWordmark({this.fontSize = 32, super.key});

  final double fontSize;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    // Backed by its own AppLocalizations key, invariant across locales since
    // this is the brand name, not a translation.
    return Text(
      AppLocalizations.of(context).brandWordmark,
      style: TextStyle(
        fontFamily: AppTheme.fontFamily,
        fontSize: fontSize,
        fontWeight: FontWeight.w800,
        letterSpacing: fontSize * -0.045,
        color: colors.textPrimary,
        height: 1,
      ),
    );
  }
}
