import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../month_cell.dart';

/// The month selector (HU-04): a year navigator ‹ 2026 › over a 3×4 grid of
/// months. Future months are disabled — the Home only navigates the current
/// month and earlier. Resolves to the chosen month (first day), or `null` when
/// dismissed.
class MonthPickerSheet extends StatefulWidget {
  const MonthPickerSheet({
    required this.selected,
    required this.currentMonth,
    super.key,
  });

  /// The month currently shown by the Home (first day).
  final DateTime selected;

  /// The current calendar month: months after it are disabled.
  final DateTime currentMonth;

  static Future<DateTime?> show(
    BuildContext context, {
    required DateTime selected,
    required DateTime currentMonth,
  }) =>
      BottomSheetBase.show<DateTime>(
        context,
        builder: (context) => MonthPickerSheet(
          selected: selected,
          currentMonth: currentMonth,
        ),
      );

  @override
  State<MonthPickerSheet> createState() => _MonthPickerSheetState();
}

class _MonthPickerSheetState extends State<MonthPickerSheet> {
  late int _year = widget.selected.year;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final canGoForward = _year < widget.currentMonth.year;

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.homeMonthPickerTitle,
          style:
              theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        YearNavigator(
          year: _year,
          canGoForward: canGoForward,
          onPrevious: () => setState(() => _year -= 1),
          onNext: canGoForward ? () => setState(() => _year += 1) : null,
        ),
        const SizedBox(height: 12),
        GridView.count(
          crossAxisCount: 3,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 2.2,
          children: [
            for (var month = 1; month <= 12; month++)
              MonthCell(
                label: _monthLabel(context, month),
                isSelected: _year == widget.selected.year &&
                    month == widget.selected.month,
                isDisabled: _isFuture(month),
                onTap: () => Navigator.of(context).pop(DateTime(_year, month)),
              ),
          ],
        ),
      ],
    );
  }

  bool _isFuture(int month) {
    final candidate = DateTime(_year, month);
    return candidate.isAfter(widget.currentMonth);
  }

  String _monthLabel(BuildContext context, int month) {
    // A localized short month name; capitalized for the cell.
    final locale = Localizations.localeOf(context).toString();
    final raw = DateFormat.MMM(locale).format(DateTime(_year, month));
    return raw.isEmpty ? raw : raw[0].toUpperCase() + raw.substring(1);
  }
}

class YearNavigator extends StatelessWidget {
  const YearNavigator({
    required this.year,
    required this.canGoForward,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final int year;
  final bool canGoForward;
  final VoidCallback onPrevious;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        IconButton(
          onPressed: onPrevious,
          icon: const Icon(LucideIcons.chevronLeft),
          color: colors.textPrimary,
        ),
        Text(
          // A bare numeral, nothing to translate.
          year.toString(),
          style: theme.textTheme.titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        Opacity(
          opacity: canGoForward ? 1 : 0.35,
          child: IconButton(
            onPressed: onNext,
            icon: const Icon(LucideIcons.chevronRight),
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
