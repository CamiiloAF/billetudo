import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/error/failure.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/neutral_button.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../domain/entities/restore_mode.dart';
import '../../cubit/restore_cubit.dart';
import '../../cubit/restore_state.dart';
import '../../pages/restore_replace_all_confirm_step.dart';
import '../blocking_progress_view.dart';
import '../io_error_view.dart';
import '../restore_choice_toggle.dart';
import '../stat_chip.dart';
import '../summary_stats_card.dart';

/// Entry point for HU-04 restore (`uUGXf`/`weAqZ`, `NY5o6`/`MjNwC`,
/// `xdG9q`/`d9wzVg`, `a5XdP`/`TmHSC`): pick the `.billetudo.json` directly
/// with the OS's native file picker — no intermediate sheet, same pattern
/// already adopted for CSV import (`ImportFlowPage`) — then, only if a file
/// was actually chosen, drive the rest of the flow (summary/mode choice →
/// escalated "reemplazar todo" confirmation → progress → done/error) inside
/// a single modal sheet, all still owned by [RestoreCubit].
class RestoreSheet {
  const RestoreSheet._();

  /// Triggers the native file picker and, if a file was chosen, opens the
  /// restore sheet. Awaiting this resolves once the whole flow (including
  /// the sheet) is closed.
  static Future<void> show(BuildContext context) async {
    final cubit = getIt<RestoreCubit>()..reset();
    await cubit.pickFile();
    if (cubit.state.step == RestoreStep.pickFile) {
      // The user backed out of the native picker without choosing a file —
      // nothing to show, so this never opens a dead sheet.
      await cubit.close();
      return;
    }
    if (!context.mounted) {
      await cubit.close();
      return;
    }
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      // Not casually dismissible (matches `GuidedReviewSheet`'s precedent
      // for another mandatory, data-changing flow): the running step is
      // irreversible mid-flight (HU-04, "o queda completa, o no queda
      // nada") and every step already has its own explicit "Cancelar" /
      // "Listo" — a stray scrim tap or drag-down must never substitute for
      // those.
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocProvider<RestoreCubit>.value(
        value: cubit,
        child: const BottomSheetBase(child: RestoreSheetBody()),
      ),
    );
    await cubit.close();
  }
}

/// The sheet's content for the current [RestoreState] — routes to running,
/// error, summary/mode-choice, the escalated "Reemplazar todo" confirmation
/// or done. `RestoreStep.pickFile` never reaches this: `RestoreSheet.show`
/// only opens the sheet once a file was chosen and its header parsed.
class RestoreSheetBody extends StatelessWidget {
  const RestoreSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<RestoreCubit, RestoreState>(
      builder: (context, state) {
        final cubit = context.read<RestoreCubit>();
        return _RestoreSheetStepView(state: state, cubit: cubit);
      },
    );
  }
}

class _RestoreSheetStepView extends StatelessWidget {
  const _RestoreSheetStepView({required this.state, required this.cubit});

