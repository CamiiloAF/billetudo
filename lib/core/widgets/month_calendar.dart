import 'package:clock/clock.dart';
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
///
/// Tapping the "mes año" label switches the whole widget to a year-selection
/// view (`CalendarYearGrid`) so the caller can jump to a far-away year without
/// paging month by month; picking a year (or tapping the range label again to
/// back out) returns to the month grid. This toggle is [MonthCalendar]'s own
/// state — it never resets [selected]/[rangeEnd], which the caller still owns.
class MonthCalendar extends StatefulWidget {
  const MonthCalendar({
    required this.visibleMonth,
    required this.selected,
    required this.onDaySelected,
    required this.onPreviousMonth,
    required this.onNextMonth,
    required this.onYearSelected,
    this.disabledBefore,
    this.disabledAfter,
    this.rangeEnd,
    super.key,
  });

  /// Any day inside the month currently shown; only its year/month matter.
  final DateTime visibleMonth;

  /// The currently selected day, or `null` when nothing has been chosen yet
  /// (e.g. `DatePickerSheet` opened without an `initialDate`) — no day renders
  /// highlighted in that case. In range mode ([rangeEnd] non-null) this is the
  /// range's start.
  final DateTime? selected;

  final ValueChanged<DateTime> onDaySelected;
  final VoidCallback onPreviousMonth;
  final VoidCallback onNextMonth;

  /// Called when the user picks a year from the year-selection view. The
  /// caller is expected to move [visibleMonth] to that year, keeping the
  /// currently visible month (e.g. `DateTime(year, visibleMonth.month)`) so a
  /// previously chosen month/day is not lost. [MonthCalendar] returns to the
  /// month grid on its own right after calling this.
  final ValueChanged<int> onYearSelected;

  /// Days strictly before this floor render dimmed and ignore taps. Years
  /// entirely before this floor's year are disabled the same way in the
  /// year-selection view.
  final DateTime? disabledBefore;

  /// Days strictly after this ceiling render dimmed and ignore taps — e.g. the
  /// confirmation sheet caps its date at today so a payment can't be recorded
  /// in the future. Years entirely after this ceiling's year are disabled the
  /// same way in the year-selection view.
  final DateTime? disabledAfter;

  /// When set, switches the grid to range mode: [selected] and [rangeEnd]
  /// render as solid `primary` endpoints, and the days strictly between them
  /// render in `primary-soft` (`Sheet - Rango Personalizado` in
  /// `billetudo.pen`, e.g. days 4-8 between the 3rd and the 9th). `null`
  /// keeps the single-date behaviour used by `DatePickerSheet`/`SnoozeSheet`.
  final DateTime? rangeEnd;

  /// Row height of a day cell, and the size of the month-nav buttons. The
  /// grid spreads across the full width (7 equal `Expanded` columns); this is
  /// only the vertical rhythm, not a fixed column width.
  static const double _cell = 44;

  /// Diameter of the circular day marker centred in each column.
  static const double _circle = 40;

  /// Fixed row count of [CalendarMonthGrid], covering every month a
  /// Monday-first calendar can produce (a month can start on any weekday and
  /// span up to 6 partial weeks, e.g. February 2026 starting on a Sunday
  /// needs only 4, August 2026 needs 6). Always rendering 6 keeps the grid's
  /// total height — and so the sheet's — constant across months.
  static const int weekRows = 6;

  @override
  State<MonthCalendar> createState() => _MonthCalendarState();
}

class _MonthCalendarState extends State<MonthCalendar> {
  bool _showYearPicker = false;
  late int _yearRangeStart = _rangeStartFor(widget.visibleMonth.year);

  static int _rangeStartFor(int year) =>
      year - (year % CalendarYearGrid.yearsPerPage);

  void _openYearPicker() {
    setState(() {
      _yearRangeStart = _rangeStartFor(widget.visibleMonth.year);
      _showYearPicker = true;
    });
  }

  void _closeYearPicker() {
    setState(() => _showYearPicker = false);
  }

  void _showPreviousYears() {
    setState(() => _yearRangeStart -= CalendarYearGrid.yearsPerPage);
  }

  void _showNextYears() {
    setState(() => _yearRangeStart += CalendarYearGrid.yearsPerPage);
  }

