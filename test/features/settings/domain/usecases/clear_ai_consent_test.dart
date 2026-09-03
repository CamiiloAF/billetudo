import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/usecases/clear_ai_consent.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late ClearAiConsent clearAiConsent;

  setUp(() {
    repository = MockAppSettingsRepository();
    clearAiConsent = ClearAiConsent(repository);
  });

  test('withdraws the consent by delegating to the repository', () async {
    when(repository.clearAiConsent).thenAnswer((_) async => const Right(unit));

    final result = await clearAiConsent();

    expect(result.isRight(), isTrue);
    verify(repository.clearAiConsent).called(1);
  });

  test(
      'never touches the notes opt-in separately: the repository write is the '
      'single place both columns move, so they cannot half-apply', () async {
    when(repository.clearAiConsent).thenAnswer((_) async => const Right(unit));

    await clearAiConsent();

    verifyNever(
      () => repository.setAiNotesAccessEnabled(enabled: any(named: 'enabled')),
    );
  });

  test('propagates a repository failure', () async {
    when(repository.clearAiConsent)
        .thenAnswer((_) async => const Left(DatabaseFailure('boom')));

    final result = await clearAiConsent();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
