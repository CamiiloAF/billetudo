import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/utils/transaction_group_total.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transaction_fixtures.dart';

TransactionWithDetails _entry({
  String id = 'tx-1',
  int amountMinor = 10000,
  String currency = 'COP',
  TransactionType type = TransactionType.expense,
}) =>
    TransactionWithDetails(
      transaction: buildTransaction(
        id: id,
        amountMinor: amountMinor,
        currency: currency,
        type: type,
      ),
      accountName: 'Cuenta',
    );

void main() {
  group('sumTransactionGroup', () {
    test('returns null for an empty group', () {
      expect(sumTransactionGroup([]), isNull);
    });

    test('sums amountMinor when every item shares a currency', () {
      final total = sumTransactionGroup([
        _entry(id: 'tx-1', amountMinor: 1000),
        _entry(id: 'tx-2', amountMinor: 2500),
      ]);

      expect(total, isNotNull);
      expect(total!.amountMinor, 3500);
      expect(total.currency, 'COP');
      expect(total.type, TransactionType.expense);
    });

    test('returns null when the group mixes currencies', () {
      final total = sumTransactionGroup([
        _entry(id: 'tx-1', amountMinor: 1000, currency: 'COP'),
        _entry(id: 'tx-2', amountMinor: 2000, currency: 'USD'),
      ]);

      expect(total, isNull);
    });
  });

  group('transactionGroupTotalFor', () {
    test('sums when the filter is exclusively income', () {
      final filter = TransactionFilter(types: const {TransactionType.income});
      final total = transactionGroupTotalFor(filter, [
        _entry(id: 'tx-1', amountMinor: 1000, type: TransactionType.income),
        _entry(id: 'tx-2', amountMinor: 500, type: TransactionType.income),
      ]);

      expect(total, isNotNull);
      expect(total!.amountMinor, 1500);
    });

    test('sums when the filter is exclusively expense', () {
      final filter = TransactionFilter(types: const {TransactionType.expense});
      final total = transactionGroupTotalFor(filter, [
        _entry(id: 'tx-1', amountMinor: 1000),
      ]);

      expect(total, isNotNull);
      expect(total!.amountMinor, 1000);
    });

    test('falls back to null (count) when no type filter is active', () {
      final filter = TransactionFilter();
      final total = transactionGroupTotalFor(filter, [_entry()]);

      expect(total, isNull);
    });

    test('falls back to null (count) when 2+ types are selected', () {
      final filter = TransactionFilter(
        types: const {TransactionType.income, TransactionType.expense},
      );
      final total = transactionGroupTotalFor(filter, [_entry()]);

      expect(total, isNull);
    });

    test(
        'falls back to null (count) when the filter is exclusively '
        'transfer', () {
      final filter = TransactionFilter(types: const {TransactionType.transfer});
      final total = transactionGroupTotalFor(filter, [
        _entry(type: TransactionType.transfer),
      ]);

      expect(total, isNull);
    });

    test('falls back to null (count) when the group mixes currencies', () {
      final filter = TransactionFilter(types: const {TransactionType.expense});
      final total = transactionGroupTotalFor(filter, [
        _entry(id: 'tx-1', currency: 'COP'),
        _entry(id: 'tx-2', currency: 'USD'),
      ]);

      expect(total, isNull);
    });
  });
}
