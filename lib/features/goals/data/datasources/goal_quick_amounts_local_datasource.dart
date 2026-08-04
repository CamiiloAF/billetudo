import 'package:drift/drift.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/database/app_database.dart';

/// Drift queries for `GoalQuickAmounts` (Metas detail's "Aporte rápido" row,
/// design-system/billetudo/pages/metas.md).
///
/// A plain injected class instead of a `@DriftAccessor`, same reasoning as
/// `GoalsLocalDatasource`: no new tables get declared here.
///
/// This table has no trash/undo flow of its own (see the table doc in
/// `app_database.dart`): removing a chip is a real `DELETE`. Reads only guard
/// `tombstonedAt`/`deletedAt` for defense in depth, even though nothing here
/// ever sets them.
@lazySingleton
class GoalQuickAmountsLocalDatasource {
  const GoalQuickAmountsLocalDatasource(this._db);

  final AppDatabase _db;

  Stream<List<GoalQuickAmount>> watchQuickAmounts(String goalId) =>
      (_db.select(_db.goalQuickAmounts)
            ..where(
              (q) =>
                  q.goalId.equals(goalId) &
                  q.deletedAt.isNull() &
                  q.tombstonedAt.isNull(),
            )
            ..orderBy([(q) => OrderingTerm.asc(q.createdAt)]))
          .watch();

  Future<GoalQuickAmount> insertQuickAmount(
    GoalQuickAmountsCompanion companion,
  ) =>
      _db.into(_db.goalQuickAmounts).insertReturning(companion);

  Future<void> deleteQuickAmount(String id) =>
      (_db.delete(_db.goalQuickAmounts)..where((q) => q.id.equals(id))).go();
}
