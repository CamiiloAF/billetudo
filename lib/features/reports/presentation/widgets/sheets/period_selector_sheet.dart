import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_range_picker_sheet.dart';
import '../../../../../core/widgets/segmented_control.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../models/reports_period_selection.dart';
import '../../utils/reports_period_format.dart';
import 'period_stepper_button.dart';

enum _Granularity { month, year }

/// The Period Selector sheet (`Sy92N`): switches between a month/year
/// stepper and an escape hatch into `DateRangePickerSheet` for a fully
/// custom range.
///
/// The `.pen` only speces this sheet's base case — see
/// `design-system/billetudo/pages/graficas.md`, "Pendientes conocidos": no
/// dark variant exists yet either (light-only reused here for both themes,
/// since `Theme.of(context)` already resolves the active one from tokens).
class PeriodSelectorSheet extends StatefulWidget {
  const PeriodSelectorSheet({required this.initial, super.key});

  final ReportsPeriodSelection initial;

  /// Opens the sheet, resolving to the chosen [ReportsPeriodSelection], or
  /// `null` if dismissed without applying.
  static Future<ReportsPeriodSelection?> show(
    BuildContext context, {
    required ReportsPeriodSelection initial,
  }) =>
      BottomSheetBase.show<ReportsPeriodSelection>(
        context,
        builder: (context) => PeriodSelectorSheet(initial: initial),
      );

  @override
  State<PeriodSelectorSheet> createState() => _PeriodSelectorSheetState();
}

class _PeriodSelectorSheetState extends State<PeriodSelectorSheet> {
  late _Granularity _granularity = widget.initial.kind == ReportsPeriodKind.year
      ? _Granularity.year
      : _Granularity.month;
  late DateTime _cursor = widget.initial.kind == ReportsPeriodKind.month ||
          widget.initial.kind == ReportsPeriodKind.year ||
          widget.initial.kind == ReportsPeriodKind.custom
      ? widget.initial.range.start
      : DateTime.now();

  /// Whether the sheet opened with an active date-range filter — either a
  /// user-picked custom range, or the app's `lastSixMonths` default, which
  /// is *also* a specific range rather than a single month/year — and the
  /// user hasn't yet interacted with the Mes/Año segmented control or the
  /// stepper, both of which would replace it with a month/year filter.
  /// Tracked separately from `widget.initial.kind` so the "aplicado"
  /// treatment on the range row disappears the moment the user starts
  /// interacting with Mes/Año, without waiting for `_apply`.
  late bool _customRangeStillActive =
      widget.initial.kind == ReportsPeriodKind.custom ||
          widget.initial.kind == ReportsPeriodKind.lastSixMonths;

  void _selectGranularity(_Granularity value) {
    setState(() {
      _granularity = value;
      _customRangeStillActive = false;
    });
  }

  void _step(int delta) {
    setState(() {
      _customRangeStillActive = false;
      _cursor = _granularity == _Granularity.month
          ? DateTime(_cursor.year, _cursor.month + delta)
          : DateTime(_cursor.year + delta);
    });
  }

  Future<void> _openCustomRange() async {
    final now = DateTime.now();
    final result = await DateRangePickerSheet.show(
      context,
      initialStart: widget.initial.range.start,
      initialEnd: widget.initial.range.endExclusive
          .subtract(const Duration(days: 1)).isBefore(now)
          ? widget.initial.range.endExclusive.subtract(const Duration(days: 1))
          : now,
    );
    if (result == null || !mounted) {
      return;
    }
    Navigator.of(context).pop(
      ReportsPeriodSelection.custom(
        start: DateUtils.dateOnly(result.start),
        endExclusive:
            DateUtils.dateOnly(result.end).add(const Duration(days: 1)),
      ),
    );
  }

  void _apply() {
    final selection = _granularity == _Granularity.month
        ? ReportsPeriodSelection.month(_cursor)
        : ReportsPeriodSelection.year(_cursor.year);
    Navigator.of(context).pop(selection);
  }

  void _clear() {
    Navigator.of(context).pop(ReportsPeriodSelection.lastSixMonths());
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final periodLabel = ReportsPeriodFormat.selectorLabel(
      l10n,
      _granularity == _Granularity.month
          ? ReportsPeriodSelection.month(_cursor)
          : ReportsPeriodSelection.year(_cursor.year),
      locale,
    );

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(
          l10n.reportsPeriodSheetTitle,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 17,
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 16),
        SegmentedControl<_Granularity>(
          selected: _customRangeStillActive ? null : _granularity,
          onChanged: _selectGranularity,
          segments: [
            SegmentedControlOption(
              value: _Granularity.month,
              label: l10n.reportsPeriodGranularityMonth,
            ),
            SegmentedControlOption(
              value: _Granularity.year,
              label: l10n.reportsPeriodGranularityYear,
            ),
          ],
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          child: Row(
            children: [
              PeriodStepperButton(icon: LucideIcons.chevronLeft, onTap: () => _step(-1)),
              Expanded(
                child: Text(
                  periodLabel,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.titleMedium?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              PeriodStepperButton(icon: LucideIcons.chevronRight, onTap: () => _step(1)),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (_customRangeStillActive)
          InkWell(
            onTap: _openCustomRange,
            borderRadius: BorderRadius.circular(14),
            child: Container(
              padding: const EdgeInsets.symmetric(
                vertical: 12,
                horizontal: 14,
              ),
              decoration: BoxDecoration(
                color: colors.primarySoft,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: colors.primaryOnSoftStrong,
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendarRange,
                    size: 18,
                    color: colors.primaryOnSoft,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          l10n.dateFilterCustomRange,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.titleSmall?.copyWith(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryOnSoftStrong,
                          ),
                        ),
                        const SizedBox(height: 1),
                        Text(
                          ReportsPeriodFormat.rangeCaption(
                            widget.initial.range,
                            locale,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: colors.primaryOnSoftStrong,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Icon(
                    LucideIcons.check,
                    size: 18,
                    color: colors.primaryOnSoft,
                  ),
                ],
              ),
            ),
          )
        else
          InkWell(
            onTap: _openCustomRange,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
              child: Row(
                children: [
                  Icon(
                    LucideIcons.calendarRange,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      l10n.dateFilterCustomRange,
                      style: theme.textTheme.titleSmall?.copyWith(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  Icon(
                    LucideIcons.chevronRight,
                    size: 18,
                    color: colors.textSecondary,
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 16),
        SheetButtonsRow(
          left: OutlinedButton(
            onPressed: _clear,
            child: Text(l10n.reportsPeriodClear),
          ),
          right: FilledButton.icon(
            onPressed: _apply,
            icon: const Icon(LucideIcons.check, size: 18),
            label: Text(l10n.commonApply),
          ),
        ),
      ],
    );
  }
}
