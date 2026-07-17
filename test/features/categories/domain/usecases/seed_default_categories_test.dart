import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/usecases/seed_default_categories.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../settings/domain/usecases/app_settings_repository_mock.dart';
import 'category_repository_mock.dart';

void main() {
  late MockCategoryRepository repository;
  late MockAppSettingsRepository settingsRepository;
  late SeedDefaultCategories seedDefaultCategories;

  AppSettings settings({required bool categoriesSeeded}) => AppSettings(
        zeroBasedEnabled: false,
        categoriesSeeded: categoriesSeeded,
      );

  setUp(() {
    repository = MockCategoryRepository();
    settingsRepository = MockAppSettingsRepository();
    seedDefaultCategories =
        SeedDefaultCategories(repository, settingsRepository);
  });

  test(
      'HU-06: siembra el set semilla y marca el flag cuando no hay flag ni '
      'categorías', () async {
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => Right(settings(categoriesSeeded: false)));
    when(() => repository.hasAnyCategory())
        .thenAnswer((_) async => const Right(false));
    when(() => repository.seedDefaultCategories())
        .thenAnswer((_) async => const Right(unit));
    when(() => settingsRepository.markCategoriesSeeded())
        .thenAnswer((_) async => const Right(unit));

    final result = await seedDefaultCategories();

    expect(result.isRight(), isTrue);
    verify(() => repository.seedDefaultCategories()).called(1);
    verify(() => settingsRepository.markCategoriesSeeded()).called(1);
  });

  test(
      'no siembra pero marca el flag si el usuario ya tiene categorías '
      '(pre-migración)', () async {
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => Right(settings(categoriesSeeded: false)));
    when(() => repository.hasAnyCategory())
        .thenAnswer((_) async => const Right(true));
    when(() => settingsRepository.markCategoriesSeeded())
        .thenAnswer((_) async => const Right(unit));

    final result = await seedDefaultCategories();

    expect(result.isRight(), isTrue);
    verifyNever(() => repository.seedDefaultCategories());
    verify(() => settingsRepository.markCategoriesSeeded()).called(1);
  });

  test(
      'es idempotente por el flag: no siembra aunque no haya categorías '
      '(el usuario las borró todas)', () async {
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => Right(settings(categoriesSeeded: true)));

    final result = await seedDefaultCategories();

    expect(result.isRight(), isTrue);
    verifyNever(() => repository.hasAnyCategory());
    verifyNever(() => repository.seedDefaultCategories());
    verifyNever(() => settingsRepository.markCategoriesSeeded());
  });

  test('propaga el fallo si no puede leer los settings', () async {
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await seedDefaultCategories();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    verifyNever(() => repository.hasAnyCategory());
    verifyNever(() => repository.seedDefaultCategories());
    verifyNever(() => settingsRepository.markCategoriesSeeded());
  });

  test('propaga el fallo si no puede verificar si ya hay categorías', () async {
    when(() => settingsRepository.getSettings())
        .thenAnswer((_) async => Right(settings(categoriesSeeded: false)));
    when(() => repository.hasAnyCategory())
        .thenAnswer((_) async => const Left(DatabaseFailure('sin disco')));

    final result = await seedDefaultCategories();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    verifyNever(() => repository.seedDefaultCategories());
    verifyNever(() => settingsRepository.markCategoriesSeeded());
  });
}
