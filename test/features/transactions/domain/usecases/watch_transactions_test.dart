import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/domain/usecases/watch_transactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../transaction_fixtures.dart';
import 'transaction_repository_mock.dart';

void main() {
  setUpAll(registerTransactionFallbacks);

  test('HU-06: pasa el filtro tal cual al repositorio y expone su stream',
      () async {
    final repository = MockTransactionRepository();
    final filter = TransactionFilter(searchText: 'café');
    final details = [
      TransactionWithDetails(
        transaction: buildTransaction(),
        accountName: 'Efectivo',
      ),
    ];
    when(() => repository.watchTransactions(filter))
        .thenAnswer((_) => Stream.value(Right(details)));
    final watchTransactions = WatchTransactions(repository);

    final result = await watchTransactions(filter).first;

    expect(result.getRight().toNullable(), details);
    verify(() => repository.watchTransactions(filter)).called(1);
  });
}
