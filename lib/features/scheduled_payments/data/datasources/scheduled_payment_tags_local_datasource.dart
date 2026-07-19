import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for Tags and the `ScheduledPaymentTags` N:N relation.
///
/// Mirror of `transactions/data/datasources/tags_local_datasource.dart`
/// against the shared `Tags` table, but targeting `ScheduledPaymentTags`
/// instead of `TransactionTags` for the bridge — same mechanics, same
/// reasoning as that datasource's own doc comment.
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `AccountsLocalDatasource`: no new tables, no forced schema regeneration.
@lazySingleton
class ScheduledPaymentTagsLocalDatasource {
  const ScheduledPaymentTagsLocalDatasource(this._db);

  final AppDatabase _db;

  Stream<List<Tag>> watchTags() {
    final query = _db.select(_db.tags)
      ..where((t) => t.tombstonedAt.isNull() & t.deletedAt.isNull())
      ..orderBy([(t) => OrderingTerm.asc(t.name)]);
    return query.watch();
  }

  /// Case-insensitive lookup, so `CreateTag` can reuse an existing tag
  /// instead of creating a near-duplicate.
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

  /// The ids of the tags currently linked to [scheduledPaymentId].
  Future<List<String>> tagIdsFor(String scheduledPaymentId) {
    final query = _db.selectOnly(_db.scheduledPaymentTags)
      ..addColumns([_db.scheduledPaymentTags.tagId])
      ..where(
        _db.scheduledPaymentTags.scheduledPaymentId
                .equals(scheduledPaymentId) &
            _db.scheduledPaymentTags.deletedAt.isNull() &
            _db.scheduledPaymentTags.tombstonedAt.isNull(),
      );
    return query.map((row) => row.read(_db.scheduledPaymentTags.tagId)!).get();
  }

  /// The tags currently linked to [scheduledPaymentId], resolved to full
  /// rows (for the detail screen).
  Future<List<Tag>> tagsFor(String scheduledPaymentId) {
    final query = _db.select(_db.scheduledPaymentTags).join([
      innerJoin(
        _db.tags,
        _db.tags.id.equalsExp(_db.scheduledPaymentTags.tagId),
      ),
    ])
      ..where(
        _db.scheduledPaymentTags.scheduledPaymentId
                .equals(scheduledPaymentId) &
            _db.scheduledPaymentTags.deletedAt.isNull() &
            _db.scheduledPaymentTags.tombstonedAt.isNull(),
      );
    return query.map((row) => row.readTable(_db.tags)).get();
  }

  /// Replaces the full set of tags linked to [scheduledPaymentId] with
  /// [tagIds] — adds the missing links and hard-deletes the ones no longer
  /// selected. `ScheduledPaymentTags` rows carry no user-facing history of
  /// their own, so a real `DELETE` (not a soft one) is the right tool here,
  /// same as `TransactionTags`.
  Future<void> replaceTags(
    String scheduledPaymentId,
    List<String> tagIds,
    DateTime now,
  ) =>
      _db.transaction(() async {
        final current = await tagIdsFor(scheduledPaymentId);
        final toAdd = tagIds.where((id) => !current.contains(id));
        final toRemove = current.where((id) => !tagIds.contains(id));

        for (final tagId in toAdd) {
          await _db.into(_db.scheduledPaymentTags).insert(
                ScheduledPaymentTagsCompanion.insert(
                  scheduledPaymentId: scheduledPaymentId,
                  tagId: tagId,
                  createdAt: Value(now),
                  updatedAt: Value(now.millisecondsSinceEpoch),
                ),
              );
        }

        if (toRemove.isNotEmpty) {
          await (_db.delete(_db.scheduledPaymentTags)
                ..where(
                  (t) =>
                      t.scheduledPaymentId.equals(scheduledPaymentId) &
                      t.tagId.isIn(toRemove),
                ))
              .go();
        }
      });
}
