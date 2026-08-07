import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'account_repository_mock.dart';

void main() {
  late MockAccountRepository repository;
  late StreamController<Result<int>> countController;
  late HasAnyActiveAccount hasAnyActiveAccount;

  setUp(() {
    repository = MockAccountRepository();
    // Single-subscription, not broadcast: it buffers events added before
    // `HasAnyActiveAccount` (or the test's own listener) subscribes, so the
    // `add` calls below never race the `listen`/`expectLater` that consumes
    // them.
    countController = StreamController<Result<int>>();
    when(() => repository.watchActiveAccountsCount())
        .thenAnswer((_) => countController.stream);
    hasAnyActiveAccount = HasAnyActiveAccount(repository);
  });

  tearDown(() => countController.close());

  test(
    'HU-02: emite false cuando no hay ninguna cuenta activa (archivadas y '
    'lápidas ya quedaron fuera del conteo del repositorio)',
    () async {
      final emissions = hasAnyActiveAccount();

      countController.add(const Right(0));

      await expectLater(emissions, emits(false));
    },
  );

  test('emite true en cuanto el conteo pasa a 1 o más', () async {
    final emissions = hasAnyActiveAccount();

    countController
      ..add(const Right(0))
      ..add(const Right(1));

    await expectLater(emissions, emitsInOrder([false, true]));
  });

  test(
    'reacciona sin reinicio: una segunda emisión del repositorio (p. ej. '
    'tras crear la primera cuenta activa) produce una nueva emisión del bool, '
    'no requiere volver a suscribirse',
    () async {
      final emissions = <bool>[];
      final subscription = hasAnyActiveAccount().listen(emissions.add);

      countController.add(const Right(0));
      await pumpEventQueue();
      countController.add(const Right(1));
      await pumpEventQueue();

      expect(emissions, [false, true]);
      await subscription.cancel();
    },
  );

  test('un fallo del repositorio degrada a false, no propaga la excepción',
      () async {
    final emissions = hasAnyActiveAccount();

    countController.add(const Left(DatabaseFailure('sin disco')));

    await expectLater(emissions, emits(false));
  });
}
