import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/date_range.dart';
import '../../domain/usecases/watch_category_breakdown_report.dart';
import 'category_breakdown_state.dart';

/// Drives the Categorías tab (HU-03). Talks only to
/// [WatchCategoryBreakdownReport] — the desglose is a flat list (`A3zxf`), so
/// there is no expand/collapse presentation state to own here.
@injectable
class CategoryBreakdownCubit extends Cubit<CategoryBreakdownState> {
  CategoryBreakdownCubit(this._watchCategoryBreakdownReport)
      : super(const CategoryBreakdownState());

  final WatchCategoryBreakdownReport _watchCategoryBreakdownReport;

  StreamSubscription<dynamic>? _subscription;

  Future<void> load({required DateRange range}) async {
    await _subscription?.cancel();
    emit(const CategoryBreakdownState());
    _subscription = _watchCategoryBreakdownReport(
      WatchCategoryBreakdownReportParams(range: range),
    ).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: CategoryBreakdownStatus.failure,
            failure: failure,
          ),
          (breakdown) => state.copyWith(
            status: CategoryBreakdownStatus.ready,
            breakdown: breakdown,
          ),
        ),
      );
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
