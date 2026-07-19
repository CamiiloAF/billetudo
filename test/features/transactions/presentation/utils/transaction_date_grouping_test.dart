import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/utils/transaction_date_grouping.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transaction_fixtures.dart';

void main() {
  group('groupTransactionsByDate', () {
    test('agrupa movimientos consecutivos del mismo día en un solo grupo', () {
      final items = [
        TransactionWithDetails(
          transaction: buildTransaction(date: DateTime(2026, 7, 18)),
          accountName: 'Bancolombia',
        ),
        TransactionWithDetails(
          transaction:
              buildTransaction(id: 'tx-2', date: DateTime(2026, 7, 18)),
          accountName: 'Bancolombia',
        ),
      ];

      final groups = groupTransactionsByDate(items);

      expect(groups, hasLength(1));
      expect(groups.single.items, hasLength(2));
      expect(groups.single.date, DateTime(2026, 7, 18));
    });

    test('crea un grupo nuevo apenas cambia el día, sin reordenar', () {
      final items = [
        TransactionWithDetails(
          transaction: buildTransaction(date: DateTime(2026, 7, 18)),
          accountName: 'Bancolombia',
        ),
        TransactionWithDetails(
          transaction:
              buildTransaction(id: 'tx-2', date: DateTime(2026, 7, 17)),
          accountName: 'Bancolombia',
        ),
        TransactionWithDetails(
          transaction:
              buildTransaction(id: 'tx-3', date: DateTime(2026, 7, 18)),
          accountName: 'Bancolombia',
        ),
      ];

      final groups = groupTransactionsByDate(items);

      // Same-day runs group; a day repeated later (not consecutive) opens a
      // second group of its own — grouping trusts the repository's order
      // rather than re-sorting.
      expect(groups, hasLength(3));
      expect(groups[0].items.single.transaction.id, 'tx-1');
      expect(groups[1].items.single.transaction.id, 'tx-2');
      expect(groups[2].items.single.transaction.id, 'tx-3');
    });

    test(
        'ignora la hora: dos movimientos del mismo día a horas distintas '
        'quedan en el mismo grupo', () {
      final items = [
        TransactionWithDetails(
          transaction: buildTransaction(date: DateTime(2026, 7, 18, 8)),
          accountName: 'Bancolombia',
        ),
        TransactionWithDetails(
          transaction: buildTransaction(
            id: 'tx-2',
            date: DateTime(2026, 7, 18, 22),
          ),
          accountName: 'Bancolombia',
        ),
      ];

      final groups = groupTransactionsByDate(items);

      expect(groups, hasLength(1));
    });

    test('una lista vacía no produce grupos', () {
      expect(groupTransactionsByDate(const []), isEmpty);
    });
  });
}
