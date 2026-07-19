import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../../../core/error/result.dart';
import '../../../../core/l10n/app_locale.dart';
import '../../domain/entities/category.dart';
import '../../domain/entities/category_deletion_impact.dart';
import '../../domain/entities/category_draft.dart';
import '../../domain/entities/category_node.dart';
import '../../domain/repositories/category_repository.dart';
import '../datasources/categories_local_datasource.dart';
import '../datasources/category_seeds_remote_datasource.dart';
import '../models/category_mapper.dart';
import '../models/category_seed_entry.dart';

/// Drift implementation of [CategoryRepository].
///
/// Stamps `updatedAt` on every write (via the mapper's companions). Never
/// writes `tombstonedAt`: see the datasource doc comment for why a plain
/// `deletedAt` trash is enough for this feature.
@LazySingleton(as: CategoryRepository)
class CategoryRepositoryImpl implements CategoryRepository {
  const CategoryRepositoryImpl(this._local, this._remoteSeeds);

  final CategoriesLocalDatasource _local;
  final CategorySeedsRemoteDatasource _remoteSeeds;

  @override
  Stream<Result<List<CategoryNode>>> watchCategories(CategoryKind kind) =>
      _guardStream(
        _local.watchCategories(CategoryMapper.kindToDb(kind)).map(
              (rows) => Right(_groupIntoNodes(rows)),
            ),
      );

  @override
  Stream<Result<List<Category>>> watchParentCandidates(
    CategoryKind kind, {
    String? excludingId,
  }) =>
      _guardStream(
        _local
            .watchParentCandidates(
              CategoryMapper.kindToDb(kind),
              excludingId: excludingId,
            )
            .map(
              (rows) => Right(rows.map(CategoryMapper.toEntity).toList()),
            ),
      );

  @override
  FutureResult<Category> getCategory(String id) => _guard(() async {
        final row = await _local.getCategory(id);
        if (row == null) {
          return Left(NotFoundFailure('category "$id" does not exist'));
        }
        return Right(CategoryMapper.toEntity(row));
      });

  @override
  FutureResult<List<Category>> getMostUsedCategories(
    CategoryKind kind, {
    int limit = 3,
  }) =>
      _guard(() async {
        final rows = await _local.mostUsedCategories(
          CategoryMapper.kindToDb(kind),
          limit,
        );
        return Right(rows.map(CategoryMapper.toEntity).toList());
      });

  @override
  FutureResult<Category> createCategory(CategoryDraft draft) =>
      _guard(() async {
        final now = DateTime.now();
        final dbKind = CategoryMapper.kindToDb(draft.kind);
        final sortOrder = await _local.nextSortOrder(
          dbKind,
          parentId: draft.parentId,
        );
        final row = await _local.insertCategory(
          CategoryMapper.toInsertCompanion(draft,
              sortOrder: sortOrder, now: now),
        );
        return Right(CategoryMapper.toEntity(row));
      });

  @override
  FutureResult<Category> updateCategory(CategoryDraft draft) =>
      _guard(() async {
        final id = draft.id;
        if (id == null) {
          return const Left(
            ValidationFailure(
              'cannot update a category without an id',
              field: CategoryDraft.fieldId,
            ),
          );
        }
        final row = await _local.updateCategory(
          id,
          CategoryMapper.toUpdateCompanion(draft, now: DateTime.now()),
        );
        if (row == null) {
          return Left(NotFoundFailure('category "$id" does not exist'));
        }
        return Right(CategoryMapper.toEntity(row));
      });

  @override
  FutureResult<Unit> reorderCategories(List<String> orderedIds) =>
      _guard(() async {
        await _local.reorderCategories(orderedIds, DateTime.now());
        return const Right(unit);
      });

  @override
  FutureResult<CategoryDeletionImpact> getDeletionImpact(String id) =>
      _guard(() async {
        final row = await _local.getCategory(id);
        if (row == null) {
          return Left(NotFoundFailure('category "$id" does not exist'));
        }
        return Right(
          CategoryDeletionImpact(
            hasActiveSubcategories:
                await _local.countActiveSubcategories(id) > 0,
            transactionCount: await _local.countActiveTransactions(id),
            budgetCount: await _local.countReferencingBudgets(id),
          ),
        );
      });

