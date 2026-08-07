import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../../../core/widgets/sheet_buttons_row.dart';
import '../../domain/entities/import_summary.dart';
import '../widgets/sheets/import_skipped_sheet.dart';
import '../widgets/summary_stats_card.dart';

/// HU-06 closing summary (`XRBVa`/`Aa1ek`, chrome "4/4"): what was imported,
/// omitted (and why) and created.
class ImportSummaryStep extends StatelessWidget {
  const ImportSummaryStep({required this.summary, required this.onDone, super.key});

  final ImportSummary summary;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
            children: [
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 72,
                      height: 72,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: colors.mintSoft,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(LucideIcons.check, size: 32, color: colors.mint),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.importExportSummaryTitle,
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      l10n.importExportSummarySubtitle(summary.batch.fileName),
                      textAlign: TextAlign.center,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        height: 1.4,
                        color: colors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SummaryStatsCard(
                children: [
                  SummaryStatsRow(
                    label: l10n.importExportSummaryImported,
                    value: '${summary.rowsImported}',
                  ),
                  SummaryStatsRow(
                    label: l10n.importExportSummarySkippedDuplicate,
                    value: '${summary.rowsSkippedDuplicate}',
                  ),
                  SummaryStatsRow(
                    label: l10n.importExportSummarySkippedError,
                    value: '${summary.rowsSkippedError}',
                  ),
                  const SummaryStatsDivider(),
                  SummaryStatsRow(
                    label: l10n.importExportSummaryAccountsCreated,
                    value: '${summary.accountsCreated}',
                  ),
                  SummaryStatsRow(
                    label: l10n.importExportSummaryCategoriesCreated,
                    value: '${summary.categoriesCreated}',
                  ),
                  SummaryStatsRow(
                    label: l10n.importExportSummaryTagsCreated,
                    value: '${summary.tagsCreated}',
                  ),
                ],
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: _totalSkipped(summary) > 0
              ? SheetButtonsRow(
                  left: OutlinedButton(
                    onPressed: () => ImportSkippedSheet.show(context, summary: summary),
                    child: Text(
                      l10n.importExportSummarySeeSkippedWithCount(_totalSkipped(summary)),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  right: NeutralButton(
                    label: l10n.commonDone,
                    icon: LucideIcons.check,
                    onPressed: onDone,
                  ),
                )
              : SizedBox(
                  width: double.infinity,
                  child: NeutralButton(
                    label: l10n.commonDone,
                    icon: LucideIcons.check,
                    onPressed: onDone,
                  ),
                ),
        ),
      ],
    );
  }

  int _totalSkipped(ImportSummary summary) =>
      summary.rowsSkippedDuplicate + summary.rowsSkippedError;
}
