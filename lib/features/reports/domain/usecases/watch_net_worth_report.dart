import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/date_range.dart';
import '../entities/net_worth_series.dart';
import '../repositories/reports_repository.dart';

/// HU-02: patrimonio (líquido vs. total) over `range`, with the "incluir
/// cuentas archivadas" toggle.
@injectable
class WatchNetWorthReport {
  const WatchNetWorthReport(this._repository);

  final ReportsRepository _repository;

  Stream<Result<NetWorthSeries>> call(WatchNetWorthReportParams params) =>
      _repository.watchNetWorth(
        range: params.range,
        includeArchivedAccounts: params.includeArchivedAccounts,
      );
}

class WatchNetWorthReportParams extends Equatable {
  const WatchNetWorthReportParams({
    required this.range,
    this.includeArchivedAccounts = false,
  });

  final DateRange range;

  /// Default `false` (HU-02 default: archived accounts excluded).
  final bool includeArchivedAccounts;

  @override
  List<Object?> get props => [range, includeArchivedAccounts];
}
