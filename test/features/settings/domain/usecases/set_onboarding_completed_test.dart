import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/usecases/set_onboarding_completed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late SetOnboardingCompleted setOnboardingCompleted;

  setUp(() {
    repository = MockAppSettingsRepository();
    setOnboardingCompleted = SetOnboardingCompleted(repository);
  });

  test('latches the welcome flow as completed by delegating to the repository',
      () async {
    when(() => repository.markOnboardingCompleted())
        .thenAnswer((_) async => const Right(unit));

    final result = await setOnboardingCompleted();

    expect(result.isRight(), isTrue);
    verify(() => repository.markOnboardingCompleted()).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.markOnboardingCompleted()).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await setOnboardingCompleted();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
