import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/neutral_button.dart';
import '../../../domain/entities/column_mapping.dart';
import '../../../domain/entities/csv_vocabulary.dart';
import '../../../domain/entities/import_entry_type.dart';
import '../import_literal_field.dart';
import '../segmented_toggle_option.dart';

/// What [ImportTypeValuesSheet.show] resolves with — `null` when dismissed
/// without confirming.
class ImportTypeValuesChoice {
  const ImportTypeValuesChoice.column(this.values) : useColumn = true;

  const ImportTypeValuesChoice.amountSign()
      : useColumn = false,
        values = null;

  final bool useColumn;

  /// Only set when [useColumn] is `true`.
  final TypeColumnValues? values;
}

/// Sheet for the "Gasto o ingreso se expresa con" field (HU-05 mapping
/// step): choose between reading a `tipo` column (with its literal values
/// editable, prefilled from what was detected or already confirmed) or the
/// amount's own sign. Either way, a live preview shows how the first real
/// row classifies under whichever option is currently highlighted.
class ImportTypeValuesSheet extends StatefulWidget {
  const ImportTypeValuesSheet({
    required this.initialUseColumn,
    required this.currentValues,
    required this.columnSampleValue,
    required this.amountSampleValue,
    super.key,
  });

  final bool initialUseColumn;
  final TypeColumnValues? currentValues;

  /// The candidate `tipo` column's raw value in the first real row, if one
  /// exists. `null` disables the column-mode preview.
  final String? columnSampleValue;

  /// The amount column's raw value in the first real row, if mapped.
  final String? amountSampleValue;

  static Future<ImportTypeValuesChoice?> show(
    BuildContext context, {
    required bool initialUseColumn,
    required TypeColumnValues? currentValues,
    required String? columnSampleValue,
    required String? amountSampleValue,
  }) =>
      BottomSheetBase.show<ImportTypeValuesChoice>(
        context,
        builder: (context) => ImportTypeValuesSheet(
          initialUseColumn: initialUseColumn,
          currentValues: currentValues,
          columnSampleValue: columnSampleValue,
          amountSampleValue: amountSampleValue,
        ),
      );

  @override
  State<ImportTypeValuesSheet> createState() => _ImportTypeValuesSheetState();
}

class _ImportTypeValuesSheetState extends State<ImportTypeValuesSheet> {
  late bool _useColumn = widget.initialUseColumn;
  late final TextEditingController _incomeController = TextEditingController(
    text: widget.currentValues?.income ?? CsvVocabulary.es.typeValues.income,
  );
  late final TextEditingController _expenseController = TextEditingController(
    text: widget.currentValues?.expense ?? CsvVocabulary.es.typeValues.expense,
  );
  late final TextEditingController _transferController = TextEditingController(
    text: widget.currentValues?.transfer ?? CsvVocabulary.es.typeValues.transfer,
  );

  @override
  void dispose() {
    _incomeController.dispose();
    _expenseController.dispose();
    _transferController.dispose();
    super.dispose();
  }

  ImportEntryType? _classifyByColumn() {
    final raw = widget.columnSampleValue?.trim().toLowerCase();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    if (raw == _incomeController.text.trim().toLowerCase()) {
      return ImportEntryType.income;
    }
    if (raw == _expenseController.text.trim().toLowerCase()) {
      return ImportEntryType.expense;
    }
    if (raw == _transferController.text.trim().toLowerCase()) {
      return ImportEntryType.transfer;
    }
    return null;
  }

  ImportEntryType? _classifyByAmountSign() {
    final raw = widget.amountSampleValue?.trim();
    if (raw == null || raw.isEmpty) {
      return null;
    }
    return raw.startsWith('-') ? ImportEntryType.expense : ImportEntryType.income;
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    final classified = _useColumn ? _classifyByColumn() : _classifyByAmountSign();
    final previewText = classified == null
        ? l10n.importExportTypeValuesResultNoMatch
        : switch (classified) {
            ImportEntryType.income => l10n.importExportTypeValuesResultIncome,
            ImportEntryType.expense => l10n.importExportTypeValuesResultExpense,
            ImportEntryType.transfer => l10n.importExportTypeValuesResultTransfer,
          };

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.importExportFormatSignLabel,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: colors.muted,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Row(
            children: [
              Expanded(
                child: SegmentedToggleOption(
                  label: l10n.importExportSignByTypeColumn,
                  active: _useColumn,
                  onTap: () => setState(() => _useColumn = true),
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: SegmentedToggleOption(
                  label: l10n.importExportSignByAmountSign,
                  active: !_useColumn,
                  onTap: () => setState(() => _useColumn = false),
                ),
              ),
            ],
          ),
        ),
        if (_useColumn) ...[
          const SizedBox(height: 14),
          ImportLiteralField(
            label: l10n.importExportTypeValuesIncomeLabel,
            controller: _incomeController,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          ImportLiteralField(
            label: l10n.importExportTypeValuesExpenseLabel,
            controller: _expenseController,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          ImportLiteralField(
            label: l10n.importExportTypeValuesTransferLabel,
            controller: _transferController,
            onChanged: () => setState(() {}),
          ),
        ],
        const SizedBox(height: 12),
        Text(
          previewText,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: NeutralButton(
            label: l10n.commonApply,
            icon: LucideIcons.check,
            onPressed: () => Navigator.of(context).pop(
              _useColumn
                  ? ImportTypeValuesChoice.column(
                      TypeColumnValues(
                        income: _incomeController.text.trim(),
                        expense: _expenseController.text.trim(),
                        transfer: _transferController.text.trim(),
                      ),
                    )
                  : const ImportTypeValuesChoice.amountSign(),
            ),
          ),
        ),
      ],
    );
  }
}
