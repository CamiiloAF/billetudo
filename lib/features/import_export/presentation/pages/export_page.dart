import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/export_cubit.dart';
import '../cubit/export_state.dart';
import '../widgets/blocking_progress_view.dart';
import '../widgets/export_form.dart';
import '../widgets/io_error_view.dart';

/// HU-01/HU-02: choose what to export (transactions/accounts/categories),
/// optionally filtered, then hand the result to the share sheet (`zFLrC`/
/// `h6ZQQw`/`calDR`).
class ExportPage extends StatelessWidget {
  const ExportPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ExportCubit, ExportState>(
      buildWhen: (previous, current) => previous.runStatus != current.runStatus,
      builder: (context, runStatusState) => PopScope(
        // HU-01/HU-09: the blocking progress overlay disables the back
        // gesture while a write is running — the only way out is "Cancelar".
        canPop: runStatusState.runStatus != ExportRunStatus.running,
        child: Scaffold(
          body: SafeArea(
            child: Column(
              children: [
                PageHeader(title: l10n.importExportExportCsvTitle),
                Expanded(
                  child: BlocConsumer<ExportCubit, ExportState>(
                    listenWhen: (previous, current) =>
                        previous.resultFilePath != current.resultFilePath ||
                        previous.runStatus != current.runStatus,
                    listener: (context, state) {
                      if (state.resultFilePath case final path?) {
                        unawaited(context.read<ExportCubit>().shareResult(path));
                      }
                    },
                    builder: (context, state) {
                      if (!state.hasAnyTransactions &&
                          !state.scope.includeAccounts &&
                          !state.scope.includeCategories) {
                        return EmptyState(
                          icon: LucideIcons.fileSpreadsheet,
                          message: l10n.importExportExportEmptyTitle,
                          description: l10n.importExportExportEmptyBody,
                        );
                      }
                      if (state.runStatus == ExportRunStatus.running) {
                        return BlockingProgressView(
                          icon: LucideIcons.fileSpreadsheet,
                          iconColor: context.colors.sky,
                          iconBackground: context.colors.skySoft,
                          title: l10n.importExportProgressExportingTitle,
                          processed: state.processed,
                          total: state.total,
                          onCancel: () => context.read<ExportCubit>().cancel(),
                        );
                      }
                      if (state.runStatus == ExportRunStatus.error) {
                        return IoErrorView(
                          icon: IoErrorIcons.writeFailure,
                          title: l10n.importExportIoErrorWriteTitle,
                          message: l10n.importExportIoErrorWriteBody,
                          actionLabel: l10n.commonRetry,
                          actionIcon: IoErrorIcons.retry,
                          onAction: () => context.read<ExportCubit>().dismissError(),
                          onCancel: () => context.pop(),
                        );
                      }
                      return ExportForm(state: state);
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
