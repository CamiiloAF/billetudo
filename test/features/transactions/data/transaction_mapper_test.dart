import 'package:billetudo/core/database/app_database.dart' as db;
import 'package:billetudo/features/transactions/data/models/transaction_mapper.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart'
    as domain;
import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';

import '../transaction_fixtures.dart';

void main() {
  group('toEntity', () {
    test('mapea cada campo, incluidos los enums por significado', () {
      final row = db.Transaction(
        id: 'tx-1',
        accountId: 'acc-1',
        categoryId: 'cat-1',
        amountMinor: 12345,
        currency: 'COP',
        type: db.EntryType.expense,
        date: testInstant,
        note: 'Almuerzo',
        source: db.TxSource.manual,
        createdAt: testInstant,
        updatedAt: testInstantMillis,
      );

      final entity = TransactionMapper.toEntity(row);

      expect(entity.id, 'tx-1');
      expect(entity.accountId, 'acc-1');
      expect(entity.categoryId, 'cat-1');
      expect(entity.amountMinor, 12345);
      expect(entity.amountMinor, isA<int>());
      expect(entity.type, domain.TransactionType.expense);
      expect(entity.source, domain.TransactionSource.manual);
      expect(entity.note, 'Almuerzo');
    });

    test('mapea cada TxSource por significado, no por índice', () {
      for (final source in db.TxSource.values) {
        final row = db.Transaction(
          id: 'tx-1',
          accountId: 'acc-1',
          amountMinor: 100,
          currency: 'COP',
          type: db.EntryType.expense,
          date: testInstant,
          source: source,
          createdAt: testInstant,
          updatedAt: testInstantMillis,
        );

        final entity = TransactionMapper.toEntity(row);

        expect(entity.source.name, source.name);
      }
    });
  });

  group('toInsertCompanion', () {
    test('deja el id al clientDefault de Drift y estampa createdAt/updatedAt',
        () {
      final companion = TransactionMapper.toInsertCompanion(
        buildExpenseDraft(),
        now: testInstant,
      );

      expect(companion.id, const Value<String>.absent());
      expect(companion.createdAt, Value(testInstant));
      expect(companion.updatedAt, Value(testInstantMillis));
      expect(companion.type.value, db.EntryType.expense);
      expect(companion.source.value, db.TxSource.manual);
    });
  });

  group('toUpdateCompanion', () {
    test('HU-04: nunca incluye `source`, que es inmutable', () {
      final companion = TransactionMapper.toUpdateCompanion(
        buildExpenseDraft(id: 'tx-1'),
        now: testInstant,
      );

      expect(companion.source.present, isFalse);
      expect(companion.updatedAt, Value(testInstantMillis));
    });

    test('escribe explícitamente los campos nulos para poder limpiarlos', () {
      final companion = TransactionMapper.toUpdateCompanion(
        buildExpenseDraft(id: 'tx-1'),
        now: testInstant,
      );

      expect(companion.categoryId, const Value(null));
      expect(companion.transferAccountId, const Value(null));
    });
  });

  group('softDeleteCompanion / restoreCompanion (HU-05)', () {
    test('el borrado estampa deletedAt, nunca tombstonedAt', () {
      final companion = TransactionMapper.softDeleteCompanion(now: testInstant);

      expect(companion.deletedAt, Value(testInstant));
      expect(companion.updatedAt, Value(testInstantMillis));
    });

    test('el restore limpia deletedAt', () {
      final companion = TransactionMapper.restoreCompanion(now: testInstant);

      expect(companion.deletedAt, const Value(null));
    });
  });
}
