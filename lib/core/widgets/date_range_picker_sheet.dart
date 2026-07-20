import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import 'bottom_sheet_base.dart';
import 'month_calendar.dart';
import 'sheet_buttons_row.dart';

/// The date range picker sheet (`Sheet - Rango Personalizado` / `OFdj4` in
/// `billetudo.pen`): the app's own range calendar, used instead of
/// Material's `showDateRangePicker` for the same reason `DatePickerSheet`
/// replaces `showDatePicker` — the design (`Bottom Sheet Base`, the two
/// read-only "Desde"/"Hasta" fields, the range-highlighted grid, a single
/// primary "Aplicar") does not map onto it.
///
/// Tapping a day starts a fresh single-day range; tapping again either
/// extends it into an end date, or restarts it if the tap lands before the
/// current start. "Aplicar" always resolves with the current range —
/// [initialStart]/[initialEnd] already form a valid one, so it is never
/// disabled. Dismissing (swipe/back, matching the sheet's lack of an "X" or
/// "Cancelar" wired to `null`) or tapping "Cancelar" resolve to `null`.
class DateRangePickerSheet extends StatefulWidget {
  const DateRangePickerSheet({
    required this.initialStart,
    required this.initialEnd,
    super.key,
  });

  final DateTime initialStart;
  final DateTime initialEnd;

  /// Opens the sheet and resolves to the applied `(start, end)` range, or
  /// `null` if dismissed/cancelled.
  static Future<DateTimeRange?> show(
    BuildContext context, {
    required DateTime initialStart,
    required DateTime initialEnd,
  }) =>
      BottomSheetBase.show<DateTimeRange>(
        context,
        builder: (context) => DateRangePickerSheet(
          initialStart: initialStart,
          initialEnd: initialEnd,
        ),
      );

  @override
  State<DateRangePickerSheet> createState() => _DateRangePickerSheetState();
}

class _DateRangePickerSheetState extends State<DateRangePickerSheet> {
  late DateTime _start = DateUtils.dateOnly(widget.initialStart);
  late DateTime _end = DateUtils.dateOnly(widget.initialEnd);

  /// `false` right after a range is complete (the initial one counts as
  /// complete): the next tap starts a brand-new single-day range instead of
  /// extending the current one.
  bool _awaitingEnd = false;

  late DateTime _visibleMonth = DateTime(_start.year, _start.month);

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

  void _daySelected(DateTime date) {
    setState(() {
      if (!_awaitingEnd || date.isBefore(_start)) {
        _start = date;
        _end = date;
        _awaitingEnd = true;
      } else {
        _end = date;
        _awaitingEnd = false;
      }
    });
  }

  void _apply() {
    Navigator.of(context).pop(DateTimeRange(start: _start, end: _end));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final dateFormat = DateFormat.yMMMd(locale);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.dateFilterCustomRange,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        Row(
          children: [
            Expanded(
              child: DateRangeField(
                label: l10n.dateFilterStart,
                value: dateFormat.format(_start),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DateRangeField(
                label: l10n.dateFilterEnd,
                value: dateFormat.format(_end),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        MonthCalendar(
          visibleMonth: _visibleMonth,
          selected: _start,
          rangeEnd: _end,
          onDaySelected: _daySelected,
          onPreviousMonth: _showPreviousMonth,
          onNextMonth: _showNextMonth,
        ),
        const SizedBox(height: 16),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(l10n.commonCancel),
          ),
          right: FilledButton(
            onPressed: _apply,
            child: Text(l10n.commonApply),
          ),
        ),
      ],
    );
  }
}

/// A read-only `Form Field` (`wOlOA` in `billetudo.pen`, with its trailing
/// chevron and error slot switched off): a label above a `calendar`-icon box
/// that only ever reflects the range picked below it, never opens its own
/// picker.
class DateRangeField extends StatelessWidget {
  const DateRangeField({required this.label, required this.value, super.key});

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
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              Icon(
                LucideIcons.calendar,
                size: 18,
                color: colors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleMedium?.copyWith(
                    color: colors.textPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
