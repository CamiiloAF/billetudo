import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// The "Dictar" pill of the amount `Zona Fija` (`oy9ZV` in `E1vEe7`).
///
/// It lives in the amount header rather than above the form for three
/// reasons the component itself records: it costs 0px of the scrollable zone
/// (the header already measured 44pt because of the collapse chevron), that
/// zone does not scroll — and dictating fills the *whole* form, not just the
/// visible field, so the trigger has to be reachable at any scroll position —
/// and it sits in the thumb's half of the screen.
///
/// It carries a label as well as the icon: a button may not rely on its shape
/// alone to be recognizable (MASTER.md). The 1pt `$primary-on-soft` stroke is
/// not decoration either — `$primary-soft` on `$surface` is 1.16:1, and this
/// is a touch target (WCAG 1.4.11).
class VoiceDictatePill extends StatelessWidget {
  const VoiceDictatePill({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onPressed,
        child: Tooltip(
          message: l10n.captureVoiceDictateTooltip,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: colors.primaryOnSoft),
            ),
            padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  LucideIcons.mic,
                  size: 16,
                  color: colors.primaryOnSoftStrong,
                ),
                const SizedBox(width: 6),
                Text(
                  l10n.captureVoiceDictate,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.primaryOnSoftStrong,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
