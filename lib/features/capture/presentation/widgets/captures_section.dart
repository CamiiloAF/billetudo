import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/capture_review_item.dart';
import '../cubit/notices_state.dart';
import 'capture_block_action_row.dart';
import 'capture_swipe_dismissible.dart';
import 'duplicate_compare_card.dart';
import 'grouped_capture_card.dart';
import 'pending_capture_card.dart';

/// `pSVZm`/`Uigwo` — the "Capturas por confirmar" section of the Avisos
/// centre.
///
/// Renders **only when it has content** (the caller checks), which is what
/// keeps orphan headers off the empty screen. Its own header stays even when
/// it is the first section on screen: "Capturas por confirmar" names
/// something other than the page's own "Avisos" title and, more importantly,
/// declares that these rows do not affect the balance yet.
///
/// There is no "confirmar todas" here, and there must not be: the block row
/// ([CaptureBlockActionRow]) only opens a guided, one-by-one review.
class CapturesSection extends StatelessWidget {
  const CapturesSection({
    required this.state,
    required this.onDispatch,
    required this.onDiscard,
    required this.onDiscardDuplicate,
    required this.onExpand,
    super.key,
  });

  final NoticesState state;

  /// Opens the pre-filled transaction form for a capture (also used for a
  /// grouped capture: the merged prefill still comes from a single item).
  final ValueChanged<CaptureReviewItem> onDispatch;

  /// Throws a capture away without dispatching it (HU-05). Wired to the
  /// swipe-to-discard gesture (approved design `IMs3M`/`bkNc1`); the page turns
  /// the cubit's `discardedId` into the undo snackbar. Not offered on the
  /// possible-duplicate card, which already has its own "Es la misma" discard
  /// with the compared transaction recorded.
  final Future<void> Function(CaptureReviewItem) onDiscard;

  /// "Es la misma" on a possible duplicate.
  final ValueChanged<CaptureReviewItem> onDiscardDuplicate;

  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final visible = state.visibleCaptures;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.captureSectionTitle,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 10),
        Text(
          // The one-line caption is the compact one: when the notices
          // section is also on screen the height budget only balances if
          // this wraps to a single line. Alone, the section can afford the
          // fuller wording.
          state.hasNotices
              ? l10n.captureSectionCaptionCompact
              : l10n.captureSectionCaption,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            height: 1.4,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        for (final item in visible) ...[
          const SizedBox(height: 10),
          if (item.hasDuplicate)
            DuplicateCompareCard(
              item: item,
              onSame: () => onDiscardDuplicate(item),
              onDifferent: () => onDispatch(item),
            )
          else if (item.isGrouped)
            CaptureSwipeDismissible(
              captureId: item.capture.id,
              onDiscard: () => onDiscard(item),
              child: GroupedCaptureCard(
                item: item,
                onTap: () => onDispatch(item),
              ),
            )
          else
            CaptureSwipeDismissible(
              captureId: item.capture.id,
              onDiscard: () => onDiscard(item),
              child: PendingCaptureCard(
                item: item,
                onTap: () => onDispatch(item),
              ),
            ),
        ],
        if (state.showCaptureBlockRow) ...[
          const SizedBox(height: 10),
          CaptureBlockActionRow(
            captureCount: state.captures.length,
            onTap: onExpand,
          ),
        ],
      ],
    );
  }
}
