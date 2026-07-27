import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/budgets/data/datasources/budgets_local_datasource.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-12: the two Drift queries `BudgetsLocalDatasource` adds for the
/// "programado" segment — active expense templates and `pending` occurrences —
/// against a real (in-memory) schema.
void main() {
  late AppDatabase database;
  late BudgetsLocalDatasource datasource;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    datasource = BudgetsLocalDatasource(database);
  });

  tearDown(() async => database.close());

  Future<Account> createAccount(String name) =>
      database.into(database.accounts).insertReturning(
            AccountsCompanion.insert(
              name: name,
              type: AccountType.bank,
              currency: 'COP',
            ),
          );

  Future<Category> createCategory(String name, {required CategoryKind kind}) =>
      database.into(database.categories).insertReturning(
            CategoriesCompanion.insert(name: name, kind: kind),
          );

  Future<ScheduledPayment> createTemplate({
    required String accountId,
    String? categoryId,
    EntryType type = EntryType.expense,
    String currency = 'COP',
    int amountMinor = 5000,
    ScheduleFrequency frequency = ScheduleFrequency.monthly,
    DateTime? nextDate,
    DateTime? endDate,
    DateTime? tombstonedAt,
  }) =>
      database.into(database.scheduledPayments).insertReturning(
            ScheduledPaymentsCompanion.insert(
              accountId: accountId,
              categoryId: Value(categoryId),
              amountMinor: amountMinor,
              currency: currency,
              type: type,
              frequency: frequency,
              firstPaymentDate: nextDate ?? DateTime(2026, 7, 1),
              nextDate: nextDate ?? DateTime(2026, 7, 1),
              endDate: Value(endDate),
              tombstonedAt: Value(tombstonedAt),
              updatedAt: const Value(0),
            ),
          );

  Future<ScheduledPaymentOccurrence> createOccurrence({
    required String scheduledPaymentId,
    required DateTime occurrenceDate,
    ScheduledOccurrenceStatus status = ScheduledOccurrenceStatus.pending,
  }) =>
      database.into(database.scheduledPaymentOccurrences).insertReturning(
            ScheduledPaymentOccurrencesCompanion.insert(
              scheduledPaymentId: scheduledPaymentId,
              occurrenceDate: occurrenceDate,
              status: Value(status),
              updatedAt: const Value(0),
            ),
          );

  group('watchScheduledExpenseTemplates', () {
    test('only returns expense templates, enriched with names', () async {
      final account = await createAccount('Efectivo');
      final category =
          await createCategory('Renta', kind: CategoryKind.expense);
      await createTemplate(accountId: account.id, categoryId: category.id);
      // Non-expense: excluded.
      await createTemplate(accountId: account.id, type: EntryType.income);

      final rows = await datasource.watchScheduledExpenseTemplates().first;

      expect(rows, hasLength(1));
      expect(rows.single.accountName, 'Efectivo');
      expect(rows.single.categoryName, 'Renta');
      expect(rows.single.template.type, EntryType.expense);
    });

    test('excludes a tombstoned template', () async {
      final account = await createAccount('Efectivo');
      await createTemplate(
        accountId: account.id,
        tombstonedAt: DateTime(2026, 1, 1),
      );

      final rows = await datasource.watchScheduledExpenseTemplates().first;

      expect(rows, isEmpty);
    });

    test('excludes a `once` template that already fired (confirmed)', () async {
      final account = await createAccount('Efectivo');
      final fired = await createTemplate(
        accountId: account.id,
        frequency: ScheduleFrequency.once,
        nextDate: DateTime(2026, 6, 1),
      );
      await createOccurrence(
        scheduledPaymentId: fired.id,
        occurrenceDate: DateTime(2026, 6, 1),
        status: ScheduledOccurrenceStatus.confirmed,
      );
      final notYetFired = await createTemplate(
        accountId: account.id,
        frequency: ScheduleFrequency.once,
        nextDate: DateTime(2026, 7, 1),
      );

      final rows = await datasource.watchScheduledExpenseTemplates().first;

      expect(rows.map((r) => r.template.id), [notYetFired.id]);
    });
  });

  group('watchPendingScheduledOccurrences', () {
    test('only returns `pending` occurrences of expense templates, enriched',
        () async {
      final account = await createAccount('Efectivo');
      final category =
          await createCategory('Servicios', kind: CategoryKind.expense);
      final template = await createTemplate(
        accountId: account.id,
        categoryId: category.id,
      );
      final pending = await createOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 7, 1),
      );
      // Confirmed: excluded (already a Transaction, counted elsewhere).
      await createOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 6, 1),
        status: ScheduledOccurrenceStatus.confirmed,
      );

      final rows = await datasource.watchPendingScheduledOccurrences().first;

      expect(rows, hasLength(1));
      expect(rows.single.occurrence.id, pending.id);
      expect(rows.single.accountName, 'Efectivo');
      expect(rows.single.categoryName, 'Servicios');
    });

    test('excludes a pending occurrence of a non-expense template', () async {
      final account = await createAccount('Efectivo');
      final template =
          await createTemplate(accountId: account.id, type: EntryType.income);
      await createOccurrence(
        scheduledPaymentId: template.id,
        occurrenceDate: DateTime(2026, 7, 1),
      );

      final rows = await datasource.watchPendingScheduledOccurrences().first;

      expect(rows, isEmpty);
    });
  });
}
