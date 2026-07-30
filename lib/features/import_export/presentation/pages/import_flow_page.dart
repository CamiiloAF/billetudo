import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/import_flow_cubit.dart';
import '../cubit/import_flow_state.dart';
import '../widgets/import_flow_body.dart';
import 'import_file_select_step.dart';

/// The import wizard shell (HU-05/06/07, `jfq0l`/`pjdLI`): one `PageHeader`
/// whose subtitle shows the numbered step, hosting each step's body.
///
/// The entry step (`W2hiZK`/`rsBfI`) is a modal bottom sheet in Pencil, not a
/// pushed page — rendered here as a scrim-backed sheet anchored to the
/// bottom instead of the numbered-step `PageHeader` chrome the rest of the
/// wizard uses.
class ImportFlowPage extends StatelessWidget {
  const ImportFlowPage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ImportFlowCubit, ImportFlowState>(
      builder: (context, state) {
        final cubit = context.read<ImportFlowCubit>();

        if (state.step == ImportFlowStep.fileSelect && state.runStatus == ImportFlowRunStatus.idle) {
          return Scaffold(
            backgroundColor: context.colors.scrim,
            body: SafeArea(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 28),
                  decoration: BoxDecoration(
                    color: context.colors.surface,
                    borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(AppTheme.sheetRadius),
                    ),
                  ),
                  child: ImportFileSelectStep(onPickFile: cubit.pickFile, onCancel: onDone),
                ),
              ),
            ),
          );
        }

        return PopScope(
          // HU-09: the blocking progress overlay disables the back gesture
          // while a write/read is running.
          canPop: !state.isWorking,
          child: Scaffold(
            body: SafeArea(
              child: Column(
                children: [
                  PageHeader(
                    title: _titleFor(l10n, state.step),
                    onBack: state.isWorking ? () {} : null,
                  ),
                  Expanded(
                    child: ImportFlowBody(state: state, cubit: cubit, onDone: onDone),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _titleFor(AppLocalizations l10n, ImportFlowStep step) => switch (step) {
        ImportFlowStep.fileSelect => l10n.importExportImportCsvTitle,
        ImportFlowStep.mapping => l10n.importExportStepMapping,
        ImportFlowStep.destinations => l10n.importExportStepDestinations,
        ImportFlowStep.preview => l10n.importExportStepPreview,
        ImportFlowStep.summary => l10n.importExportStepSummary,
      };
}
