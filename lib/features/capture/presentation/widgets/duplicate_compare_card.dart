import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import 'capture_card_header.dart';
import 'duplicate_compare_strip.dart';

/// `EqRlj` — a capture flagged as a POSSIBLE duplicate (HU-07), shown next to
/// the movement it might be repeating so the user can compare date, account
/// and amount before deciding.
///
/// **The app never merges nor discards on its own.** Both answers are
/// explicit and carry exactly the same visual weight (see
/// [DuplicateActionButton]): a false positive erases a real expense and
/// silently unbalances the account, which is worse than the duplicate it
/// would have prevented.
///
/// Shares the capture family's look (tinted fill, attenuated amount,
/// `$primary-on-soft` stroke) so it reads as the same thing in another state.
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
    final duplicate = item.duplicate;
    if (duplicate == null) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.primaryOnSoft),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          CaptureCardHeader(item: item, icon: LucideIcons.copy),
          const SizedBox(height: 10),
          Row(
            children: [
              const DuplicateBadge(),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  l10n.captureNotBalancePill,
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
          const SizedBox(height: 10),
          DuplicateCompareStrip(duplicate: duplicate),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: DuplicateActionButton(
                  label: l10n.captureDuplicateSameAction,
                  onPressed: onSame,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: DuplicateActionButton(
                  label: l10n.captureDuplicateOtherAction,
                  onPressed: onDifferent,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
