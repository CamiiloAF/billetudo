import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../cubit/transactions_list_cubit.dart';
import '../cubit/transactions_list_state.dart';
import '../widgets/sheets/unified_filters_sheet.dart';

/// Opens `UnifiedFiltersSheet` seeded with [state]'s current filter and, if
/// the user applies it, merges the result back into `TransactionsListCubit`.
/// The only trigger in production is `FiltersButton` in
/// `TransactionsSearchRow` — the `FilterChipPill` "Chip Fecha" that used to
/// share it was removed on 2026-11-07 (the always-visible `PeriodStepper`
/// already names the period). Everything but cuenta lives in this sheet; see
/// `unified_filters_sheet.dart`.
Future<void> openUnifiedFiltersSheet(
  BuildContext context,
  TransactionsListState state,
) async {
  final cubit = context.read<TransactionsListCubit>();
  final filter = state.filter;
  final result = await UnifiedFiltersSheet.show(
    context,
    initialFilter: filter,
    budgetOptions: state.budgetOptions,
  );
  // Null means the sheet was dismissed without "Aplicar"/"Limpiar" — keep the
  // current filter.
  if (result != null) {
    await cubit.updateFilter(
      filter.copyWith(
        datePeriod: result.datePeriod,
        budgetPeriod: result.budgetPeriod,
        clearBudgetPeriod: result.budgetPeriod == null,
        types: result.types,
        categoryIds: result.categoryIds,
        tagIds: result.tagIds,
      ),
    );
  }
}
