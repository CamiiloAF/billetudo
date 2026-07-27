import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'google_logo_mark.dart';

/// `Button/Google` (`FJ4Yl` in `billetudo.pen`): the `neutral` style from
/// Google's Identity branding guidelines — surface fill, bordered, fixed
/// text weight — deliberately **not** billetudo's `$primary`/Plus Jakarta
/// Sans (documented exception in `design-system/billetudo/pages/auth.md`).
/// The fill/border/text use `$surface`/`$border`/`$text-primary` (per the
/// Pencil component), so the button recolors to a solid dark style in dark
/// theme instead of staying a fixed white — only the 4-color "G" glyph is
/// fixed by brand, per the doc.
///
/// Height 50 / radius 12, matching `Auth/Sign-in Buttons Group`. Shows a
/// spinner in place of the logo while [isLoading] (design ref `QD8kh`).
class GoogleSignInButton extends StatelessWidget {
  const GoogleSignInButton({
    required this.label,
    required this.loadingLabel,
    required this.onPressed,
    this.isLoading = false,
    super.key,
  });

  final String label;

  /// Shown in place of [label] while [isLoading] — "Conectando con Google…"
  /// per the loading frame (`QD8kh`), which swaps the label too, not only the
  /// logo for the spinner.
  final String loadingLabel;
  final VoidCallback? onPressed;
  final bool isLoading;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    // The loading frame (`QD8kh`) mutes the whole content to `$text-secondary`
    // and bumps the label to 700; the resting button stays `$text-primary`/600.
    final contentColor = isLoading ? colors.textSecondary : colors.textPrimary;

    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 50),
      child: SizedBox(
        width: double.infinity,
        child: OutlinedButton(
          onPressed: isLoading ? null : onPressed,
          style: OutlinedButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.textPrimary,
            side: BorderSide(color: colors.border),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isLoading)
                SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: contentColor,
                  ),
                )
              else
                const GoogleLogoMark(),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  isLoading ? loadingLabel : label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  // 'Roboto' isn't bundled in assets/fonts/ (only Plus Jakarta
                  // Sans is, see pubspec.yaml) — this falls back to the
                  // platform default, which is Roboto on Android anyway. Both
                  // brand guidelines forbid the app's own typeface here
                  // regardless.
                  style: TextStyle(
                    fontFamily: 'Roboto',
                    fontSize: 15,
                    fontWeight: isLoading ? FontWeight.w700 : FontWeight.w600,
                    color: contentColor,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
