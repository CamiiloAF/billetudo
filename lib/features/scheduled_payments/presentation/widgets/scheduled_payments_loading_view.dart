import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import 'scheduled_filter_chips_placeholder.dart';
import 'scheduled_skeleton_card.dart';

/// The list's loading state (`QE1Wq`/`gD9g7`): skeleton cards, optionally
/// under a placeholder for the filter chips row.
///
/// Two knobs, both about not moving the screen when the data lands:
///
/// * [cardCount] — the filter's load already knows its counter (that is *why*
///   its chips stay visible), so it asks for `min(N, 5)` cards. Painting five
///   when the chip reads "Terminados · 3" contradicts the chip and makes the
///   list shrink on resolve.
/// * [showsChipsPlaceholder] — the initial load does not know the counters, so
///   it cannot render the real chips, but it still reserves their height with
///   [ScheduledFilterChipsPlaceholder]. The filter's load renders the real
///   chips above this view instead, and passes false.
class ScheduledPaymentsLoadingView extends StatelessWidget {
  const ScheduledPaymentsLoadingView({
    this.padding,
    this.cardCount = maxSkeletonCards,
    this.showsChipsPlaceholder = false,
    super.key,
  });

  /// The list never shows more than five skeletons: past that they stop
  /// promising a shape and become noise.
  static const int maxSkeletonCards = 5;

  /// Title/subtitle widths per card, uneven on purpose so the stack does not
  /// read as a table.
  static const List<(double title, double subtitle)> _cardWidths = [
    (126, 160),
    (96, 140),
    (134, 118),
    (108, 152),
    (118, 132),
  ];

  final EdgeInsetsGeometry? padding;
  final int cardCount;
  final bool showsChipsPlaceholder;

  @override
  Widget build(BuildContext context) {
    final count = cardCount.clamp(1, maxSkeletonCards);
    return Semantics(
      label: AppLocalizations.of(context).scheduledPaymentsLoading,
      child: ListView(
        // Same geometry as the loaded list, so the skeleton does not shift
        // anything on resolve; the bottom padding clears the FAB.
        padding: padding ?? const EdgeInsets.fromLTRB(20, 6, 20, 92),
        children: [
          if (showsChipsPlaceholder) ...[
            const ScheduledFilterChipsPlaceholder(),
            const SizedBox(height: 16),
          ],
          for (var index = 0; index < count; index++) ...[
            if (index > 0) const SizedBox(height: 10),
            ScheduledSkeletonCard(
              titleWidth: _cardWidths[index].$1,
              subtitleWidth: _cardWidths[index].$2,
            ),
          ],
        ],
      ),
    );
  }
}
