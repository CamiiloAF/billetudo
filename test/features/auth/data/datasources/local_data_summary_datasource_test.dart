import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_summary_datasource.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalDataSummaryDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = LocalDataSummaryDatasource(db);
  });

  tearDown(() async => db.close());

  test('HU-04: cuenta solo lo activo (no tombstoned/deleted)', () async {
    final accountId = await db
        .into(db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
              name: 'Cuenta', type: AccountType.bank, currency: 'COP'),
        )
        .then((row) => row.id);
    await db.into(db.accounts).insert(
          AccountsCompanion.insert(
            name: 'Borrada',
            type: AccountType.bank,
            currency: 'COP',
            tombstonedAt: Value(DateTime(2026, 7)),
          ),
        );

    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
              name: 'Comida', kind: CategoryKind.expense),
        );
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
            name: 'Tombstoned',
            kind: CategoryKind.expense,
            tombstonedAt: Value(DateTime(2026, 7)),
          ),
        );

    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: accountId,
            amountMinor: 1000,
            currency: 'COP',
            type: EntryType.expense,
            date: DateTime(2026, 7, 10),
          ),
        );
    await db.into(db.transactions).insert(
          TransactionsCompanion.insert(
            accountId: accountId,
            amountMinor: 1000,
            currency: 'COP',
            type: EntryType.expense,
            date: DateTime(2026, 7, 10),
            deletedAt: Value(DateTime(2026, 7, 12)),
          ),
        );

    final summary = await datasource.getSummary();

    expect(summary.accountsCount, 1);
    expect(summary.categoriesCount, 1);
    expect(summary.transactionsCount, 1);
    expect(summary.hasLocalData, isTrue);
  });

  test('sin datos locales, hasLocalData es false', () async {
    final summary = await datasource.getSummary();

    expect(summary.accountsCount, 0);
    expect(summary.transactionsCount, 0);
    expect(summary.categoriesCount, 0);
    expect(summary.hasLocalData, isFalse);
  });
}
