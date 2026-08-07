import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/export_cubit.dart';
import '../../cubit/export_state.dart';
import '../blocking_progress_view.dart';
import '../io_error_view.dart';

/// HU-01/HU-02/HU-09: the export write and its outcome — blocking progress
/// (`xdG9q`/`dSkbx`) or a write failure (`TmHSC`/`HbEJc`) — instance
/// `Bottom Sheet Base` (`PqTUt`) in `billetudo.pen`, not `ExportPage`'s own
/// `Page Header` chrome (`zFLrC`/`h6ZQQw`/`calDR`, not flagged). The scope
/// form stays a page; only the write itself moves here.
class ExportRunSheet {
  const ExportRunSheet._();

  /// Starts [ExportCubit.confirm] and opens the sheet that follows it live.
  /// Not dismissible by scrim/drag while running (same "progreso bloqueante"
  /// criterion as `RestoreSheet`/`ImportRunSheet`).
  static Future<void> show(
    BuildContext context, {
    required ExportCubit cubit,
    required String language,
  }) {
    // `confirm` emits `running` synchronously before its first `await`, so
    // the sheet's first build already has real progress to show.
    unawaited(cubit.confirm(language: language));
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useRootNavigator: true,
      isDismissible: false,
      enableDrag: false,
      builder: (context) => BlocProvider<ExportCubit>.value(
        value: cubit,
        child: const BottomSheetBase(child: ExportRunSheetBody()),
      ),
    );
  }
}

/// The sheet's content for the current [ExportState]: progress while
/// `running`, the write-failure pattern on `error`. `done` never renders here
/// — it only hands the file to the share sheet and settles back to `idle`,
/// which closes this sheet the same way a cancellation does.
class ExportRunSheetBody extends StatelessWidget {
  const ExportRunSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocConsumer<ExportCubit, ExportState>(
      listenWhen: (previous, current) =>
          previous.resultFilePath != current.resultFilePath ||
          previous.runStatus != current.runStatus,
      listener: (context, state) {
        if (state.resultFilePath case final path?) {
          unawaited(context.read<ExportCubit>().shareResult(path));
          return;
        }
        // `idle` (post-share) and `cancelled` both mean there is nothing
        // left for this sheet to show — the scope form underneath is
        // untouched, so closing just reveals it again.
        if (state.runStatus == ExportRunStatus.idle ||
            state.runStatus == ExportRunStatus.cancelled) {
          Navigator.of(context).pop();
        }
      },
      builder: (context, state) {
        final l10n = AppLocalizations.of(context);
        final colors = context.colors;

        if (state.runStatus == ExportRunStatus.error) {
          return IntrinsicHeight(
            child: IoErrorView(
              icon: IoErrorIcons.writeFailure,
              title: l10n.importExportIoErrorWriteTitle,
              message: l10n.importExportIoErrorWriteBody,
              actionLabel: l10n.commonRetry,
              actionIcon: IoErrorIcons.retry,
              onAction: () => context.read<ExportCubit>().dismissError(),
              onCancel: () => Navigator.of(context).pop(),
            ),
          );
        }
        return IntrinsicHeight(
          child: BlockingProgressView(
            icon: LucideIcons.fileSpreadsheet,
            iconColor: colors.sky,
            iconBackground: colors.skySoft,
            title: l10n.importExportProgressExportingTitle,
            processed: state.processed,
            total: state.total,
            onCancel: () => context.read<ExportCubit>().cancel(),
          ),
        );
      },
    );
  }
}
