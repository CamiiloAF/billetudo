import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for Tags and the `TransactionTags` N:N relation (HU-07).
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `AccountsLocalDatasource`/`CategoriesLocalDatasource`: no new tables, no
/// forced schema regeneration.
///
/// Tags has no trash flow (nothing in this feature soft-deletes a tag), so
/// reads only guard `tombstonedAt IS NULL` for defense in depth.
@lazySingleton
class TagsLocalDatasource {
  const TagsLocalDatasource(this._db);

  final AppDatabase _db;

  Stream<List<Tag>> watchTags() {
    final query = _db.select(_db.tags)
      ..where((t) => t.tombstonedAt.isNull() & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Case-insensitive lookup, so `CreateTag` can reuse an existing tag
  /// instead of creating a near-duplicate (HU-07).
  Future<Tag?> getTagByName(String name) => (_db.select(_db.tags)
        ..where(
          (t) =>
              t.name.lower().equals(name.toLowerCase()) &
              t.tombstonedAt.isNull() &
              t.deletedAt.isNull(),
        ))
      .getSingleOrNull();

  Future<Tag> insertTag(TagsCompanion companion) =>
      _db.into(_db.tags).insertReturning(companion);

  /// The ids of the tags currently linked to [transactionId] (HU-07).
  Future<List<String>> tagIdsFor(String transactionId) {
    final query = _db.selectOnly(_db.transactionTags)
      ..addColumns([_db.transactionTags.tagId])
      ..where(
        _db.transactionTags.transactionId.equals(transactionId) &
            _db.transactionTags.deletedAt.isNull() &
            _db.transactionTags.tombstonedAt.isNull(),
      );
    return query.map((row) => row.read(_db.transactionTags.tagId)!).get();
  }

  /// HU-07: replaces the full set of tags linked to [transactionId] with
  /// [tagIds] — adds the missing links and hard-deletes the ones no longer
  /// selected. `TransactionTags` rows carry no user-facing history of their
  /// own, so a real `DELETE` (not a soft one) is the right tool here, unlike
  /// the transaction itself.
  Future<void> replaceTags(
    String transactionId,
    List<String> tagIds,
    DateTime now,
  ) =>
      _db.transaction(() async {
        final current = await tagIdsFor(transactionId);
        final toAdd = tagIds.where((id) => !current.contains(id));
        final toRemove = current.where((id) => !tagIds.contains(id));

        for (final tagId in toAdd) {
          await _db.into(_db.transactionTags).insert(
                TransactionTagsCompanion.insert(
                  transactionId: transactionId,
                  tagId: tagId,
                  createdAt: Value(now),
                  updatedAt: Value(now.millisecondsSinceEpoch),
                ),
              );
        }

        if (toRemove.isNotEmpty) {
          await (_db.delete(_db.transactionTags)
                ..where(
                  (tt) =>
                      tt.transactionId.equals(transactionId) &
                      tt.tagId.isIn(toRemove),
                ))
              .go();
        }
      });
}
