import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/notes/data/repositories/note_suggestions_repository_impl.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late NoteSuggestionsRepositoryImpl repository;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    repository = NoteSuggestionsRepositoryImpl(db);
  });

  tearDown(() => db.close());

  Future<String> createAccount() async {
    final account = await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Efectivo',
            type: AccountType.cash,
            currency: 'COP',
          ),
        );
    return account.id;
  }

  Future<String> createGoal() async {
    final goal = await db.into(db.goals).insertReturning(
          GoalsCompanion.insert(
            name: 'Vacaciones',
            targetMinor: 100000,
            currency: 'COP',
          ),
        );
    return goal.id;
  }

  Future<String> createDebt() async {
    final debt = await db.into(db.debts).insertReturning(
          DebtsCompanion.insert(
            name: 'Tarjeta',
            direction: DebtDirection.iOwe,
            principalMinor: 100000,
            currency: 'COP',
          ),
        );
    return debt.id;
  }

  Future<void> insertTransaction({
    required String accountId,
    required String note,
    DateTime? updatedAt,
    DateTime? deletedAt,
    DateTime? tombstonedAt,
  }) =>
      db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
              note: Value(note),
              updatedAt: updatedAt == null
                  ? const Value.absent()
                  : Value(updatedAt.millisecondsSinceEpoch),
              deletedAt: Value(deletedAt),
              tombstonedAt: Value(tombstonedAt),
            ),
          );

  Future<void> insertGoalContribution({
    required String goalId,
    required String note,
    DateTime? updatedAt,
    DateTime? deletedAt,
  }) =>
      db.into(db.goalContributions).insert(
            GoalContributionsCompanion.insert(
              goalId: goalId,
              amountMinor: 1000,
              direction: GoalMovementDirection.contribution,
              date: DateTime(2026, 1, 1),
              note: Value(note),
              updatedAt: updatedAt == null
                  ? const Value.absent()
                  : Value(updatedAt.millisecondsSinceEpoch),
              deletedAt: Value(deletedAt),
            ),
          );

  Future<void> insertDebtEntry({
    required String debtId,
    required String note,
    DateTime? updatedAt,
    DateTime? tombstonedAt,
  }) =>
      db.into(db.debtEntries).insert(
            DebtEntriesCompanion.insert(
              debtId: debtId,
              kind: DebtEntryKind.payment,
              amountMinor: -1000,
              entryDate: DateTime(2026, 1, 1),
              note: Value(note),
              updatedAt: updatedAt == null
                  ? const Value.absent()
                  : Value(updatedAt.millisecondsSinceEpoch),
              tombstonedAt: Value(tombstonedAt),
            ),
          );

  Future<void> insertScheduledPayment({
    required String accountId,
    required String note,
    DateTime? updatedAt,
  }) =>
      db.into(db.scheduledPayments).insert(
            ScheduledPaymentsCompanion.insert(
              accountId: accountId,
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              frequency: ScheduleFrequency.monthly,
              firstPaymentDate: DateTime(2026, 1, 1),
              nextDate: DateTime(2026, 2, 1),
              note: Value(note),
              updatedAt: updatedAt == null
                  ? const Value.absent()
                  : Value(updatedAt.millisecondsSinceEpoch),
            ),
          );

  group('suggest', () {
    test('unions notes from all four tables', () async {
      final accountId = await createAccount();
      final goalId = await createGoal();
      final debtId = await createDebt();

      await insertTransaction(accountId: accountId, note: 'Almuerzo');
      await insertGoalContribution(goalId: goalId, note: 'Aporte mensual');
      await insertDebtEntry(debtId: debtId, note: 'Abono tarjeta');
      await insertScheduledPayment(accountId: accountId, note: 'Arriendo');

      final result = await repository.suggest('a');

      expect(
        result,
        containsAll(['Almuerzo', 'Aporte mensual', 'Abono tarjeta', 'Arriendo']),
      );
    });

    test('matches partially via LIKE, case-insensitively', () async {
      final accountId = await createAccount();
      await insertTransaction(accountId: accountId, note: 'Almuerzo oficina');

      final result = await repository.suggest('OFICI');

      expect(result, ['Almuerzo oficina']);
    });

    test('deduplicates notes that only differ by case', () async {
      final accountId = await createAccount();
      await insertTransaction(accountId: accountId, note: 'Almuerzo');
      await insertTransaction(accountId: accountId, note: 'almuerzo');
      await insertTransaction(accountId: accountId, note: 'ALMUERZO');

      final result = await repository.suggest('almu');

      expect(result, hasLength(1));
    });

    test('orders by frequency of use, most used first', () async {
      final accountId = await createAccount();
      // 'Arroz' used 3 times, 'Aporte' used 1 time — both match 'a'.
      await insertTransaction(accountId: accountId, note: 'Arroz');
      await insertTransaction(accountId: accountId, note: 'Arroz');
      await insertTransaction(accountId: accountId, note: 'Arroz');
      await insertTransaction(accountId: accountId, note: 'Aporte');

      final result = await repository.suggest('a');

      expect(result, ['Arroz', 'Aporte']);
    });

    test('on a frequency tie, orders by most recently used first', () async {
      final accountId = await createAccount();
      await insertTransaction(
        accountId: accountId,
        note: 'Almuerzo',
        updatedAt: DateTime(2026, 1, 1),
      );
      await insertTransaction(
        accountId: accountId,
        note: 'Aporte',
        updatedAt: DateTime(2026, 1, 10),
      );

      final result = await repository.suggest('a');

      expect(result, ['Aporte', 'Almuerzo']);
    });

    test('a higher-frequency note ranks above a more recent lower-frequency one',
        () async {
      final accountId = await createAccount();
      await insertTransaction(
        accountId: accountId,
        note: 'Almuerzo',
        updatedAt: DateTime(2026, 1, 1),
      );
      await insertTransaction(
        accountId: accountId,
        note: 'Almuerzo',
        updatedAt: DateTime(2026, 1, 2),
      );
      await insertTransaction(
        accountId: accountId,
        note: 'Arriendo',
        updatedAt: DateTime(2026, 1, 20),
      );

      final result = await repository.suggest('a');

      expect(result.first, 'Almuerzo');
    });

    test('excludes soft-deleted (deletedAt) and tombstoned rows', () async {
      final accountId = await createAccount();
      final debtId = await createDebt();
      await insertTransaction(
        accountId: accountId,
        note: 'Borrada',
        deletedAt: DateTime(2026, 1, 1),
      );
      await insertDebtEntry(
        debtId: debtId,
        note: 'Lapidada',
        tombstonedAt: DateTime(2026, 1, 1),
      );

      final result = await repository.suggest('a');

      expect(result, isNot(contains('Borrada')));
      expect(result, isNot(contains('Lapidada')));
    });

    test('excludes blank/whitespace-only notes', () async {
      final accountId = await createAccount();
      await insertTransaction(accountId: accountId, note: '   ');

      final result = await repository.suggest('');

      expect(result, isEmpty);
    });

    test('limits the result to 10 distinct notes', () async {
      final accountId = await createAccount();
      for (var i = 0; i < 15; i++) {
        await insertTransaction(accountId: accountId, note: 'Nota $i');
      }

      final result = await repository.suggest('Nota');

      expect(result, hasLength(10));
    });
  });
}
