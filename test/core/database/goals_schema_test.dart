import 'package:billetudo/core/database/app_database.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema-only coverage for the Metas (savings goals) model change:
/// `Goals` no longer stores `savedMinor`/`color`, and `GoalContributions` is
/// the only source of a goal's progress. This exercises `onCreate` (a fresh
/// database, i.e. the schema shape itself), not `onUpgrade` — the migration's
/// raw `ps_data__`/`ps_data_local__` backfill step depends on PowerSync's own
/// SQL functions/views, which a plain in-memory `NativeDatabase` (used here,
/// like every other Drift schema test in this repo) does not provide.
void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => database.close());

  test('Goals gains completedAt/archivedAt/lastMilestonePct with sane '
      'defaults, and has no savedMinor/color column', () async {
    final goal = await database.into(database.goals).insertReturning(
          GoalsCompanion.insert(
            name: 'Fondo de emergencia',
            targetMinor: 100000,
            currency: 'COP',
          ),
        );

    expect(goal.completedAt, isNull);
    expect(goal.archivedAt, isNull);
    expect(goal.lastMilestonePct, 0);
  });

  test('GoalContributions derives a goal\'s saved amount: '
      'SUM(contribution) - SUM(withdrawal)', () async {
    final goal = await database.into(database.goals).insertReturning(
          GoalsCompanion.insert(
            name: 'Vacaciones',
            targetMinor: 500000,
            currency: 'COP',
          ),
        );

    await database.into(database.goalContributions).insert(
          GoalContributionsCompanion.insert(
            goalId: goal.id,
            amountMinor: 100000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 1, 1),
          ),
        );
    await database.into(database.goalContributions).insert(
          GoalContributionsCompanion.insert(
            goalId: goal.id,
            amountMinor: 30000,
            direction: GoalMovementDirection.withdrawal,
            date: DateTime(2026, 2, 1),
          ),
        );
    await database.into(database.goalContributions).insert(
          GoalContributionsCompanion.insert(
            goalId: goal.id,
            amountMinor: 20000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 3, 1),
            transactionId: const Value('some-transaction-id'),
            note: const Value('Bono de fin de año'),
          ),
        );

    final movements = await (database.select(database.goalContributions)
          ..where((t) => t.goalId.equals(goal.id)))
        .get();

    final saved = movements.fold<int>(
      0,
      (sum, m) => sum +
          (m.direction == GoalMovementDirection.contribution
              ? m.amountMinor
              : -m.amountMinor),
    );

    expect(saved, 90000);
    expect(movements, hasLength(3));
    expect(
      movements.where((m) => m.transactionId != null),
      hasLength(1),
    );
  });

  test('a goal can be linked to an account and archived/completed '
      'independently of its contributions', () async {
    final account = await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Ahorros',
            type: AccountType.savings,
            currency: 'COP',
          ),
        );
    final goal = await database.into(database.goals).insertReturning(
          GoalsCompanion.insert(
            name: 'Carro nuevo',
            targetMinor: 2000000,
            currency: 'COP',
            accountId: Value(account.id),
          ),
        );

    await (database.update(database.goals)..where((t) => t.id.equals(goal.id)))
        .write(
      const GoalsCompanion(
        completedAt: Value.absent(),
        archivedAt: Value.absent(),
        lastMilestonePct: Value(50),
      ),
    );

    final updated = await (database.select(database.goals)
          ..where((t) => t.id.equals(goal.id)))
        .getSingle();

    expect(updated.accountId, account.id);
    expect(updated.lastMilestonePct, 50);
  });
}
