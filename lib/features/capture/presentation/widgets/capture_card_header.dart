import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import '../utils/capture_presentation.dart';

/// `vzYKi`/`KNhfC` — the top row shared by `PendingCaptureCard` and
/// `DuplicateCompareCard`: icon tile, merchant + "cuenta · fecha", and the
/// **attenuated** amount.
///
/// Shared because the two cards are the same object in two states, and the
/// three "this is not money" signals that live in this row (the tinted tile,
/// the `bell-ring` icon and the `$text-secondary` amount) must not be able to
/// drift apart between them.
class CaptureCardHeader extends StatelessWidget {
  const CaptureCardHeader({required this.item, this.icon, super.key});

  final CaptureReviewItem item;

  /// Overrides the icon derived from the entry type — `EqRlj` uses `copy`
  /// to mark the comparison.
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final capture = item.capture;

    return Row(
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
            icon ?? captureIcon(capture.entryType),
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
                // Pencil does not render ellipsis, so a merchant that fits on
                // one line in the frame can still be long enough to wrap
                // here: real issuer strings run to "GRANERO Y SUPERM LA
                // ESPERANZA SAS". One line, clipped, keeps every card the
                // same height so the block reads as a list.
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
          // `$text-secondary`, never `$income-text`/`$text-primary`: an
          // attenuated amount is one of the five signals that this figure has
          // not moved any balance.
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textSecondary,
          ),
        ),
      ],
    );
  }
}
