import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../core/widgets/neutral_button.dart';
import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/csv_vocabulary.dart';
import '../../domain/entities/import_mapping_mode.dart';
import '../../domain/entities/parsed_csv_sample.dart';
import '../../domain/utils/text_normalizer.dart';
import '../utils/date_order_label.dart';
import '../widgets/automatic_mapping_summary.dart';
import '../widgets/column_mapping_row.dart';
import '../widgets/import_format_field.dart';
import '../widgets/import_live_preview_card.dart';
import '../widgets/import_mapping_mode_toggle.dart';
import '../widgets/sheets/import_date_format_sheet.dart';
import '../widgets/sheets/import_decimal_format_sheet.dart';
import '../widgets/sheets/import_field_picker_sheet.dart';
import '../widgets/sheets/import_type_values_sheet.dart';

/// HU-05/06 mapping step (`drEA1`/`y19Ij`, chrome "2/4"): an Automático/Manual
/// toggle gates between the one-tap "confirm what we detected" summary and
/// the full column-by-column view — "Formato detectado" (the current
/// dialect), a live preview of the first real row, then one
/// [ColumnMappingRow] per raw CSV header letting the user pick which
/// canonical field it fills. Neither the toggle nor the tappable format
/// fields exist in `billetudo.pen` yet (`design-system/billetudo/pages/
/// import-export.md` "Pendientes"/"Interacciones no diseñadas en Pencil") —
/// built here against the shared `Segmented Toggle`/`Bottom Sheet Base`
/// pieces the rest of this feature already uses.
class ImportMappingStep extends StatelessWidget {
  const ImportMappingStep({
    required this.sample,
    required this.dialect,
    required this.mapping,
    required this.mappingMode,
    required this.matchedTemplateName,
    required this.onMappingModeChanged,
    required this.onFieldChanged,
    required this.onDateFormatChanged,
    required this.onDecimalConventionChanged,
    required this.onTypeColumnChanged,
    required this.onAmountSignModeChanged,
    required this.onConfirm,
    super.key,
  });

  final ParsedCsvSample sample;

  /// The mapping's current dialect (autodetected, then possibly refined by
  /// the format sheets) — never `sample.dialect` directly once the user has
  /// touched a format field, so this always reflects the live choice.
  final CsvDialect dialect;
  final ColumnMapping mapping;
  final ImportMappingMode mappingMode;
  final String? matchedTemplateName;
  final ValueChanged<ImportMappingMode> onMappingModeChanged;
  final void Function(int headerIndex, ImportField? field) onFieldChanged;
  final void Function(DateComponentOrder order, DateSeparatorChar separator)
      onDateFormatChanged;
  final ValueChanged<DecimalConvention> onDecimalConventionChanged;
  final void Function(int columnIndex, TypeColumnValues values) onTypeColumnChanged;
  final VoidCallback onAmountSignModeChanged;
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
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
          child: ImportMappingModeToggle(
            mode: mappingMode,
            onChanged: onMappingModeChanged,
            automaticLabel: l10n.importExportMappingModeAutomatic,
            manualLabel: l10n.importExportMappingModeManual,
          ),
        ),
        Expanded(
          child: mappingMode == ImportMappingMode.automatic
              ? AutomaticMappingSummary(sample: sample, dialect: dialect, mapping: mapping)
              : ListView(
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
                    ImportFormatField(
                      icon: LucideIcons.calendar,
                      label: l10n.importExportFormatDateLabel,
                      value: dateOrderLabel(l10n, dialect.dateOrder),
                      onTap: () => _pickDateFormat(context),
                    ),
                    const SizedBox(height: 8),
                    ImportFormatField(
                      icon: LucideIcons.hash,
                      label: l10n.importExportFormatDecimalLabel,
                      value: dialect.decimalConvention == DecimalConvention.comma
                          ? l10n.importExportDecimalComma
                          : l10n.importExportDecimalDot,
                      onTap: () => _pickDecimalFormat(context),
                    ),
                    const SizedBox(height: 8),
                    ImportFormatField(
                      icon: LucideIcons.scale,
                      label: l10n.importExportFormatSignLabel,
                      value: mapping.hasTypeColumn
                          ? l10n.importExportSignByTypeColumn
                          : l10n.importExportSignByAmountSign,
                      onTap: () => _pickTypeValues(context),
                    ),
                    const SizedBox(height: 14),
                    ImportLivePreviewCard(sample: sample, mapping: mapping),
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
              label: mappingMode == ImportMappingMode.automatic
                  ? l10n.importExportMappingModeAutoConfirmCta
                  : l10n.commonContinue,
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

  String? _rawValueAt(int? columnIndex) {
    if (columnIndex == null || sample.sampleRows.isEmpty) {
      return null;
    }
    final row = sample.sampleRows.first;
    if (columnIndex >= row.length) {
      return null;
    }
    final value = row[columnIndex].trim();
    return value.isEmpty ? null : value;
  }

  /// The `tipo` column to offer in [ImportTypeValuesSheet] when the mapping
  /// has none mapped yet: a header whose text matches either vocabulary's
  /// `type` label, even though `AutodetectColumnMapping` deliberately left
  /// it unmapped because its sample values didn't (bug fixed alongside this
  /// step — see `autodetect_column_mapping.dart`). Lets the user still use a
  /// column-based mapping with their own literals instead of only the
  /// amount-sign fallback.
  int? _candidateTypeColumnIndex() {
    if (mapping.hasTypeColumn) {
      return mapping.columnFor(ImportField.type);
    }
    final normalizedHeaders = sample.headers.map(normalizeForMatching).toList();
    for (final vocabulary in CsvVocabulary.all) {
      final label =
          normalizeForMatching(vocabulary.transactionHeaders[TransactionCsvColumn.type]!);
      final index = normalizedHeaders.indexOf(label);
      if (index != -1) {
        return index;
      }
    }
    return null;
  }

  Future<void> _pickDateFormat(BuildContext context) async {
    final choice = await ImportDateFormatSheet.show(
      context,
      currentOrder: dialect.dateOrder,
      currentSeparator: dialect.dateSeparator,
      sampleValue: _rawValueAt(mapping.columnFor(ImportField.date)),
    );
    if (choice != null) {
      onDateFormatChanged(choice.order, choice.separator);
    }
  }

  Future<void> _pickDecimalFormat(BuildContext context) async {
    final choice = await ImportDecimalFormatSheet.show(
      context,
      current: dialect.decimalConvention,
      sampleValue: _rawValueAt(mapping.columnFor(ImportField.amount)),
    );
    if (choice != null) {
      onDecimalConventionChanged(choice);
    }
  }

  Future<void> _pickTypeValues(BuildContext context) async {
    final candidateIndex = _candidateTypeColumnIndex();
    final choice = await ImportTypeValuesSheet.show(
      context,
      initialUseColumn: mapping.hasTypeColumn,
      currentValues: mapping.typeValues,
      columnSampleValue: _rawValueAt(candidateIndex),
      amountSampleValue: _rawValueAt(mapping.columnFor(ImportField.amount)),
    );
    if (choice == null) {
      return;
    }
    if (choice.useColumn) {
      if (candidateIndex != null) {
        onTypeColumnChanged(candidateIndex, choice.values!);
      }
    } else {
      onAmountSignModeChanged();
    }
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
