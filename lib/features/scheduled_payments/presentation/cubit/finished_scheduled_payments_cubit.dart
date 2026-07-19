import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/scheduled_payment_summary.dart';
import '../../domain/usecases/get_finished_scheduled_payments.dart';
import 'finished_scheduled_payments_state.dart';

/// Drives the "Terminados" history (HU-04 overflow): templates that no
/// longer generate occurrences, análogo al histórico de Presupuestos.
@injectable
class FinishedScheduledPaymentsCubit
    extends Cubit<FinishedScheduledPaymentsState> {
  FinishedScheduledPaymentsCubit(this._getFinishedScheduledPayments)
      : super(const FinishedScheduledPaymentsState());

  final GetFinishedScheduledPayments _getFinishedScheduledPayments;

  StreamSubscription<Result<List<ScheduledPaymentSummary>>>? _subscription;

  Future<void> start() async {
    await _subscription?.cancel();
    emit(const FinishedScheduledPaymentsState());
    _subscription = _getFinishedScheduledPayments().listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: FinishedScheduledPaymentsStatus.failure,
            failure: failure,
          ),
          (items) => state.copyWith(
            status: FinishedScheduledPaymentsStatus.ready,
            items: items,
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
