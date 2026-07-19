import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_draft.dart';
import '../../domain/usecases/create_category.dart';
import '../../domain/usecases/delete_category.dart';
import '../../domain/usecases/get_category.dart';
import '../../domain/usecases/get_category_deletion_impact.dart';
import '../../domain/usecases/update_category.dart';
import 'category_form_state.dart';

/// Drives the single add/edit form that covers HU-01/HU-02/HU-03's 4 cases
/// (create root, create subcategory, edit root, edit subcategory) and HU-04's
/// delete flow.
///
/// Only talks to use cases: the Tipo-toggle lock rules and the parentId/kind
/// coherence live in `CreateCategory`/`UpdateCategory`, this cubit just
/// mirrors them into state so the form can render the lock and surface a
/// `ValidationFailure` under the right field.
@injectable
class CategoryFormCubit extends Cubit<CategoryFormState> {
  CategoryFormCubit(
    this._createCategory,
    this._updateCategory,
    this._getCategory,
    this._getDeletionImpact,
    this._deleteCategory,
  ) : super(const CategoryFormState());

  final CreateCategory _createCategory;
  final UpdateCategory _updateCategory;
  final GetCategory _getCategory;
  final GetCategoryDeletionImpact _getDeletionImpact;
  final DeleteCategory _deleteCategory;

  /// Loads the form for one of its 4 cases.
  ///  - `id == null, parentId == null` -> create a root category, with
  ///    [kind] as its starting Tipo (the Toggle segment active on the list
  ///    when the user tapped `+`); defaults to expense.
  ///  - `id == null, parentId != null` -> create a subcategory of
  ///    [parentId] (`STIfS`): the Tipo field is prefilled from the parent
  ///    and locked, same treatment as editing one, since a subcategory's
  ///    kind is never actually chosen by the user (HU-02).
  ///  - `id != null` -> edit that category (root or subcategory); [parentId]
  ///    and [kind] are ignored, the loaded category's own hierarchy wins.
  Future<void> load({
    String? id,
    String? parentId,
    CategoryKind kind = CategoryKind.expense,
  }) async {
    if (id == null) {
      if (parentId == null) {
        emit(CategoryFormState(status: CategoryFormStatus.ready, kind: kind));
        return;
      }
      await _loadForNewSubcategory(parentId);
      return;
    }
    await _loadForEdit(id);
  }

