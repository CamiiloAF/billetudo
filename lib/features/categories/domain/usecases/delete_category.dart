import 'package:equatable/equatable.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../repositories/category_repository.dart';

/// What to do with the active transactions that reference the category being
/// deleted (HU-04 case 2). Required whenever
/// `CategoryDeletionImpact.transactionCount > 0`.
sealed class TransactionResolution extends Equatable {
  const TransactionResolution();

  const factory TransactionResolution.none() = NoTransactionResolution;

  const factory TransactionResolution.reassign(String targetCategoryId) =
      ReassignTransactions;

  const factory TransactionResolution.clear() = ClearTransactionCategory;

  @override
  List<Object?> get props => [];
}

/// No resolution supplied. Only valid when there is nothing to resolve.
class NoTransactionResolution extends TransactionResolution {
  const NoTransactionResolution();
}

/// Move every transaction to [targetCategoryId] (must be the same kind).
class ReassignTransactions extends TransactionResolution {
  const ReassignTransactions(this.targetCategoryId);

  final String targetCategoryId;

  @override
  List<Object?> get props => [targetCategoryId];
}

/// Leave every transaction without a category (`categoryId = null`).
class ClearTransactionCategory extends TransactionResolution {
  const ClearTransactionCategory();
}

/// What to do with the active subcategories of a root being deleted (HU-04
/// case 3). Required whenever `CategoryDeletionImpact.hasActiveSubcategories`.
sealed class SubcategoryResolution extends Equatable {
  const SubcategoryResolution();

  const factory SubcategoryResolution.none() = NoSubcategoryResolution;

  const factory SubcategoryResolution.reassign(String targetRootId) =
      ReassignSubcategories;

  const factory SubcategoryResolution.cascade() = CascadeDeleteSubcategories;

  @override
  List<Object?> get props => [];
}

/// No resolution supplied. Only valid when there is nothing to resolve.
class NoSubcategoryResolution extends SubcategoryResolution {
  const NoSubcategoryResolution();
}

/// Move every active subcategory under [targetRootId] (another root of the
/// same kind), then soft-delete the now-childless root.
class ReassignSubcategories extends SubcategoryResolution {
  const ReassignSubcategories(this.targetRootId);

  final String targetRootId;

  @override
  List<Object?> get props => [targetRootId];
}

/// Soft-delete the root and every one of its active subcategories.
class CascadeDeleteSubcategories extends SubcategoryResolution {
  const CascadeDeleteSubcategories();
}

/// HU-04: deletes a category, covering its 3 cases.
///
///  1. No dependents: a plain soft delete (`deletedAt`).
///  2. Active transactions reference it: `transactionResolution` is
///     mandatory, either reassigning them to another category of the same
///     kind or leaving them without one.
///  3. It is a root with active subcategories: `subcategoryResolution` is
///     mandatory, either reassigning them to another root of the same kind
///     or cascading the delete to them.
///
/// Cases 2 and 3 can combine on the same root: both resolutions are required
/// together when both conditions hold. Every delete is logical (`deletedAt`),
/// recoverable from the trash — this feature never writes `tombstonedAt`.
@injectable
class DeleteCategory {
  const DeleteCategory(this._repository);

  static const String transactionResolutionField = 'transactionResolution';
  static const String subcategoryResolutionField = 'subcategoryResolution';
  static const String targetCategoryField = 'targetCategoryId';
  static const String targetRootField = 'targetRootId';

  final CategoryRepository _repository;

