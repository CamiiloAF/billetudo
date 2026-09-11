import 'package:billetudo/core/bootstrap/first_launch_offline_cubit.dart';
import 'package:billetudo/core/bootstrap/first_launch_offline_state.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/legal/domain/repositories/legal_documents_repository.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSeedDefaultCategories extends Mock implements SeedDefaultCategories {}

class MockLegalDocumentsRepository extends Mock
    implements LegalDocumentsRepository {}

void main() {
  late MockSeedDefaultCategories seedDefaultCategories;
  late MockLegalDocumentsRepository legalDocuments;

  setUp(() {
    seedDefaultCategories = MockSeedDefaultCategories();
    legalDocuments = MockLegalDocumentsRepository();
    when(() => legalDocuments.refreshFromRemote()).thenAnswer((_) async {});
  });

  FirstLaunchOfflineCubit build() =>
      FirstLaunchOfflineCubit(seedDefaultCategories, legalDocuments);

  blocTest<FirstLaunchOfflineCubit, FirstLaunchOfflineState>(
    'retry exitoso emite retrying y luego success',
    build: build,
    setUp: () => when(() => seedDefaultCategories())
        .thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.retry(),
    expect: () => [
      const FirstLaunchOfflineState(status: FirstLaunchOfflineStatus.retrying),
      const FirstLaunchOfflineState(status: FirstLaunchOfflineStatus.success),
    ],
  );

  blocTest<FirstLaunchOfflineCubit, FirstLaunchOfflineState>(
    'un retry exitoso también dispara la descarga legal en segundo plano',
    build: build,
    setUp: () => when(() => seedDefaultCategories())
        .thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.retry(),
    verify: (_) => verify(legalDocuments.refreshFromRemote).called(1),
  );

  blocTest<FirstLaunchOfflineCubit, FirstLaunchOfflineState>(
    'un retry que sigue fallando por red vuelve a idle, sin estado de error',
    build: build,
    setUp: () => when(() => seedDefaultCategories()).thenAnswer(
      (_) async => const Left(NetworkFailure('still offline')),
    ),
    act: (cubit) => cubit.retry(),
    expect: () => [
      const FirstLaunchOfflineState(status: FirstLaunchOfflineStatus.retrying),
      const FirstLaunchOfflineState(),
    ],
  );
}
