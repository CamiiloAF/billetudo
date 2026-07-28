import 'package:billetudo/core/database/app_database.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// Schema-only coverage for `GoalQuickAmounts` (schemaVersion 20): the
/// user-defined "aporte rápido" chips per goal (design-system/billetudo/
/// pages/metas.md, "Aporte rápido"). Exercises `onCreate` (fresh database),
/// like `goals_schema_test.dart`.
void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async => database.close());

  test('a goal quick amount links to its goal and stores cents', () async {
    final goal = await database.into(database.goals).insertReturning(
          GoalsCompanion.insert(
            name: 'Viaje a la costa',
            targetMinor: 800000,
            currency: 'COP',
          ),
        );

    final chip = await database.into(database.goalQuickAmounts).insertReturning(
          GoalQuickAmountsCompanion.insert(
            goalId: goal.id,
            amountMinor: 25000,
          ),
        );

    expect(chip.goalId, goal.id);
    expect(chip.amountMinor, 25000);
    expect(chip.deletedAt, isNull);
    expect(chip.tombstonedAt, isNull);
  });

  test('deleting a quick amount is a real DELETE, not a soft delete',
      () async {
    final goal = await database.into(database.goals).insertReturning(
          GoalsCompanion.insert(
            name: 'Fondo de emergencia',
            targetMinor: 100000,
            currency: 'COP',
          ),
        );
    final chip = await database.into(database.goalQuickAmounts).insertReturning(
          GoalQuickAmountsCompanion.insert(
            goalId: goal.id,
            amountMinor: 50000,
          ),
        );

    await (database.delete(database.goalQuickAmounts)
          ..where((t) => t.id.equals(chip.id)))
        .go();

    final remaining = await database.select(database.goalQuickAmounts).get();
    expect(remaining, isEmpty);
  });

  test('multiple quick amounts can exist for the same goal', () async {
    final goal = await database.into(database.goals).insertReturning(
          GoalsCompanion.insert(
            name: 'Carro nuevo',
            targetMinor: 2000000,
            currency: 'COP',
          ),
        );

    await database.into(database.goalQuickAmounts).insert(
          GoalQuickAmountsCompanion.insert(goalId: goal.id, amountMinor: 50000),
        );
    await database.into(database.goalQuickAmounts).insert(
          GoalQuickAmountsCompanion.insert(
            goalId: goal.id,
            amountMinor: 100000,
          ),
        );

    final chips = await (database.select(database.goalQuickAmounts)
          ..where((t) => t.goalId.equals(goal.id)))
        .get();

    expect(chips, hasLength(2));
  });
}
