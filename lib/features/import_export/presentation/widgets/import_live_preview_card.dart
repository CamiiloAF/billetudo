import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/column_mapping.dart';
import '../../domain/entities/parsed_csv_sample.dart';

/// The mint "vista previa en vivo" card (`cBSZp`): how the first real data
/// row reads with the mapping chosen so far. Shows the raw CSV values for
/// the mapped fields (not the fully parsed/normalized amount and date —
/// that full resolution only happens once `PreviewImport` runs, past this
/// step), joined for a quick sanity check while mapping.
class ImportLivePreviewCard extends StatelessWidget {
  const ImportLivePreviewCard({required this.sample, required this.mapping, super.key});

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

    // `cBSZp`: the note leads the line ("{nota} · {fecha} · {tipo} ·
    // {monto} · {cuenta} · {categoría}") — it's what most reliably tells the
    // user "yes, this is the right row", ahead of the parsed values.
    final parts = [
      valueFor(ImportField.note),
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
