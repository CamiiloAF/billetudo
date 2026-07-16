import 'package:billetudo/core/database/app_database.dart' hide CategoryKind;
import 'package:billetudo/core/database/app_database.dart' as schema
    show CategoryKind;
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/data/datasources/tags_local_datasource.dart';
import 'package:billetudo/features/transactions/data/datasources/transactions_local_datasource.dart';
import 'package:billetudo/features/transactions/data/repositories/transaction_repository_impl.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    as domain;
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:drift/drift.dart' show Value;
import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';

/// All list tests date their fixtures within July 2026, so a single "this
/// month" period covers them without depending on the wall clock.
DatePeriodFilter _julyPeriod() =>
    DatePeriodFilter.granular(DateGranularity.month, DateTime(2026, 7, 15));

void main() {
  late AppDatabase database;
  late TransactionRepositoryImpl repository;

  setUp(() {
    database = AppDatabase(NativeDatabase.memory());
    repository = TransactionRepositoryImpl(
      TransactionsLocalDatasource(database),
      TagsLocalDatasource(database),
    );
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

  Future<Category> createCategory(
    String name, {
    required CategoryKind kind,
  }) =>
      database.into(database.categories).insertReturning(
            CategoriesCompanion.insert(
              name: name,
              kind: switch (kind) {
                CategoryKind.expense => schema.CategoryKind.expense,
                CategoryKind.income => schema.CategoryKind.income,
              },
            ),
          );

  Future<domain.Transaction> createTransaction(TransactionDraft draft) async {
    final result = await repository.createTransaction(draft);
    return result.getRight().toNullable()!;
  }

  Future<Transaction> rowOf(String id) =>
      (database.select(database.transactions)..where((t) => t.id.equals(id)))
          .getSingle();

  late Account account;
  late Account otherAccount;
  late Category expenseCategory;

  setUp(() async {
    account = await createAccount('Efectivo');
    otherAccount = await createAccount('Banco');
    expenseCategory =
        await createCategory('Comida', kind: CategoryKind.expense);
  });

  TransactionDraft expenseDraft({
    String? id,
    int amountMinor = 10000,
    String? categoryId,
    DateTime? date,
  }) =>
      TransactionDraft(
        id: id,
        accountId: account.id,
        categoryId: categoryId,
        categoryKind: categoryId == null ? null : CategoryKind.expense,
        amountMinor: amountMinor,
        currency: 'COP',
        type: domain.TransactionType.expense,
        date: date ?? DateTime(2026, 7, 15),
      );

  group('createTransaction (HU-01)', () {
    test('persiste el gasto con id UUID, monto en centavos y source manual',
        () async {
      final transaction = await createTransaction(expenseDraft());

      final row = await rowOf(transaction.id);
      expect(row.id, hasLength(36));
      expect(row.amountMinor, 10000);
      expect(row.type, EntryType.expense);
      expect(row.source, TxSource.manual);
      expect(row.deletedAt, isNull);
      expect(row.tombstonedAt, isNull);
    });

    test('persiste una transferencia sin categoría', () async {
      final transaction = await createTransaction(
        TransactionDraft(
          accountId: account.id,
          transferAccountId: otherAccount.id,
          amountMinor: 5000,
          currency: 'COP',
          type: domain.TransactionType.transfer,
          date: DateTime(2026, 7, 15),
        ),
      );

      final row = await rowOf(transaction.id);
      expect(row.type, EntryType.transfer);
      expect(row.categoryId, isNull);
      expect(row.transferAccountId, otherAccount.id);
    });
  });

  group('updateTransaction (HU-04)', () {
    test('sube updatedAt por encima del valor anterior', () async {
      final transaction = await createTransaction(expenseDraft());
      // `updatedAt` es epoch millis (schema v5): se retrocede el valor para
      // que la comparación no dependa de que el test tarde más de un
      // milisegundo.
      final backdated = DateTime.now()
          .subtract(const Duration(minutes: 5))
          .millisecondsSinceEpoch;
      await (database.update(database.transactions)
            ..where((t) => t.id.equals(transaction.id)))
          .write(TransactionsCompanion(updatedAt: Value(backdated)));
      final before = (await rowOf(transaction.id)).updatedAt;

      await repository.updateTransaction(
        expenseDraft(id: transaction.id, amountMinor: 20000),
      );

      final after = await rowOf(transaction.id);
      expect(after.amountMinor, 20000);
      expect(after.updatedAt > before, isTrue);
    });

    test('nunca cambia `source`, aunque el draft esté vacío de él', () async {
      final transaction = await createTransaction(expenseDraft());

      await repository.updateTransaction(
        expenseDraft(id: transaction.id, amountMinor: 30000),
      );

      final row = await rowOf(transaction.id);
      expect(row.source, TxSource.manual);
    });

    test('editar una transacción inexistente es NotFound', () async {
      final result = await repository.updateTransaction(
        expenseDraft(id: 'no-existe'),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });

    test('editar una transacción ya borrada es NotFound y no la muta',
        () async {
      final transaction = await createTransaction(expenseDraft());
      await repository.deleteTransaction(transaction.id);

      final result = await repository.updateTransaction(
        expenseDraft(id: transaction.id, amountMinor: 99999),
      );

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
      expect((await rowOf(transaction.id)).amountMinor, 10000);
    });
  });

  group('deleteTransaction / restoreTransaction (HU-05)', () {
    test('el borrado es lógico: deletedAt, nunca tombstonedAt', () async {
      final transaction = await createTransaction(expenseDraft());

      final result = await repository.deleteTransaction(transaction.id);

      expect(result.isRight(), isTrue);
      final row = await rowOf(transaction.id);
      expect(row.deletedAt, isNotNull);
      expect(row.tombstonedAt, isNull);
    });

    test('una transacción borrada desaparece de watchTransactions', () async {
      final transaction = await createTransaction(expenseDraft());
      await repository.deleteTransaction(transaction.id);

      final result = await repository
          .watchTransactions(TransactionFilter(datePeriod: _julyPeriod()))
          .first;

      expect(result.getRight().toNullable(), isEmpty);
    });

    test('restaurar limpia deletedAt y la devuelve a la lista', () async {
      final transaction = await createTransaction(expenseDraft());
      await repository.deleteTransaction(transaction.id);

      final restoreResult = await repository.restoreTransaction(transaction.id);

      expect(restoreResult.isRight(), isTrue);
      expect((await rowOf(transaction.id)).deletedAt, isNull);
      final list = await repository
          .watchTransactions(TransactionFilter(datePeriod: _julyPeriod()))
          .first;
      expect(
        list.getRight().toNullable()!.map((t) => t.transaction.id),
        [transaction.id],
      );
    });

    test('restaurar una transacción inexistente es NotFound', () async {
      final result = await repository.restoreTransaction('no-existe');

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('watchTransactions (HU-06)', () {
    test('filtra por rango de fechas (HU-06b)', () async {
      await createTransaction(expenseDraft(date: DateTime(2026, 7, 5)));
      await createTransaction(expenseDraft(date: DateTime(2026, 6, 20)));

      final result = await repository
          .watchTransactions(TransactionFilter(datePeriod: _julyPeriod()))
          .first;

      expect(result.getRight().toNullable(), hasLength(1));
    });

    test('un periodo sin transacciones es una lista vacía, no un error',
        () async {
      final result = await repository
          .watchTransactions(TransactionFilter(datePeriod: _julyPeriod()))
          .first;

      expect(result.isRight(), isTrue);
      expect(result.getRight().toNullable(), isEmpty);
    });

    test(
        'HU-06a: el filtro de cuenta incluye si accountId o transferAccountId '
        'coinciden', () async {
      final asOrigin = await createTransaction(expenseDraft());
      final transferIn = await createTransaction(
        TransactionDraft(
          accountId: otherAccount.id,
          transferAccountId: account.id,
          amountMinor: 3000,
          currency: 'COP',
          type: domain.TransactionType.transfer,
          date: DateTime(2026, 7, 10),
        ),
      );
      // No toca `account` en absoluto.
      await createTransaction(
        TransactionDraft(
          accountId: otherAccount.id,
          amountMinor: 1000,
          currency: 'COP',
          type: domain.TransactionType.expense,
          date: DateTime(2026, 7, 10),
        ),
      );

      final result = await repository
          .watchTransactions(
            TransactionFilter(
              accountIds: {account.id},
              datePeriod: _julyPeriod(),
            ),
          )
          .first;

      final ids =
          result.getRight().toNullable()!.map((t) => t.transaction.id).toSet();
      expect(ids, {asOrigin.id, transferIn.id});
    });

    test('filtra por categoría', () async {
      final withCategory = await createTransaction(
        expenseDraft(categoryId: expenseCategory.id),
      );
      await createTransaction(expenseDraft());

      final result = await repository
          .watchTransactions(
            TransactionFilter(
              categoryIds: {expenseCategory.id},
              datePeriod: _julyPeriod(),
            ),
          )
          .first;

      expect(
        result.getRight().toNullable()!.map((t) => t.transaction.id),
        [withCategory.id],
      );
    });

    test('filtra por tipo', () async {
      final expense = await createTransaction(expenseDraft());
      await createTransaction(
        TransactionDraft(
          accountId: account.id,
          amountMinor: 5000,
          currency: 'COP',
          type: domain.TransactionType.income,
          date: DateTime(2026, 7, 10),
        ),
      );

      final result = await repository
          .watchTransactions(
            TransactionFilter(
              types: const {domain.TransactionType.expense},
              datePeriod: _julyPeriod(),
            ),
          )
          .first;

      expect(
        result.getRight().toNullable()!.map((t) => t.transaction.id),
        [expense.id],
      );
    });

    test('busca por texto en la nota', () async {
      final match = await createTransaction(
        TransactionDraft(
          accountId: account.id,
          amountMinor: 1000,
          currency: 'COP',
          type: domain.TransactionType.expense,
          date: DateTime(2026, 7, 10),
          note: 'Almuerzo con el equipo',
        ),
      );
      await createTransaction(expenseDraft());

      final result = await repository
          .watchTransactions(
            TransactionFilter(
                searchText: 'almuerzo', datePeriod: _julyPeriod()),
          )
          .first;

      expect(
        result.getRight().toNullable()!.map((t) => t.transaction.id),
        [match.id],
      );
    });

    test('busca por texto en el nombre de la categoría', () async {
      final match = await createTransaction(
        expenseDraft(categoryId: expenseCategory.id),
      );
      await createTransaction(expenseDraft());

      final result = await repository
          .watchTransactions(
            TransactionFilter(searchText: 'comida', datePeriod: _julyPeriod()),
          )
          .first;

      expect(
        result.getRight().toNullable()!.map((t) => t.transaction.id),
        [match.id],
      );
    });

    test('ordena por fecha descendente por defecto', () async {
      final older = await createTransaction(
        expenseDraft(date: DateTime(2026, 7)),
      );
      final newer = await createTransaction(
        expenseDraft(date: DateTime(2026, 7, 20)),
      );

      final result = await repository
          .watchTransactions(TransactionFilter(datePeriod: _julyPeriod()))
          .first;

      expect(
        result.getRight().toNullable()!.map((t) => t.transaction.id),
        [newer.id, older.id],
      );
    });

    test('ordena por monto descendente cuando se pide', () async {
      final small = await createTransaction(expenseDraft(amountMinor: 1000));
      final big = await createTransaction(expenseDraft(amountMinor: 90000));

      final result = await repository
          .watchTransactions(
            TransactionFilter(
              sortOrder: TransactionSortOrder.amountDesc,
              datePeriod: _julyPeriod(),
            ),
          )
          .first;

      expect(
        result.getRight().toNullable()!.map((t) => t.transaction.id),
        [big.id, small.id],
      );
    });

    test('enriquece con nombre de cuenta y categoría', () async {
      await createTransaction(expenseDraft(categoryId: expenseCategory.id));

      final result = await repository
          .watchTransactions(TransactionFilter(datePeriod: _julyPeriod()))
          .first;

      final item = result.getRight().toNullable()!.single;
      expect(item.accountName, 'Efectivo');
      expect(item.categoryName, 'Comida');
    });

    test('filtra por etiqueta y reacciona a que se asigne una nueva', () async {
      final tagged = await createTransaction(expenseDraft());
      final untagged = await createTransaction(expenseDraft());
      final tag = await database
          .into(database.tags)
          .insertReturning(TagsCompanion.insert(name: 'viaje'));

      final emissions = <List<String>>[];
      final subscription = repository
          .watchTransactions(
            TransactionFilter(tagIds: {tag.id}, datePeriod: _julyPeriod()),
          )
          .listen(
            (result) => emissions.add(
              result
                  .getRight()
                  .toNullable()!
                  .map((t) => t.transaction.id)
                  .toList(),
            ),
          );
      await pumpEventQueue();

      await repository.setTransactionTags(tagged.id, [tag.id]);
      await pumpEventQueue();
      await subscription.cancel();

      expect(emissions.first, isEmpty);
      expect(emissions.last, [tagged.id]);
      expect(emissions.last, isNot(contains(untagged.id)));
    });
  });

  group('setTransactionTags (HU-07)', () {
    test('agrega y quita etiquetas hasta igualar el conjunto pedido', () async {
      final transaction = await createTransaction(expenseDraft());
      final tagA = await database
          .into(database.tags)
          .insertReturning(TagsCompanion.insert(name: 'a'));
      final tagB = await database
          .into(database.tags)
          .insertReturning(TagsCompanion.insert(name: 'b'));

      await repository.setTransactionTags(transaction.id, [tagA.id, tagB.id]);
      var links = await (database.select(database.transactionTags)
            ..where((tt) => tt.transactionId.equals(transaction.id)))
          .get();
      expect(links.map((l) => l.tagId).toSet(), {tagA.id, tagB.id});

      await repository.setTransactionTags(transaction.id, [tagB.id]);
      links = await (database.select(database.transactionTags)
            ..where((tt) => tt.transactionId.equals(transaction.id)))
          .get();
      expect(links.map((l) => l.tagId).toSet(), {tagB.id});
    });

    test('sobre una transacción inexistente es NotFound', () async {
      final result = await repository.setTransactionTags('no-existe', []);

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });

  group('watchTransactionDetail (HU-08)', () {
    test('expone el detalle con cuenta, categoría y etiquetas', () async {
      final transaction = await createTransaction(
        expenseDraft(categoryId: expenseCategory.id),
      );
      final tag = await database
          .into(database.tags)
          .insertReturning(TagsCompanion.insert(name: 'x'));
      await repository.setTransactionTags(transaction.id, [tag.id]);

      final result =
          await repository.watchTransactionDetail(transaction.id).first;

      final detail = result.getRight().toNullable()!;
      expect(detail.accountName, 'Efectivo');
      expect(detail.categoryName, 'Comida');
      expect(detail.tags.map((t) => t.id), [tag.id]);
    });

    test('una transacción inexistente es NotFound', () async {
      final result = await repository.watchTransactionDetail('no-existe').first;

      expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    });
  });
}
