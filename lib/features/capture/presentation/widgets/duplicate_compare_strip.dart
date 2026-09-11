import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import '../utils/capture_presentation.dart';

/// `B1ydf` — the comparison strip of `DuplicateCompareCard`: the verdict line
/// plus the already-registered transaction the capture may be repeating.
///
/// Rebuilt 2026-09-09 on `$muted` (the card's own fill moved to `$surface`,
/// so the strip can no longer borrow contrast from a tinted card). Every
/// label inside uses `$segment-inactive-text`, not `$text-secondary`:
/// `$text-secondary` on `$muted` measures 4.56:1, which fails AA for anything
/// under 18.66px — none of these labels qualify.
///
/// Not tappable, not editable from here — for comparison only.
class DuplicateCompareStrip extends StatelessWidget {
  const DuplicateCompareStrip({
    required this.capturePostedAt,
    required this.duplicate,
    super.key,
  });

  final DateTime capturePostedAt;
  final CaptureDuplicateView duplicate;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.muted,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            captureDuplicateVerdict(
              l10n,
              capturePostedAt: capturePostedAt,
              duplicate: duplicate,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      duplicate.title ?? l10n.captureNoMerchant,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 1),
                    Text(
                      captureDuplicateExistingLine(l10n, duplicate),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: colors.segmentInactiveText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    l10n.captureDuplicateExistingKicker,
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: colors.segmentInactiveText,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    // Same size and weight as the capture's own amount
                    // (`LBnuX`, 15/600): the two must read as coincident,
                    // which is the entire point of the mark. Only the token
                    // differs, and only because this one sits on `$muted`.
                    // Unsigned on purpose, like the capture's own amount
                    // (`captureAmountLabel`, not `signedAmountLabel`): a
                    // leading `-` here would break the "these two read as
                    // the same number" signal the strip exists to give.
                    captureAmountLabel(
                      amountMinor: duplicate.amountMinor,
                      currencyCode: duplicate.currency,
                      type: duplicate.type,
                    ),
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: colors.segmentInactiveText,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
