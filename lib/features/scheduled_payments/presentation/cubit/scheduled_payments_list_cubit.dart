import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/scheduled_payment_summary.dart';
import '../../domain/usecases/generate_due_scheduled_payments.dart';
import '../../domain/usecases/get_finished_scheduled_payments.dart';
import '../../domain/usecases/get_scheduled_payments.dart';
import 'scheduled_payments_list_state.dart';

/// Drives the "próximos vencimientos" list (HU-04).
///
/// [start] first runs the HU-02 catch-up (idempotent, safe to call every time
/// the screen opens) so anything that vencía while the app was closed lands —
/// generated automatically or accumulated as a pending occurrence — before the
/// list subscribes, so the very first frame is already caught up. It also
/// subscribes to the finished-templates count (feeds the "Terminados · N"
/// pill) so the page never needs a second cubit just for that number.
@injectable
class ScheduledPaymentsListCubit extends Cubit<ScheduledPaymentsListState> {
  ScheduledPaymentsListCubit(
    this._getScheduledPayments,
    this._generateDueScheduledPayments,
    this._getFinishedScheduledPayments,
  ) : super(const ScheduledPaymentsListState());

  final GetScheduledPayments _getScheduledPayments;
  final GenerateDueScheduledPayments _generateDueScheduledPayments;
  final GetFinishedScheduledPayments _getFinishedScheduledPayments;

  StreamSubscription<Result<List<ScheduledPaymentSummary>>>? _subscription;
  StreamSubscription<Result<List<ScheduledPaymentSummary>>>?
      _finishedSubscription;

  Future<void> start() async {
    await _subscription?.cancel();
    await _finishedSubscription?.cancel();
    emit(const ScheduledPaymentsListState());
    await _generateDueScheduledPayments();
    if (isClosed) {
      return;
    }
    _subscription = _getScheduledPayments().listen(_onItems);
    _finishedSubscription =
        _getFinishedScheduledPayments().listen(_onFinishedItems);
  }

  void _onItems(Result<List<ScheduledPaymentSummary>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: ScheduledPaymentsListStatus.failure,
          failure: failure,
        ),
        (items) => state.copyWith(
          status: ScheduledPaymentsListStatus.ready,
          items: items,
        ),
      ),
    );
  }

  void _onFinishedItems(Result<List<ScheduledPaymentSummary>> result) {
    if (isClosed) {
      return;
    }
    result.fold(
      (_) {},
      (items) => emit(state.copyWith(finishedCount: items.length)),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    await _finishedSubscription?.cancel();
    return super.close();
  }
}
