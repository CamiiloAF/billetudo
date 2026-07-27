import 'dart:async';

import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/local_data_choice.dart';
import 'package:billetudo/features/auth/domain/entities/sign_out_outcome.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out_with_local_data_choice.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignOut extends Mock implements SignOut {}

class MockWipeLocalData extends Mock implements WipeLocalData {}

class MockSeedDefaultCategories extends Mock implements SeedDefaultCategories {}

class MockCrashReporter extends Mock implements CrashReporter {}

void main() {
  late MockSignOut signOut;
  late MockWipeLocalData wipeLocalData;
  late MockSeedDefaultCategories seedDefaultCategories;
  late MockCrashReporter crashReporter;
  late SignOutWithLocalDataChoice useCase;

  setUpAll(() {
    registerFallbackValue(const NetworkFailure('fallback'));
  });

  setUp(() {
    signOut = MockSignOut();
    wipeLocalData = MockWipeLocalData();
    seedDefaultCategories = MockSeedDefaultCategories();
    crashReporter = MockCrashReporter();
    useCase = SignOutWithLocalDataChoice(
      signOut,
      wipeLocalData,
      seedDefaultCategories,
      crashReporter,
    );
    // Re-seed defaults after a wipe: idempotent, succeeds by default.
    when(seedDefaultCategories.call).thenAnswer((_) async => const Right(unit));
    when(
      () => crashReporter.recordFailure(any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
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

  group('HU-06: re-siembra las categorias por defecto tras un wipe OK', () {
    test(
      'tras SignedOutAndWiped invoca SeedDefaultCategories en la misma sesion',
      () async {
        givenSignOutSucceeds();
        when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

        final outcome = await useCase(LocalDataChoice.delete);
        // La re-siembra es best-effort (fire-and-forget), asi que drenamos la
        // cola de eventos antes de verificar la llamada.
        await pumpEventQueue();

        expect(outcome, isA<SignedOutAndWiped>());
        verify(seedDefaultCategories.call).called(1);
      },
    );

    test('NO re-siembra cuando el usuario conserva sus datos (keep)', () async {
      givenSignOutSucceeds();

      final outcome = await useCase(LocalDataChoice.keep);
      await pumpEventQueue();

      expect(outcome, isA<SignedOutKeepingData>());
      verifyNever(seedDefaultCategories.call);
    });

    test('NO re-siembra cuando el wipe falla', () async {
      givenSignOutSucceeds();
      when(wipeLocalData.call).thenAnswer(
        (_) async => const Left(DatabaseFailure('no se pudo limpiar')),
      );

      final outcome = await useCase(LocalDataChoice.delete);
      await pumpEventQueue();

      expect(outcome, isA<SignedOutButWipeFailed>());
      verifyNever(seedDefaultCategories.call);
    });

    test(
      'un fallo de la re-siembra NO cambia el desenlace: sigue siendo '
      'SignedOutAndWiped y se registra el failure',
      () async {
        givenSignOutSucceeds();
        when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));
        // Sin conexion en el momento del sign-out: el catalogo vive en
        // Supabase, asi que la siembra puede fallar. El proximo arranque
        // re-siembra igual gracias al latch reseteado por el wipe.
        const seedFailure = NetworkFailure('sin red al re-sembrar');
        when(seedDefaultCategories.call)
            .thenAnswer((_) async => const Left(seedFailure));

        final outcome = await useCase(LocalDataChoice.delete);
        await pumpEventQueue();

        expect(outcome, isA<SignedOutAndWiped>());
        verify(
          () => crashReporter.recordFailure(
            seedFailure,
            context: 'reseedDefaultCategoriesAfterWipe',
          ),
        ).called(1);
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

  group('HU-06: un SignOut fallido aborta todo (SignOutFailed)', () {
    // Antes este grupo afirmaba lo contrario ("el Result de SignOut se
    // descarta a proposito"): `signOut()` disparaba sus pasos con `unawaited`
    // y siempre devolvia Right, asi que el Result no traia informacion. Ahora
    // los espera y puede fallar, y ese fallo es el cuarto desenlace.
    const failure = NetworkFailure('sin red');

    void givenSignOutFails() {
      when(signOut.call).thenAnswer((_) async => const Left(failure));
    }

    test('con keep devuelve SignOutFailed, no SignedOutKeepingData', () async {
      givenSignOutFails();

      final outcome = await useCase(LocalDataChoice.keep);

      expect(outcome, isA<SignOutFailed>());
      expect((outcome as SignOutFailed).failure, same(failure));
      verifyNever(wipeLocalData.call);
    });

    test(
      'con delete NO borra nada: la sesion sigue viva y el sync repoblaria '
      'lo borrado al reabrir la app',
      () async {
        givenSignOutFails();
        when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

        final outcome = await useCase(LocalDataChoice.delete);

        expect(outcome, isA<SignOutFailed>());
        expect((outcome as SignOutFailed).failure, same(failure));
        // Lo importante del cambio: el desenlace se decide ANTES de mirar la
        // eleccion del usuario. Confirmarle un borrado que la proxima apertura
        // deshace es peor que no borrar.
        verifyNever(wipeLocalData.call);
      },
    );

    test('SignOutFailed nunca se confunde con un desenlace exitoso', () async {
      givenSignOutFails();
      when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

      final outcome = await useCase(LocalDataChoice.delete);

      expect(outcome, isNot(isA<SignedOutAndWiped>()));
      expect(outcome, isNot(isA<SignedOutKeepingData>()));
      // Tampoco es el "sesion cerrada pero el wipe fallo": ahi la sesion SI
      // se cerro, y el mensaje que le toca al usuario es otro.
      expect(outcome, isNot(isA<SignedOutButWipeFailed>()));
    });
  });
}
