import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/theme/app_theme.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/date_range_picker_sheet.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../../../../core/widgets/sheet_head.dart';
import '../../../domain/entities/date_period_filter.dart';
import '../../cubit/date_filter_cubit.dart';
import '../../utils/date_period_label.dart';

/// HU-06b's date filter sheet: the granularity segmented control, stepper and
/// custom range are edited against a local working copy ([DateFilterCubit]);
/// nothing touches the list until the footer's "Aplicar" pops with the
/// selection. "Limpiar" resets the working copy back to "Este mes".
class DateFilterSheet extends StatelessWidget {
  const DateFilterSheet({required this.initial, super.key});

  final DatePeriodFilter initial;

  /// Resolves to the [DatePeriodFilter] the user confirmed with "Aplicar", or
  /// `null` when the sheet is dismissed/cancelled without applying (the caller
  /// keeps its current filter).
  static Future<DatePeriodFilter?> show(
    BuildContext context, {
    required DatePeriodFilter initial,
  }) async {
    final cubit = getIt<DateFilterCubit>()..start(initial);
    final applied = await BottomSheetBase.show<DatePeriodFilter>(
      context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: const DateFilterSheetBody(),
      ),
    );
    await cubit.close();
    return applied;
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (context) => getIt<DateFilterCubit>()..start(initial),
      child: const DateFilterSheetBody(),
    );
  }
}

class DateFilterSheetBody extends StatelessWidget {
  const DateFilterSheetBody({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    return BlocBuilder<DateFilterCubit, DateFilterState>(
      builder: (context, state) {
        final cubit = context.read<DateFilterCubit>();
        final filter = state.filter;
        final isCustom = filter.isCustomRange;
        // When a custom range is active the granularity block is inert: it
        // stays visible but dimmed (0.4) and swallows taps, showing the "Este
        // mes" defaults instead of the null granularity a custom filter holds.
        final granularityView =
            isCustom ? DatePeriodFilter.thisMonth() : filter;
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // A sheet title is 17/700 in billetudo.pen (`ElVUc` in `jpARf`),
            // which is what `SheetHead` renders.
            SheetHead(title: l10n.dateFilterSheetTitle),
            const SizedBox(height: 16),
            IgnorePointer(
              ignoring: isCustom,
              child: Opacity(
                opacity: isCustom ? 0.4 : 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    SegmentedButton<DateGranularity>(
                      segments: [
                        ButtonSegment(
                          value: DateGranularity.week,
                          label: Text(l10n.dateFilterWeek),
                        ),
                        ButtonSegment(
                          value: DateGranularity.month,
                          label: Text(l10n.dateFilterMonth),
                        ),
                        ButtonSegment(
                          value: DateGranularity.year,
                          label: Text(l10n.dateFilterYear),
                        ),
                      ],
                      selected: {granularityView.granularity!},
                      onSelectionChanged: (selection) =>
                          cubit.granularitySelected(selection.first),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        IconButton(
                          onPressed: () => cubit.step(-1),
                          icon: const Icon(LucideIcons.chevronLeft),
                        ),
                        Text(datePeriodLabel(granularityView)),
                        IconButton(
                          onPressed: () => cubit.step(1),
                          icon: const Icon(LucideIcons.chevronRight),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            DateFilterCustomRangeRow(
              selected: isCustom,
              label: isCustom
                  ? l10n.dateFilterRangeLabel(
                      DateFormat.yMMMd('es_CO').format(filter.start),
                      DateFormat.yMMMd('es_CO').format(
                        filter.endExclusive.subtract(const Duration(days: 1)),
                      ),
                    )
                  : l10n.dateFilterCustomRange,
              onTap: () => _pickCustomRange(context, cubit, filter),
            ),
            const SizedBox(height: 16),
            SheetButtonsRow(
              left: OutlinedButton(
                onPressed: cubit.clearToThisMonth,
                child: Text(l10n.commonClear),
              ),
              right: FilledButton(
                onPressed: () => Navigator.of(context).pop(cubit.state.filter),
                child: Text(l10n.commonApply),
              ),
            ),
          ],
        );
      },
    );
  }

  Future<void> _pickCustomRange(
    BuildContext context,
    DateFilterCubit cubit,
    DatePeriodFilter filter,
  ) async {
    final now = DateTime.now();
    final initialStart = filter.isCustomRange ? filter.start : now;
    final initialEnd = filter.isCustomRange
        ? filter.endExclusive.subtract(const Duration(days: 1))
        : now;
    final range = await DateRangePickerSheet.show(
      context,
      initialStart: initialStart,
      initialEnd: initialEnd,
    );
    if (range == null) {
      return;
    }
    cubit.applyCustomRange(start: range.start, end: range.end);
  }
}

/// The "Rango personalizado" row: a plain entry that opens the range picker
/// when granularity is active, and — once a custom range is the working
/// selection — the highlighted block (`$primary-soft` fill, `$primary` border,
/// the range dates and a `check`) that reads as the chosen mode.
class DateFilterCustomRangeRow extends StatelessWidget {
  const DateFilterCustomRangeRow({
    required this.selected,
    required this.label,
    required this.onTap,
    super.key,
  });

  final bool selected;

  /// "Rango personalizado" when unselected, or the formatted range dates when
  /// selected. Already localized.
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final accent = selected ? colors.primary : colors.textSecondary;
    return Material(
      color: selected ? colors.primarySoft : Colors.transparent,
      borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
            border: Border.all(
              color: selected ? colors.primary : colors.border,
            ),
          ),
          child: Row(
            children: [
              Icon(LucideIcons.calendarRange, size: 18, color: accent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
              ),
              if (selected) ...[
                const SizedBox(width: 10),
                Icon(LucideIcons.check, size: 18, color: colors.primary),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