  final RestoreState state;
  final RestoreCubit cubit;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    switch (state.step) {
      case RestoreStep.pickFile:
        // Defensive only — see `RestoreSheetBody`'s doc comment.
        return const SizedBox.shrink();
      case RestoreStep.running:
        // `IntrinsicHeight`: `BlockingProgressView` centers its content with
        // a top-level `Center`, which — given the modal sheet's bounded but
        // otherwise loose height constraints — would stretch the whole sheet
        // to fill the screen instead of shrink-wrapping to the content.
        return IntrinsicHeight(
          child: BlockingProgressView(
            icon: LucideIcons.rotateCcw,
            iconColor: colors.teal,
            iconBackground: colors.tealSoft,
            title: l10n.importExportProgressRestoringTitle,
            processed: state.processed,
            total: state.total,
            onCancel: cubit.cancel,
          ),
        );
      case RestoreStep.error:
        // Two very different failures share this step: the file's header
        // never validated (state.failure is IoFailure/ValidationFailure —
        // "this isn't a valid copy"), or the header was fine but the actual
        // restore transaction failed partway (DatabaseFailure) and rolled
        // back. Telling the user "invalid file" for the second case is
        // actively misleading — the file was fine, something else broke.
        final isExecutionFailure = state.failure is DatabaseFailure;
        // `IntrinsicHeight` for the same reason as the `running` step:
        // `IoErrorView` centers its content with a top-level `Center` too.
        return IntrinsicHeight(
          child: IoErrorView(
            icon: IoErrorIcons.unreadableFile,
            title: isExecutionFailure
                ? l10n.importExportRestoreExecutionErrorTitle
                : l10n.importExportRestoreErrorTitle,
            message: isExecutionFailure
                ? l10n.importExportRestoreExecutionErrorBody
                : l10n.importExportRestoreErrorBody,
            actionLabel: l10n.importExportChooseAnotherFile,
            actionIcon: IoErrorIcons.chooseAnotherFile,
            // Straight to the native picker again — there's no
            // intermediate "elegir archivo" sheet to land on anymore (same
            // entry pattern as `RestoreSheet.show`). `cubit.pickFile`
            // leaves the state untouched if the user backs out of the
            // picker without choosing a file, so this stays on the same
            // error until they either pick a file or tap "Cancelar".
            onAction: cubit.pickFile,
            onCancel: () => Navigator.of(context).pop(),
            stackButtons: true,
          ),
        );
      case RestoreStep.done:
        final summary = state.summary!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.tealSoft,
                        shape: BoxShape.circle,
                      ),
                      child:
                          Icon(LucideIcons.check, size: 32, color: colors.teal),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.importExportRestoreDoneTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 20),
                    SummaryStatsCard(
                      children: [
                        SummaryStatsRow(
                          label: l10n.importExportRestoreCreated,
                          value: '${summary.totalCreated}',
                        ),
                        SummaryStatsRow(
                          label: l10n.importExportRestoreUpdated,
                          value: '${summary.totalUpdated}',
                        ),
                        SummaryStatsRow(
                          label: l10n.importExportRestoreSkipped,
                          value: '${summary.totalSkipped}',
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: NeutralButton(
                label: l10n.commonDone,
                icon: LucideIcons.check,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ),
          ],
        );
      case RestoreStep.replaceAllConfirm:
        return RestoreReplaceAllConfirmStep(
          header: state.header!,
          acknowledged: state.replaceAllAcknowledged,
          onAcknowledgedChanged: (value) =>
              cubit.setReplaceAllAcknowledged(value: value),
          onCancel: cubit.cancelReplaceAllConfirm,
          onConfirm: cubit.confirm,
        );
      case RestoreStep.summary:
        final header = state.header!;
        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // `XPjIZ` Sheet Icon Header: icon + title + a subtitle
                    // that says exactly which copy this is (date, format
                    // version, app version it was made with) — a plain
                    // title alone left that out (`uUGXf`/`weAqZ`).
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                          color: colors.tealSoft, shape: BoxShape.circle),
                      child: Icon(LucideIcons.rotateCcw,
                          color: colors.teal, size: 26),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.importExportRestoreSheetTitle,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            height: 1.3,
                          ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.importExportRestoreSheetSubtitle(
                        DateFormat.yMMMMd(l10n.localeName)
                            .format(header.createdAt),
                        header.formatVersion,
                        header.appVersion,
                      ),
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: colors.textPrimary,
                          ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Expanded(
                          child: StatChip(
                            value:
                                '${header.rowCountsByTable['accounts'] ?? 0}',
                            label: l10n.importExportRestoreStatAccounts,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatChip(
                            value:
                                '${header.rowCountsByTable['categories'] ?? 0}',
                            label: l10n.importExportRestoreStatCategories,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatChip(
                            value:
                                '${header.rowCountsByTable['transactions'] ?? 0}',
                            label: l10n.importExportRestoreStatTransactions,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: StatChip(
                            value: '${header.rowCountsByTable['budgets'] ?? 0}',
                            label: l10n.importExportRestoreStatBudgets,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatChip(
                            value: '${header.rowCountsByTable['goals'] ?? 0}',
                            label: l10n.importExportRestoreStatGoals,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: StatChip(
                            value: '${header.rowCountsByTable['debts'] ?? 0}',
                            label: l10n.importExportRestoreStatDebts,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        l10n.importExportRestoreChoiceLabel,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontSize: 13, fontWeight: FontWeight.w700),
                      ),
                    ),
                    const SizedBox(height: 8),
                    RestoreChoiceToggle(
                      mode: state.mode,
                      onChanged: cubit.setMode,
                      mergeLabel: l10n.importExportRestoreModeMerge,
                      mergeSubLabel: l10n.commonRecommended,
                      replaceLabel: l10n.importExportRestoreModeReplace,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      l10n.importExportRestoreChoiceHint,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            height: 1.4,
                            color: colors.textSecondary,
                          ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            SheetButtonsRow(
              left: OutlinedButton(
                onPressed: () => Navigator.of(context).pop(),
                child: Text(l10n.commonCancel),
              ),
              right: NeutralButton(
                label: l10n.importExportRestoreCta,
                icon: LucideIcons.rotateCcw,
                onPressed: state.mode == RestoreMode.replaceAll
                    ? cubit.requestReplaceAllConfirm
                    : cubit.confirm,
              ),
            ),
          ],
        );
    }
  }
}
