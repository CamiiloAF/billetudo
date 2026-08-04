import 'package:billetudo/core/crash/noop_crash_reporter.dart';
import 'package:billetudo/core/database/app_database.dart'
    hide GoalMovementDirection;
import 'package:billetudo/core/database/app_database.dart' as schema
    show GoalMovementDirection;
import 'package:billetudo/features/goals/data/datasources/goals_local_datasource.dart';
import 'package:billetudo/features/goals/data/repositories/goal_repository_impl.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart' as domain;
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution_draft.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/services/goal_coherence_calculator.dart';
import 'package:billetudo/features/goals/domain/services/goal_milestone_tracker.dart';
import 'package:billetudo/features/goals/domain/services/goal_momentum_calculator.dart';
import 'package:billetudo/features/goals/domain/services/goal_progress_calculator.dart';
import 'package:billetudo/features/goals/domain/services/goal_projection_calculator.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late GoalRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = GoalRepositoryImpl(
      GoalsLocalDatasource(db),
      const GoalProgressCalculator(),
      const GoalMilestoneTracker(),
      const GoalProjectionCalculator(),
      const GoalMomentumCalculator(),
      const GoalCoherenceCalculator(),
      const NoopCrashReporter(),
    );
  });

  tearDown(() async => db.close());

  Future<Account> insertAccount({
    String name = 'Nu',
    String currency = 'COP',
    int initialBalanceMinor = 0,
  }) =>
      db.into(db.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: currency,
              initialBalanceMinor: Value(initialBalanceMinor),
            ),
          );

  Future<domain.Goal> createGoal({
    String name = 'Vacaciones',
    int targetMinor = 500000,
    String currency = 'COP',
    String? accountId,
    int? initialSavedMinor,
  }) async {
    final result = await repository.createGoal(
      GoalDraft(
        name: name,
        targetMinor: targetMinor,
        currency: currency,
        accountId: accountId,
        initialSavedMinor: initialSavedMinor,
      ),
    );
    return result.getRight().toNullable()!;
  }

  group('createGoal (HU-01)', () {
    test('persiste con progreso inicial 0 (sin columna savedMinor)', () async {
      final goal = await createGoal();

      final savedResult = await repository.getSavedMinor(goal.id);
      expect(savedResult.getRight().toNullable(), 0);
      expect(goal.lastMilestonePct, 0);
      expect(goal.completedAt, isNull);
    });

    test(
      'un avance ya existente se inserta como el primer GoalContribution, '
      'nunca como un valor suelto',
      () async {
        final goal = await createGoal(initialSavedMinor: 150000);

        final savedResult = await repository.getSavedMinor(goal.id);
        expect(savedResult.getRight().toNullable(), 150000);

        final rows = await (db.select(db.goalContributions)
              ..where((c) => c.goalId.equals(goal.id)))
            .get();
        expect(rows, hasLength(1));
        expect(
          rows.single.direction,
          schema.GoalMovementDirection.contribution,
        );
        expect(rows.single.transactionId, isNull);
      },
    );
  });

  group('contribute (HU-03)', () {
    test('un aporte de seguimiento puro solo crea la fila de movimiento', () async {
      final goal = await createGoal();

      final result = await repository.contribute(
        GoalContributionDraft(
          goalId: goal.id,
          amountMinor: 40000,
          direction: GoalMovementDirection.contribution,
          date: DateTime(2026, 7, 10),
          currency: 'COP',
        ),
      );

      expect(result.isRight(), isTrue);
      final (contribution, crossed) = result.getRight().toNullable()!;
      expect(contribution.transactionId, isNull);
      expect(crossed, isNull);

      final transactions = await db.select(db.transactions).get();
      expect(transactions, isEmpty);

      final savedResult = await repository.getSavedMinor(goal.id);
      expect(savedResult.getRight().toNullable(), 40000);
    });

    test(
      'un aporte que mueve dinero crea una transferencia real con goalId y '
      'su GoalContribution apunta a esa transacción',
      () async {
        final origin = await insertAccount(name: 'Bancolombia');
        final goalAccount = await insertAccount(name: 'Ahorros Nu');
        final goal = await createGoal(accountId: goalAccount.id);

        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 30000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
            moveMoney: true,
            originAccountId: origin.id,
            destinationAccountId: goalAccount.id,
          ),
        );

        final (contribution, _) = result.getRight().toNullable()!;
        expect(contribution.transactionId, isNotNull);

        final transaction = await (db.select(db.transactions)
              ..where((t) => t.id.equals(contribution.transactionId!)))
            .getSingle();
        expect(transaction.type, EntryType.transfer);
        expect(transaction.accountId, origin.id);
        expect(transaction.transferAccountId, goalAccount.id);
        expect(transaction.goalId, goal.id);
      },
    );
  });

  group('withdraw (HU-04)', () {
    test('un retiro crea una fila con direction withdrawal', () async {
      final goal = await createGoal(initialSavedMinor: 100000);

      final result = await repository.withdraw(
        GoalContributionDraft(
          goalId: goal.id,
          amountMinor: 20000,
          direction: GoalMovementDirection.withdrawal,
          date: DateTime(2026, 7, 10),
          currency: 'COP',
        ),
      );

      expect(result.isRight(), isTrue);
      final savedResult = await repository.getSavedMinor(goal.id);
      expect(savedResult.getRight().toNullable(), 80000);
    });
  });

  group('HU-06/HU-07 — hitos y meta cumplida', () {
    test('alcanzar el 100% marca completedAt automáticamente', () async {
      final goal = await createGoal(targetMinor: 100000);

      final result = await repository.contribute(
        GoalContributionDraft(
          goalId: goal.id,
          amountMinor: 100000,
          direction: GoalMovementDirection.contribution,
          date: DateTime(2026, 7, 10),
          currency: 'COP',
        ),
      );

      final (_, crossed) = result.getRight().toNullable()!;
      expect(crossed, 100);

      final updated = await repository.getGoal(goal.id);
      expect(updated.getRight().toNullable()!.completedAt, isNotNull);
    });

    test(
      'un retiro posterior en una meta cumplida no limpia completedAt ni '
      'baja el progreso mostrado',
      () async {
        final goal = await createGoal(targetMinor: 100000, initialSavedMinor: 100000);
        final completedGoal = await repository.getGoal(goal.id);
        expect(completedGoal.getRight().toNullable()!.completedAt, isNotNull);

        await repository.withdraw(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 40000,
            direction: GoalMovementDirection.withdrawal,
            date: DateTime(2026, 7, 11),
            currency: 'COP',
          ),
        );

        final afterWithdrawal = await repository.getGoal(goal.id);
        expect(afterWithdrawal.getRight().toNullable()!.completedAt, isNotNull);

        final savedResult = await repository.getSavedMinor(goal.id);
        expect(savedResult.getRight().toNullable(), 60000);
      },
    );

    test(
      'subir targetMinor de una meta cumplida por encima de savedMinor '
      'limpia completedAt',
      () async {
        final goal = await createGoal(targetMinor: 100000, initialSavedMinor: 100000);

        final updateResult = await repository.updateGoal(
          GoalDraft(
            id: goal.id,
            name: goal.name,
            targetMinor: 200000,
            currency: goal.currency,
          ),
        );

        expect(updateResult.getRight().toNullable()!.completedAt, isNull);
      },
    );

    test('bajar targetMinor por debajo de savedMinor marca completedAt', () async {
      final goal = await createGoal(targetMinor: 200000, initialSavedMinor: 100000);

      final updateResult = await repository.updateGoal(
        GoalDraft(
          id: goal.id,
          name: goal.name,
          targetMinor: 80000,
          currency: goal.currency,
        ),
      );

      expect(updateResult.getRight().toNullable()!.completedAt, isNotNull);
    });
  });

  group('archiveGoal / deleteGoal / purgeGoal (HU-09/HU-10)', () {
    test('archivar oculta la meta de watchGoals sin borrar su historial', () async {
      final goal = await createGoal();
      await repository.contribute(
        GoalContributionDraft(
          goalId: goal.id,
          amountMinor: 10000,
          direction: GoalMovementDirection.contribution,
          date: DateTime(2026, 7, 10),
          currency: 'COP',
        ),
      );

      await repository.archiveGoal(goal.id);

      final list = await repository.watchGoals().first;
      expect(list.getRight().toNullable(), isEmpty);

      final savedResult = await repository.getSavedMinor(goal.id);
      expect(savedResult.getRight().toNullable(), 10000);
    });

    test(
      'eliminar es deletedAt (recuperable); vaciar la papelera pone '
      'tombstonedAt y oculta también sus movimientos',
      () async {
        final goal = await createGoal(initialSavedMinor: 10000);

        await repository.deleteGoal(goal.id);
        final afterDelete = await (db.select(db.goals)
              ..where((g) => g.id.equals(goal.id)))
            .getSingle();
        expect(afterDelete.deletedAt, isNotNull);
        expect(afterDelete.tombstonedAt, isNull);

        await repository.purgeGoal(goal.id);
        final afterPurge = await (db.select(db.goals)
              ..where((g) => g.id.equals(goal.id)))
            .getSingle();
        expect(afterPurge.tombstonedAt, isNotNull);

        final contributionRows = await (db.select(db.goalContributions)
              ..where((c) => c.goalId.equals(goal.id)))
            .get();
        expect(contributionRows.single.tombstonedAt, isNotNull);
      },
    );
  });

  group('cascade HU-08 — transacción enlazada', () {
    test(
      'sync de monto de la transacción actualiza el GoalContribution',
      () async {
        final origin = await insertAccount(name: 'Bancolombia');
        final goalAccount = await insertAccount(name: 'Ahorros');
        final goal = await createGoal(accountId: goalAccount.id);

        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 30000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
            moveMoney: true,
            originAccountId: origin.id,
            destinationAccountId: goalAccount.id,
          ),
        );
        final (contribution, _) = result.getRight().toNullable()!;

        await repository.syncContributionForTransactionAmount(
          transactionId: contribution.transactionId!,
          amountMinor: 90000,
        );

        final savedResult = await repository.getSavedMinor(goal.id);
        expect(savedResult.getRight().toNullable(), 90000);
      },
    );

    test('eliminar la transacción elimina en cascada el GoalContribution', () async {
      final origin = await insertAccount(name: 'Bancolombia');
      final goalAccount = await insertAccount(name: 'Ahorros');
      final goal = await createGoal(accountId: goalAccount.id);

      final result = await repository.contribute(
        GoalContributionDraft(
          goalId: goal.id,
          amountMinor: 30000,
          direction: GoalMovementDirection.contribution,
          date: DateTime(2026, 7, 10),
          currency: 'COP',
          moveMoney: true,
          originAccountId: origin.id,
          destinationAccountId: goalAccount.id,
        ),
      );
      final (contribution, _) = result.getRight().toNullable()!;

      await repository.removeContributionForTransaction(
        contribution.transactionId!,
      );

      final rows = await (db.select(db.goalContributions)
            ..where((c) => c.goalId.equals(goal.id)))
          .get();
      expect(rows, isEmpty);
    });
  });

  group('HU-12 — señal de coherencia', () {
    test(
      'la suma de savedMinor de las metas activas de una cuenta que supera '
      'el saldo real produce una señal en watchGoals',
      () async {
        final account = await insertAccount(initialBalanceMinor: 50000);
        await createGoal(accountId: account.id, initialSavedMinor: 70000);

        final list = await repository.watchGoals().first;
        final goals = list.getRight().toNullable()!;
        expect(goals.single.coherence, isNotNull);
        expect(goals.single.coherence!.totalSavedMinor, 70000);
        expect(goals.single.coherence!.accountBalanceMinor, 50000);
      },
    );

    test('metas sin cuenta nunca producen señal de coherencia', () async {
      await createGoal(initialSavedMinor: 999999999);

      final list = await repository.watchGoals().first;
      final goals = list.getRight().toNullable()!;
      expect(goals.single.coherence, isNull);
    });
  });

  group('cuenta vinculada con tombstonedAt', () {
    test(
      'si la cuenta vinculada recibe tombstonedAt, la meta conserva su '
      'accountId e histórico pero deja de producir señal de coherencia '
      '(se comporta como una meta sin cuenta)',
      () async {
        final account = await insertAccount(initialBalanceMinor: 50000);
        final goal =
            await createGoal(accountId: account.id, initialSavedMinor: 70000);

        // Sanity check: before tombstoning, this goal does over-assign.
        final before = await repository.watchGoals().first;
        expect(before.getRight().toNullable()!.single.coherence, isNotNull);

        await (db.update(db.accounts)..where((a) => a.id.equals(account.id)))
            .write(AccountsCompanion(tombstonedAt: Value(DateTime(2026, 8))));

        final after = await repository.watchGoals().first;
        final goalWithProgress = after.getRight().toNullable()!.single;
        expect(goalWithProgress.goal.accountId, account.id);
        expect(goalWithProgress.coherence, isNull);
        expect(goalWithProgress.savedMinor, 70000);

        final savedResult = await repository.getSavedMinor(goal.id);
        expect(savedResult.getRight().toNullable(), 70000);
      },
    );

    test(
      'watchGoalDetail expone accountTombstoned cuando la cuenta vinculada '
      'fue tombstoneada',
      () async {
        final account = await insertAccount();
        final goal = await createGoal(accountId: account.id);

        final before = await repository.watchGoalDetail(goal.id).first;
        expect(before.getRight().toNullable()!.accountTombstoned, isFalse);

        await (db.update(db.accounts)..where((a) => a.id.equals(account.id)))
            .write(AccountsCompanion(tombstonedAt: Value(DateTime(2026, 8))));

        final after = await repository.watchGoalDetail(goal.id).first;
        expect(after.getRight().toNullable()!.accountTombstoned, isTrue);
      },
    );

    test('una meta sin cuenta nunca reporta accountTombstoned', () async {
      final goal = await createGoal();

      final detail = await repository.watchGoalDetail(goal.id).first;
      expect(detail.getRight().toNullable()!.accountTombstoned, isFalse);
    });
  });

  group('getMovementAccounts (sheet detalle del movimiento, N8Dv2e)', () {
    test(
      'resuelve el nombre de la cuenta de origen y destino de una '
      'transferencia',
      () async {
        final origin = await insertAccount(name: 'Nequi');
        final destination = await insertAccount(name: 'Ahorros Bancolombia');
        final goal = await createGoal(accountId: destination.id);

        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 30000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
            moveMoney: true,
            originAccountId: origin.id,
            destinationAccountId: destination.id,
          ),
        );
        final (contribution, _) = result.getRight().toNullable()!;

        final accounts = await repository.getMovementAccounts(
          contribution.transactionId!,
        );
        final resolved = accounts.getRight().toNullable();
        expect(resolved, isNotNull);
        expect(resolved!.originName, 'Nequi');
        expect(resolved.destinationName, 'Ahorros Bancolombia');
      },
    );

    test(
      'sigue resolviendo el nombre aunque la cuenta haya sido tombstoneada',
      () async {
        final origin = await insertAccount(name: 'Nequi');
        final destination = await insertAccount(name: 'Ahorros Bancolombia');
        final goal = await createGoal(accountId: destination.id);

        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 30000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
            moveMoney: true,
            originAccountId: origin.id,
            destinationAccountId: destination.id,
          ),
        );
        final (contribution, _) = result.getRight().toNullable()!;

        await (db.update(db.accounts)..where((a) => a.id.equals(destination.id)))
            .write(AccountsCompanion(tombstonedAt: Value(DateTime(2026, 8))));

        final accounts = await repository.getMovementAccounts(
          contribution.transactionId!,
        );
        expect(
          accounts.getRight().toNullable()!.destinationName,
          'Ahorros Bancolombia',
        );
      },
    );

    test('null cuando el movimiento no movió dinero', () async {
      final goal = await createGoal();
      final result = await repository.contribute(
        GoalContributionDraft(
          goalId: goal.id,
          amountMinor: 30000,
          direction: GoalMovementDirection.contribution,
          date: DateTime(2026, 7, 10),
          currency: 'COP',
        ),
      );
      final (contribution, _) = result.getRight().toNullable()!;
      expect(contribution.transactionId, isNull);
    });
  });

  group('removeContribution — eliminar movimiento (arr2T/H2ND7O/xCNxM)', () {
    test('elimina un aporte de seguimiento puro (deletedAt reversible)', () async {
      final goal = await createGoal();
      final result = await repository.contribute(
        GoalContributionDraft(
          goalId: goal.id,
          amountMinor: 50000,
          direction: GoalMovementDirection.contribution,
          date: DateTime(2026, 7, 10),
          currency: 'COP',
        ),
      );
      final (contribution, _) = result.getRight().toNullable()!;

      final removeResult = await repository.removeContribution(contribution.id);
      expect(removeResult.isRight(), isTrue);

      final savedResult = await repository.getSavedMinor(goal.id);
      expect(savedResult.getRight().toNullable(), 0);

      final row = await (db.select(db.goalContributions)
            ..where((c) => c.id.equals(contribution.id)))
          .getSingleOrNull();
      expect(row!.deletedAt, isNotNull);
    });

    test(
      'eliminar el aporte que completó la meta la vuelve a poner en curso',
      () async {
        final goal = await createGoal(targetMinor: 100000);
        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 100000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
          ),
        );
        final (contribution, crossed) = result.getRight().toNullable()!;
        expect(crossed, 100);

        final completedGoal = await repository.getGoal(goal.id);
        expect(completedGoal.getRight().toNullable()!.completedAt, isNotNull);

        await repository.removeContribution(contribution.id);

        final reverted = await repository.getGoal(goal.id);
        expect(reverted.getRight().toNullable()!.completedAt, isNull);
        expect(reverted.getRight().toNullable()!.lastMilestonePct, lessThan(100));
      },
    );

    test('NotFoundFailure cuando el movimiento ya no existe', () async {
      final result = await repository.removeContribution('no-existe');
      expect(result.isLeft(), isTrue);
    });
  });

  group('updateContribution — editar movimiento de solo seguimiento', () {
    test(
      'reescribe amountMinor/date/note en la misma fila y actualiza updatedAt',
      () async {
        final goal = await createGoal();
        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 40000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
            note: 'nota original',
          ),
        );
        final (contribution, _) = result.getRight().toNullable()!;

        final updateResult = await repository.updateContribution(
          contributionId: contribution.id,
          amountMinor: 55000,
          date: DateTime(2026, 7, 12),
          note: 'nota editada',
        );
        expect(updateResult.isRight(), isTrue);

        final row = await (db.select(db.goalContributions)
              ..where((c) => c.id.equals(contribution.id)))
            .getSingle();
        expect(row.amountMinor, 55000);
        expect(row.date, DateTime(2026, 7, 12));
        expect(row.note, 'nota editada');
        expect(row.updatedAt, greaterThanOrEqualTo(contribution.updatedAt));

        final savedResult = await repository.getSavedMinor(goal.id);
        expect(savedResult.getRight().toNullable(), 55000);
      },
    );

    test(
      'getContribution lee el movimiento vivo por su propio id',
      () async {
        final goal = await createGoal();
        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 40000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
          ),
        );
        final (contribution, _) = result.getRight().toNullable()!;

        final readResult = await repository.getContribution(contribution.id);
        expect(readResult.isRight(), isTrue);
        expect(readResult.getRight().toNullable()!.id, contribution.id);
        expect(readResult.getRight().toNullable()!.transactionId, isNull);
      },
    );

    test('NotFoundFailure de getContribution cuando el id no existe',
        () async {
      final result = await repository.getContribution('no-existe');
      expect(result.isLeft(), isTrue);
    });

    test(
      'editar el aporte que completó la meta hacia abajo la vuelve a poner en curso',
      () async {
        final goal = await createGoal(targetMinor: 100000);
        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 100000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
          ),
        );
        final (contribution, crossed) = result.getRight().toNullable()!;
        expect(crossed, 100);

        await repository.updateContribution(
          contributionId: contribution.id,
          amountMinor: 40000,
          date: DateTime(2026, 7, 10),
        );

        final reverted = await repository.getGoal(goal.id);
        expect(reverted.getRight().toNullable()!.completedAt, isNull);
      },
    );

    test(
      'rechaza editar un movimiento que sí movió dinero (transactionId != null)',
      () async {
        final origin = await insertAccount(name: 'Origen');
        final destination = await insertAccount(name: 'Destino');
        final goal = await createGoal();
        final result = await repository.contribute(
          GoalContributionDraft(
            goalId: goal.id,
            amountMinor: 30000,
            direction: GoalMovementDirection.contribution,
            date: DateTime(2026, 7, 10),
            currency: 'COP',
            moveMoney: true,
            originAccountId: origin.id,
            destinationAccountId: destination.id,
          ),
        );
        final (contribution, _) = result.getRight().toNullable()!;
        expect(contribution.transactionId, isNotNull);

        final updateResult = await repository.updateContribution(
          contributionId: contribution.id,
          amountMinor: 1000,
          date: DateTime(2026, 7, 10),
        );

        expect(updateResult.isLeft(), isTrue);
        final row = await (db.select(db.goalContributions)
              ..where((c) => c.id.equals(contribution.id)))
            .getSingle();
        expect(row.amountMinor, 30000);
      },
    );

    test('NotFoundFailure cuando el movimiento a editar ya no existe',
        () async {
      final result = await repository.updateContribution(
        contributionId: 'no-existe',
        amountMinor: 1000,
        date: DateTime(2026, 7, 10),
      );
      expect(result.isLeft(), isTrue);
    });
  });
}
