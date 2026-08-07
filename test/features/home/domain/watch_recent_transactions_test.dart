import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/home/domain/usecases/watch_recent_transactions.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../transactions/domain/usecases/transaction_repository_mock.dart';
import '../home_fixtures.dart';

/// HU-05 "Movimientos recientes": this use case is a thin pass-through to
/// `TransactionRepository.watchRecentTransactions()` — the one repository
/// method with no date/period bound — so the only thing worth asserting here
/// is that it calls exactly that, with no filter constructed on top.
void main() {
  late MockTransactionRepository repository;
  late WatchRecentTransactions useCase;

  setUp(() {
    repository = MockTransactionRepository();
    useCase = WatchRecentTransactions(repository);
  });

  test('delega en TransactionRepository.watchRecentTransactions() sin filtro',
      () {
    final activity = [buildActivity(id: 'a'), buildActivity(id: 'b')];
    when(() => repository.watchRecentTransactions())
        .thenAnswer((_) => Stream.value(Right(activity)));

    expect(
      useCase(),
      emits(
        isA<Result<Object?>>().having(
          (r) => r.getRight().toNullable(),
          'right',
          activity,
        ),
      ),
    );
    verify(() => repository.watchRecentTransactions()).called(1);
  });
}