  @override
  FutureResult<Unit> softDeleteCategory(String id) => _guard(() async {
        final row = await _local.softDeleteCategory(id, DateTime.now());
        if (row == null) {
          return Left(NotFoundFailure('category "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<Unit> cascadeDeleteCategory(String rootId) => _guard(() async {
        final current = await _local.getCategory(rootId);
        if (current == null) {
          return Left(NotFoundFailure('category "$rootId" does not exist'));
        }
        await _local.cascadeDeleteCategory(rootId, DateTime.now());
        return const Right(unit);
      });

  @override
  FutureResult<Unit> reassignSubcategories(
    String rootId,
    String targetRootId,
  ) =>
      _guard(() async {
        await _local.reassignSubcategories(
          rootId,
          targetRootId,
          DateTime.now(),
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> reassignTransactions(
    String fromCategoryId,
    String toCategoryId,
  ) =>
      _guard(() async {
        await _local.reassignTransactions(
          fromCategoryId,
          toCategoryId,
          DateTime.now(),
        );
        return const Right(unit);
      });

  @override
  FutureResult<Unit> clearTransactionCategory(String categoryId) =>
      _guard(() async {
        await _local.clearTransactionCategory(categoryId, DateTime.now());
        return const Right(unit);
      });

  @override
  FutureResult<Unit> restoreCategory(String id) => _guard(() async {
        final row = await _local.restoreCategory(id, DateTime.now());
        if (row == null) {
          return Left(NotFoundFailure('category "$id" does not exist'));
        }
        return const Right(unit);
      });

  @override
  FutureResult<bool> hasAnyCategory() => _guard(() async {
        final count = await _local.countActiveCategories();
        return Right(count > 0);
      });

  /// HU-06: fetches the onboarding catalog from `category_seeds`
  /// (`docs/requirements/05-auth-sync.md`, decision #12) and seeds it
  /// locally. A fetch failure is mapped to [NetworkFailure] explicitly —
  /// distinct from the generic [DatabaseFailure] `_guard` produces for local
  /// Drift errors — so the caller (`SeedDefaultCategories`) can tell "no
  /// internet on first launch" apart from a local storage problem, without
  /// marking the `categoriesSeeded` latch either way.
  @override
  FutureResult<Unit> seedDefaultCategories() async {
    final List<CategorySeedEntry> catalog;
    try {
      catalog = await _remoteSeeds.fetchCatalog();
    } on CategorySeedsFetchException catch (e, stackTrace) {
      return Left(
        NetworkFailure(
          'failed to fetch the category_seeds catalog',
          cause: e.cause,
          stackTrace: stackTrace,
        ),
      );
    }

    return _guard(() async {
      await _local.seedDefaultCategories(
        catalog,
        DateTime.now(),
        AppLocale.resolveLanguageCode(),
      );
      return const Right(unit);
    });
  }

  /// Groups the flat, `sortOrder`-ordered rows into roots with their
  /// subcategories, preserving that order in both lists.
  List<CategoryNode> _groupIntoNodes(List<db.Category> rows) {
    final roots = <Category>[];
    final subsByParent = <String, List<Category>>{};

    for (final row in rows) {
      final entity = CategoryMapper.toEntity(row);
      if (entity.isRoot) {
        roots.add(entity);
      } else {
        subsByParent.putIfAbsent(entity.parentId!, () => []).add(entity);
      }
    }

    return [
      for (final root in roots)
        CategoryNode(
          root: root,
          subcategories: subsByParent[root.id] ?? const [],
        ),
    ];
  }

  /// Turns any infrastructure exception into a `Failure`, so nothing escapes
  /// the data layer as a raw exception.
  FutureResult<T> _guard<T>(FutureResult<T> Function() body) async {
    try {
      return await body();
    } catch (e, st) {
      return Left(
        DatabaseFailure('categories query failed', cause: e, stackTrace: st),
      );
    }
  }

  /// Same for streams: a query error becomes a `Left` **emission** instead of
  /// a stream error, so the cubit can render the error state without the
  /// subscription dying.
  Stream<Result<T>> _guardStream<T>(Stream<Result<T>> source) =>
      source.transform(
        StreamTransformer<Result<T>, Result<T>>.fromHandlers(
          handleData: (data, sink) => sink.add(data),
          handleError: (error, stackTrace, sink) => sink.add(
            Left(
              DatabaseFailure(
                'categories stream failed',
                cause: error,
                stackTrace: stackTrace,
              ),
            ),
          ),
        ),
      );
}
