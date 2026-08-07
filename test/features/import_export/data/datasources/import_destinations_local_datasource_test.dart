import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/import_export/data/datasources/import_destinations_local_datasource.dart';
import 'package:billetudo/features/import_export/domain/repositories/import_repository.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ImportDestinationsLocalDatasource datasource;
  late String accountId;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    datasource = ImportDestinationsLocalDatasource(database);
    accountId = (await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
        ))
        .id;
  });

  tearDown(() => database.close());

  group('HU-07 — duplicado exacto', () {
    test('encuentra solo los ids que ya existen y están vivos', () async {
      final live = await database.into(database.transactions).insertReturning(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
            ),
          );
      final trashed = await database.into(database.transactions).insertReturning(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 2000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
              deletedAt: Value(DateTime(2026, 1, 2)),
            ),
          );

      final found = await datasource.findExistingTransactionIds(
        {live.id, trashed.id, 'no-existe'},
      );

      expect(found, {live.id});
    });
  });

  group('HU-07 — duplicado probable', () {
    test('coincide por cuenta+monto+moneda+tipo+fecha', () async {
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
            ),
          );
      final signature = ProbableDuplicateSignature(
        accountId: accountId,
        amountMinor: 1000,
        currency: 'COP',
        type: EntryType.expense.name,
        date: DateTime(2026, 1, 1),
      );

      final found = await datasource.findProbableDuplicates({signature});

      expect(found, {signature});
    });

    test('un monto distinto no es una coincidencia probable', () async {
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
            ),
          );
      final signature = ProbableDuplicateSignature(
        accountId: accountId,
        amountMinor: 9999,
        currency: 'COP',
        type: EntryType.expense.name,
        date: DateTime(2026, 1, 1),
      );

      final found = await datasource.findProbableDuplicates({signature});

      expect(found, isEmpty);
    });

    test(
        'dos gastos iguales el mismo día SÍ producen coincidencia probable '
        '(la decisión de tratarla como duplicado real es del usuario, no de '
        'esta consulta)', () async {
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
              note: const Value('Café 1'),
            ),
          );
      await database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: 1000,
              currency: 'COP',
              type: EntryType.expense,
              date: DateTime(2026, 1, 1),
              note: const Value('Café 2'),
            ),
          );
      final signature = ProbableDuplicateSignature(
        accountId: accountId,
        amountMinor: 1000,
        currency: 'COP',
        type: EntryType.expense.name,
        date: DateTime(2026, 1, 1),
      );

      final found = await datasource.findProbableDuplicates({signature});

      expect(found, {signature});
    });
  });

  group('HU-06 — categorías y subcategorías activas', () {
    test('separa categorías raíz de gasto e ingreso', () async {
      await database.into(database.categories).insert(
            CategoriesCompanion.insert(name: 'Comida', kind: CategoryKind.expense),
          );
      await database.into(database.categories).insert(
            CategoriesCompanion.insert(name: 'Salario', kind: CategoryKind.income),
          );

      final expenseRoots = await datasource.getActiveRootCategories(isExpense: true);
      final incomeRoots = await datasource.getActiveRootCategories(isExpense: false);

      expect(expenseRoots.map((c) => c.name), ['Comida']);
      expect(incomeRoots.map((c) => c.name), ['Salario']);
    });

    test('una categoría borrada no aparece como destino', () async {
      await database.into(database.categories).insert(
            CategoriesCompanion.insert(
              name: 'Comida',
              kind: CategoryKind.expense,
              deletedAt: Value(DateTime(2026, 1, 1)),
            ),
          );

      final roots = await datasource.getActiveRootCategories(isExpense: true);

      expect(roots, isEmpty);
    });
  });
}
