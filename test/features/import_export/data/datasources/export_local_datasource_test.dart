import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/import_export/data/datasources/export_local_datasource.dart';
import 'package:billetudo/features/import_export/domain/entities/export_scope.dart';
import 'package:billetudo/features/import_export/domain/entities/import_entry_type.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase database;
  late ExportLocalDatasource datasource;
  late String accountA;
  late String accountB;

  setUp(() async {
    database = AppDatabase(NativeDatabase.memory());
    datasource = ExportLocalDatasource(database);

    accountA = (await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(name: 'Efectivo', type: AccountType.cash, currency: 'COP'),
        ))
        .id;
    accountB = (await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(name: 'Banco', type: AccountType.bank, currency: 'COP'),
        ))
        .id;
  });

  tearDown(() => database.close());

  Future<void> insertTransaction({
    required String accountId,
    required int amountMinor,
    required EntryType type,
    required DateTime date,
    DateTime? deletedAt,
    DateTime? tombstonedAt,
  }) =>
      database.into(database.transactions).insert(
            TransactionsCompanion.insert(
              accountId: accountId,
              amountMinor: amountMinor,
              currency: 'COP',
              type: type,
              date: date,
              deletedAt: Value(deletedAt),
              tombstonedAt: Value(tombstonedAt),
            ),
          );

  test('excluye transacciones borradas y tombstonadas (HU-01)', () async {
    await insertTransaction(
      accountId: accountA,
      amountMinor: 1000,
      type: EntryType.expense,
      date: DateTime(2026, 1, 1),
      deletedAt: DateTime(2026, 1, 2),
    );
    await insertTransaction(
      accountId: accountA,
      amountMinor: 2000,
      type: EntryType.expense,
      date: DateTime(2026, 1, 1),
      tombstonedAt: DateTime(2026, 1, 2),
    );
    await insertTransaction(
      accountId: accountA,
      amountMinor: 3000,
      type: EntryType.expense,
      date: DateTime(2026, 1, 1),
    );

    final page = await datasource.getTransactionsPage(
      filter: const TransactionExportFilter(),
      allHistory: true,
      offset: 0,
    );

    expect(page, hasLength(1));
    expect(page.single.amountMinor, 3000);
  });

  test('filtra por cuenta (origen o destino de transferencia)', () async {
    await insertTransaction(
      accountId: accountA,
      amountMinor: 1000,
      type: EntryType.expense,
      date: DateTime(2026, 1, 1),
    );
    await insertTransaction(
      accountId: accountB,
      amountMinor: 2000,
      type: EntryType.expense,
      date: DateTime(2026, 1, 1),
    );

    final page = await datasource.getTransactionsPage(
      filter: TransactionExportFilter(accountIds: {accountA}),
      allHistory: true,
      offset: 0,
    );

    expect(page, hasLength(1));
    expect(page.single.accountId, accountA);
  });

  test('filtra por tipo', () async {
    await insertTransaction(
      accountId: accountA,
      amountMinor: 1000,
      type: EntryType.expense,
      date: DateTime(2026, 1, 1),
    );
    await insertTransaction(
      accountId: accountA,
      amountMinor: 2000,
      type: EntryType.income,
      date: DateTime(2026, 1, 1),
    );

    final page = await datasource.getTransactionsPage(
      filter: const TransactionExportFilter(types: {ImportEntryType.income}),
      allHistory: true,
      offset: 0,
    );

    expect(page, hasLength(1));
    expect(page.single.type, EntryType.income);
  });

  test('el rango de fechas se ignora cuando allHistory es true', () async {
    await insertTransaction(
      accountId: accountA,
      amountMinor: 1000,
      type: EntryType.expense,
      date: DateTime(2020, 1, 1),
    );

    final withRange = await datasource.getTransactionsPage(
      filter: TransactionExportFilter(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
      allHistory: false,
      offset: 0,
    );
    expect(withRange, isEmpty);

    final allHistory = await datasource.getTransactionsPage(
      filter: TransactionExportFilter(
        startDate: DateTime(2026, 1, 1),
        endDate: DateTime(2026, 12, 31),
      ),
      allHistory: true,
      offset: 0,
    );
    expect(allHistory, hasLength(1));
  });

  test('las cuentas archivadas se incluyen en el export (es historial)', () async {
    final archived = await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Vieja',
            type: AccountType.cash,
            currency: 'COP',
            archived: const Value(true),
          ),
        );

    final accounts = await datasource.getAllAccountsForExport();

    expect(accounts.any((a) => a.id == archived.id), isTrue);
  });

  test('las cuentas tombstonadas se excluyen del export', () async {
    final tombstoned = await database.into(database.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Borrada',
            type: AccountType.cash,
            currency: 'COP',
            tombstonedAt: Value(DateTime(2026, 1, 1)),
          ),
        );

    final accounts = await datasource.getAllAccountsForExport();

    expect(accounts.any((a) => a.id == tombstoned.id), isFalse);
  });
}
