import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/usecases/has_any_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'transaction_repository_mock.dart';

void main() {
  late MockTransactionRepository repository;
  late StreamController<Result<int>> countController;
  late HasAnyTransaction hasAnyTransaction;

  setUp(() {
    repository = MockTransactionRepository();
    // Single-subscription, not broadcast: it buffers events added before
    // `HasAnyTransaction` (or the test's own listener) subscribes, so the
    // `add` calls below never race the `listen`/`expectLater` that consumes
    // them.
    countController = StreamController<Result<int>>();
    when(() => repository.watchActiveTransactionsCount())
        .thenAnswer((_) => countController.stream);
    hasAnyTransaction = HasAnyTransaction(repository);
  });

  tearDown(() => countController.close());

  test(
    'emite false cuando no hay ningún movimiento activo (Import/Export: '
    'hub Am9cg y export calDR)',
    () async {
      final emissions = hasAnyTransaction();

      countController.add(const Right(0));

      await expectLater(emissions, emits(false));
    },
  );

  test('emite true en cuanto el conteo pasa a 1 o más', () async {
    final emissions = hasAnyTransaction();

    countController
      ..add(const Right(0))
      ..add(const Right(1));

    await expectLater(emissions, emitsInOrder([false, true]));
  });

  test('un fallo del repositorio degrada a false, no propaga la excepción',
      () async {
    final emissions = hasAnyTransaction();

    countController.add(const Left(DatabaseFailure('sin disco')));

    await expectLater(emissions, emits(false));
  });
}
