import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/debts_summary.dart';
import '../../domain/usecases/watch_debts.dart';
import 'debts_list_state.dart';

/// Drives the debts list (HU-04) and its per-currency summary card.
///
/// Talks only to the `WatchDebts` use case, which already folds the
/// per-currency totals so the anti-cross-currency rule stays in the domain.
@injectable
class DebtsListCubit extends Cubit<DebtsListState> {
  DebtsListCubit(this._watchDebts) : super(const DebtsListState());

  final WatchDebts _watchDebts;

  StreamSubscription<Result<DebtsSummary>>? _subscription;

  /// Subscribes to the stream. Safe to call again to retry after an error.
  Future<void> start() async {
    await _subscription?.cancel();
    emit(const DebtsListState());
    _subscription = _watchDebts().listen(_onSummary);
  }

  void _onSummary(Result<DebtsSummary> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: DebtsListStatus.failure,
          failure: failure,
        ),
        (summary) => state.copyWith(
          status: DebtsListStatus.ready,
          summary: summary,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
