import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../cubit/pending_occurrences_cubit.dart';
import '../cubit/pending_occurrences_state.dart';
import 'scheduled_pending_card.dart';
import 'sheets/confirmation_sheet.dart';

/// Wires [PendingOccurrencesCubit] to the "Pendientes" card on top of the
/// "próximos vencimientos" list (HU-04): renders nothing while there are no
/// pending occurrences, and offers the same "Deshacer" affordance as "Por
/// confirmar" for a skip/snooze that just happened inside the confirmation
/// sheet (criterion 9/10).
class PendingOccurrencesSection extends StatelessWidget {
  const PendingOccurrencesSection({required this.onOpenPending, super.key});

  final VoidCallback onOpenPending;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<PendingOccurrencesCubit, PendingOccurrencesState>(
      listenWhen: (previous, current) =>
          previous.pendingUndo != current.pendingUndo,
      listener: (context, state) {
        final undo = state.pendingUndo;
        if (undo == null) {
          return;
        }
        final l10n = AppLocalizations.of(context);
        final cubit = context.read<PendingOccurrencesCubit>();
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(
                undo.isSnooze
                    ? l10n.scheduledUndoSnoozeMessage
                    : l10n.scheduledUndoSkipMessage,
              ),
              action: SnackBarAction(
                label: l10n.transactionsUndoAction,
                onPressed: cubit.undo,
              ),
              duration: const Duration(seconds: 5),
              persist: false,
            ),
          );
      },
      builder: (context, state) {
        if (state.items.isEmpty) {
          return const SizedBox.shrink();
        }
        final cubit = context.read<PendingOccurrencesCubit>();
        return Padding(
          // `Content.gap` = 16 between "Por confirmar" and the list below it.
          padding: const EdgeInsets.only(bottom: 16),
          child: ScheduledPendingCard(
            items: state.items,
            onReviewAll: onOpenPending,
            onTapRow: (entry) async {
              final result = await ConfirmationSheet.show(
                context,
                source: entry,
                allPending: state.items,
              );
              switch (result) {
                case ConfirmationSheetResult.skipped:
                  cubit.notifySkipped(entry.occurrence.id);
                case ConfirmationSheetResult.snoozed:
                  cubit.notifySnoozed(
                    entry.occurrence.id,
                    previousSnoozedToDate: entry.occurrence.snoozedToDate,
                  );
                case ConfirmationSheetResult.confirmed:
                case ConfirmationSheetResult.cancelled:
                case null:
                  break;
              }
            },
          ),
        );
      },
    );
  }
}
