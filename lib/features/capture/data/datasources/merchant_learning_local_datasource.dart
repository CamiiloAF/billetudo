import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries over `MerchantCategoryLearning` (HU-06).
///
/// Holds no notification content: one normalized merchant key and one
/// category id per row.
@lazySingleton
class MerchantLearningLocalDatasource {
  const MerchantLearningLocalDatasource(this._db);

  final AppDatabase _db;

  Future<MerchantCategoryLearningData?> getByMerchantKey(String merchantKey) =>
      (_db.select(_db.merchantCategoryLearning)
            ..where(
              (t) =>
                  t.deletedAt.isNull() &
                  t.tombstonedAt.isNull() &
                  t.merchantKey.equals(merchantKey),
            ))
          .getSingleOrNull();

  /// Joined against `Categories` so a learned association pointing at a
  /// category the user has since deleted stops being suggested — without
  /// deleting the association, which becomes useful again if the category is
  /// restored.
  Future<String?> suggestedCategoryFor(String merchantKey) async {
    final query = _db.select(_db.merchantCategoryLearning).join([
      innerJoin(
        _db.categories,
        _db.categories.id.equalsExp(_db.merchantCategoryLearning.categoryId),
      ),
    ])
      ..where(
        _db.merchantCategoryLearning.deletedAt.isNull() &
            _db.merchantCategoryLearning.tombstonedAt.isNull() &
            _db.merchantCategoryLearning.merchantKey.equals(merchantKey) &
            _db.categories.deletedAt.isNull() &
            _db.categories.tombstonedAt.isNull(),
      )
      ..limit(1);
    final row = await query.getSingleOrNull();
    return row?.readTable(_db.merchantCategoryLearning).categoryId;
  }

  Future<void> insertLearning(MerchantCategoryLearningCompanion companion) =>
      _db.into(_db.merchantCategoryLearning).insert(companion);

  Future<void> updateLearning(
    String id,
    MerchantCategoryLearningCompanion companion,
  ) =>
      (_db.update(_db.merchantCategoryLearning)..where((t) => t.id.equals(id)))
          .write(companion);

  /// PHYSICAL delete: forgetting an association means it is gone, not hidden
  /// (HU-08).
  Future<int> deleteByMerchantKey(String merchantKey) =>
      (_db.delete(_db.merchantCategoryLearning)
            ..where((t) => t.merchantKey.equals(merchantKey)))
          .go();

  Future<int> deleteAll() => _db.delete(_db.merchantCategoryLearning).go();

  Future<T> runInTransaction<T>(Future<T> Function() body) =>
      _db.transaction(body);
}
