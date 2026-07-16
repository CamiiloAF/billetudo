import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart' show CategoryKind;
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/domain/usecases/watch_categories.dart';

enum CategoryFilterStatus { loading, ready, failure }

/// HU-06's category filter sheet: both trees (income and expense) plus the
/// pending selection, edited freely and only handed back on "Aplicar".
class CategoryFilterState extends Equatable {
  CategoryFilterState({
    this.status = CategoryFilterStatus.loading,
    this.expenseNodes = const <CategoryNode>[],
    this.incomeNodes = const <CategoryNode>[],
    Set<String> selected = const <String>{},
    this.failure,
  }) : selected = Set.unmodifiable(selected);

  final CategoryFilterStatus status;
  final List<CategoryNode> expenseNodes;
  final List<CategoryNode> incomeNodes;

  /// Empty means "all categories" (HU-06).
  final Set<String> selected;

  final Failure? failure;

  CategoryFilterState copyWith({
    CategoryFilterStatus? status,
    List<CategoryNode>? expenseNodes,
    List<CategoryNode>? incomeNodes,
    Set<String>? selected,
    Failure? failure,
  }) =>
      CategoryFilterState(
        status: status ?? this.status,
        expenseNodes: expenseNodes ?? this.expenseNodes,
        incomeNodes: incomeNodes ?? this.incomeNodes,
        selected: selected ?? this.selected,
        failure: failure,
      );

  @override
  List<Object?> get props =>
      [status, expenseNodes, incomeNodes, selected, failure];
}

/// Drives the category filter sheet: the symmetric root/subcategory toggle of
/// HU-06 over both the income and expense trees at once.
@injectable
class CategoryFilterCubit extends Cubit<CategoryFilterState> {
  CategoryFilterCubit(this._watchCategories) : super(CategoryFilterState());

  final WatchCategories _watchCategories;

  StreamSubscription<Result<List<CategoryNode>>>? _expenseSubscription;
  StreamSubscription<Result<List<CategoryNode>>>? _incomeSubscription;

  Future<void> start(Set<String> initialSelected) async {
    await _cancelSubscriptions();
    emit(CategoryFilterState(selected: initialSelected));
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
