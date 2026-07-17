import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/zero_based_summary.dart';
import '../../domain/usecases/get_zero_based_summary.dart';
import 'zero_based_summary_state.dart';

/// Drives the "Modo sobres" hero on the budgets list (HU-06). Talks only to a
/// use case. On failure it keeps the last good value and simply stops updating —
/// the hero is guidance, never a blocker.
@injectable
class ZeroBasedSummaryCubit extends Cubit<ZeroBasedSummaryState> {
  ZeroBasedSummaryCubit(this._getZeroBasedSummary)
      : super(const ZeroBasedSummaryState());

  final GetZeroBasedSummary _getZeroBasedSummary;

  StreamSubscription<Result<ZeroBasedSummary?>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    _subscription = _getZeroBasedSummary().listen((result) {
      if (isClosed) {
        return;
      }
      result.fold(
        (_) {},
        (summary) => emit(ZeroBasedSummaryState(summary: summary)),
      );
    });
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