  FutureResult<Unit> call(
    String id, {
    TransactionResolution transactionResolution =
        const TransactionResolution.none(),
    SubcategoryResolution subcategoryResolution =
        const SubcategoryResolution.none(),
  }) async {
    final impactResult = await _repository.getDeletionImpact(id);
    if (impactResult case Left(value: final failure)) {
      return Left(failure);
    }
    final impact = impactResult.getOrElse(
      (_) => throw StateError('unreachable: impactResult is Left'),
    );

    final categoryResult = await _repository.getCategory(id);
    if (categoryResult case Left(value: final failure)) {
      return Left(failure);
    }
    final category = categoryResult.getOrElse(
      (_) => throw StateError('unreachable: categoryResult is Left'),
    );

    if (impact.transactionCount > 0) {
      final failure = await _resolveTransactions(
        id,
        category.kind,
        transactionResolution,
      );
      if (failure != null) {
        return Left(failure);
      }
    }

    if (impact.hasActiveSubcategories) {
      return switch (subcategoryResolution) {
        NoSubcategoryResolution() => const Left(
            ValidationFailure(
              'this category has active subcategories; a resolution is '
              'required',
              field: subcategoryResolutionField,
            ),
          ),
        ReassignSubcategories(:final targetRootId) =>
          await _reassignSubcategoriesThenDelete(
            id,
            category.kind,
            targetRootId,
          ),
        CascadeDeleteSubcategories() =>
          await _repository.cascadeDeleteCategory(id),
      };
    }

    return _repository.softDeleteCategory(id);
  }

  /// `null` on success; the [Failure] to return otherwise.
  Future<Failure?> _resolveTransactions(
    String id,
    CategoryKind kind,
    TransactionResolution resolution,
  ) async {
    switch (resolution) {
      case NoTransactionResolution():
        return const ValidationFailure(
          'this category has associated transactions; a resolution is '
          'required',
          field: transactionResolutionField,
        );
      case ReassignTransactions(:final targetCategoryId):
        if (targetCategoryId == id) {
          return const ValidationFailure(
            'cannot reassign transactions to the category being deleted',
            field: targetCategoryField,
          );
        }
        final targetResult = await _repository.getCategory(targetCategoryId);
        if (targetResult case Left(value: final failure)) {
          return failure is NotFoundFailure
              ? const ValidationFailure(
                  'target category does not exist',
                  field: targetCategoryField,
                )
              : failure;
        }
        final target = targetResult.getOrElse(
          (_) => throw StateError('unreachable: targetResult is Left'),
        );
        if (target.kind != kind) {
          return const ValidationFailure(
            'target category must have the same kind',
            field: targetCategoryField,
          );
        }
        final reassignResult = await _repository.reassignTransactions(
          id,
          targetCategoryId,
        );
        return reassignResult.fold((failure) => failure, (_) => null);
      case ClearTransactionCategory():
        final clearResult = await _repository.clearTransactionCategory(id);
        return clearResult.fold((failure) => failure, (_) => null);
    }
  }

  FutureResult<Unit> _reassignSubcategoriesThenDelete(
    String id,
    CategoryKind kind,
    String targetRootId,
  ) async {
    if (targetRootId == id) {
      return const Left(
        ValidationFailure(
          'cannot reassign subcategories to the category being deleted',
          field: targetRootField,
        ),
      );
    }
    final targetResult = await _repository.getCategory(targetRootId);
    if (targetResult case Left(value: final failure)) {
      return Left(
        failure is NotFoundFailure
            ? const ValidationFailure(
                'target root category does not exist',
                field: targetRootField,
              )
            : failure,
      );
    }
    final target = targetResult.getOrElse(
      (_) => throw StateError('unreachable: targetResult is Left'),
    );
    if (!target.isRoot) {
      return const Left(
        ValidationFailure(
          'the target must be a root category',
          field: targetRootField,
        ),
      );
    }
    if (target.kind != kind) {
      return const Left(
        ValidationFailure(
          'the target root must have the same kind',
          field: targetRootField,
        ),
      );
    }

    final reassignResult = await _repository.reassignSubcategories(
      id,
      targetRootId,
    );
    if (reassignResult case Left(value: final failure)) {
      return Left(failure);
    }
    return _repository.softDeleteCategory(id);
  }
}
