import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import '../utils/capture_presentation.dart';
import 'capture_card_shell.dart';
import 'capture_guarantee_kicker.dart';

/// `skjlg` — the ordinary pending-capture card of the Avisos centre
/// (HU-04/HU-05). Rebuilt 2026-09-09: zero-tint chasis identical to a Notice
/// Card (`cYVQm`), a 4px `$primary-on-soft` rail as the only accent, no icon
/// wrap, no "Confirmar" button.
///
/// **The whole card is the tap target** (350x81, ~8x a 96x44 button) and it
/// navigates to the ordinary transaction form, pre-filled (HU-05) — it never
/// writes a `Transaction` itself. There is deliberately no solid `$primary`
/// button here: with two notices already using one, a third would make
/// "solid" stop meaning priority.
///
/// This is the Avisos-centre-only member of the capture-card family. The
/// movements list uses a different component, `MovementPendingCaptureCard`
/// (`vRWd5`) — the two used to share one widget, but the 2026-09-09 redesign
/// gave them genuinely different chrome (tint vs. none, icon wrap vs. none,
/// a category chip vs. none) and forcing them back into one class is what let
/// details drift silently before.
class PendingCaptureCard extends StatelessWidget {
  const PendingCaptureCard(
      {required this.item, required this.onTap, super.key});

  final CaptureReviewItem item;

  /// Opens the ordinary transaction form, pre-filled. Never a parallel
  /// "quick confirm" with rules of its own.
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final capture = item.capture;
    final issuerName = item.issuerName;

    return CaptureCardShell(
      railColor: colors.primaryOnSoft,
      onTap: onTap,
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  capture.merchantRaw ?? l10n.captureNoMerchant,
                  // Pencil does not render ellipsis: real issuer strings run
                  // to "GRANERO Y SUPERM LA ESPERANZA SAS". One line, clipped,
                  // keeps every card the same height so the block reads as a
                  // list.
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    height: 1.3,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  l10n.captureSubtitle(
                    item.accountName ?? l10n.captureNoAccount,
                    captureWhenLabel(l10n, capture.postedAt),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
                const SizedBox(height: 5),
                Row(
                  children: [
                    const CaptureGuaranteeKicker(),
                    if (issuerName != null) ...[
                      const SizedBox(width: 5),
                      Text(
                        '·',
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: colors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 5),
                      Expanded(
                        child: Text(
                          l10n.captureIssuerLabel(issuerName),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.labelSmall?.copyWith(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Text(
            captureAmountLabel(
              amountMinor: capture.amountMinor,
              currencyCode: capture.currency,
              type: capture.entryType,
            ),
            // `$text-secondary`, never `$income-text`/`$text-primary`: an
            // attenuated amount is one of the signals that this figure has
            // not moved any balance yet.
            style: theme.textTheme.titleSmall?.copyWith(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 10),
          Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary),
        ],
      ),
    );
  }
}
