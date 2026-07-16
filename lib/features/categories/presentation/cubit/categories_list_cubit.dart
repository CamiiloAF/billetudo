import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_node.dart';
import '../../domain/usecases/reorder_categories.dart';
import '../../domain/usecases/watch_categories.dart';
import 'categories_list_state.dart';

/// Drives the categories list (HU-05/HU-12): the Toggle Gasto/Ingreso and the
/// accordion (`bA51N`/`vH7RI`/`QZAKU`/`oaBzm`).
///
/// Talks only to use cases, same pattern as `AccountsListCubit`. Expand/
/// collapse is local UI state — it never round-trips through the repository.
@injectable
class CategoriesListCubit extends Cubit<CategoriesListState> {
  CategoriesListCubit(
    this._watchCategories,
    this._reorderCategories,
  ) : super(const CategoriesListState());

  final WatchCategories _watchCategories;
  final ReorderCategories _reorderCategories;

  StreamSubscription<Result<List<CategoryNode>>>? _subscription;

  /// Subscribes to the active kind's stream. Safe to call again to retry
  /// after an error.
  Future<void> start({CategoryKind kind = CategoryKind.expense}) async {
    await _subscription?.cancel();
    emit(CategoriesListState(kind: kind));
    _subscribe(kind);
  }

  void _subscribe(CategoryKind kind) {
    _subscription = _watchCategories(kind).listen(_onNodes);
  }

  void _onNodes(Result<List<CategoryNode>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: CategoriesListStatus.failure,
          failure: failure,
        ),
        (nodes) =>
            state.copyWith(status: CategoriesListStatus.ready, nodes: nodes),
      ),
    );
  }

  /// Switches the Toggle segment (`hFu41`). Resubscribes to the new kind's
  /// stream and resets which rows are expanded — a row expanded under Gasto
  /// says nothing about Ingreso.
  Future<void> selectKind(CategoryKind kind) async {
    if (kind == state.kind) {
      return;
    }
    await _subscription?.cancel();
    emit(CategoriesListState(kind: kind));
    _subscribe(kind);
  }

  /// Expands/collapses a root row (`AnimatedSize`, per the design's pending
  /// interaction note).
  void toggleExpanded(String rootId) {
    final expanded = {...state.expandedRootIds};
    if (!expanded.remove(rootId)) {
      expanded.add(rootId);
    }
    emit(state.copyWith(expandedRootIds: expanded));
  }

  /// HU-05: persists a long-press drag among the root rows, same contract as
  /// `AccountsListCubit.reorder` (`SliverReorderableList.onReorder`'s raw
  /// indices).
  Future<void> reorder(int oldIndex, int newIndex) async {
    if (newIndex == oldIndex ||
        oldIndex >= state.nodes.length ||
        newIndex > state.nodes.length) {
      return;
    }
    if (oldIndex < newIndex) {
      newIndex -= 1;
    }

    final reordered = [...state.nodes];
    final moved = reordered.removeAt(oldIndex);
    reordered.insert(newIndex, moved);
    emit(state.copyWith(nodes: reordered));

    final result = await _reorderCategories(
      [for (final node in reordered) node.root.id],
    );
    if (isClosed) {
      return;
    }
    if (result case Left(value: final failure)) {
      emit(
        state.copyWith(
          status: CategoriesListStatus.failure,
          failure: failure,
        ),
      );
    }
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