  void _selectYear(int year) {
    widget.onYearSelected(year);
    setState(() => _showYearPicker = false);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();

    final monthLabel = toBeginningOfSentenceCase(
      DateFormat('MMMM y', locale).format(widget.visibleMonth),
    );
    final yearRangeLabel =
        '$_yearRangeStart–${_yearRangeStart + CalendarYearGrid.yearsPerPage - 1}';

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
            children: _showYearPicker
                ? [
                    MonthNavButton(
                      icon: LucideIcons.chevronLeft,
                      tooltip: l10n.datePickerPreviousYears,
                      onTap: _showPreviousYears,
                    ),
                    Expanded(
                      child: MonthYearHeaderLabel(
                        label: yearRangeLabel,
                        tooltip: l10n.datePickerBackToMonths,
                        onTap: _closeYearPicker,
                      ),
                    ),
                    MonthNavButton(
                      icon: LucideIcons.chevronRight,
                      tooltip: l10n.datePickerNextYears,
                      onTap: _showNextYears,
                    ),
                  ]
                : [
                    MonthNavButton(
                      icon: LucideIcons.chevronLeft,
                      tooltip: l10n.datePickerPreviousMonth,
                      onTap: widget.onPreviousMonth,
                    ),
                    Expanded(
                      child: MonthYearHeaderLabel(
                        label: monthLabel,
                        tooltip: l10n.datePickerSelectYear,
                        onTap: _openYearPicker,
                      ),
                    ),
                    MonthNavButton(
                      icon: LucideIcons.chevronRight,
                      tooltip: l10n.datePickerNextMonth,
                      onTap: widget.onNextMonth,
                    ),
                  ],
          ),
        ),
        const SizedBox(height: 12),
        if (_showYearPicker)
          CalendarYearGrid(
            rangeStart: _yearRangeStart,
            selectedYear: widget.visibleMonth.year,
            onYearSelected: _selectYear,
            disabledBefore: widget.disabledBefore,
            disabledAfter: widget.disabledAfter,
          )
        else ...[
          CalendarWeekdayHeader(locale: locale),
          const SizedBox(height: 4),
          CalendarMonthGrid(
            visibleMonth: widget.visibleMonth,
            selected: widget.selected,
            onDaySelected: widget.onDaySelected,
            disabledBefore: widget.disabledBefore,
            disabledAfter: widget.disabledAfter,
            rangeEnd: widget.rangeEnd,
          ),
        ],
      ],
    );
  }
}

/// The tappable "mes año" (month view) / "año–año" (year view) header label
/// (`MonthYearHeaderLabel`, new): visually identical to the plain text it
/// replaces, wrapped in an `InkWell` for feedback plus a `Tooltip`/`Semantics`
/// pair so the affordance to jump between the month grid and the year grid is
/// discoverable, not just tappable.
class MonthYearHeaderLabel extends StatelessWidget {
  const MonthYearHeaderLabel({
    required this.label,
    required this.tooltip,
    required this.onTap,
    super.key,
  });

