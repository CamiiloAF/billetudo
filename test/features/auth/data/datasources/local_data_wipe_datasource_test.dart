import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart';
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late AppDatabase db;
  late LocalDataWipeDatasource datasource;

  setUp(() {
    db = AppDatabase(NativeDatabase.memory());
    datasource = LocalDataWipeDatasource(db);
  });

  tearDown(() async => db.close());

  test('HU-07 paso 2: borra todas las filas de todas las tablas', () async {
    final accountId = await db
        .into(db.accounts)
        .insertReturning(
          AccountsCompanion.insert(
              name: 'Cuenta', type: AccountType.bank, currency: 'COP'),
        )
        .then((row) => row.id);
    await db.into(db.categories).insert(
          CategoriesCompanion.insert(
              name: 'Comida', kind: CategoryKind.expense),
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

    await datasource.wipeAll();

    expect(await db.select(db.accounts).get(), isEmpty);
    expect(await db.select(db.categories).get(), isEmpty);
    expect(await db.select(db.transactions).get(), isEmpty);
  });
}
