import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/usecases/watch_categories.dart';
import '../../domain/usecases/watch_parent_candidates.dart';
import 'parent_category_picker_state.dart';

/// Drives the category picker sheet (`Q55fEz`) — see
/// [ParentCategoryPickerState] for its two reuse cases.
@injectable
class ParentCategoryPickerCubit extends Cubit<ParentCategoryPickerState> {
  ParentCategoryPickerCubit(
    this._watchParentCandidates,
    this._watchCategories,
  ) : super(const ParentCategoryPickerState());

  final WatchParentCandidates _watchParentCandidates;
  final WatchCategories _watchCategories;

  StreamSubscription<Result<List<Category>>>? _subscription;

  /// [rootsOnly] (default) restricts the list to root categories — the
  /// "Categoría padre" field and the "Reasignar subcategorías" picker both
  /// need this so the 2-level hierarchy limit holds. `false` offers every
  /// active category (root + sub) of [kind], for "Reasignar a otra
  /// categoría" when resolving transactions.
  Future<void> start(
    CategoryKind kind, {
    String? excludingId,
    String? selectedId,
    bool rootsOnly = true,
  }) async {
    await _subscription?.cancel();
    emit(ParentCategoryPickerState(selectedId: selectedId));

    final Stream<Result<List<Category>>> stream = rootsOnly
        ? _watchParentCandidates(kind, excludingId: excludingId)
        : _watchCategories(kind).map(
            (result) => result.map(
              (nodes) => [
                for (final node in nodes) ...[
                  if (node.root.id != excludingId) node.root,
                  ...node.subcategories.where((sub) => sub.id != excludingId),
                ],
              ],
            ),
          );

    _subscription = stream.listen(_onCandidates);
  }

  void _onCandidates(Result<List<Category>> result) {
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: ParentCategoryPickerStatus.failure,
          failure: failure,
        ),
        (candidates) => state.copyWith(
          status: ParentCategoryPickerStatus.ready,
          candidates: candidates,
        ),
      ),
    );
  }

  @override
  Future<void> close() async {
    await _subscription?.cancel();
    return super.close();
  }
}
