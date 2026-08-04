import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/category_breakdown.dart';

enum CategoryBreakdownStatus { loading, ready, failure }

/// State of the Categorías tab (HU-03): the flat top-level breakdown as
/// `WatchCategoryBreakdownReport` produced it — no in-place expand/collapse
/// state (`A3zxf`: the desglose is a flat list, no accordion).
class CategoryBreakdownState extends Equatable {
  const CategoryBreakdownState({
    this.status = CategoryBreakdownStatus.loading,
    this.breakdown,
    this.failure,
  });

  final CategoryBreakdownStatus status;
  final CategoryBreakdown? breakdown;
  final Failure? failure;

  bool get isLoading => status == CategoryBreakdownStatus.loading;

  CategoryBreakdownState copyWith({
    CategoryBreakdownStatus? status,
    CategoryBreakdown? breakdown,
    Failure? failure,
  }) =>
      CategoryBreakdownState(
        status: status ?? this.status,
        breakdown: breakdown ?? this.breakdown,
        failure: failure,
      );

  @override
  List<Object?> get props => [status, breakdown, failure];
}
