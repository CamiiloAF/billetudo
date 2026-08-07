import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/features/import_export/data/models/transaction_csv_mapper.dart';
import 'package:billetudo/features/import_export/domain/entities/csv_vocabulary.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// HU-01: the transaction CSV row's exact 13-column order and content,
/// including the two privacy rules from `docs/requirements/11-import-export.md`
/// §Identidad y datos que nunca salen — `last4` on accounts is exported
/// elsewhere (HU-02, accounts CSV), but a transaction row must never carry
/// anything beyond these 13 fields, structurally ruling out `accountNumberEnc`
/// and `userId` leaking through this path.
void main() {
  late AppDatabase db;

  setUp(() => db = AppDatabase(NativeDatabase.memory()));
  tearDown(() => db.close());

  test('produce las 13 columnas en el orden exacto de HU-01, con montos '
      'positivos y punto decimal', () async {
    final accountId = (await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Bancolombia',
            type: AccountType.savings,
            currency: 'COP',
          ),
        ))
        .id;
    final destinationId = (await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Ahorros',
            type: AccountType.savings,
            currency: 'COP',
          ),
        ))
        .id;
    final rootCategoryId = (await db.into(db.categories).insertReturning(
          CategoriesCompanion.insert(
            name: 'Comida',
            kind: CategoryKind.expense,
          ),
        ))
        .id;
    final subcategoryId = (await db.into(db.categories).insertReturning(
          CategoriesCompanion.insert(
            name: 'Mercado',
            kind: CategoryKind.expense,
            parentId: Value(rootCategoryId),
          ),
        ))
        .id;

    final transaction = await db.into(db.transactions).insertReturning(
          TransactionsCompanion.insert(
            accountId: accountId,
            transferAccountId: Value(destinationId),
            categoryId: Value(subcategoryId),
            // `amountMinor` is always stored positive (`CLAUDE.md`); the
            // `tipo` column, not the sign, carries income vs. expense.
            amountMinor: 1999,
            currency: 'COP',
            type: EntryType.expense,
            date: DateTime(2026, 7, 10),
            note: const Value('Mercado semanal'),
            countsInBudget: const Value(true),
            source: const Value(TxSource.manual),
          ),
        );

    final row = TransactionCsvMapper.toRow(
      transaction,
      context: TransactionCsvContext(
        accountNames: {accountId: 'Bancolombia', destinationId: 'Ahorros'},
        categoryNames: {rootCategoryId: 'Comida', subcategoryId: 'Mercado'},
        categoryParentIds: {subcategoryId: rootCategoryId},
        tagNamesByTransactionId: {
          transaction.id: ['recurrente', 'importante'],
        },
      ),
      vocabulary: CsvVocabulary.es,
    );

    expect(row, hasLength(13));
    expect(row, [
      transaction.id,
      '2026-07-10',
      'gasto',
      '19.99',
      'COP',
      'Bancolombia',
      'Ahorros',
      'Comida',
      'Mercado',
      'Mercado semanal',
      'recurrente;importante',
      'sí',
      'manual',
    ]);
  });

  test('una transacción directamente en la raíz deja "subcategoria" vacía',
      () async {
    final accountId = (await db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: 'Efectivo',
            type: AccountType.cash,
            currency: 'COP',
          ),
        ))
        .id;
    final rootCategoryId = (await db.into(db.categories).insertReturning(
          CategoriesCompanion.insert(
            name: 'Comida',
            kind: CategoryKind.expense,
          ),
        ))
        .id;
    final transaction = await db.into(db.transactions).insertReturning(
          TransactionsCompanion.insert(
            accountId: accountId,
            categoryId: Value(rootCategoryId),
            amountMinor: 500,
            currency: 'COP',
            type: EntryType.expense,
            date: DateTime(2026, 7, 10),
          ),
        );

    final row = TransactionCsvMapper.toRow(
      transaction,
      context: TransactionCsvContext(
        accountNames: {accountId: 'Efectivo'},
        categoryNames: {rootCategoryId: 'Comida'},
        categoryParentIds: {},
        tagNamesByTransactionId: const {},
      ),
      vocabulary: CsvVocabulary.es,
    );

    // categoria, subcategoria at indices 7, 8.
    expect(row[7], 'Comida');
    expect(row[8], '');
  });

  test('ninguna columna es accountNumberEnc ni userId', () async {
    // 13 canonical fields, none of which is a sync-only or secure-storage
    // column — asserted against the enum itself so a future column addition
    // that reintroduces one of them fails this test too.
    const forbidden = {'accountNumberEnc', 'userId'};
    final columnNames = TransactionCsvColumn.values.map((c) => c.name).toSet();
    expect(columnNames.intersection(forbidden), isEmpty);
  });
}
