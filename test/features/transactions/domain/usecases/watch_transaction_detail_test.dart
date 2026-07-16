import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_transaction_detail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../transaction_fixtures.dart';
import 'transaction_repository_mock.dart';

void main() {
  test('HU-08: expone el detalle enriquecido de una transacción', () async {
    final repository = MockTransactionRepository();
    final detail = TransactionWithDetails(
      transaction: buildTransaction(),
      accountName: 'Efectivo',
    );
    when(() => repository.watchTransactionDetail('tx-1'))
        .thenAnswer((_) => Stream.value(Right(detail)));
    final watchTransactionDetail = WatchTransactionDetail(repository);

    final result = await watchTransactionDetail('tx-1').first;

    expect(result.getRight().toNullable(), detail);
  });
}
