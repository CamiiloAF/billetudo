import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/import_export_hub_cubit.dart';
import '../cubit/import_export_hub_state.dart';
import '../widgets/import_export_empty_hub.dart';
import '../widgets/import_export_hub_content.dart';

/// The Import/Export hub (`oSWz9`/`qDCvi`/`Am9cg` — Variant B "Copia
/// protagonista"), stacked from "Más" → Gestión. Three content states, never
/// an async spinner beyond the very first load: with data, no previous copy
/// yet, and brand-new user (no transactions at all).
class ImportExportHubPage extends StatelessWidget {
  const ImportExportHubPage({
    required this.onSaveCopy,
    required this.onExportCsv,
    required this.onImportCsv,
    required this.onRestore,
    required this.onSeeImportHistory,
    required this.onOpenBatch,
    super.key,
  });

  final VoidCallback onSaveCopy;
  final VoidCallback onExportCsv;
  final VoidCallback onImportCsv;
  final VoidCallback onRestore;
  final VoidCallback onSeeImportHistory;
  final ValueChanged<String> onOpenBatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.importExportHubTitle),
            Expanded(
              child: BlocBuilder<ImportExportHubCubit, ImportExportHubState>(
                builder: (context, state) {
                  if (state.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == ImportExportHubStatus.failure) {
                    return ErrorState(
                      title: l10n.importExportHubErrorTitle,
                      onRetry: () =>
                          context.read<ImportExportHubCubit>().start(),
                      // `$primary` is reserved for "the cloud" everywhere
                      // else — this feature never wears it on its own
                      // elements (design-system/billetudo/pages/import-export.md).
                      neutralCta: true,
                    );
                  }
                  if (!state.hasAnyTransactions) {
                    return ImportExportEmptyHub(
                      onImportCsv: onImportCsv,
                      onRestore: onRestore,
                    );
                  }
                  return ImportExportHubContent(
                    state: state,
                    onSaveCopy: onSaveCopy,
                    onExportCsv: onExportCsv,
                    onImportCsv: onImportCsv,
                    onRestore: onRestore,
                    onSeeImportHistory: onSeeImportHistory,
                    onOpenBatch: onOpenBatch,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
