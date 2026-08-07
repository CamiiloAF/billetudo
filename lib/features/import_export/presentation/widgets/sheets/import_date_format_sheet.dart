import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/neutral_button.dart';
import '../../../data/models/csv_date_parser.dart';
import '../../../domain/entities/csv_dialect.dart';

/// One selectable date-format combination (HU-05): [DateComponentOrder.isoYmd]
/// always reads `-`, so it has a single entry; the other two orders offer all
/// three [DateSeparatorChar]s.
class _DateFormatOption {
  const _DateFormatOption(this.order, this.separator, this.pattern);

  final DateComponentOrder order;
  final DateSeparatorChar separator;

  /// Already localized (`AAAA-MM-DD`, `DD/MM/AAAA`…).
  final String pattern;
}

/// What [ImportDateFormatSheet.show] resolves with — `null` when dismissed
/// without confirming.
class ImportDateFormatChoice {
  const ImportDateFormatChoice(this.order, this.separator);

  final DateComponentOrder order;
  final DateSeparatorChar separator;
}

/// Sheet for picking [DateComponentOrder] × [DateSeparatorChar] (HU-05
/// mapping step, "Formato de fecha" field): every combination the app
/// supports, the active one highlighted, with a live preview of how the
/// first real CSV row's date value reads under whichever option is
/// currently highlighted (not necessarily the one confirmed yet).
class ImportDateFormatSheet extends StatefulWidget {
  const ImportDateFormatSheet({
    required this.currentOrder,
    required this.currentSeparator,
    required this.sampleValue,
    super.key,
  });

  final DateComponentOrder currentOrder;
  final DateSeparatorChar currentSeparator;

  /// The first real data row's raw value for the date column, if the field
  /// is mapped and the row has one. `null` disables the live preview text.
  final String? sampleValue;

  static Future<ImportDateFormatChoice?> show(
    BuildContext context, {
    required DateComponentOrder currentOrder,
    required DateSeparatorChar currentSeparator,
    required String? sampleValue,
  }) =>
      BottomSheetBase.show<ImportDateFormatChoice>(
        context,
        builder: (context) => ImportDateFormatSheet(
          currentOrder: currentOrder,
          currentSeparator: currentSeparator,
          sampleValue: sampleValue,
        ),
      );

  @override
  State<ImportDateFormatSheet> createState() => _ImportDateFormatSheetState();
}

class _ImportDateFormatSheetState extends State<ImportDateFormatSheet> {
  late DateComponentOrder _order = widget.currentOrder;
  late DateSeparatorChar _separator = widget.currentSeparator;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    final options = [
      _DateFormatOption(
        DateComponentOrder.isoYmd,
        DateSeparatorChar.dash,
        l10n.importExportDateFormatOptionIso,
      ),
      _DateFormatOption(
        DateComponentOrder.dayMonthYear,
        DateSeparatorChar.slash,
        l10n.importExportDateFormatOptionDmySlash,
      ),
      _DateFormatOption(
        DateComponentOrder.dayMonthYear,
        DateSeparatorChar.dash,
        l10n.importExportDateFormatOptionDmyDash,
      ),
      _DateFormatOption(
        DateComponentOrder.dayMonthYear,
        DateSeparatorChar.dot,
        l10n.importExportDateFormatOptionDmyDot,
      ),
      _DateFormatOption(
        DateComponentOrder.monthDayYear,
        DateSeparatorChar.slash,
        l10n.importExportDateFormatOptionMdySlash,
      ),
      _DateFormatOption(
        DateComponentOrder.monthDayYear,
        DateSeparatorChar.dash,
        l10n.importExportDateFormatOptionMdyDash,
      ),
      _DateFormatOption(
        DateComponentOrder.monthDayYear,
        DateSeparatorChar.dot,
        l10n.importExportDateFormatOptionMdyDot,
      ),
    ];

    final sampleValue = widget.sampleValue;
    final parsed = sampleValue == null || sampleValue.trim().isEmpty
        ? null
        : CsvDateParser.parse(sampleValue, order: _order, separator: _separator);
    final previewText = sampleValue == null
        ? null
        : (parsed == null
            ? l10n.importExportDateFormatPreviewUnreadable(sampleValue)
            : l10n.importExportFieldPreview(
                DateFormat('dd/MM/yyyy').format(parsed.date),
              ));

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.importExportFormatDateLabel,
          style: theme.textTheme.titleMedium
              ?.copyWith(fontSize: 17, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 12),
        for (final option in options)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: InkWell(
              onTap: () => setState(() {
                _order = option.order;
                _separator = option.separator;
              }),
              borderRadius: BorderRadius.circular(14),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                decoration: BoxDecoration(
                  color: option.order == _order && option.separator == _separator
                      ? colors.mintSoft
                      : colors.muted,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        option.pattern,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: option.order == _order && option.separator == _separator
                              ? colors.mintText
                              : colors.textPrimary,
                        ),
                      ),
                    ),
                    if (option.order == _order && option.separator == _separator)
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
            onPressed: () => Navigator.of(context)
                .pop(ImportDateFormatChoice(_order, _separator)),
          ),
        ),
      ],
    );
  }
}
