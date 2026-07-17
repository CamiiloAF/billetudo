import 'package:flutter/material.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import 'bottom_sheet_base.dart';
import 'month_calendar.dart';

/// The date picker sheet (`Date Picker Sheet` / `zMqxt`): the app's own
/// single-date calendar, used instead of Material's `showDatePicker` because
/// the design (Bottom Sheet Base, "Hoy" chip, Monday-first grid, ring-for-today)
/// does not map onto it.
///
/// Tapping a day selects it and closes the sheet, returning the chosen
/// [DateTime] (patrón del formulario: sin botón "Aplicar"). Dismissing returns
/// null.
class DatePickerSheet extends StatefulWidget {
  const DatePickerSheet({required this.initialDate, super.key});

  final DateTime initialDate;

  /// Opens the sheet and resolves to the picked day, or null if dismissed.
  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime initialDate,
  }) =>
      BottomSheetBase.show<DateTime>(
        context,
        builder: (context) => DatePickerSheet(initialDate: initialDate),
      );

  @override
  State<DatePickerSheet> createState() => _DatePickerSheetState();
}

class _DatePickerSheetState extends State<DatePickerSheet> {
  late DateTime _selected = DateUtils.dateOnly(widget.initialDate);
  late DateTime _visibleMonth =
      DateTime(widget.initialDate.year, widget.initialDate.month);

  void _showPreviousMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month - 1);
    });
  }

  void _showNextMonth() {
    setState(() {
      _visibleMonth = DateTime(_visibleMonth.year, _visibleMonth.month + 1);
    });
  }

  void _goToToday() {
    final today = DateUtils.dateOnly(DateTime.now());
    setState(() {
      _selected = today;
      _visibleMonth = DateTime(today.year, today.month);
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                l10n.datePickerTitle,
                style: theme.textTheme.titleLarge?.copyWith(
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            TodayChip(onTap: _goToToday, label: l10n.transactionFormDateToday),
          ],
        ),
        const SizedBox(height: 16),
        MonthCalendar(
          visibleMonth: _visibleMonth,
          selected: _selected,
          onDaySelected: (date) => Navigator.of(context).pop(date),
          onPreviousMonth: _showPreviousMonth,
          onNextMonth: _showNextMonth,
        ),
      ],
    );
  }
}

class TodayChip extends StatelessWidget {
  const TodayChip({required this.onTap, required this.label, super.key});

  final VoidCallback onTap;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.primarySoft,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          height: 44,
          alignment: Alignment.center,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            label,
            style: theme.textTheme.labelLarge?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.primaryOnSoftStrong,
            ),
          ),
        ),
      ),
    );
  }
}
