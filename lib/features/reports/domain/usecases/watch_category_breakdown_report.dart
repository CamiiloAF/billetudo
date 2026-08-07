import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category_breakdown.dart';
import '../entities/date_range.dart';
import '../repositories/reports_repository.dart';

/// HU-03: estructura de gasto por categoría over `range`. No range limit —
/// the essential set is never recortado por fechas.
@injectable
class WatchCategoryBreakdownReport {
  const WatchCategoryBreakdownReport(this._repository);

  final ReportsRepository _repository;

  Stream<Result<CategoryBreakdown>> call(
    WatchCategoryBreakdownReportParams params,
  ) =>
      _repository.watchCategoryBreakdown(
        range: params.range,
        accountIds: params.accountIds,
      );
}

class WatchCategoryBreakdownReportParams extends Equatable {
  const WatchCategoryBreakdownReportParams({
    required this.range,
    this.accountIds = const <String>{},
  });

  final DateRange range;

  /// Gráficas' cuentas filter (criterion 4): inclusive-empty, default `{}`
  /// = todas las cuentas activas incluidas.
  final Set<String> accountIds;

  @override
  List<Object?> get props => [range, accountIds];
}
