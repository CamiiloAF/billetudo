import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/domain/entities/sign_out_outcome.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out_with_local_data_choice.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignOut extends Mock implements SignOut {}

class MockWipeLocalData extends Mock implements WipeLocalData {}

void main() {
  late MockSignOut signOut;
  late MockWipeLocalData wipeLocalData;
  late SignOutWithLocalDataChoice useCase;

  setUp(() {
    signOut = MockSignOut();
    wipeLocalData = MockWipeLocalData();
    useCase = SignOutWithLocalDataChoice(signOut, wipeLocalData);
  });

  void givenSignOutSucceeds() {
    when(signOut.call).thenAnswer((_) async => const Right(unit));
  }

  group('HU-06: LocalDataChoice.keep', () {
    test('cierra sesion y NUNCA borra los datos locales', () async {
      givenSignOutSucceeds();

      final outcome = await useCase(LocalDataChoice.keep);

      expect(outcome, isA<SignedOutKeepingData>());
      verify(signOut.call).called(1);
      verifyNever(wipeLocalData.call);
    });
  });

  group('HU-06: LocalDataChoice.delete', () {
    test('con wipe OK devuelve SignedOutAndWiped', () async {
      givenSignOutSucceeds();
      when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

      final outcome = await useCase(LocalDataChoice.delete);

      expect(outcome, isA<SignedOutAndWiped>());
      verify(signOut.call).called(1);
      verify(wipeLocalData.call).called(1);
    });

    test(
      'con wipe fallido devuelve SignedOutButWipeFailed con ese failure, '
      'nunca un exito',
      () async {
        givenSignOutSucceeds();
        const failure = DatabaseFailure('no se pudo limpiar la base');
        when(wipeLocalData.call).thenAnswer((_) async => const Left(failure));

        final outcome = await useCase(LocalDataChoice.delete);

        // El caso que se pierde si alguien colapsa el resultado a un bool o a
        // un Result: la sesion se cerro, pero los datos siguen en el telefono.
        expect(outcome, isNot(isA<SignedOutAndWiped>()));
        expect(outcome, isA<SignedOutButWipeFailed>());
        expect((outcome as SignedOutButWipeFailed).failure, same(failure));
      },
    );
  });

  group('HU-06: orden sign out -> wipe (PowerSync ya desconectado)', () {
    test('invoca SignOut antes que WipeLocalData', () async {
      givenSignOutSucceeds();
      when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

      await useCase(LocalDataChoice.delete);

      // Si se invierte el orden en lib/, este verifyInOrder falla: seria el
      // escenario donde un signOut fallido dejaria una sesion viva sobre una
      // base vacia y el sync repoblaria lo que el usuario pidio borrar.
      verifyInOrder([signOut.call, wipeLocalData.call]);
    });

    test(
      'NO invoca WipeLocalData mientras el sign out sigue pendiente '
      '(realmente lo espera)',
      () async {
        final signOutCompleter = Completer<Result<Unit>>();
        when(signOut.call).thenAnswer((_) => signOutCompleter.future);
        when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

        final pending = useCase(LocalDataChoice.delete);
        await pumpEventQueue();

        verify(signOut.call).called(1);
        verifyNever(wipeLocalData.call);

        signOutCompleter.complete(const Right(unit));
        final outcome = await pending;

        expect(outcome, isA<SignedOutAndWiped>());
        verify(wipeLocalData.call).called(1);
      },
    );
  });

  group('HU-06: el Result de SignOut se descarta a proposito', () {
    // Comportamiento heredado del router: un signOut fallido no cambia el
    // desenlace. Queda escrito para que cambiarlo sea deliberado, no un
    // efecto colateral.
    test('signOut fallido + keep sigue siendo SignedOutKeepingData', () async {
      when(signOut.call).thenAnswer(
        (_) async => const Left(NetworkFailure('sin red')),
      );

      final outcome = await useCase(LocalDataChoice.keep);

      expect(outcome, isA<SignedOutKeepingData>());
      verifyNever(wipeLocalData.call);
    });

    test('signOut fallido + delete igual intenta el wipe y reporta su '
        'resultado', () async {
      when(signOut.call).thenAnswer(
        (_) async => const Left(NetworkFailure('sin red')),
      );
      when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

      final outcome = await useCase(LocalDataChoice.delete);

      expect(outcome, isA<SignedOutAndWiped>());
      verify(wipeLocalData.call).called(1);
    });
  });
}
