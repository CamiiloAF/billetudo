import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../domain/entities/date_period_filter.dart';
import '../../cubit/date_filter_cubit.dart';

/// HU-06b's date filter sheet: the granularity segmented control and stepper
/// apply immediately (delegated straight to [DateFilterCubit]); a custom
/// range only takes effect once the user confirms it in the native date range
/// picker, and its "X" always lands back on "Este mes".
class DateFilterSheet extends StatelessWidget {
  const DateFilterSheet({required this.initial, super.key});

  final DatePeriodFilter initial;

  /// Resolves to the applied [DatePeriodFilter] once the sheet is dismissed.
  /// Never `null`: HU-06b has no "no filter" state to fall back to.
  static Future<DatePeriodFilter> show(
    BuildContext context, {
    required DatePeriodFilter initial,
  }) async {
    final cubit = getIt<DateFilterCubit>()..start(initial);
    await BottomSheetBase.show<void>(
      context,
      builder: (context) => BlocProvider.value(
        value: cubit,
        child: const DateFilterSheetBody(),
      ),
    );
    final result = cubit.state.filter;
    await cubit.close();
    return result;
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
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    l10n.dateFilterSheetTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                if (filter.isCustomRange)
                  IconButton(
                    onPressed: cubit.clearToThisMonth,
                    icon: const Icon(LucideIcons.x),
                  ),
              ],
            ),
            if (!filter.isCustomRange) ...[
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
                selected: {filter.granularity!},
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
                  Text(DateFormat.yMMMd('es_CO').format(filter.start)),
                  IconButton(
                    onPressed: () => cubit.step(1),
                    icon: const Icon(LucideIcons.chevronRight),
                  ),
                ],
              ),
            ] else
              Text(
                l10n.dateFilterRangeLabel(
                  DateFormat.yMMMd('es_CO').format(filter.start),
                  DateFormat.yMMMd('es_CO').format(
                    filter.endExclusive.subtract(const Duration(days: 1)),
                  ),
                ),
              ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => _pickCustomRange(context, cubit, filter),
              child: Text(l10n.dateFilterCustomRange),
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
    final range = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 5),
      lastDate: DateTime(now.year + 5),
      initialDateRange: filter.isCustomRange
          ? DateTimeRange(
              start: filter.start,
              end: filter.endExclusive.subtract(const Duration(days: 1)),
            )
          : null,
    );
    if (range == null) {
      return;
    }
    cubit.applyCustomRange(start: range.start, end: range.end);
  }
}
