import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/sync/presentation/widgets/sync_section_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_action_row.dart';
import '../cubit/import_export_hub_state.dart';
import 'import_batch_row.dart';
import 'local_copy_hero_card.dart';
import 'privacy_note_strip.dart';

/// The Import/Export hub content once there is at least one transaction
/// (`oSWz9`/`qDCvi`/`Am9cg` — Variant B "Copia protagonista"): hero card,
/// privacy note, other actions and the most recent import batch, if any.
class ImportExportHubContent extends StatelessWidget {
  const ImportExportHubContent({
    required this.state,
    required this.onSaveCopy,
    required this.onExportCsv,
    required this.onImportCsv,
    required this.onRestore,
    required this.onSeeImportHistory,
    required this.onOpenBatch,
    super.key,
  });

  final ImportExportHubState state;
  final VoidCallback onSaveCopy;
  final VoidCallback onExportCsv;
  final VoidCallback onImportCsv;
  final VoidCallback onRestore;
  final VoidCallback onSeeImportHistory;
  final ValueChanged<String> onOpenBatch;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final latestBatch = state.latestBatch;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
      children: [
        LocalCopyHeroCard(
          lastSavedAt: state.lastBackupSavedAt,
          onSaveCopy: onSaveCopy,
        ),
        const SizedBox(height: 16),
        PrivacyNoteStrip(text: l10n.importExportPrivacyNote),
        const SizedBox(height: 16),
        SyncSectionHeader(title: l10n.importExportSectionOtherActions),
        const SizedBox(height: 10),
        DataActionRow(
          icon: LucideIcons.fileSpreadsheet,
          iconColor: colors.sky,
          iconBackground: colors.skySoft,
          title: l10n.importExportExportCsvTitle,
          description: l10n.importExportExportCsvSubtitle,
          onTap: onExportCsv,
        ),
        const SizedBox(height: 10),
        DataActionRow(
          icon: LucideIcons.fileInput,
          iconColor: colors.mint,
          iconBackground: colors.mintSoft,
          title: l10n.importExportImportCsvTitle,
          description: l10n.importExportImportCsvSubtitle,
          onTap: onImportCsv,
        ),
        const SizedBox(height: 10),
        DataActionRow(
          icon: LucideIcons.rotateCcw,
          iconColor: colors.teal,
          iconBackground: colors.tealSoft,
          title: l10n.importExportRestoreTitle,
          description: l10n.importExportRestoreSubtitle,
          onTap: onRestore,
        ),
        if (latestBatch != null) ...[
          const SizedBox(height: 16),
          SyncSectionHeader(
            title: l10n.importExportSectionRecentImports,
            linkLabel: l10n.importExportSeeAll,
            onLinkTap: onSeeImportHistory,
          ),
          const SizedBox(height: 10),
          ImportBatchRow(
            fileName: latestBatch.fileName,
            metaLabel: l10n.importExportBatchMeta(
              latestBatch.rowsImported,
              _relativeTime(context, latestBatch.importedAt),
            ),
            reverted: latestBatch.isReverted,
            revertedLabel: l10n.importExportBatchRevertedBadge,
            onTap: () => onOpenBatch(latestBatch.id),
          ),
        ],
      ],
    );
  }

  String _relativeTime(BuildContext context, DateTime at) {
    final l10n = AppLocalizations.of(context);
    final diff = DateTime.now().difference(at);
    if (diff.inDays >= 1) {
      return l10n.importExportRelativeDays(diff.inDays);
    }
    if (diff.inHours >= 1) {
      return l10n.importExportRelativeHours(diff.inHours);
    }
    return l10n.importExportRelativeJustNow;
  }
}
