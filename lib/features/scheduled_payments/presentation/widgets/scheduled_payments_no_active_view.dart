import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../accounts/presentation/widgets/empty_state.dart';
import '../cubit/scheduled_payments_list_state.dart';
import 'scheduled_filter_chips.dart';

/// "0 activas + N terminadas" (`U9jUDR`): the empty state that keeps the
/// filter chips.
///
/// Unlike the total empty state, here the "Terminados · N" chip is the only
/// road to the history the user still has — dropping the row would hide it.
class ScheduledPaymentsNoActiveView extends StatelessWidget {
  const ScheduledPaymentsNoActiveView({
    required this.state,
    required this.onAdd,
    required this.onFilterSelected,
    super.key,
  });

  final ScheduledPaymentsListState state;
  final VoidCallback onAdd;
  final ValueChanged<ScheduledPaymentsFilter> onFilterSelected;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // `U9jUDR` `Content`: top 6 like every other state with chips.
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: ScheduledFilterChips(
            activeCount: state.activeCount,
            finishedCount: state.finishedCount,
            filter: state.filter,
            onFilterSelected: onFilterSelected,
          ),
        ),
        Expanded(
          // `Body` is centred inside the content area, which stops 92px above
          // the bottom edge to clear the FAB.
          child: Padding(
            padding: const EdgeInsets.fromLTRB(0, 16, 0, 92),
            child: EmptyState(
              icon: LucideIcons.calendarClock,
              message: l10n.scheduledPaymentsNoActiveMessage,
              // Points at the chip by its literal name: "Terminados" is the
              // only word for the history that exists in the UI.
              description: l10n.scheduledPaymentsNoActiveDescription(
                state.finishedCount,
              ),
              ctaLabel: l10n.scheduledPaymentsEmptyCta,
              onCta: onAdd,
            ),
          ),
        ),
      ],
    );
  }
}