  Future<void> _loadForNewSubcategory(String parentId) async {
    emit(const CategoryFormState());
    final result = await _getCategory(parentId);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          CategoryFormState(status: CategoryFormStatus.failure, failure: failure),
        );
      case Right(value: final parent):
        emit(
          CategoryFormState(
            status: CategoryFormStatus.ready,
            parentId: parent.id,
            parentName: parent.name,
            kind: parent.kind,
            kindLockReason: CategoryKindLockReason.subcategory,
            icon: parent.icon,
            color: parent.color,
          ),
        );
    }
  }

  Future<void> _loadForEdit(String id) async {
    emit(const CategoryFormState());
    final result = await _getCategory(id);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          CategoryFormState(status: CategoryFormStatus.failure, failure: failure),
        );
      case Right(value: final category):
        await _emitFormFor(category);
    }
  }

  Future<void> _emitFormFor(Category category) async {
    if (!category.isRoot) {
      // The parent's own name is not on `category`, only its id: a second
      // read gets it, purely for display in the "Categoría padre" field.
      final parentResult = await _getCategory(category.parentId!);
      if (isClosed) {
        return;
      }
      final parentName = parentResult.fold((_) => null, (parent) => parent.name);

      emit(
        CategoryFormState(
          status: CategoryFormStatus.ready,
          id: category.id,
          parentId: category.parentId,
          parentName: parentName,
          name: category.name,
          icon: category.icon,
          color: category.color,
          kind: category.kind,
          kindLockReason: CategoryKindLockReason.subcategory,
        ),
      );
      return;
    }

    // A root's Tipo only locks conditionally, on whether it currently has
    // active subcategories.
    final impactResult = await _getDeletionImpact(category.id);
    if (isClosed) {
      return;
    }
    final hasActiveSubcategories = impactResult.fold(
      (_) => false,
      (impact) => impact.hasActiveSubcategories,
    );

    emit(
      CategoryFormState(
        status: CategoryFormStatus.ready,
        id: category.id,
        name: category.name,
        icon: category.icon,
        color: category.color,
        kind: category.kind,
        kindLockReason: hasActiveSubcategories
            ? CategoryKindLockReason.rootWithSubcategories
            : CategoryKindLockReason.none,
      ),
    );
  }

  void nameChanged(String value) => emit(state.copyWith(name: value));

  /// Icon is always free to change. Color, however, is locked for
  /// subcategories — it always inherits the parent's, set once in
  /// [_loadForNewSubcategory]/[_emitFormFor] and never overwritten here.
  void appearanceSelected({String? icon, String? color}) => emit(
        state.copyWith(
          icon: icon,
          color: state.isSubcategory ? state.color : color,
        ),
      );

  /// Ignored while [CategoryFormState.kindLocked] — the toggle renders
  /// disabled in that case, but the cubit refuses the write too.
  void kindSelected(CategoryKind kind) {
    if (state.kindLocked) {
      return;
    }
    emit(state.copyWith(kind: kind));
  }

  /// Reclassifies an existing subcategory to another root (HU-03). Only
  /// meaningful while editing a subcategory.
  void parentSelected(Category parent) {
    if (!state.isSubcategory) {
      return;
    }
    emit(state.copyWith(parentId: parent.id, parentName: parent.name));
  }

  Future<void> submit() async {
    final draft = CategoryDraft(
      id: state.id,
      name: state.name,
      kind: state.kind,
      parentId: state.parentId,
      icon: state.icon,
      color: state.color,
    );

    emit(state.copyWith(status: CategoryFormStatus.saving));
    final result = state.isEditing
        ? await _updateCategory(draft)
        : await _createCategory(draft);
    if (isClosed) {
      return;
    }

    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(status: CategoryFormStatus.ready, failure: failure));
      case Right():
        emit(state.copyWith(status: CategoryFormStatus.saved));
    }
  }

  /// HU-04: loads the impact and picks the first sheet to show.
  Future<void> promptDelete() async {
    final id = state.id;
    if (id == null) {
      return;
    }
    final result = await _getDeletionImpact(id);
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(state.copyWith(failure: failure));
      case Right(value: final impact):
        emit(
          state.copyWith(
            deletionImpact: impact,
            deletePrompt: impact.transactionCount > 0
                ? CategoryDeletePrompt.transactions
                : impact.hasActiveSubcategories
                    ? CategoryDeletePrompt.subcategories
                    : CategoryDeletePrompt.simple,
          ),
        );
    }
  }

  void dismissDeletePrompt() => emit(
        state.copyWith(
          deletePrompt: CategoryDeletePrompt.none,
          clearPendingTransactionResolution: true,
        ),
      );

  /// HU-04 case 1: no dependents, nothing to resolve.
  Future<void> confirmSimpleDelete() => _finishDelete();

  /// HU-04 case 2: reassign or leave the associated transactions
  /// uncategorized. When the same root also has active subcategories, this
  /// only stores the answer and steps into [CategoryDeletePrompt.subcategories]
  /// next — the delete only runs once both are resolved.
  Future<void> confirmTransactionResolution(
    TransactionResolution resolution,
  ) async {
    final impact = state.deletionImpact;
    if (impact != null && impact.hasActiveSubcategories) {
      emit(
        state.copyWith(
          pendingTransactionResolution: resolution,
          deletePrompt: CategoryDeletePrompt.subcategories,
        ),
      );
      return;
    }
    await _finishDelete(transactionResolution: resolution);
  }

  /// HU-04 case 3: reassign the active subcategories to another root, or
  /// cascade-delete them together with this root.
  Future<void> confirmSubcategoryResolution(
    SubcategoryResolution resolution,
  ) =>
      _finishDelete(
        transactionResolution:
            state.pendingTransactionResolution ?? const TransactionResolution.none(),
        subcategoryResolution: resolution,
      );

  Future<void> _finishDelete({
    TransactionResolution transactionResolution = const TransactionResolution.none(),
    SubcategoryResolution subcategoryResolution = const SubcategoryResolution.none(),
  }) async {
    final id = state.id;
    if (id == null) {
      return;
    }
    // Clearing deletePrompt here (not just status) matters: `listenWhen`
    // reacts to either field changing, and this `saving` emission changes
    // `status` while leaving a stale `deletePrompt` behind if it isn't reset
    // explicitly. The page's listener would then replay `_handlePrompt` on
    // this transient state and reopen the confirmation sheet a second time —
    // silently, since the user already dismissed the real one by confirming.
    // The eventual `Navigator.pop()` for the real `saved` status then pops
    // that phantom sheet instead of the page, stranding it on the spinner
    // (same failure shape as `AccountDetailCubit._runClosing`, different
    // trigger: no stream involved here, just this method's own two emits).
    emit(
      state.copyWith(
        status: CategoryFormStatus.saving,
        deletePrompt: CategoryDeletePrompt.none,
      ),
    );
    final result = await _deleteCategory(
      id,
      transactionResolution: transactionResolution,
      subcategoryResolution: subcategoryResolution,
    );
    if (isClosed) {
      return;
    }
    switch (result) {
      case Left(value: final failure):
        emit(
          state.copyWith(
            status: CategoryFormStatus.ready,
            deletePrompt: CategoryDeletePrompt.none,
            clearPendingTransactionResolution: true,
            failure: failure,
          ),
        );
      case Right():
        emit(
          state.copyWith(
            status: CategoryFormStatus.saved,
            deletePrompt: CategoryDeletePrompt.none,
          ),
        );
    }
  }
}
