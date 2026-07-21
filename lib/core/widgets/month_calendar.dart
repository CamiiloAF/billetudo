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
    this.disabledBefore,
    this.rangeEnd,
    super.key,
  });

  /// Any day inside the month currently shown; only its year/month matter.
  final DateTime visibleMonth;

  /// The currently selected day. In range mode ([rangeEnd] non-null) this is
  /// the range's start.
  final DateTime selected;

  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  /// Days strictly before this floor render dimmed and ignore taps.
  final DateTime? disabledBefore;

  /// When set, switches the grid to range mode: [selected] and [rangeEnd]
  /// render as solid `primary` endpoints, and the days strictly between them
  /// render in `primary-soft` (`Sheet - Rango Personalizado` in
  /// `billetudo.pen`, e.g. days 4-8 between the 3rd and the 9th). `null`
  /// keeps the single-date behaviour used by `DatePickerSheet`/`SnoozeSheet`.
  final DateTime? rangeEnd;

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
          disabledBefore: disabledBefore,
          rangeEnd: rangeEnd,
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
      mainAxisAlignment: MainAxisAlignment.center,
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
    this.disabledBefore,
    this.rangeEnd,
    super.key,
  });

  final DateTime visibleMonth;
  final DateTime selected;
  final ValueChanged<DateTime> onDaySelected;
  final DateTime? disabledBefore;

  /// See [MonthCalendar.rangeEnd].
  final DateTime? rangeEnd;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth =
        DateUtils.getDaysInMonth(visibleMonth.year, visibleMonth.month);
    // weekday: Mon=1..Sun=7; leading blanks before the 1st, Monday-first.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final today = DateUtils.dateOnly(DateTime.now());
    final selectedDay = DateUtils.dateOnly(selected);
    final rangeEndDay = rangeEnd == null ? null : DateUtils.dateOnly(rangeEnd!);
    final floor =
        disabledBefore == null ? null : DateUtils.dateOnly(disabledBefore!);

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
                  selectedDay ||
              (rangeEndDay != null &&
                  DateTime(visibleMonth.year, visibleMonth.month, day) ==
                      rangeEndDay),
          isRangeMiddle: rangeEndDay != null &&
              DateTime(visibleMonth.year, visibleMonth.month, day)
                  .isAfter(selectedDay) &&
              DateTime(visibleMonth.year, visibleMonth.month, day)
                  .isBefore(rangeEndDay),
          isToday:
              DateTime(visibleMonth.year, visibleMonth.month, day) == today,
          isDisabled: floor != null &&
              DateTime(visibleMonth.year, visibleMonth.month, day)
                  .isBefore(floor),
          onTap: onDaySelected,
        ),
    ];

    // A plain `Wrap` sizes each row by how many 44px cells fit the sheet's
    // full width, not by 7 — on wide phones that fits 8+ per row and drifts
    // every row out from under `CalendarWeekdayHeader`'s fixed 7-column Row.
    // Chunking into 7-wide rows pins each cell under its weekday column.
    const columns = 7;
    return Column(
      children: [
        for (var i = 0; i < cells.length; i += columns)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: cells.sublist(
              i,
              i + columns > cells.length ? cells.length : i + columns,
            ),
          ),
      ],
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
    this.isDisabled = false,
    this.isRangeMiddle = false,
    super.key,
  });

  final int day;
  final DateTime date;
  final bool isSelected;
  final bool isToday;
  final bool isDisabled;
  final ValueChanged<DateTime> onTap;

  /// Strictly between a range's start and end (`isSelected` is reserved for
  /// the two endpoints). Renders `primary-soft` background with
  /// `primary-on-soft` text, as in `billetudo.pen`'s range sheet.
  final bool isRangeMiddle;

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
    } else if (isRangeMiddle) {
      background = colors.primarySoft;
      foreground = colors.primaryOnSoft;
      weight = FontWeight.w500;
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

    return Opacity(
      opacity: isDisabled ? 0.35 : 1,
      child: SizedBox(
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
              onTap: isDisabled ? null : () => onTap(date),
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
      ),
    );
  }
}
