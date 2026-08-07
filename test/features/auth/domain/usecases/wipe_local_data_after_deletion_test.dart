import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data_after_deletion.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWipeLocalData extends Mock implements WipeLocalData {}

class MockSeedDefaultCategories extends Mock implements SeedDefaultCategories {}

class MockCrashReporter extends Mock implements CrashReporter {}

void main() {
  late MockWipeLocalData wipeLocalData;
  late MockSeedDefaultCategories seedDefaultCategories;
  late MockCrashReporter crashReporter;
  late WipeLocalDataAfterDeletion useCase;

  setUpAll(() {
    registerFallbackValue(const NetworkFailure('fallback'));
  });

  setUp(() {
    wipeLocalData = MockWipeLocalData();
    seedDefaultCategories = MockSeedDefaultCategories();
    crashReporter = MockCrashReporter();
    useCase = WipeLocalDataAfterDeletion(
      wipeLocalData,
      seedDefaultCategories,
      crashReporter,
    );
    when(seedDefaultCategories.call).thenAnswer((_) async => const Right(unit));
    when(
      () => crashReporter.recordFailure(any(), context: any(named: 'context')),
    ).thenAnswer((_) async {});
  });

  group('HU-07 paso 2: wipe exitoso re-siembra las categorías por defecto', () {
    test(
      'tras un wipe OK invoca SeedDefaultCategories en la misma sesión',
      () async {
        when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));

        final result = await useCase();
        // La re-siembra es best-effort (fire-and-forget), asi que drenamos la
        // cola de eventos antes de verificar la llamada.
        await pumpEventQueue();

        expect(result, const Right<Object, Unit>(unit));
        verify(seedDefaultCategories.call).called(1);
      },
    );

    test(
      'un fallo de la re-siembra NO cambia el resultado del wipe: sigue '
      'siendo éxito y se registra el failure',
      () async {
        when(wipeLocalData.call).thenAnswer((_) async => const Right(unit));
        const seedFailure = NetworkFailure('sin red al re-sembrar');
        when(seedDefaultCategories.call)
            .thenAnswer((_) async => const Left(seedFailure));

        final result = await useCase();
        await pumpEventQueue();

        expect(result, const Right<Object, Unit>(unit));
        verify(
          () => crashReporter.recordFailure(
            seedFailure,
            context: 'reseedDefaultCategoriesAfterAccountDeletionWipe',
          ),
        ).called(1);
      },
    );

    test('NO re-siembra cuando el wipe falla', () async {
      const wipeFailure = DatabaseFailure('no se pudo limpiar');
      when(wipeLocalData.call).thenAnswer((_) async => const Left(wipeFailure));

      final result = await useCase();
      await pumpEventQueue();

      expect(result, const Left<Object, Unit>(wipeFailure));
      verifyNever(seedDefaultCategories.call);
    });
  });
}
