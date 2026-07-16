import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../entities/category_draft.dart';
import '../repositories/category_repository.dart';

/// HU-03: renames a category, changes its icon/color, or moves a
/// subcategory to another root parent of the same kind.
///
/// Never touches `Transactions.categoryId`: transactions stay linked by id,
/// so nothing here needs to know they exist. Two kind-change rules are
/// enforced because a mismatch would break the coherence between a category
/// and the subcategories/transactions that assume its `kind`:
///  - A subcategory always inherits its parent's kind; it can never change
///    its own.
///  - A root category can only change kind while it has no active
///    subcategories (they would otherwise disagree with their parent).
@injectable
class UpdateCategory {
  const UpdateCategory(this._repository);

  final CategoryRepository _repository;

  FutureResult<Category> call(CategoryDraft draft) async {
    final id = draft.id;
    if (id == null) {
      return const Left(
        ValidationFailure(
          'cannot update a category without an id',
          field: CategoryDraft.fieldId,
        ),
      );
    }

    final validated = draft.validated();
    if (validated case Left(value: final failure)) {
      return Left(failure);
    }
    final normalized = validated.getOrElse(
      (_) => throw StateError('unreachable: validated() returned Left'),
    );

    final currentResult = await _repository.getCategory(id);
    if (currentResult case Left(value: final failure)) {
      return Left(failure);
    }
    final current = currentResult.getOrElse(
      (_) => throw StateError('unreachable: currentResult is Left'),
    );

    return current.isRoot
        ? _updateRoot(id, current, normalized)
        : _updateSubcategory(id, current, normalized);
  }

  FutureResult<Category> _updateSubcategory(
    String id,
    Category current,
    CategoryDraft normalized,
  ) async {
    if (normalized.parentId == null) {
      return const Left(
        ValidationFailure(
          'a subcategory cannot become a root category',
          field: CategoryDraft.fieldParentId,
        ),
      );
    }
    if (normalized.kind != current.kind) {
      return const Left(
        ValidationFailure(
          'a subcategory cannot change its kind: it always inherits its '
          "parent's",
          field: CategoryDraft.fieldKind,
        ),
      );
    }

    if (normalized.parentId != current.parentId) {
      final validation = await _validateNewParent(
        normalized.parentId!,
        expectedKind: current.kind,
      );
      if (validation != null) {
        return Left(validation);
      }
    }

    return _repository.updateCategory(
      CategoryDraft(
        id: id,
        name: normalized.name,
        kind: current.kind,
        parentId: normalized.parentId,
        icon: normalized.icon,
        color: normalized.color,
      ),
    );
  }

  FutureResult<Category> _updateRoot(
    String id,
    Category current,
    CategoryDraft normalized,
  ) async {
    if (normalized.parentId != null) {
      return const Left(
        ValidationFailure(
          'a root category cannot become a subcategory',
          field: CategoryDraft.fieldParentId,
        ),
      );
    }

    if (normalized.kind != current.kind) {
      final impactResult = await _repository.getDeletionImpact(id);
      if (impactResult case Left(value: final failure)) {
        return Left(failure);
      }
      final impact = impactResult.getOrElse(
        (_) => throw StateError('unreachable: impactResult is Left'),
      );
      if (impact.hasActiveSubcategories) {
        return const Left(
          ValidationFailure(
            'cannot change the type of a category that has active '
            'subcategories',
            field: CategoryDraft.fieldKind,
          ),
        );
      }
    }

    return _repository.updateCategory(
      CategoryDraft(
        id: id,
        name: normalized.name,
        kind: normalized.kind,
        icon: normalized.icon,
        color: normalized.color,
      ),
    );
  }

  /// `null` when the target is a valid new root parent; a [Failure]
  /// otherwise.
  Future<Failure?> _validateNewParent(
    String targetParentId, {
    required CategoryKind expectedKind,
  }) async {
    final result = await _repository.getCategory(targetParentId);
    return result.fold(
      (failure) => failure is NotFoundFailure
          ? const ValidationFailure(
              'parent category does not exist',
              field: CategoryDraft.fieldParentId,
            )
          : failure,
      (parent) {
        if (!parent.isRoot) {
          return const ValidationFailure(
            'the new parent must be a root category',
            field: CategoryDraft.fieldParentId,
          );
        }
        if (parent.kind != expectedKind) {
          return const ValidationFailure(
            'the new parent must have the same kind',
            field: CategoryDraft.fieldParentId,
          );
        }
        return null;
      },
    );
  }
}
