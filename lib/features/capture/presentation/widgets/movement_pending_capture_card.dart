import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import '../utils/capture_presentation.dart';
import 'capture_status_pill.dart';

/// `vRWd5` — the pending-capture card for contexts where a capture CO-EXISTS
/// with already-registered movements: today, only the ghost block at the top
/// of Movimientos.
///
/// **The tint stays here, on purpose.** `$primary-soft` fill + `$primary-on-
/// soft` stroke + `bell-ring` icon wrap + attenuated amount + "No suma a tu
/// saldo" pill + issuer line. In the Avisos centre every card in the section
/// is a capture, so the same tint had nothing to contrast against and read as
/// noise (user feedback, 2026-09-09) — that surface uses `PendingCaptureCard`
/// (`skjlg`) instead. Since 2026-09-09 there is a sixth, structural signal
/// too: real movement rows in that list are `$surface` cards with 24pt
/// corners, so this card also differs by chasis (tint vs. white) and by
/// radius (16 vs. 24), not only by color.
///
/// Carries the SUGGESTED CATEGORY chip (`oKokr`) this surface alone shows:
/// the chip only exists because `IngestParsedCaptures` resolved one through
/// merchant learning, never from parsing the notification text, so the first
/// capture of a new merchant has none — the chip then simply does not
/// render, no placeholder, no gap.
class MovementPendingCaptureCard extends StatelessWidget {
  const MovementPendingCaptureCard({
    required this.item,
    required this.onTap,
    super.key,
  });

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
    final suggestedCategoryName = item.suggestedCategoryName;

    return Material(
      color: colors.primarySoft,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        // `$primary-on-soft` 1px: the whole card is the tap target, and
        // `$primary-soft` on `$background` is 1.06:1 — WCAG 1.4.11 asks 3:1
        // for a control's boundary.
        side: BorderSide(color: colors.primaryOnSoft),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.surface,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Icon(
                      captureIcon(capture.entryType),
                      size: 20,
                      color: colors.primaryOnSoftStrong,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          capture.merchantRaw ?? l10n.captureNoMerchant,
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
                        if (suggestedCategoryName != null) ...[
                          const SizedBox(height: 6),
                          _SuggestedCategoryChip(name: suggestedCategoryName),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    captureAmountLabel(
                      amountMinor: capture.amountMinor,
                      currencyCode: capture.currency,
                      type: capture.entryType,
                    ),
                    // `$text-secondary`: one of the five signals this figure
                    // has not moved any balance.
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  const CaptureStatusPill(),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      item.issuerName == null
                          ? ''
                          : l10n.captureIssuerLabel(item.issuerName!),
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
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// `oKokr` — "Sugerida: {categoría}", a proposal, never a confirmed fact
/// (category stays required at confirmation). Deliberately not the 44px
/// colored circle a real `TransactionRow` uses for its category: that circle
/// is the visual signature of an ALREADY-REGISTERED movement, and giving it
/// to a capture would spend the strongest signal that tells the two apart.
class _SuggestedCategoryChip extends StatelessWidget {
  const _SuggestedCategoryChip({required this.name});

  final String name;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(9),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(LucideIcons.tag, size: 12, color: colors.textSecondary),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              AppLocalizations.of(context).captureSuggestedCategoryLabel(name),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: colors.textSecondary,
                  ),
            ),
          ),
        ],
      ),
    );
  }
}
