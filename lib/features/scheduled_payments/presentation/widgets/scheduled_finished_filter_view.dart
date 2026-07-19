import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/scheduled_payments_list_state.dart';
import 'scheduled_card.dart';
import 'scheduled_filter_chips.dart';
import 'scheduled_payments_error_view.dart';
import 'scheduled_payments_loading_view.dart';

/// The "Terminados" filter (`LmrIV`/`gD9g7`/`w3MUo`): the same list, filtered
/// in place — header, chips row and FAB stay put, only the content changes.
///
/// The chips row renders in every state here, including loading and error:
/// unlike the list's first load, the counters are already known (the user got
/// here by tapping the chip), and without the row there would be no way back
/// to "Activos" other than leaving the screen.
class ScheduledFinishedFilterView extends StatelessWidget {
  const ScheduledFinishedFilterView({
    required this.state,
    required this.onOpenScheduledPayment,
    required this.onFilterSelected,
    required this.onRetry,
    super.key,
  });

  final ScheduledPaymentsListState state;
  final ValueChanged<String> onOpenScheduledPayment;
  final ValueChanged<ScheduledPaymentsFilter> onFilterSelected;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final isFailure =
        state.finishedStatus == ScheduledPaymentsListStatus.failure;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          // `LmrIV`/`gD9g7`/`w3MUo` `Content`: top 6, horizontal 20 — the same
          // as the "Activos" list, so switching filters never moves the chips.
          padding: const EdgeInsets.fromLTRB(20, 6, 20, 0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ScheduledFilterChips(
                activeCount: state.activeCount,
                finishedCount: state.finishedCount,
                filter: state.filter,
                onFilterSelected: onFilterSelected,
              ),
              // Omitted in the error state: it explains a list that is not
              // there, and the screen already has one message to read.
              if (!isFailure) ...[
                const SizedBox(height: 16),
                const ScheduledFinishedCaption(),
              ],
            ],
          ),
        ),
        Expanded(
          child: switch (state.finishedStatus) {
            // `min(N, 5)`: the chip already told the user how many finished
            // templates there are, so five fixed skeletons would contradict it
            // and shrink the screen on resolve.
            ScheduledPaymentsListStatus.loading => ScheduledPaymentsLoadingView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 92),
                cardCount: state.finishedCount,
              ),
            // The error card is centred in what is left *above* the FAB, as in
            // `w3MUo`, not in the full body.
            ScheduledPaymentsListStatus.failure => Padding(
                padding: const EdgeInsets.fromLTRB(0, 16, 0, 92),
                child: ScheduledPaymentsErrorView(onRetry: onRetry),
              ),
            ScheduledPaymentsListStatus.ready => ListView.separated(
                // `Content.gap` 16 below the caption, `Lista.gap` 10 between
                // cards, 92 of FAB clearance at the bottom.
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 92),
                itemCount: state.finishedItems.length,
                separatorBuilder: (context, index) =>
                    const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final entry = state.finishedItems[index];
                  return ScheduledCard(
                    entry: entry,
                    isFinished: true,
                    onTap: () =>
                        onOpenScheduledPayment(entry.scheduledPayment.id),
                  );
                },
              ),
          },
        ),
      ],
    );
  }
}

/// "Ya no generan movimientos. Los que crearon siguen en tus cuentas."
///
/// The one line that answers the question this filter raises — whether ending
/// a template erased the transactions it created. It did not.
class ScheduledFinishedCaption extends StatelessWidget {
  const ScheduledFinishedCaption({super.key});

  @override
  Widget build(BuildContext context) {
    return Text(
      AppLocalizations.of(context).scheduledFinishedCaption,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: context.colors.textSecondary,
          ),
    );
  }
}
