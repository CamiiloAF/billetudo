import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../month_cell.dart';
import '../year_nav_button.dart';

/// The hero's month picker (HU-04, `k7kv4`/`iGwrg`): a year stepper (`‹ 2026
/// ›`) over a 3×4 grid of [MonthCell]s. Opens from `MonthSelectorChip` when
/// no budget is featured (the featured-budget case navigates its own period
/// window instead, via `HeroPeriodStepper`).
///
/// Any month strictly after the real current month is disabled — the app
/// has no data for the future — so [MonthPickerSheet] computes that floor
/// itself against `clock.now()` rather than trusting a caller-supplied
/// flag, per the design's "no hardcodees el mes futuro" note.
class MonthPickerSheet extends StatefulWidget {
  const MonthPickerSheet({
    required this.initialMonth,
    required this.onMonthSelected,
    super.key,
  });

  /// The month currently shown in the hero (first day, any time-of-day).
  final DateTime initialMonth;

  final ValueChanged<DateTime> onMonthSelected;

  /// Opens the sheet and calls [onMonthSelected] once, right before closing
  /// itself — the caller never has to also pop the sheet.
  static Future<void> show(
    BuildContext context, {
    required DateTime initialMonth,
    required ValueChanged<DateTime> onMonthSelected,
  }) =>
      BottomSheetBase.show(
        context,
        builder: (context) => MonthPickerSheet(
          initialMonth: initialMonth,
          onMonthSelected: onMonthSelected,
        ),
      );

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late int _visibleYear = widget.initialMonth.year;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final now = clock.now();
    final nextYearDisabled = _visibleYear >= now.year;

    final gridRows = <Widget>[];
    for (var row = 0; row < 4; row++) {
      if (row > 0) {
        gridRows.add(const SizedBox(height: 10));
      }
      final rowCells = <Widget>[];
      for (var col = 0; col < 3; col++) {
        if (col > 0) {
          rowCells.add(const SizedBox(width: 10));
        }
        final month = row * 3 + col + 1;
        final date = DateTime(_visibleYear, month);
        final label = DateFormat.MMM(locale).format(date);
        final isSelected = widget.initialMonth.year == _visibleYear &&
            widget.initialMonth.month == month;
        final isDisabled = _visibleYear > now.year ||
            (_visibleYear == now.year && month > now.month);
        rowCells.add(
          Expanded(
            child: MonthCell(
              label: _capitalize(label),
              isSelected: isSelected,
              isDisabled: isDisabled,
              onTap: () {
                widget.onMonthSelected(date);
                Navigator.of(context).pop();
              },
            ),
          ),
        );
      }
      gridRows.add(Row(children: rowCells));
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.homeMonthPickerTitle,
          textAlign: TextAlign.center,
          style: theme.textTheme.titleMedium?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
        const SizedBox(height: 18),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            YearNavButton(
              icon: LucideIcons.chevronLeft,
              tooltip: l10n.homeMonthPickerPreviousYear,
              onPressed: () => setState(() => _visibleYear--),
            ),
            const SizedBox(width: 24),
            Text(
              '$_visibleYear',
              style: theme.textTheme.titleMedium?.copyWith(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: colors.textPrimary,
              ),
            ),
            const SizedBox(width: 24),
            Opacity(
              opacity: nextYearDisabled ? 0.35 : 1,
              child: YearNavButton(
                icon: LucideIcons.chevronRight,
                tooltip: l10n.homeMonthPickerNextYear,
                onPressed: nextYearDisabled
                    ? null
                    : () => setState(() => _visibleYear++),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        ...gridRows,
      ],
    );
  }

  static String _capitalize(String value) =>
      value.isEmpty ? value : value[0].toUpperCase() + value.substring(1);
}
