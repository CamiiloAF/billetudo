import 'package:billetudo/core/bootstrap/first_launch_offline_cubit.dart';
import 'package:billetudo/core/bootstrap/first_launch_offline_state.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSeedDefaultCategories extends Mock implements SeedDefaultCategories {}

void main() {
  late MockSeedDefaultCategories seedDefaultCategories;

  setUp(() {
    seedDefaultCategories = MockSeedDefaultCategories();
  });

  FirstLaunchOfflineCubit build() =>
      FirstLaunchOfflineCubit(seedDefaultCategories);

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
