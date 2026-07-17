import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/usecases/set_zero_based_enabled.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late SetZeroBasedEnabled setZeroBasedEnabled;

  setUp(() {
    repository = MockAppSettingsRepository();
    setZeroBasedEnabled = SetZeroBasedEnabled(repository);
  });

  test('HU-06: turns the flag on by delegating to the repository', () async {
    when(() => repository.setZeroBasedEnabled(true))
        .thenAnswer((_) async => const Right(unit));

    final result = await setZeroBasedEnabled(true);

    expect(result.isRight(), isTrue);
    verify(() => repository.setZeroBasedEnabled(true)).called(1);
  });

  test('turns the flag off by delegating to the repository', () async {
    when(() => repository.setZeroBasedEnabled(false))
        .thenAnswer((_) async => const Right(unit));

    final result = await setZeroBasedEnabled(false);

    expect(result.isRight(), isTrue);
    verify(() => repository.setZeroBasedEnabled(false)).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.setZeroBasedEnabled(true)).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await setZeroBasedEnabled(true);

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
