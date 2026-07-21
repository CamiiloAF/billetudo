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

/// Drives HU-06b's date filter as a local working copy: granularity, stepper
/// and custom range all edit this state without touching the list — the sheet
/// only commits the working filter when the user taps "Aplicar". "Limpiar"
/// resets it to "Este mes"; there is no bare "no filter" state.
@injectable
class DateFilterCubit extends Cubit<DateFilterState> {
  DateFilterCubit() : super(DateFilterState());

  void start(DatePeriodFilter initial) =>
      emit(DateFilterState(filter: initial));

  /// Updates the working granularity (committed later via "Aplicar").
  void granularitySelected(DateGranularity granularity) =>
      emit(DateFilterState(filter: state.filter.withGranularity(granularity)));

  /// One step per tap on the working period (committed later via "Aplicar").
  void step(int direction) =>
      emit(DateFilterState(filter: state.filter.stepped(direction)));

  /// Sets the working filter to a custom range (committed later via "Aplicar").
  void applyCustomRange({required DateTime start, required DateTime end}) =>
      emit(
        DateFilterState(
          filter: DatePeriodFilter.custom(start: start, end: end),
        ),
      );

  /// "Limpiar" — reset the working filter to "Este mes", never to a bare
  /// "no filter".
  void clearToThisMonth() =>
      emit(DateFilterState(filter: DatePeriodFilter.clearedToThisMonth()));
}
