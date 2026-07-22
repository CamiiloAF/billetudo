import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/usecases/get_category.dart';
import '../../../categories/domain/usecases/get_most_used_categories.dart';
import 'category_quick_picker_state.dart';

/// Drives the transaction form's Category Quick Picker (HU-01/02): loads the
/// most-used categories of the active kind and keeps the selection resolved as
/// a full entity so its chip can render even when it isn't among the top 3.
///
/// Talks only to use cases, same pattern as `CategoryFilterCubit`. Selection
/// is owned by the form (`TransactionFormCubit`); this cubit only mirrors it
/// so the picker can render, via [select] for chips/sheet returns we already
/// hold and [syncSelection] for an id coming from outside (edit-load, kind
/// switch).
@injectable
class CategoryQuickPickerCubit extends Cubit<CategoryQuickPickerState> {
  CategoryQuickPickerCubit(this._getMostUsedCategories, this._getCategory)
      : super(const CategoryQuickPickerState());

  final GetMostUsedCategories _getMostUsedCategories;
  final GetCategory _getCategory;

  CategoryKind _kind = CategoryKind.expense;
  String? _accountId;

  /// Loads the most-used categories for [kind]/[accountId] and resolves
  /// [selectedId].
  Future<void> start({
    required CategoryKind kind,
    String? selectedId,
    String? accountId,
  }) async {
    _kind = kind;
    _accountId = accountId;
    emit(const CategoryQuickPickerState());
    await _loadMostUsed();
    await syncSelection(selectedId);
  }

  /// Reacts to the Segmento Gasto/Ingreso switching: reloads the most-used set
  /// for the new kind. A no-op when the kind is unchanged.
  Future<void> setKind(CategoryKind kind, {String? selectedId}) async {
    if (kind == _kind) {
      return;
    }
    await start(kind: kind, selectedId: selectedId, accountId: _accountId);
  }

  /// Reacts to the form's account switching: reloads the most-used set scoped
  /// to the new account, without touching the current selection — a category
  /// already picked stays selected (as the extra chip, via [syncSelection]'s
  /// existing fallback) even if it isn't in the new account's top-3. A no-op
  /// when the account is unchanged.
  Future<void> setAccount(String? accountId) async {
    if (accountId == _accountId) {
      return;
    }
    _accountId = accountId;
    await _loadMostUsed();
  }

  /// The user picked a category we already hold (a chip, or the select sheet's
  /// return value): set it directly, no fetch needed.
  void select(Category category) => emit(state.copyWith(selected: category));

  /// Reconciles the selection with an id owned elsewhere (the form state):
  /// clears it when `null`, keeps it when unchanged, otherwise resolves it
  /// from the most-used set or a one-shot fetch (e.g. editing a transaction
  /// whose category isn't among the top 3).
  Future<void> syncSelection(String? id) async {
    if (id == null) {
      if (state.selected != null) {
        emit(state.copyWith(clearSelected: true));
      }
      return;
    }
    if (state.selected?.id == id) {
      return;
    }
    for (final category in state.mostUsed) {
      if (category.id == id) {
        emit(state.copyWith(selected: category));
        return;
      }
    }
    final result = await _getCategory(id);
    if (isClosed) {
      return;
    }
    if (result case Right(value: final category)) {
      emit(state.copyWith(selected: category));
    }
  }

  Future<void> _loadMostUsed() async {
    final result = await _getMostUsedCategories(_kind, accountId: _accountId);
    if (isClosed) {
      return;
    }
    emit(
      result.fold(
        (failure) => state.copyWith(
          status: CategoryQuickPickerStatus.failure,
          failure: failure,
        ),
        (categories) => state.copyWith(
          status: CategoryQuickPickerStatus.ready,
          mostUsed: categories,
        ),
      ),
    );
  }
}
