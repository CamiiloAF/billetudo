import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/pending_occurrences_cubit.dart';
import '../cubit/pending_occurrences_state.dart';
import '../widgets/scheduled_pending_row.dart';
import '../widgets/sheets/confirmation_sheet.dart';

/// "Por confirmar" (HU-03/HU-04 overflow): every pending occurrence across
/// every manual-mode template. Tapping a row always opens the mandatory
/// confirmation sheet (criterion 7/9); "Revisar todas" steps through every
/// one in sequence, never applying them in bulk.
class PendingOccurrencesPage extends StatelessWidget {
  const PendingOccurrencesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return Scaffold(
      appBar: AppBar(title: Text(l10n.scheduledPendingTitle)),
      body: SafeArea(
        child: BlocConsumer<PendingOccurrencesCubit, PendingOccurrencesState>(
          listenWhen: (previous, current) =>
              previous.pendingUndo != current.pendingUndo,
          listener: (context, state) {
            final undo = state.pendingUndo;
            if (undo == null) {
              return;
            }
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
            if (state.isLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            if (state.isEmpty) {
              return const PendingOccurrencesEmptyView();
            }
            return PendingOccurrencesListView(state: state);
          },
        ),
      ),
    );
  }
}

class PendingOccurrencesEmptyView extends StatelessWidget {
  const PendingOccurrencesEmptyView({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20),
        child: Text(
          l10n.scheduledPendingEmpty,
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .bodyLarge
              ?.copyWith(color: colors.textSecondary),
        ),
      ),
    );
  }
}

class PendingOccurrencesListView extends StatelessWidget {
  const PendingOccurrencesListView({required this.state, super.key});

  final PendingOccurrencesState state;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final cubit = context.read<PendingOccurrencesCubit>();
    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
      children: [
        OutlinedButton(
          onPressed: () => GuidedReviewSheet.show(context, pending: state.items),
          child: Text(l10n.scheduledReviewAll),
        ),
        const SizedBox(height: 12),
        for (final entry in state.items) ...[
          ScheduledPendingRow(
            entry: entry,
            onTap: () async {
              final result = await ConfirmationSheet.show(
                context,
                source: entry,
                allPending: state.items,
              );
              switch (result) {
                case ConfirmationSheetResult.skipped:
                  cubit.notifySkipped(entry.occurrence.id);
                case ConfirmationSheetResult.snoozed:
                  cubit.notifySnoozed(entry.occurrence.id);
                case ConfirmationSheetResult.confirmed:
                case ConfirmationSheetResult.cancelled:
                case null:
                  break;
              }
            },
          ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }
}
