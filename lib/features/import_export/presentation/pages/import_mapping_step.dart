import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/parsed_csv_sample.dart';
import '../widgets/column_mapping_row.dart';
import '../widgets/sheets/import_field_picker_sheet.dart';

/// HU-05/06 mapping step (`drEA1`/`y19Ij`, chrome "2/4"): "Formato detectado"
/// (the autodetected dialect), a live preview of the first real row, then
/// one [ColumnMappingRow] per raw CSV header letting the user pick which
/// canonical field it fills.
class ImportMappingStep extends StatelessWidget {
  const ImportMappingStep({
    required this.sample,
    required this.mapping,
    required this.matchedTemplateName,
    required this.onFieldChanged,
    required this.onConfirm,
    super.key,
  });

  final ParsedCsvSample sample;
  final ColumnMapping mapping;
  final String? matchedTemplateName;
  final void Function(int headerIndex, ImportField? field) onFieldChanged;
  final VoidCallback onConfirm;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Column(
      children: [
        if (matchedTemplateName case final name?)
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 0),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(
                color: colors.mintSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                l10n.importExportTemplateMatched(name),
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: colors.mintText,
                ),
              ),
            ),
          ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
            children: [
              Text(
                l10n.importExportFormatDetectedTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              _FormatField(
                icon: LucideIcons.calendar,
                label: l10n.importExportFormatDateLabel,
                value: _dateOrderLabel(l10n, sample.dialect.dateOrder),
              ),
              const SizedBox(height: 8),
              _FormatField(
                icon: LucideIcons.hash,
                label: l10n.importExportFormatDecimalLabel,
                value: sample.dialect.decimalConvention == DecimalConvention.comma
                    ? l10n.importExportDecimalComma
                    : l10n.importExportDecimalDot,
              ),
              const SizedBox(height: 8),
              _FormatField(
                icon: LucideIcons.scale,
                label: l10n.importExportFormatSignLabel,
                value: mapping.hasTypeColumn
                    ? l10n.importExportSignByTypeColumn
                    : l10n.importExportSignByAmountSign,
              ),
              const SizedBox(height: 14),
              _LivePreviewCard(sample: sample, mapping: mapping),
              const SizedBox(height: 14),
              Text(
                l10n.importExportFieldsSectionTitle,
                style: Theme.of(context)
                    .textTheme
                    .titleSmall
                    ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              for (var index = 0; index < sample.headers.length; index++) ...[
                if (index > 0) const SizedBox(height: 12),
                Builder(
                  builder: (context) {
                    final field = _fieldFor(index);
                    final sampleValue = sample.sampleRows.isEmpty ||
                            index >= sample.sampleRows.first.length
                        ? null
                        : sample.sampleRows.first[index];
                    return ColumnMappingRow(
                      source: sample.headers[index],
                      value: field == null
                          ? l10n.importExportFieldNotUsed
                          : _fieldLabel(l10n, field),
                      badgeLabel: field == null
                          ? null
                          : (ColumnMapping.requiredFields.contains(field)
                              ? l10n.importExportFieldRequired
                              : l10n.importExportFieldOptional),
                      preview: sampleValue == null || sampleValue.isEmpty
                          ? null
                          : l10n.importExportFieldPreview(sampleValue),
                      onTap: () => _pickField(context, index),
                    );
                  },
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 20),
          child: SizedBox(
            width: double.infinity,
            child: NeutralButton(
              label: l10n.commonContinue,
              icon: LucideIcons.arrowRight,
              enabled: mapping.isComplete,
              onPressed: onConfirm,
            ),
          ),
        ),
      ],
    );
  }

  ImportField? _fieldFor(int headerIndex) {
    for (final entry in mapping.columns.entries) {
      if (entry.value == headerIndex) {
        return entry.key;
      }
    }
    return null;
  }

  Future<void> _pickField(BuildContext context, int headerIndex) async {
    final selected = await BottomSheetBase.show<Object>(
      context,
      builder: (context) => ImportFieldPickerSheet(currentMapping: mapping),
    );
    // `null` means the sheet was dismissed without choosing — leave the
    // mapping untouched. `clearedImportField` means "No usar" was tapped
    // explicitly — distinct from dismissal even though both leave the field
    // unmapped, so a real `ImportField` selection is the only case that
    // reaches here as itself.
    if (selected == null) {
      return;
    }
    onFieldChanged(
      headerIndex,
      selected == clearedImportField ? null : selected as ImportField,
    );
  }

  String _fieldLabel(AppLocalizations l10n, ImportField field) => switch (field) {
        ImportField.id => l10n.importExportFieldId,
        ImportField.date => l10n.importExportFieldDate,
        ImportField.amount => l10n.importExportFieldAmount,
        ImportField.type => l10n.importExportFieldType,
        ImportField.currency => l10n.importExportFieldCurrency,
        ImportField.account => l10n.importExportFieldAccount,
        ImportField.transferAccount => l10n.importExportFieldTransferAccount,
        ImportField.category => l10n.importExportFieldCategory,
        ImportField.subcategory => l10n.importExportFieldSubcategory,
        ImportField.note => l10n.importExportFieldNote,
        ImportField.tags => l10n.importExportFieldTags,
      };
}

String _dateOrderLabel(AppLocalizations l10n, DateComponentOrder order) => switch (order) {
      DateComponentOrder.isoYmd => l10n.importExportDateOrderYmd,
      DateComponentOrder.dayMonthYear => l10n.importExportDateOrderDmy,
      DateComponentOrder.monthDayYear => l10n.importExportDateOrderMdy,
    };

/// One row of the "Formato detectado" section (HU-05): a `Form Field`-style
/// readout (`wOlOA`), non-interactive — the dialect the file was detected
/// with, informational only at this step.
class _FormatField extends StatelessWidget {
  const _FormatField({required this.icon, required this.label, required this.value});

  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          width: double.infinity,
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(icon, size: 18, color: colors.textSecondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium
                      ?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The mint "vista previa en vivo" card (`cBSZp`): how the first real data
/// row reads with the mapping chosen so far. Shows the raw CSV values for
/// the mapped fields (not the fully parsed/normalized amount and date —
/// that full resolution only happens once `PreviewImport` runs, past this
/// step), joined for a quick sanity check while mapping.
class _LivePreviewCard extends StatelessWidget {
  const _LivePreviewCard({required this.sample, required this.mapping});

  final ParsedCsvSample sample;
  final ColumnMapping mapping;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final row = sample.sampleRows.isEmpty ? null : sample.sampleRows.first;

    String? valueFor(ImportField field) {
      final index = mapping.columnFor(field);
      if (index == null || row == null || index >= row.length) {
        return null;
      }
      final value = row[index].trim();
      return value.isEmpty ? null : value;
    }

    final parts = [
      valueFor(ImportField.date),
      valueFor(ImportField.type),
      valueFor(ImportField.amount),
      valueFor(ImportField.account),
      valueFor(ImportField.category),
    ].whereType<String>().toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(color: colors.mintSoft, borderRadius: BorderRadius.circular(16)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(LucideIcons.eye, size: 14, color: colors.mint),
              const SizedBox(width: 6),
              Text(
                l10n.importExportLivePreviewLabel,
                style: theme.textTheme.bodySmall
                    ?.copyWith(fontSize: 12, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            parts.isEmpty ? l10n.importExportFieldNotUsed : parts.join(' · '),
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}
