import 'package:flutter/material.dart';

import 'scheduled_skeleton_card.dart';

/// The `$skeleton` stand-in for `ScheduledFilterChips` on the initial load
/// (`QE1Wq`→`c2RuB`, `VcbSV`→`XHnuP`).
///
/// The first load does not know the counters yet, so the real chips cannot be
/// rendered — but their height has to be reserved anyway: otherwise the 44px
/// row plus its 16px gap appear at once when the data lands and push the
/// content down ~60px, which reads as a glitch.
///
/// Two label-less pills, since a skeleton promises geometry, not content. The
/// error state does not use this: it is terminal, nothing resolves after it.
class ScheduledFilterChipsPlaceholder extends StatelessWidget {
  const ScheduledFilterChipsPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const ExcludeSemantics(
      child: Row(
        children: [
          ScheduledSkeletonBlock(width: 96, height: 44, radius: 14),
          SizedBox(width: 8),
          ScheduledSkeletonBlock(width: 124, height: 44, radius: 14),
        ],
      ),
    );
  }
}
