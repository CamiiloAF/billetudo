import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';
import '../../domain/entities/restore_mode.dart';
import '../cubit/restore_cubit.dart';
import '../cubit/restore_state.dart';
import '../pages/restore_replace_all_confirm_step.dart';
import 'blocking_progress_view.dart';
import 'io_error_view.dart';
import 'restore_choice_toggle.dart';
import 'stat_chip.dart';

/// The body of `RestorePage` for the current [RestoreState] — routes to
/// pick-file, running, error, summary, the escalated "Reemplazar todo"
/// confirmation or done.
class RestoreBody extends StatelessWidget {
  const RestoreBody({
    required this.state,
    required this.cubit,
    required this.onDone,
    super.key,
  });

  final RestoreState state;
  final RestoreCubit cubit;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    switch (state.step) {
      case RestoreStep.pickFile:
        return Center(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  l10n.importExportRestorePickFileBody,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: colors.textSecondary,
                        height: 1.45,
                      ),
                ),
                const SizedBox(height: 20),
                NeutralButton(
                  label: l10n.importExportRestorePickFileCta,
                  icon: LucideIcons.folderOpen,
                  onPressed: cubit.pickFile,
                ),
              ],
            ),
          ),
        );
      case RestoreStep.running:
        return BlockingProgressView(
          icon: LucideIcons.rotateCcw,
          iconColor: colors.teal,
          iconBackground: colors.tealSoft,
          title: l10n.importExportProgressRestoringTitle,
          processed: state.processed,
          total: state.total,
          onCancel: cubit.cancel,
        );
      case RestoreStep.error:
        return IoErrorView(
          icon: IoErrorIcons.unreadableFile,
          title: l10n.importExportRestoreErrorTitle,
          message: l10n.importExportRestoreErrorBody,
          actionLabel: l10n.importExportChooseAnotherFile,
          actionIcon: IoErrorIcons.chooseAnotherFile,
          onAction: cubit.dismissError,
          onCancel: onDone,
          stackButtons: true,
        );
      case RestoreStep.done:
        final summary = state.summary!;
        return Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(20),
                children: [
                  Center(
                    child: Icon(LucideIcons.checkCheck, size: 48, color: colors.teal),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      l10n.importExportRestoreDoneTitle,
                      style: Theme.of(context)
                          .textTheme
                          .titleMedium
                          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    alignment: WrapAlignment.center,
                    children: [
                      SizedBox(
                        width: 110,
                        child: StatChip(
                          value: '${summary.totalCreated}',
                          label: l10n.importExportRestoreCreated,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: StatChip(
                          value: '${summary.totalUpdated}',
                          label: l10n.importExportRestoreUpdated,
                        ),
                      ),
                      SizedBox(
                        width: 110,
                        child: StatChip(
                          value: '${summary.totalSkipped}',
                          label: l10n.importExportRestoreSkipped,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SizedBox(
                width: double.infinity,
                child: NeutralButton(
                  label: l10n.commonDone,
                  icon: LucideIcons.check,
                  onPressed: onDone,
                ),
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
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
                children: [
                  // `XPjIZ` Sheet Icon Header: icon + title + a subtitle that
                  // says exactly which copy this is (date, format version,
                  // app version it was made with) — a plain title alone left
                  // that out (`uUGXf`/`weAqZ`).
                  Center(
                    child: Column(
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          alignment: Alignment.center,
                          decoration:
                              BoxDecoration(color: colors.tealSoft, shape: BoxShape.circle),
                          child: Icon(LucideIcons.rotateCcw, color: colors.teal, size: 26),
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
                            DateFormat.yMMMMd(l10n.localeName).format(header.createdAt),
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
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    children: [
                      Expanded(
                        child: StatChip(
                          value: '${header.rowCountsByTable['accounts'] ?? 0}',
                          label: l10n.importExportRestoreStatAccounts,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatChip(
                          value: '${header.rowCountsByTable['categories'] ?? 0}',
                          label: l10n.importExportRestoreStatCategories,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: StatChip(
                          value: '${header.rowCountsByTable['transactions'] ?? 0}',
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
                  Text(
                    l10n.importExportRestoreChoiceLabel,
                    style: Theme.of(context)
                        .textTheme
                        .titleSmall
                        ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
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
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
              child: SheetButtonsRow(
                left: OutlinedButton(
                  onPressed: onDone,
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
            ),
          ],
        );
    }
  }
}
