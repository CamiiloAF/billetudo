import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/cashflow_series.dart';
import '../entities/date_range.dart';
import '../repositories/reports_repository.dart';

/// HU-01: flujo de caja over `range`, with the "movimientos de deuda" toggle.
@injectable
class WatchCashflowReport {
  const WatchCashflowReport(this._repository);

  final ReportsRepository _repository;

  Stream<Result<CashflowSeries>> call(WatchCashflowReportParams params) =>
      _repository.watchCashflow(
        range: params.range,
        includeDebtMovements: params.includeDebtMovements,
      );
}

class WatchCashflowReportParams extends Equatable {
  const WatchCashflowReportParams({
    required this.range,
    this.includeDebtMovements = true,
  });

  final DateRange range;

  /// Default `true` = integrated (HU-01 default). `false` segregates
  /// movimientos de deuda into their own series without hiding or altering
  /// the total.
  final bool includeDebtMovements;

  @override
  List<Object?> get props => [range, includeDebtMovements];
}
