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
      _repository.watchCategoryBreakdown(range: params.range);
}

class WatchCategoryBreakdownReportParams extends Equatable {
  const WatchCategoryBreakdownReportParams({required this.range});

  final DateRange range;

  @override
  List<Object?> get props => [range];
}
