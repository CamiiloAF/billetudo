import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/import_flow_cubit.dart';
import '../cubit/import_flow_state.dart';
import '../widgets/import_flow_body.dart';

/// The import wizard shell (HU-05/06/07, `jfq0l`/`pjdLI`): one `PageHeader`
/// whose subtitle shows the numbered step, hosting the mapping/destinations/
/// preview steps' bodies — the only steps that are actually pages in
/// `billetudo.pen`. The final commit and what follows it (blocking progress,
/// a write failure, the closing summary) are `Bottom Sheet Base` instead
/// (`ImportRunSheet`, opened by the preview step's "Importar" tap, corrected
/// 2026-08-07 alongside `RestoreSheet`) — this page stays mounted underneath
/// it, covered by its scrim.
///
/// The entry step (`a5XdP`/`qWIvy`, decision 2026-08-07) is not this page's
/// responsibility at all anymore: `ImportPickSheet.show` drives the native
/// file picker and, on the unreadable-file error, its own modal sheet,
/// entirely before this page is ever pushed. This page is only reached once
/// a file already parsed, so the [ImportFlowCubit] it's given always starts
/// on [ImportFlowStep.mapping] with `state.sample` populated — never on
/// [ImportFlowStep.fileSelect].
class ImportFlowPage extends StatelessWidget {
  const ImportFlowPage({required this.onDone, super.key});

  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<ImportFlowCubit, ImportFlowState>(
      builder: (context, state) {
        final cubit = context.read<ImportFlowCubit>();

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
