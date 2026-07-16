import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/date_period_filter.dart';

/// HU-06b's date filter state: always a bounded period, never "no filter".
class DateFilterState extends Equatable {
  DateFilterState({DatePeriodFilter? filter})
      : filter = filter ?? DatePeriodFilter.thisMonth();

  final DatePeriodFilter filter;

  @override
  List<Object?> get props => [filter];
}

/// Drives HU-06b's date filter: the granularity stepper applies immediately;
/// a custom range only takes effect once the caller confirms it with
/// "Aplicar" (this cubit's [applyCustomRange]), and its "X" always lands back
/// on "Este mes" — there is no bare "no filter" state.
@injectable
class DateFilterCubit extends Cubit<DateFilterState> {
  DateFilterCubit() : super(DateFilterState());

  void start(DatePeriodFilter initial) =>
      emit(DateFilterState(filter: initial));

  /// HU-06b: the granularity segmented control applies immediately.
  void granularitySelected(DateGranularity granularity) =>
      emit(DateFilterState(filter: state.filter.withGranularity(granularity)));

  /// HU-06b: one step per tap, applied immediately.
  void step(int direction) =>
      emit(DateFilterState(filter: state.filter.stepped(direction)));

  /// HU-06b: only takes effect when the sheet's "Aplicar" calls this.
  void applyCustomRange({required DateTime start, required DateTime end}) =>
      emit(
        DateFilterState(
          filter: DatePeriodFilter.custom(start: start, end: end),
        ),
      );

  /// HU-06b: the custom range's "X" — back to "Este mes", never to a bare
  /// "no filter".
  void clearToThisMonth() =>
      emit(DateFilterState(filter: DatePeriodFilter.clearedToThisMonth()));
}
