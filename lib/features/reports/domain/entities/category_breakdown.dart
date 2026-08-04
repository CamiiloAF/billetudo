import 'package:equatable/equatable.dart';

import 'category_breakdown_item.dart';
import 'date_range.dart';

/// The full estructura de gasto report (HU-03): every root category (and the
/// "Sin categoría" bucket, when non-zero) with an expense in [range], ordered
/// descending by [CategoryBreakdownItem.amountMinor].
class CategoryBreakdown extends Equatable {
  const CategoryBreakdown({
    required this.items,
    required this.totalMinor,
    required this.range,
  });

  final List<CategoryBreakdownItem> items;

  /// Sum of every item's `amountMinor` — the dona's 100%.
  final int totalMinor;

  final DateRange range;

  bool get isEmpty => items.isEmpty;

  @override
  List<Object?> get props => [items, totalMinor, range];
}
