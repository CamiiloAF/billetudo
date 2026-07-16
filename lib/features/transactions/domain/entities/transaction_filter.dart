import 'package:equatable/equatable.dart';

import 'date_period_filter.dart';
import 'transaction.dart';

/// How the results of [TransactionFilter] are ordered (HU-06).
enum TransactionSortOrder { dateDesc, amountDesc }

/// Combinable search + filter criteria for the transaction list (HU-06),
/// persisted across the cubit's lifetime so scrolling/re-emitting never
/// resets them.
///
/// Every `Set` filter is **inclusive-empty**: an empty set means "no filter
/// on this dimension", never "match nothing" — that is what keeps "all
/// accounts"/"all categories"/"all types" the default with no badge shown
/// (HU-06a).
class TransactionFilter extends Equatable {
  TransactionFilter({
    this.searchText = '',
    Set<String> accountIds = const <String>{},
    Set<String> categoryIds = const <String>{},
    Set<TransactionType> types = const <TransactionType>{},
    Set<String> tagIds = const <String>{},
    DatePeriodFilter? datePeriod,
    this.sortOrder = TransactionSortOrder.dateDesc,
  })  : accountIds = Set.unmodifiable(accountIds),
        categoryIds = Set.unmodifiable(categoryIds),
        types = Set.unmodifiable(types),
        tagIds = Set.unmodifiable(tagIds),
        // HU-06b: there is no "no filter" state for dates; default "this
        // month" is always active.
        datePeriod = datePeriod ?? DatePeriodFilter.thisMonth();

  final String searchText;
  final Set<String> accountIds;
  final Set<String> categoryIds;
  final Set<TransactionType> types;

  /// HU-06/HU-07: empty = no tag filter.
  final Set<String> tagIds;

  final DatePeriodFilter datePeriod;
  final TransactionSortOrder sortOrder;

  bool get hasAccountFilter => accountIds.isNotEmpty;
  bool get hasCategoryFilter => categoryIds.isNotEmpty;
  bool get hasTypeFilter => types.isNotEmpty;
  bool get hasTagFilter => tagIds.isNotEmpty;

  TransactionFilter copyWith({
    String? searchText,
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<TransactionType>? types,
    Set<String>? tagIds,
    DatePeriodFilter? datePeriod,
    TransactionSortOrder? sortOrder,
  }) =>
      TransactionFilter(
        searchText: searchText ?? this.searchText,
        accountIds: accountIds ?? this.accountIds,
        categoryIds: categoryIds ?? this.categoryIds,
        types: types ?? this.types,
        tagIds: tagIds ?? this.tagIds,
        datePeriod: datePeriod ?? this.datePeriod,
        sortOrder: sortOrder ?? this.sortOrder,
      );

  /// HU-06 toggle rule: tapping a root category selects/deselects **itself
  /// and its whole subcategory tree** in one block — a symmetric toggle, not
  /// only "select all". [subcategoryIds] are the ids of every subcategory
  /// under [rootId], resolved by the caller (this entity does not know the
  /// category hierarchy).
  TransactionFilter toggleRootCategory({
    required String rootId,
    required Iterable<String> subcategoryIds,
  }) {
    final wasSelected = categoryIds.contains(rootId);
    final next = Set<String>.of(categoryIds);
    if (wasSelected) {
      next.remove(rootId);
      next.removeAll(subcategoryIds);
    } else {
      next.add(rootId);
      next.addAll(subcategoryIds);
    }
    return copyWith(categoryIds: next);
  }

  /// HU-06: a subcategory toggles on its own, independently of its root and
  /// siblings (granular partial selection) — unlike [toggleRootCategory].
  TransactionFilter toggleSubcategory(String subcategoryId) {
    final next = Set<String>.of(categoryIds);
    if (!next.remove(subcategoryId)) {
      next.add(subcategoryId);
    }
    return copyWith(categoryIds: next);
  }

  @override
  List<Object?> get props => [
        searchText,
        accountIds,
        categoryIds,
        types,
        tagIds,
        datePeriod,
        sortOrder,
      ];
}
