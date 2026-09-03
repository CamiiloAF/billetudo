import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../domain/entities/transaction.dart' show TransactionType;

enum CategoryFilterStatus { loading, ready, failure }

/// HU-06's category filter sheet: both trees (income and expense) plus the
/// pending selection, edited freely and only handed back on "Aplicar".
class CategoryFilterState extends Equatable {
  CategoryFilterState({
    this.status = CategoryFilterStatus.loading,
    this.expenseNodes = const <CategoryNode>[],
    this.incomeNodes = const <CategoryNode>[],
    Set<String> selected = const <String>{},
    Set<String> expandedRootIds = const <String>{},
    Set<TransactionType> activeTypes = const <TransactionType>{},
    this.failure,
  })  : selected = Set.unmodifiable(selected),
        expandedRootIds = Set.unmodifiable(expandedRootIds),
        activeTypes = Set.unmodifiable(activeTypes);

  final CategoryFilterStatus status;
  final List<CategoryNode> expenseNodes;
  final List<CategoryNode> incomeNodes;

  /// Empty means "all categories" (HU-06).
  final Set<String> selected;

  /// Which root rows are expanded in the sheet's list (`q0CTl`/`NZbsD`).
  /// Purely a UI concern: never persisted, always starts collapsed.
  final Set<String> expandedRootIds;

  /// Bugfix item 2: the Tipo chip's active selection, passed in so this sheet
  /// only offers categories of a type the user could actually be filtering
  /// for — an income-only or expense-only selection hides the other tree.
  /// Empty means "no type filter", i.e. both trees stay visible.
  final Set<TransactionType> activeTypes;

  final Failure? failure;

  bool isExpanded(String rootId) => expandedRootIds.contains(rootId);

  /// Whether the expense tree should render, given [activeTypes].
  bool get showsExpenseTree =>
      activeTypes.isEmpty || activeTypes.contains(TransactionType.expense);

  /// Whether the income tree should render, given [activeTypes].
  bool get showsIncomeTree =>
      activeTypes.isEmpty || activeTypes.contains(TransactionType.income);

  CategoryFilterState copyWith({
    CategoryFilterStatus? status,
    List<CategoryNode>? expenseNodes,
    List<CategoryNode>? incomeNodes,
    Set<String>? selected,
    Set<String>? expandedRootIds,
    Set<TransactionType>? activeTypes,
    Failure? failure,
  }) =>
      CategoryFilterState(
        status: status ?? this.status,
        expenseNodes: expenseNodes ?? this.expenseNodes,
        incomeNodes: incomeNodes ?? this.incomeNodes,
        selected: selected ?? this.selected,
        expandedRootIds: expandedRootIds ?? this.expandedRootIds,
        activeTypes: activeTypes ?? this.activeTypes,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        expenseNodes,
        incomeNodes,
        selected,
        expandedRootIds,
        activeTypes,
        failure,
      ];
}

/// Drives the category filter sheet: the symmetric root/subcategory toggle of
/// HU-06 over both the income and expense trees at once.
@injectable
class CategoryFilterCubit extends Cubit<CategoryFilterState> {
  CategoryFilterCubit(this._watchCategories) : super(CategoryFilterState());

  final WatchCategories _watchCategories;

  StreamSubscription<Result<List<CategoryNode>>>? _expenseSubscription;
  StreamSubscription<Result<List<CategoryNode>>>? _incomeSubscription;

  Future<void> start(
    Set<String> initialSelected, {
    Set<TransactionType> activeTypes = const <TransactionType>{},
  }) async {
    await _cancelSubscriptions();
    emit(CategoryFilterState(selected: initialSelected, activeTypes: activeTypes));
    _expenseSubscription =
        _watchCategories(CategoryKind.expense).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: CategoryFilterStatus.failure,
            failure: failure,
          ),
          (nodes) => state.copyWith(
            status: CategoryFilterStatus.ready,
            expenseNodes: nodes,
          ),
        ),
      );
    });
    _incomeSubscription =
        _watchCategories(CategoryKind.income).listen((result) {
      if (isClosed) {
        return;
      }
      emit(
        result.fold(
          (failure) => state.copyWith(
            status: CategoryFilterStatus.failure,
            failure: failure,
          ),
          (nodes) => state.copyWith(
            status: CategoryFilterStatus.ready,
            incomeNodes: nodes,
          ),
        ),
      );
    });
  }

  /// HU-06: tapping a root selects/deselects itself and its whole
  /// subcategory tree in one block — the same symmetric rule
  /// `TransactionFilter.toggleRootCategory` enforces on the applied filter.
  void toggleRootCategory(CategoryNode node) {
    final subIds = node.subcategories.map((category) => category.id);
    final wasSelected = state.selected.contains(node.root.id);
    final next = Set<String>.of(state.selected);
    if (wasSelected) {
      next.remove(node.root.id);
      next.removeAll(subIds);
    } else {
      next.add(node.root.id);
      next.addAll(subIds);
    }
    emit(state.copyWith(selected: next));
  }

  /// HU-06: a subcategory toggles on its own, independently of its root and
  /// siblings.
  void toggleSubcategory(String subcategoryId) {
    final next = Set<String>.of(state.selected);
    if (!next.remove(subcategoryId)) {
      next.add(subcategoryId);
    }
    emit(state.copyWith(selected: next));
  }

  /// Expands/collapses [rootId]'s subcategories in the sheet's list — its own
  /// 44x44 tap zone, independent of selecting the root (`q0CTl`/`NZbsD`).
  void toggleExpanded(String rootId) {
    final next = Set<String>.of(state.expandedRootIds);
    if (!next.remove(rootId)) {
      next.add(rootId);
    }
    emit(state.copyWith(expandedRootIds: next));
  }

  /// The header's "Todas": selects every root and subcategory across the
  /// tree(s) currently visible (bugfix item 2 — a hidden tree, e.g. income
  /// while filtering "solo gastos", is left untouched instead of being
  /// selected behind the scenes).
  void selectAll() {
    final next = <String>{};
    for (final node in [
      if (state.showsExpenseTree) ...state.expenseNodes,
      if (state.showsIncomeTree) ...state.incomeNodes,
    ]) {
      next.add(node.root.id);
      next.addAll(node.subcategories.map((category) => category.id));
    }
    emit(state.copyWith(selected: next));
  }

  /// The header's "Ninguna": clears the whole selection.
  void selectNone() => emit(state.copyWith(selected: const <String>{}));

  Future<void> _cancelSubscriptions() async {
    await _expenseSubscription?.cancel();
    await _incomeSubscription?.cancel();
    _expenseSubscription = null;
    _incomeSubscription = null;
  }

  @override
  Future<void> close() async {
    await _cancelSubscriptions();
    return super.close();
  }
}
