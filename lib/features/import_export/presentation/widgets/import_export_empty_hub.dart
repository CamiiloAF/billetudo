import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/sync/presentation/widgets/sync_section_header.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/data_action_row.dart';
import '../../../../core/widgets/empty_state.dart';

/// The brand-new-user state of the Import/Export hub (no transactions at
/// all): import CTA plus secondary restore/export affordances.
class ImportExportEmptyHub extends StatelessWidget {
  const ImportExportEmptyHub({required this.onImportCsv, required this.onRestore, super.key});

  final VoidCallback onImportCsv;
  final VoidCallback onRestore;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 6, 20, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            EmptyState(
              icon: LucideIcons.fileInput,
              message: l10n.importExportEmptyHeroTitle,
              description: l10n.importExportEmptyHeroBody,
              ctaLabel: l10n.importExportEmptyImportCta,
              ctaIcon: LucideIcons.fileInput,
              onCta: onImportCsv,
              // `$mint` = importar, never `$primary` — this feature's whole
              // point is "nunca te sentirás atrapado" and violet means "the
              // cloud" everywhere else in the product.
              iconColor: colors.mint,
              iconBackground: colors.mintSoft,
              neutralCta: true,
            ),
            const SizedBox(height: 20),
            SyncSectionHeader(title: l10n.importExportSectionOtherOptions),
            const SizedBox(height: 10),
            DataActionRow(
              icon: LucideIcons.rotateCcw,
              iconColor: colors.teal,
              iconBackground: colors.tealSoft,
              title: l10n.importExportRestoreTitle,
              description: l10n.importExportRestoreSubtitle,
              onTap: onRestore,
            ),
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
              decoration: BoxDecoration(
                color: colors.muted,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Row(
                children: [
                  Icon(LucideIcons.archive, size: 20, color: colors.textSecondary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.importExportEmptyExportRowTitle,
                          style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                fontSize: 15,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          l10n.importExportEmptyExportRowSubtitle,
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
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
