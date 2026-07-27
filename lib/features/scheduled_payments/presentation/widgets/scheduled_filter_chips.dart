import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_theme.dart';
import '../cubit/scheduled_payments_list_state.dart';
import 'scheduled_count_pill.dart';

/// `Scheduled Filter Chips`: the "Activos · N" / "Terminados · N" pair that
/// filters the list in place.
///
/// Extracted as its own widget because every state of the list that knows its
/// counters renders it (con datos, carga y error del filtro, y el vacío "0
/// activas + N terminadas"), same as the reusable component in Pencil.
///
/// The "Terminados" chip is **absent** at 0, not disabled: there is no history
/// to reach, and a dead pill next to a live one only invites a tap that does
/// nothing.
class ScheduledFilterChips extends StatelessWidget {
  const ScheduledFilterChips({
    required this.activeCount,
    required this.finishedCount,
    required this.filter,
    required this.onFilterSelected,
    super.key,
  });

  final int activeCount;
  final int finishedCount;
  final ScheduledPaymentsFilter filter;
  final ValueChanged<ScheduledPaymentsFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Row(
      children: [
        ScheduledFilterChip(
          label: l10n.scheduledPaymentsActiveCount(activeCount),
          selected: filter == ScheduledPaymentsFilter.active,
          onTap: () => onFilterSelected(ScheduledPaymentsFilter.active),
        ),
        if (finishedCount > 0) ...[
          const SizedBox(width: 8),
          ScheduledFilterChip(
            label: l10n.scheduledFinishedCount(finishedCount),
            selected: filter == ScheduledPaymentsFilter.finished,
            onTap: () => onFilterSelected(ScheduledPaymentsFilter.finished),
          ),
        ],
      ],
    );
  }
}

/// One tappable pill of [ScheduledFilterChips]. The pill's own visuals stay in
/// `ScheduledCountPill`; this only adds the tap target and the selected
/// semantics screen readers need to tell the pair apart.
class ScheduledFilterChip extends StatelessWidget {
  const ScheduledFilterChip({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        child: ScheduledCountPill(label: label, emphasized: selected),
      ),
    );
  }
}
