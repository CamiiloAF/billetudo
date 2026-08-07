import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/neutral_button.dart';
import '../../../data/models/decimal_amount_parser.dart';
import '../../../domain/entities/csv_dialect.dart';

/// Sheet for picking [DecimalConvention] (HU-05 mapping step, "Convención
/// decimal" field): dot vs. comma, the active one highlighted, with a live
/// preview of how the first real CSV row's amount value reads under
/// whichever option is currently highlighted.
class ImportDecimalFormatSheet extends StatefulWidget {
  const ImportDecimalFormatSheet({
    required this.current,
    required this.sampleValue,
    this.currencyDecimals = 2,
    super.key,
  });

  final DecimalConvention current;

  /// The first real data row's raw value for the amount column, if the
  /// field is mapped and the row has one. `null` disables the live preview.
  final String? sampleValue;

  final int currencyDecimals;

  static Future<DecimalConvention?> show(
    BuildContext context, {
    required DecimalConvention current,
    required String? sampleValue,
  }) =>
      BottomSheetBase.show<DecimalConvention>(
        context,
        builder: (context) => ImportDecimalFormatSheet(
          current: current,
          sampleValue: sampleValue,
        ),
      );

  @override
  State<ImportDecimalFormatSheet> createState() => _ImportDecimalFormatSheetState();
}

class _ImportDecimalFormatSheetState extends State<ImportDecimalFormatSheet> {
  late DecimalConvention _selected = widget.current;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    final options = [
      (DecimalConvention.dot, l10n.importExportDecimalDot),
      (DecimalConvention.comma, l10n.importExportDecimalComma),
    ];

    final sampleValue = widget.sampleValue;
    final parsed = sampleValue == null || sampleValue.trim().isEmpty
        ? null
        : DecimalAmountParser.parse(
            sampleValue,
            convention: _selected,
            currencyDecimals: widget.currencyDecimals,
          );
    final previewText = sampleValue == null
        ? null
        : (parsed == null
            ? l10n.importExportDateFormatPreviewUnreadable(sampleValue)
            : l10n.importExportFieldPreview(
                DecimalAmountParser.format(
                  parsed.minorUnits.abs(),
                  currencyDecimals: widget.currencyDecimals,
                ),
              ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.importExportFormatDecimalLabel,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() => _selected = option.$1),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: option.$1 == _selected ? colors.mintSoft : colors.muted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.$2,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: option.$1 == _selected
                              ? colors.mintText
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (option.$1 == _selected)
                      Icon(LucideIcons.check, size: 18, color: colors.mintText),
                  ],
                ),
              ),
            ),
          ),
        if (previewText != null) ...[
          const SizedBox(height: 4),
          Text(
            previewText,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: colors.textSecondary,
            ),
          ),
        ],
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: NeutralButton(
            label: l10n.commonApply,
            icon: LucideIcons.check,
            onPressed: () => Navigator.of(context).pop(_selected),
          ),
        ),
      ],
    );
  }
}
