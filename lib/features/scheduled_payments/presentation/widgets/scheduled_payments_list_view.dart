import 'package:flutter/material.dart';

import '../cubit/scheduled_payments_list_state.dart';
import 'pending_occurrences_section.dart';
import 'scheduled_card.dart';
import 'scheduled_filter_chips.dart';

/// "Activos" con datos (`o0twiq`/`t6UXUo`): filter chips, the "Por confirmar"
/// zone and one card per active template.
class ScheduledPaymentsListView extends StatelessWidget {
  const ScheduledPaymentsListView({
    required this.state,
    required this.onOpenScheduledPayment,
    required this.onOpenPending,
    required this.onFilterSelected,
    super.key,
  });

  final ScheduledPaymentsListState state;
  final ValueChanged<String> onOpenScheduledPayment;
  final VoidCallback onOpenPending;
  final ValueChanged<ScheduledPaymentsFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final entries =
        state.items.where((item) => !item.hasPendingOccurrence).toList();
    return ListView(
      // `o0twiq`/`t6UXUo` `Content`: padding [6, 20, 92, 20], gap 16 between
      // the chips row, "Por confirmar" and the list. The bottom 92 is not
      // breathing room — it is the FAB's clearance, so the last card can be
      // scrolled clear of it.
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 92),
      children: [
        ScheduledFilterChips(
          activeCount: state.activeCount,
          finishedCount: state.finishedCount,
          filter: state.filter,
          onFilterSelected: onFilterSelected,
        ),
        const SizedBox(height: 16),
        PendingOccurrencesSection(onOpenPending: onOpenPending),
        // A template whose occurrence is pending shows up above, in "Por
        // confirmar", and must not be repeated here: `nextDate` only advances
        // when the occurrence is confirmed or skipped, so it would render the
        // same date twice (page spec). The "Activos · N" counter still counts
        // it — that is `state.activeCount`, not this filtered list.
        for (var index = 0; index < entries.length; index++) ...[
          // `Lista.gap` = 10, and no trailing gap: the clearance below the
          // last card is the padding's job.
          if (index > 0) const SizedBox(height: 10),
          ScheduledCard(
            entry: entries[index],
            onTap: () =>
                onOpenScheduledPayment(entries[index].scheduledPayment.id),
          ),
        ],
      ],
    );
  }
}
