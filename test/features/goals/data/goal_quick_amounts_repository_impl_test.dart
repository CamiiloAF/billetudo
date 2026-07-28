import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/goals/data/datasources/goal_quick_amounts_local_datasource.dart';
import 'package:billetudo/features/goals/data/repositories/goal_quick_amounts_repository_impl.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late GoalQuickAmountsRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = GoalQuickAmountsRepositoryImpl(
      GoalQuickAmountsLocalDatasource(database),
      const NoopCrashReporter(),
    );
  });

  tearDown(() async => database.close());

  Future<String> insertGoal({String name = 'Viaje a Cartagena'}) async {
    final goal = await database.into(database.goals).insertReturning(
          GoalsCompanion.insert(
            name: name,
            targetMinor: 6000000,
            currency: 'COP',
          ),
        );
    return goal.id;
  }

  group('createQuickAmount', () {
    test('persiste el chip con id UUID', () async {
      final goalId = await insertGoal();

      final result = await repository.createQuickAmount(
        goalId: goalId,
        amountMinor: 20000,
      );

      final quickAmount = result.getRight().toNullable()!;
      expect(quickAmount.id, hasLength(36));
      expect(quickAmount.goalId, goalId);
      expect(quickAmount.amountMinor, 20000);
    });
  });

  group('watchQuickAmounts', () {
    test('emite los chips de la meta, más antiguo primero', () async {
      final goalId = await insertGoal();
      await repository.createQuickAmount(goalId: goalId, amountMinor: 30000);
      await repository.createQuickAmount(goalId: goalId, amountMinor: 20000);

      final result = await repository.watchQuickAmounts(goalId).first;

      expect(
        result.getRight().toNullable()!.map((q) => q.amountMinor),
        [30000, 20000],
      );
    });

    test('no mezcla chips de otra meta', () async {
      final goalId = await insertGoal();
      final otherGoalId = await insertGoal(name: 'Fondo de emergencia');
      await repository.createQuickAmount(goalId: goalId, amountMinor: 30000);
      await repository.createQuickAmount(
        goalId: otherGoalId,
        amountMinor: 99000,
      );

      final result = await repository.watchQuickAmounts(goalId).first;

      expect(
        result.getRight().toNullable()!.map((q) => q.amountMinor),
        [30000],
      );
    });
  });

  group('deleteQuickAmount', () {
    test('borra la fila de forma real (DELETE), no soft-delete', () async {
      final goalId = await insertGoal();
      final created = await repository.createQuickAmount(
        goalId: goalId,
        amountMinor: 20000,
      );
      final id = created.getRight().toNullable()!.id;

      final deleteResult = await repository.deleteQuickAmount(id);
      expect(deleteResult.isRight(), isTrue);

      // The row is gone entirely, not merely hidden behind `deletedAt` — a
      // raw select (ignoring the `deletedAt`/`tombstonedAt` guard) finds
      // nothing at all.
      final rawRow = await (database.select(database.goalQuickAmounts)
            ..where((q) => q.id.equals(id)))
          .getSingleOrNull();
      expect(rawRow, isNull);

      final watched = await repository.watchQuickAmounts(goalId).first;
      expect(watched.getRight().toNullable(), isEmpty);
    });

    test('reacciona en el stream tras eliminar', () async {
      final goalId = await insertGoal();
      final created = await repository.createQuickAmount(
        goalId: goalId,
        amountMinor: 20000,
      );
      final id = created.getRight().toNullable()!.id;

      final emissions = <int>[];
      final subscription = repository
          .watchQuickAmounts(goalId)
          .listen((r) => emissions.add(r.getRight().toNullable()!.length));
      await pumpEventQueue();

      await repository.deleteQuickAmount(id);
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.first, 1);
      expect(emissions.last, 0);
    });
  });
}
