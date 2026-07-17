import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';

/// A single-month calendar grid (`Month Calendar` / `w4yuu`): a month-nav pill,
/// a Monday-first weekday header and circular day cells. It is display-only for
/// a month — paging between months and the selection live in the caller (see
/// `DatePickerSheet`).
///
/// Day-cell states mirror the design:
/// - selected: filled `primary`, number `onPrimary` weight 700;
/// - today (when not selected): a 1px `primary` ring, number `textPrimary` 600;
/// - other days: transparent, number `textPrimary` 500.
class MonthCalendar extends StatelessWidget {
  const MonthCalendar({
    required this.visibleMonth,
    required this.selected,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    super.key,
  });

  /// Any day inside the month currently shown; only its year/month matter.
  final DateTime visibleMonth;

  /// The currently selected day.
  final DateTime selected;

  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  static const double _cell = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    final monthLabel = toBeginningOfSentenceCase(
      DateFormat('MMMM y', locale).format(visibleMonth),
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Month Nav pill.
        DecoratedBox(
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              MonthNavButton(
                icon: LucideIcons.chevronLeft,
                tooltip: l10n.datePickerPreviousMonth,
                onTap: onPreviousMonth,
              ),
              Expanded(
                child: Text(
                  monthLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              MonthNavButton(
                icon: LucideIcons.chevronRight,
                tooltip: l10n.datePickerNextMonth,
                onTap: onNextMonth,
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        CalendarWeekdayHeader(locale: locale),
        const SizedBox(height: 4),
        CalendarMonthGrid(
          visibleMonth: visibleMonth,
          selected: selected,
          onDaySelected: onDaySelected,
        ),
      ],
    );
  }
}

class MonthNavButton extends StatelessWidget {
  const MonthNavButton({
    required this.icon,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return IconButton(
      onPressed: onTap,
      tooltip: tooltip,
      iconSize: 20,
      color: colors.textSecondary,
      constraints: const BoxConstraints.tightFor(
        width: MonthCalendar._cell,
        height: MonthCalendar._cell,
      ),
      icon: Icon(icon),
    );
  }
}

class CalendarWeekdayHeader extends StatelessWidget {
  const CalendarWeekdayHeader({required this.locale, super.key});

  final String locale;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final symbols = DateFormat('EEE', locale).dateSymbols;
    // dateSymbols.STANDALONENARROWWEEKDAYS is Sunday-first; rotate to Monday.
    final narrow = symbols.STANDALONENARROWWEEKDAYS;
    final labels = [
      for (var i = 1; i <= 7; i++) narrow[i % 7],
    ];
    return Row(
      children: [
        for (final label in labels)
          SizedBox(
            width: MonthCalendar._cell,
            height: 24,
            child: Center(
              child: Text(
                toBeginningOfSentenceCase(label) ?? label,
                style: theme.textTheme.labelSmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: colors.textSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class CalendarMonthGrid extends StatelessWidget {
  const CalendarMonthGrid({
    required this.visibleMonth,
    required this.selected,
    required this.onDaySelected,
    super.key,
  });

  final DateTime visibleMonth;
  final DateTime selected;
  final ValueChanged<DateTime> onDaySelected;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth =
        DateUtils.getDaysInMonth(visibleMonth.year, visibleMonth.month);
    // weekday: Mon=1..Sun=7; leading blanks before the 1st, Monday-first.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(selected);

    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++)
        const SizedBox(
          width: MonthCalendar._cell,
          height: MonthCalendar._cell,
        ),
      for (var day = 1; day <= daysInMonth; day++)
        CalendarDayCell(
          day: day,
          date: DateTime(visibleMonth.year, visibleMonth.month, day),
          isSelected: DateTime(visibleMonth.year, visibleMonth.month, day) ==
              selectedDay,
          isToday:
              DateTime(visibleMonth.year, visibleMonth.month, day) == today,
          onTap: onDaySelected,
        ),
    ];

    return Wrap(
      children: cells,
    );
  }
}

class CalendarDayCell extends StatelessWidget {
  const CalendarDayCell({
    required this.day,
    required this.date,
    required this.isSelected,
    required this.isToday,
    required this.onTap,
    super.key,
  });

  final int day;
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final ValueChanged<DateTime> onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    final Color background;
    final Color foreground;
    final FontWeight weight;
    final BoxBorder? border;
    if (isSelected) {
      background = colors.primary;
      foreground = colors.onPrimary;
      weight = FontWeight.w700;
      border = null;
    } else if (isToday) {
      background = Colors.transparent;
      foreground = colors.textPrimary;
      weight = FontWeight.w600;
      border = Border.all(color: colors.primary);
    } else {
      background = Colors.transparent;
      foreground = colors.textPrimary;
      weight = FontWeight.w500;
      border = null;
    }

    return SizedBox(
      width: MonthCalendar._cell,
      height: MonthCalendar._cell,
      child: Padding(
        padding: const EdgeInsets.all(2),
        child: Material(
          color: background,
          shape: CircleBorder(
            side: border == null
                ? BorderSide.none
                : BorderSide(color: colors.primary),
          ),
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => onTap(date),
            customBorder: const CircleBorder(),
            child: Center(
              child: Text(
                // A bare day numeral, nothing to translate.
                day.toString(),
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: weight,
                  color: foreground,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
