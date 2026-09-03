import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/settings/domain/usecases/set_ai_notes_access_enabled.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'app_settings_repository_mock.dart';

void main() {
  late MockAppSettingsRepository repository;
  late SetAiNotesAccessEnabled setAiNotesAccessEnabled;

  setUp(() {
    repository = MockAppSettingsRepository();
    setAiNotesAccessEnabled = SetAiNotesAccessEnabled(repository);
  });

  test('lets the assistant read notes by delegating to the repository',
      () async {
    when(() => repository.setAiNotesAccessEnabled(enabled: true))
        .thenAnswer((_) async => const Right(unit));

    final result = await setAiNotesAccessEnabled(enabled: true);

    expect(result.isRight(), isTrue);
    verify(() => repository.setAiNotesAccessEnabled(enabled: true)).called(1);
  });

  test('takes the access away again by delegating to the repository', () async {
    when(() => repository.setAiNotesAccessEnabled(enabled: false))
        .thenAnswer((_) async => const Right(unit));

    final result = await setAiNotesAccessEnabled(enabled: false);

    expect(result.isRight(), isTrue);
    verify(() => repository.setAiNotesAccessEnabled(enabled: false)).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.setAiNotesAccessEnabled(enabled: true))
        .thenAnswer((_) async => const Left(DatabaseFailure('boom')));

    final result = await setAiNotesAccessEnabled(enabled: true);

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
