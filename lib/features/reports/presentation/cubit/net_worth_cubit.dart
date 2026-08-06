import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../domain/entities/date_range.dart';
import '../../domain/usecases/watch_net_worth_report.dart';
import 'net_worth_state.dart';

/// Drives the Patrimonio tab (HU-02). Talks only to [WatchNetWorthReport].
@injectable
class NetWorthCubit extends Cubit<NetWorthState> {
  NetWorthCubit(this._watchNetWorthReport) : super(const NetWorthState());

  final WatchNetWorthReport _watchNetWorthReport;

  StreamSubscription<dynamic>? _subscription;

  Future<void> load({
    required DateRange range,
    required bool includeArchivedAccounts,
    Set<String> accountIds = const <String>{},
  }) async {
    await _subscription?.cancel();
    emit(const NetWorthState());
    _subscription = _watchNetWorthReport(
      WatchNetWorthReportParams(
        range: range,
        includeArchivedAccounts: includeArchivedAccounts,
        accountIds: accountIds,
      ),
    ).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) =>
              state.copyWith(status: NetWorthStatus.failure, failure: failure),
          (series) =>
              state.copyWith(status: NetWorthStatus.ready, series: series),
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
