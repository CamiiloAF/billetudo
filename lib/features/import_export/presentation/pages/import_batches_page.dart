import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/widgets/empty_state.dart';
import '../../../../core/widgets/error_state.dart';
import '../../../../core/widgets/page_header.dart';
import '../cubit/import_batches_cubit.dart';
import '../cubit/import_batches_state.dart';
import '../widgets/import_batch_row.dart';
import '../widgets/sheets/undo_import_confirm_sheet.dart';

/// HU-08 "Importaciones" history (`tJhwB`/`tiCoZ`).
class ImportBatchesPage extends StatelessWidget {
  const ImportBatchesPage({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            PageHeader(title: l10n.importExportBatchesTitle),
            Expanded(
              child: BlocBuilder<ImportBatchesCubit, ImportBatchesState>(
                builder: (context, state) {
                  if (state.status == ImportBatchesStatus.loading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  if (state.status == ImportBatchesStatus.failure) {
                    return ErrorState(
                      title: l10n.importExportBatchesErrorTitle,
                      onRetry: () => context.read<ImportBatchesCubit>().start(),
                    );
                  }
                  if (state.isEmpty) {
                    return EmptyState(
                      icon: LucideIcons.fileInput,
                      message: l10n.importExportBatchesEmptyTitle,
                      description: l10n.importExportBatchesEmptyBody,
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
                    itemCount: state.batches.length,
                    separatorBuilder: (context, _) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final batch = state.batches[index];
                      return ImportBatchRow(
                        fileName: batch.fileName,
                        metaLabel: l10n.importExportBatchMeta(
                          batch.rowsImported,
                          l10n.importExportRelativeDays(
                            DateTime.now().difference(batch.importedAt).inDays,
                          ),
                        ),
                        reverted: batch.isReverted,
                        revertedLabel: l10n.importExportBatchRevertedBadge,
                        onTap: batch.isReverted
                            ? () {}
                            : () async {
                                final confirmed = await UndoImportConfirmSheet.show(
                                  context,
                                  batch: batch,
                                );
                                if (confirmed == true && context.mounted) {
                                  await context.read<ImportBatchesCubit>().undo(batch.id);
                                }
                              },
                      );
                    },
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
