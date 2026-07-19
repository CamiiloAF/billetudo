import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../transactions/presentation/widgets/transaction_header_button.dart';
import '../../domain/entities/pending_scheduled_occurrence.dart';
import '../cubit/pending_occurrences_cubit.dart';
import '../cubit/pending_occurrences_state.dart';
import '../utils/pending_occurrence_grouping.dart';
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
    final colors = context.colors;
    return Scaffold(
      appBar: AppBar(
        // `Dtm0X`, same as the main list: `arrow-left` inside a `$muted`
        // circle, not the platform default chevron.
        leadingWidth: 60,
        leading: Padding(
          padding: const EdgeInsets.only(left: 12),
          child: TransactionHeaderButton(
            icon: LucideIcons.arrowLeft,
            background: colors.muted,
            foreground: colors.textPrimary,
            tooltip: l10n.commonBack,
            onPressed: Navigator.of(context).pop,
          ),
        ),
        title: Text(l10n.scheduledPendingTitle),
      ),
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
    final colors = context.colors;
    final cubit = context.read<PendingOccurrencesCubit>();
    final groups = PendingOccurrenceGroup.groupByTemplate(state.items);
    return Column(
      children: [
        Expanded(
          child: ListView(
            // `QkLV0` `Content`: padding [6, 20, 28, 20], gap 16 between the
            // scroll area and the CTA (carried here as bottom padding so the
            // list keeps scrolling clear of the button). No FAB on this
            // screen, so no 92px clearance.
            padding: const EdgeInsets.fromLTRB(20, 6, 20, 16),
            children: [
              Text(
                l10n.scheduledPendingCardCaption,
                style: Theme.of(context)
                    .textTheme
                    .bodySmall
                    ?.copyWith(color: colors.textSecondary),
              ),
              // `Lista (scroll).gap` = 14 between the caption and the card.
              const SizedBox(height: 14),
              Container(
                decoration: BoxDecoration(
                  color: colors.surface,
                  borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
                  border: Border.all(color: colors.border),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: Column(
                  children: [
                    for (var i = 0; i < groups.length; i++) ...[
                      if (i > 0) Divider(height: 1, color: colors.border),
                      ScheduledPendingRow(
                        entry: groups[i].entry,
                        count: groups[i].count,
                        onTap: () => _confirm(context, cubit, groups[i].entry),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 28),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: () =>
                  GuidedReviewSheet.show(context, pending: state.items),
              icon: const Icon(LucideIcons.listChecks, size: 18),
              label: Text(l10n.scheduledReviewAll),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _confirm(
    BuildContext context,
    PendingOccurrencesCubit cubit,
    PendingScheduledOccurrence entry,
  ) async {
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
  }
}