  final String label;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Tooltip(
      message: tooltip,
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(8),
          child: Semantics(
            button: true,
            label: tooltip,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: colors.textPrimary,
                ),
              ),
            ),
          ),
        ),
      ),
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
          Expanded(
            child: SizedBox(
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
    this.disabledAfter,
    this.rangeEnd,
    super.key,
  });

  final DateTime visibleMonth;

  /// See [MonthCalendar.selected].
  final DateTime? selected;
  final ValueChanged<DateTime> onDaySelected;
  final DateTime? disabledBefore;
  final DateTime? disabledAfter;

  /// See [MonthCalendar.rangeEnd].
  final DateTime? rangeEnd;

  @override
  Widget build(BuildContext context) {
    final firstOfMonth = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth =
        DateUtils.getDaysInMonth(visibleMonth.year, visibleMonth.month);
    // weekday: Mon=1..Sun=7; leading blanks before the 1st, Monday-first.
    final leadingBlanks = firstOfMonth.weekday - 1;
    final today = DateUtils.dateOnly(clock.now());
    final selectedDay = selected == null ? null : DateUtils.dateOnly(selected!);
    final rangeEndDay = rangeEnd == null ? null : DateUtils.dateOnly(rangeEnd!);
    final floor =
        disabledBefore == null ? null : DateUtils.dateOnly(disabledBefore!);
    final ceiling =
        disabledAfter == null ? null : DateUtils.dateOnly(disabledAfter!);

    const blank = SizedBox(height: MonthCalendar._cell);
    final cells = <Widget>[
      for (var i = 0; i < leadingBlanks; i++) blank,
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
              selectedDay != null &&
              DateTime(visibleMonth.year, visibleMonth.month, day)
                  .isAfter(selectedDay) &&
              DateTime(visibleMonth.year, visibleMonth.month, day)
                  .isBefore(rangeEndDay),
          isToday:
              DateTime(visibleMonth.year, visibleMonth.month, day) == today,
          isDisabled: (floor != null &&
                  DateTime(visibleMonth.year, visibleMonth.month, day)
                      .isBefore(floor)) ||
              (ceiling != null &&
                  DateTime(visibleMonth.year, visibleMonth.month, day)
                      .isAfter(ceiling)),
          onTap: onDaySelected,
        ),
    ];

    // Seven equal `Expanded` columns per row spread the grid across the full
    // width, like a conventional calendar, and keep every cell under its
    // weekday header (which uses the same 7 `Expanded` columns). A month
    // rarely fills the last row (or even all `MonthCalendar.weekRows` rows);
    // pad up to a fixed 6 rows always, with blank cells, so the grid's total
    // height never depends on how many weeks a given month spans — a month
    // with only 4 visible weeks (e.g. February 2026, starting on a Sunday)
    // renders exactly like one with 6 (e.g. August 2026), keeping the sheet's
    // height stable while paging between months.
    const columns = 7;
    const totalCells = columns * MonthCalendar.weekRows;
    while (cells.length < totalCells) {
      cells.add(blank);
    }
    return Column(
      children: [
        for (var i = 0; i < cells.length; i += columns)
          Row(
            children: [
              for (final cell in cells.sublist(i, i + columns))
                Expanded(child: cell),
            ],
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
      // Row height fixed, width supplied by the parent's `Expanded` column;
      // the circular marker is a fixed diameter centred in that column so it
      // stays a perfect circle regardless of how wide the column gets.
      child: SizedBox(
        height: MonthCalendar._cell,
        child: Center(
          child: SizedBox(
            width: MonthCalendar._circle,
            height: MonthCalendar._circle,
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
      ),
    );
  }
}

/// The year-selection view (new, no reusable Pencil node yet) that
/// `MonthCalendar` swaps in for `CalendarWeekdayHeader`/`CalendarMonthGrid`
/// when the header label is tapped. A 3-column grid of pill-shaped year
/// cells, paged 12 years at a time, so jumping to a year far from the one
/// currently visible doesn't require paging month by month.
///
/// Cell states mirror [CalendarDayCell]'s language on a rectangular pill
/// instead of a circle (a 4-digit year doesn't fit one): selected —
/// filled `primary`; current real year (when not selected) — a 1px `primary`
/// ring; other years — transparent; out of [disabledBefore]/[disabledAfter]'s
/// range — 0.35 opacity and taps ignored, same as disabled days.
class CalendarYearGrid extends StatelessWidget {
  const CalendarYearGrid({
    required this.rangeStart,
    required this.selectedYear,
    required this.onYearSelected,
    this.disabledBefore,
    this.disabledAfter,
    super.key,
  });

  /// First year of the 12-year page currently shown.
  final int rangeStart;

  final int selectedYear;
  final ValueChanged<int> onYearSelected;
  final DateTime? disabledBefore;
  final DateTime? disabledAfter;

  static const int yearsPerPage = 12;
  static const int columns = 3;
  static const double cellHeight = 56;

  @override
  Widget build(BuildContext context) {
    final currentYear = clock.now().year;
    final floorYear = disabledBefore?.year;
    final ceilingYear = disabledAfter?.year;
    final years = [for (var i = 0; i < yearsPerPage; i++) rangeStart + i];

    return Column(
      children: [
        for (var i = 0; i < years.length; i += columns)
          Row(
            children: [
              for (final year in years.sublist(i, i + columns))
                Expanded(
                  child: CalendarYearCell(
                    year: year,
                    isSelected: year == selectedYear,
                    isCurrentYear: year == currentYear,
                    isDisabled: (floorYear != null && year < floorYear) ||
                        (ceilingYear != null && year > ceilingYear),
                    onTap: onYearSelected,
                  ),
                ),
            ],
          ),
      ],
    );
  }
}

class CalendarYearCell extends StatelessWidget {
  const CalendarYearCell({
    required this.year,
    required this.isSelected,
    required this.isCurrentYear,
    required this.onTap,
    this.isDisabled = false,
    super.key,
  });

  final int year;
  final bool isSelected;
  final bool isCurrentYear;
  final bool isDisabled;
  final ValueChanged<int> onTap;

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
    } else if (isCurrentYear) {
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
      child: Padding(
        padding: const EdgeInsets.all(4),
        child: SizedBox(
          height: CalendarYearGrid.cellHeight,
          child: Material(
            color: background,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: border == null
                  ? BorderSide.none
                  : BorderSide(color: colors.primary),
            ),
            clipBehavior: Clip.antiAlias,
            child: InkWell(
              onTap: isDisabled ? null : () => onTap(year),
              child: Center(
                child: Text(
                  // A bare year numeral, nothing to translate.
                  year.toString(),
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 15,
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
