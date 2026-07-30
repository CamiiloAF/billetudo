import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../domain/entities/import_preview.dart';
import '../../domain/entities/import_preview_row.dart';
import '../../domain/entities/import_row_issue.dart';
import '../widgets/disclosure_row.dart';
import '../widgets/import_preview_row_tile.dart';
import '../widgets/stat_chip.dart';

/// HU-06/HU-07 final preview (`ScJz3`/`L82zyd`, chrome "4/4", Var 2 —
/// jerarquía por severidad, the approved variant).
class ImportPreviewStep extends StatefulWidget {
  const ImportPreviewStep({
    required this.preview,
    required this.includedRowNumbers,
    required this.onToggleRow,
    required this.onIncludeAllDuplicates,
    required this.onOmitAllDuplicates,
    required this.onConfirm,
    super.key,
  });

  final ImportPreview preview;
  final Set<int> includedRowNumbers;
  final void Function(int rowNumber, {required bool included}) onToggleRow;
  final VoidCallback onIncludeAllDuplicates;
  final VoidCallback onOmitAllDuplicates;
  final VoidCallback onConfirm;

  @override
  State<ImportPreviewStep> createState() => _ImportPreviewStepState();
}

class _ImportPreviewStepState extends State<ImportPreviewStep> {
  bool _invalidExpanded = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final preview = widget.preview;
    final validRows =
        preview.rows.where((r) => r.status == ImportRowStatus.valid).toList();
    final duplicateRows = preview.rows.where((r) => r.isDuplicate).toList();
    final invalidRows =
        preview.rows.where((r) => r.status == ImportRowStatus.invalid).toList();

    return Column(
      children: [
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            children: [
              Row(
                children: [
                  Expanded(
                    child: StatChip(
                      value: '${preview.totalRows}',
                      label: l10n.importExportStatRead,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatChip(
                      value: '${preview.willImportCount}',
                      label: l10n.importExportStatWillImport,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatChip(
                      value: '${preview.duplicateCount}',
                      label: l10n.importExportStatDuplicates,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: StatChip(
                      value: '${preview.invalidCount}',
                      label: l10n.importExportStatErrors,
                    ),
                  ),
                ],
              ),
              if (duplicateRows.isNotEmpty) ...[
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onOmitAllDuplicates,
                        child: Text(l10n.importExportOmitAllDuplicates),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton(
                        onPressed: widget.onIncludeAllDuplicates,
                        child: Text(l10n.importExportIncludeAllDuplicates),
                      ),
                    ),
                  ],
                ),
              ],
              const SizedBox(height: 16),
              for (final row in [...validRows, ...duplicateRows]) ...[
                ImportPreviewRowTile(
                  title: _titleFor(row),
                  selectable: true,
                  checked: widget.includedRowNumbers.contains(row.rowNumber),
                  onChanged: (checked) =>
                      widget.onToggleRow(row.rowNumber, included: checked),
                  reason: row.status == ImportRowStatus.duplicateExact
                      ? l10n.importExportDuplicateExact
                      : (row.status == ImportRowStatus.duplicateProbable
                          ? l10n.importExportDuplicateProbable
                          : null),
                  reasonColor: colors.amberText,
                ),
                const SizedBox(height: 10),
              ],
              if (invalidRows.isNotEmpty)
                DisclosureRow(
                  icon: LucideIcons.circleAlert,
                  iconColor: colors.expenseText,
                  label: l10n.importExportInvalidRowsCount(invalidRows.length),
                  expanded: _invalidExpanded,
                  onToggle: () => setState(() => _invalidExpanded = !_invalidExpanded),
                  children: [
                    for (final row in invalidRows)
                      ImportPreviewRowTile(
                        title: l10n.importExportRowNumber(row.rowNumber),
                        selectable: false,
                        reason: _issueLabel(l10n, row),
                        reasonColor: colors.expenseText,
                      ),
                  ],
                ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: NeutralButton(
              label: l10n.importExportImportRowsCta(widget.includedRowNumbers.length),
              icon: LucideIcons.check,
              enabled: widget.includedRowNumbers.isNotEmpty,
              onPressed: widget.onConfirm,
            ),
          ),
        ),
      ],
    );
  }

  String _titleFor(ImportPreviewRow row) {
    final date = row.date == null ? '' : DateFormat('dd/MM/yyyy').format(row.date!);
    final amount = row.amountMinor == null
        ? ''
        : NumberFormat.currency(symbol: r'$', decimalDigits: 0)
            .format(row.amountMinor! / 100);
    return [date, amount].where((s) => s.isNotEmpty).join(' · ');
  }

  String? _issueLabel(AppLocalizations l10n, ImportPreviewRow row) => switch (row.invalidIssue) {
        ImportRowIssue.missingAccount => l10n.importExportIssueMissingAccount,
        ImportRowIssue.missingDate => l10n.importExportIssueMissingDate,
        ImportRowIssue.invalidDate => l10n.importExportIssueInvalidDate,
        ImportRowIssue.missingAmount => l10n.importExportIssueMissingAmount,
        ImportRowIssue.invalidAmount => l10n.importExportIssueInvalidAmount,
        ImportRowIssue.invalidType => l10n.importExportIssueInvalidType,
        null => null,
      };
}
