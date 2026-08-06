import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/import_flow_cubit.dart';
import '../cubit/import_flow_state.dart';
import '../widgets/import_flow_body.dart';

/// The import wizard shell (HU-05/06/07, `jfq0l`/`pjdLI`): one `PageHeader`
/// whose subtitle shows the numbered step, hosting each step's body.
///
/// The entry step (previously `W2hiZK`/`rsBfI`, now marked OBSOLETO en
/// `billetudo.pen`, decisión 2026-08-06) no longer renders an intermediate
/// sheet — tapping "Importar desde un CSV" opens the OS's native file
/// picker directly. `_pickTriggered` guards against re-opening the picker
/// on every rebuild while it's still on `fileSelect`; if the user backs out
/// of the picker (`pickFile` returns without moving past `fileSelect`),
/// [onDone] pops back to the hub instead of leaving a dead screen behind.
class ImportFlowPage extends StatefulWidget {
  const ImportFlowPage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  State<ImportFlowPage> createState() => _ImportFlowPageState();
}

class _ImportFlowPageState extends State<ImportFlowPage> {
  bool _pickTriggered = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ImportFlowCubit, ImportFlowState>(
      builder: (context, state) {
        final cubit = context.read<ImportFlowCubit>();

        if (state.step == ImportFlowStep.fileSelect &&
            state.runStatus == ImportFlowRunStatus.idle) {
          if (!_pickTriggered) {
            _pickTriggered = true;
            WidgetsBinding.instance.addPostFrameCallback((_) async {
              await cubit.pickFile();
              if (!mounted) {
                return;
              }
              if (cubit.state.step == ImportFlowStep.fileSelect) {
                widget.onDone();
              }
            });
          }
          return Scaffold(backgroundColor: context.colors.background);
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
                    child: ImportFlowBody(state: state, cubit: cubit, onDone: widget.onDone),
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
