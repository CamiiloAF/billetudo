import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/import_flow_cubit.dart';
import '../../cubit/import_flow_state.dart';
import '../../pages/import_summary_step.dart';
import '../blocking_progress_view.dart';
import '../io_error_view.dart';

/// HU-05/06/09: the final commit ("Importar" on `ImportPreviewStep`) and its
/// outcome — blocking progress (`d9wzVg`/`VHJP8`), a write failure
/// (`TmHSC`/`HbEJc`) or the closing summary (`Aa1ek`/`XRBVa`) — all instance
/// `Bottom Sheet Base` (`PqTUt`) in `billetudo.pen`, not the full-page wizard
/// chrome the mapping/destinations/preview steps use. Those three steps stay
/// pages (`Page Header`, `jfq0l`/`pjdLI` is not flagged); only the commit and
/// what follows it move here.
class ImportRunSheet {
  const ImportRunSheet._();

  /// Starts [ImportFlowCubit.confirm] and opens the sheet that follows it
  /// live. Not dismissible by scrim/drag while running (same "progreso
  /// bloqueante" criterion as `RestoreSheet`) — cancelling or finishing are
  /// the only ways out, both wired inside [ImportRunSheetBody].
  static Future<void> show(
    BuildContext context, {
    required ImportFlowCubit cubit,
    required VoidCallback onDone,
    String? saveTemplateAs,
  }) {
    // `confirm` emits `committing` synchronously before its first `await`,
    // so by the time the sheet's builder runs the cubit's state already has
    // real progress to show — no flash of a stale `preview`-step state.
    unawaited(cubit.confirm(saveTemplateAs: saveTemplateAs));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocProvider<ImportFlowCubit>.value(
        value: cubit,
        child: BottomSheetBase(child: ImportRunSheetBody(onDone: onDone)),
      ),
    );
  }
}

/// The sheet's content for the current [ImportFlowState]: progress while
/// `committing`, the write-failure pattern on `error`, or the closing
/// summary once `step` reaches [ImportFlowStep.summary].
class ImportRunSheetBody extends StatelessWidget {
  const ImportRunSheetBody({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ImportFlowCubit, ImportFlowState>(
      listenWhen: (previous, current) =>
          previous.runStatus != current.runStatus || previous.step != current.step,
      listener: (context, state) {
        // Cancelling the commit rolls it back to the preview step with
        // `idle` (HU-05/HU-09, same rollback `ImportFlowCubit.confirm`
        // already does) — the wizard page underneath already reflects that,
        // so this sheet has nothing left to show and closes itself instead
        // of waiting for an explicit tap.
        if (state.runStatus == ImportFlowRunStatus.idle &&
            state.step != ImportFlowStep.summary) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;

        if (state.runStatus == ImportFlowRunStatus.error) {
          // `ImportFlowCubit.confirm` only ever lands here from the write
          // itself (the header/preview parsing errors are surfaced inline on
          // their own page steps, not through this sheet) — always the
          // "sin espacio/permiso" write-failure pattern, never the
          // "archivo ilegible" read one.
          return IntrinsicHeight(
            child: IoErrorView(
              icon: IoErrorIcons.writeFailure,
              title: l10n.importExportIoErrorWriteTitle,
              message: l10n.importExportIoErrorWriteBody,
              actionLabel: l10n.commonRetry,
              actionIcon: IoErrorIcons.retry,
              onAction: () => context.read<ImportFlowCubit>().confirm(),
              onCancel: () {
                Navigator.of(context).pop();
                onDone();
              },
            ),
          );
        }
        if (state.step == ImportFlowStep.summary && state.summary != null) {
          return ImportSummaryStep(
            summary: state.summary!,
            onDone: () {
              Navigator.of(context).pop();
              onDone();
            },
          );
        }
        return IntrinsicHeight(
          child: BlockingProgressView(
            icon: LucideIcons.fileInput,
            iconColor: colors.mint,
            iconBackground: colors.mintSoft,
            title: l10n.importExportProgressImportingTitle,
            processed: state.processed,
            total: state.total,
            onCancel: () => context.read<ImportFlowCubit>().cancel(),
          ),
        );
      },
    );
  }
}
