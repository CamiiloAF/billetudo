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
        accountIds: params.accountIds,
      );
}

class WatchNetWorthReportParams extends Equatable {
  const WatchNetWorthReportParams({
    required this.range,
    this.includeArchivedAccounts = false,
    this.accountIds = const <String>{},
  });

  final DateRange range;

  /// Default `false` (HU-02 default: archived accounts excluded).
  final bool includeArchivedAccounts;

  /// Gráficas' cuentas filter (criterion 5): inclusive-empty, scopes only
  /// the líquido side — the deuda side always stays fully included
  /// (criterion 6), regardless of this set.
  final Set<String> accountIds;

  @override
  List<Object?> get props => [range, includeArchivedAccounts, accountIds];
}
