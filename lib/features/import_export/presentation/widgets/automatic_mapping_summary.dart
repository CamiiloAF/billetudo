import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/parsed_csv_sample.dart';
import '../utils/date_order_label.dart';
import 'import_format_field.dart';
import 'import_live_preview_card.dart';

/// "Automático con confirmación" (HU-05/06): a short summary of the detected
/// dialect/sign convention plus the live preview, no per-column list — the
/// user only confirms. `ImportMappingStep`'s own CTA is the single confirm
/// button this mode calls for.
class AutomaticMappingSummary extends StatelessWidget {
  const AutomaticMappingSummary({
    required this.sample,
    required this.dialect,
    required this.mapping,
    super.key,
  });

  final ParsedCsvSample sample;
  final CsvDialect dialect;
  final ColumnMapping mapping;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final theme = Theme.of(context);
    final colors = context.colors;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 140),
      children: [
        Text(
          l10n.importExportMappingModeAutoSummaryTitle,
          style: theme.textTheme.titleSmall
              ?.copyWith(fontSize: 13, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 8),
        ImportFormatField(
          icon: LucideIcons.calendar,
          label: l10n.importExportFormatDateLabel,
          value: dateOrderLabel(l10n, dialect.dateOrder),
        ),
        const SizedBox(height: 8),
        ImportFormatField(
          icon: LucideIcons.hash,
          label: l10n.importExportFormatDecimalLabel,
          value: dialect.decimalConvention == DecimalConvention.comma
              ? l10n.importExportDecimalComma
              : l10n.importExportDecimalDot,
        ),
        const SizedBox(height: 8),
        ImportFormatField(
          icon: LucideIcons.scale,
          label: l10n.importExportFormatSignLabel,
          value: mapping.hasTypeColumn
              ? l10n.importExportSignByTypeColumn
              : l10n.importExportSignByAmountSign,
        ),
        const SizedBox(height: 14),
        ImportLivePreviewCard(sample: sample, mapping: mapping),
        if (!mapping.isComplete) ...[
          const SizedBox(height: 14),
          Text(
            l10n.importExportMappingModeAutoIncompleteHint,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
      ],
    );
  }
}
