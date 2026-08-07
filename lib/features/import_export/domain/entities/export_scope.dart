import 'package:equatable/equatable.dart';

import 'import_entry_type.dart';

/// A self-contained mirror of Transacciones' `TransactionFilter` (HU-01:
/// "reutiliza los filtros de `03-transacciones.md` HU-06"). Declared locally,
/// not imported from `features/transactions/domain`, to keep this feature's
/// domain free of cross-feature dependencies (no other feature does it
/// either) — `presentation/` is what actually reuses the Transacciones filter
/// sheets and translates their state into this shape.
class TransactionExportFilter extends Equatable {
  const TransactionExportFilter({
    this.accountIds = const <String>{},
    this.categoryIds = const <String>{},
    this.types = const <ImportEntryType>{},
    this.tagIds = const <String>{},
    this.searchText = '',
    this.startDate,
    this.endDate,
  });

  final Set<String> accountIds;
  final Set<String> categoryIds;
  final Set<ImportEntryType> types;
  final Set<String> tagIds;
  final String searchText;

  /// Inclusive range, date-only. Both `null` when [ExportScope.allHistory] is
  /// set on the containing scope.
  final DateTime? startDate;
  final DateTime? endDate;

  TransactionExportFilter copyWith({
    Set<String>? accountIds,
    Set<String>? categoryIds,
    Set<ImportEntryType>? types,
    Set<String>? tagIds,
    String? searchText,
    DateTime? startDate,
    DateTime? endDate,
  }) =>
      TransactionExportFilter(
        accountIds: accountIds ?? this.accountIds,
        categoryIds: categoryIds ?? this.categoryIds,
        types: types ?? this.types,
        tagIds: tagIds ?? this.tagIds,
        searchText: searchText ?? this.searchText,
        startDate: startDate ?? this.startDate,
        endDate: endDate ?? this.endDate,
      );

  @override
  List<Object?> get props => [
        accountIds,
        categoryIds,
        types,
        tagIds,
        searchText,
        startDate,
        endDate,
      ];
}

/// What to export in one HU-01/HU-02 flow: any combination of transactions,
/// accounts and categories. More than one selected bundles into a `.zip`
/// (HU-02); exactly one exports a bare `.csv`.
class ExportScope extends Equatable {
  const ExportScope({
    this.includeTransactions = true,
    this.includeAccounts = false,
    this.includeCategories = false,
    this.transactionFilter = const TransactionExportFilter(),
    this.allHistory = false,
  });

  final bool includeTransactions;
  final bool includeAccounts;
  final bool includeCategories;

  /// Ignored entirely when [includeTransactions] is `false`.
  final TransactionExportFilter transactionFilter;

  /// HU-01: ignores `TransactionExportFilter.startDate`/`endDate` and exports
  /// every transaction regardless of the active date filter.
  final bool allHistory;

  bool get selectionCount =>
      includeTransactions || includeAccounts || includeCategories;

  bool get bundlesIntoZip =>
      [includeTransactions, includeAccounts, includeCategories]
          .where((selected) => selected)
          .length >
      1;

  @override
  List<Object?> get props => [
        includeTransactions,
        includeAccounts,
        includeCategories,
        transactionFilter,
        allHistory,
      ];
}
