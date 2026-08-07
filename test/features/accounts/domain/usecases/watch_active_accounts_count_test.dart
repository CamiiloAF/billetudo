import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late StreamController<Result<int>> countController;
  late WatchActiveAccountsCount watchActiveAccountsCount;

  setUp(() {
    repository = MockAccountRepository();
    countController = StreamController<Result<int>>();
    when(() => repository.watchActiveAccountsCount())
        .thenAnswer((_) => countController.stream);
    watchActiveAccountsCount = WatchActiveAccountsCount(repository);
  });

  tearDown(() => countController.close());

  test(
    'expone el conteo exacto — no solo si hay alguna: la transferencia '
    'necesita distinguir 0/1/2+',
    () async {
      final emissions = watchActiveAccountsCount();

      countController.add(const Right(0));

      await expectLater(emissions, emits(0));
    },
  );

  test('reacciona a cada cambio del repositorio sin volver a suscribirse',
      () async {
    final emissions = <int>[];
    final subscription = watchActiveAccountsCount().listen(emissions.add);

    countController.add(const Right(0));
    await pumpEventQueue();
    countController.add(const Right(1));
    await pumpEventQueue();
    countController.add(const Right(2));
    await pumpEventQueue();

    expect(emissions, [0, 1, 2]);
    await subscription.cancel();
  });

  test('un fallo del repositorio degrada a 0, no propaga la excepción',
      () async {
    final emissions = watchActiveAccountsCount();

    countController.add(const Left(DatabaseFailure('sin disco')));

    await expectLater(emissions, emits(0));
  });
}
