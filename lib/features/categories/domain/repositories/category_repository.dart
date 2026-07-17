import '../../../../core/error/result.dart';
import '../entities/category.dart';
import '../entities/category_deletion_impact.dart';
import '../entities/category_draft.dart';
import '../entities/category_node.dart';

/// Contract the Categories feature depends on. Implemented in `data/` over
/// Drift (source of truth).
///
/// Every write updates `updatedAt`. Unlike Accounts, Categories has no
/// referential-integrity tombstone in play: `Transactions.categoryId` is
/// nullable and every delete flow resolves dependent transactions/
/// subcategories *before* the category itself is removed, so a plain
/// `deletedAt` (reversible trash/undo) is enough — `tombstonedAt` is never
/// written by this feature.
abstract class CategoryRepository {
  /// Active categories (not tombstoned, not deleted) of [kind], grouped
  /// root -> subcategories and ordered by `sortOrder` (HU-05/HU-12). Re-emits
  /// on every relevant change.
  Stream<Result<List<CategoryNode>>> watchCategories(CategoryKind kind);

  /// Root categories of [kind] (not tombstoned, not deleted), for the parent
  /// picker (HU-02/HU-03). [excludingId] omits a given id, so editing a root
  /// category never offers itself as its own parent.
  Stream<Result<List<Category>>> watchParentCandidates(
    CategoryKind kind, {
    String? excludingId,
  });

  /// A single category by id. `Left(NotFoundFailure)` when it does not
  /// exist, or is tombstoned/deleted.
  FutureResult<Category> getCategory(String id);

  /// The [limit] most-used categories of [kind] by active-transaction count,
  /// for the transaction form's Category Quick Picker (HU-01/02). Ties — and
  /// a user with no history at all — fall back to the earliest root
  /// categories by `sortOrder`, so the picker always has something to show.
  FutureResult<List<Category>> getMostUsedCategories(
    CategoryKind kind, {
    int limit = 3,
  });

  /// Persists a new category. `sortOrder` is assigned at the end of its
  /// scope: among root categories of `draft.kind` when `draft.parentId` is
  /// `null`, or among the siblings of `draft.parentId` otherwise.
  FutureResult<Category> createCategory(CategoryDraft draft);

  /// Updates an existing category (HU-03). Requires `draft.id`.
  FutureResult<Category> updateCategory(CategoryDraft draft);

  /// Rewrites `sortOrder` as a contiguous 0..n-1 sequence in the given order
  /// (HU-05), in one transaction.
  FutureResult<Unit> reorderCategories(List<String> orderedIds);

  /// What deleting the category would affect (HU-04): active subcategories
  /// and the count of active transactions that reference it.
  FutureResult<CategoryDeletionImpact> getDeletionImpact(String id);

  /// Logical delete (HU-04 case 1/2): stamps `deletedAt`, recoverable from
  /// the trash via [restoreCategory]. Callers must have already resolved any
  /// dependent transaction/subcategory.
  FutureResult<Unit> softDeleteCategory(String id);

  /// HU-04 case 3 (cascade): soft-deletes [rootId] and every one of its
  /// active subcategories, in a single transaction.
  FutureResult<Unit> cascadeDeleteCategory(String rootId);

  /// HU-04 case 3 (reassign): moves every active subcategory of [rootId]
  /// under [targetRootId].
  FutureResult<Unit> reassignSubcategories(String rootId, String targetRootId);

  /// HU-04 case 2 (reassign): moves every active transaction referencing
  /// [fromCategoryId] to [toCategoryId].
  FutureResult<Unit> reassignTransactions(
    String fromCategoryId,
    String toCategoryId,
  );

  /// HU-04 case 2 (leave uncategorized): clears `categoryId` on every active
  /// transaction referencing [categoryId].
  FutureResult<Unit> clearTransactionCategory(String categoryId);

  /// Undo from the trash (HU-04): clears `deletedAt`. Does not require the
  /// parent to still be alive; a category whose parent was itself deleted is
  /// restored as-is (documented, non-blocking edge case).
  FutureResult<Unit> restoreCategory(String id);

  /// Whether the user has any active category at all, of any kind — drives
  /// the idempotency of [seedDefaultCategories] (HU-06).
  FutureResult<bool> hasAnyCategory();

  /// Inserts the onboarding seed set (HU-06). Callers are expected to have
  /// checked [hasAnyCategory] first; this method does not re-check it.
  FutureResult<Unit> seedDefaultCategories();
}
