import 'package:drift/drift.dart';

import '../../../../core/database/app_database.dart' as db;
import '../../domain/entities/goal_quick_amount.dart';

/// Translates between Drift's generated `GoalQuickAmount` rows and the domain
/// [GoalQuickAmount] entity. The only place `*Data`/`*Companion` types meet
/// the domain, so no generated type escapes `data/`.
abstract final class GoalQuickAmountMapper {
  static GoalQuickAmount toEntity(db.GoalQuickAmount row) => GoalQuickAmount(
        id: row.id,
        goalId: row.goalId,
        amountMinor: row.amountMinor,
        createdAt: row.createdAt,
        updatedAt: row.updatedAt,
      );

  /// Insert companion. `id`/`createdAt`/`updatedAt` are left to Drift's
  /// `clientDefault`s.
  static db.GoalQuickAmountsCompanion toInsertCompanion({
    required String goalId,
    required int amountMinor,
    required DateTime now,
  }) =>
      db.GoalQuickAmountsCompanion.insert(
        goalId: goalId,
        amountMinor: amountMinor,
        createdAt: Value(now),
        updatedAt: Value(now.millisecondsSinceEpoch),
      );
}
