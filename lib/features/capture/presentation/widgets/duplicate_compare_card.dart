import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import '../utils/capture_presentation.dart';
import 'capture_card_shell.dart';
import 'capture_guarantee_kicker.dart';
import 'duplicate_action_button.dart';
import 'duplicate_badge.dart';
import 'duplicate_compare_strip.dart';

/// `EqRlj` — a capture flagged as a POSSIBLE duplicate (HU-07, heuristic case:
/// against a transaction the user already recorded by hand). Rebuilt
/// 2026-09-09; the earlier tinted design no longer exists.
///
/// Shares the family chasis ([CaptureCardShell]) with a `$amber-text` rail —
/// attention, never alarm, never `$expense`, which here would be an
/// accusation about something the user has not even done. **The app never
/// merges nor discards on its own.**
///
/// **Not tappable as a whole, and no chevron** — the one deliberate
/// discrepancy from its siblings (`PendingCaptureCard`, `GroupedCaptureCard`):
/// this card has two exclusive branches, and a tap on the chasis would pick
/// one for the user, exactly where a false positive erases a real expense and
/// silently unbalances an account. Only [DuplicateActionButton] responds.
class DuplicateCompareCard extends StatelessWidget {
  const DuplicateCompareCard({
    required this.item,
    required this.onSame,
    required this.onDifferent,
    super.key,
  });

  final CaptureReviewItem item;

  /// "Es la misma": discards the capture, recording which transaction the
  /// user pointed at. Undoable through the snackbar like any other discard.
  final VoidCallback onSame;

  /// "Es otra compra": carries on to the ordinary dispatch, exactly as a
  /// capture without a duplicate would.
  final VoidCallback onDifferent;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final capture = item.capture;
    final duplicate = item.duplicate;
    if (duplicate == null) {
      return const SizedBox.shrink();
    }

    return CaptureCardShell(
      railColor: colors.amberText,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      // Never truncated to one line here: this is the one
                      // card whose whole purpose is to let the user
                      // recognise the purchase.
                      capture.merchantRaw ?? l10n.captureNoMerchant,
                      maxLines: 2,
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
                        if (item.issuerName != null) ...[
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
                              l10n.captureIssuerLabel(item.issuerName!),
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
                // Identical size/weight to the existing movement's amount in
                // the strip below — the two are meant to read as coincident.
                captureAmountLabel(
                  amountMinor: capture.amountMinor,
                  currencyCode: capture.currency,
                  type: capture.entryType,
                ),
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const DuplicateBadge(),
          const SizedBox(height: 10),
          DuplicateCompareStrip(
            capturePostedAt: capture.postedAt,
            duplicate: duplicate,
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DuplicateActionButton(
                  label: l10n.captureDuplicateSameAction,
                  variant: DuplicateActionVariant.same,
                  onPressed: onSame,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DuplicateActionButton(
                  label: l10n.captureDuplicateOtherAction,
                  variant: DuplicateActionVariant.different,
                  onPressed: onDifferent,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            l10n.captureDuplicateConsequenceCaption,
            style: theme.textTheme.labelSmall?.copyWith(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: colors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
