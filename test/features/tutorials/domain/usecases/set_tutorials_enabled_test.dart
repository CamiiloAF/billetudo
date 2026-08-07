import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/tutorials/domain/usecases/set_tutorials_enabled.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'tutorials_repository_mock.dart';

void main() {
  late MockTutorialsRepository repository;
  late SetTutorialsEnabled setTutorialsEnabled;

  setUp(() {
    repository = MockTutorialsRepository();
    setTutorialsEnabled = SetTutorialsEnabled(repository);
  });

  group('turning it off', () {
    test('writes the preference and never touches the registry', () async {
      when(() => repository.setHelpEnabled(enabled: false))
          .thenAnswer((_) async => const Right(unit));

      final result = await setTutorialsEnabled(enabled: false);

      expect(result.isRight(), isTrue);
      verify(() => repository.setHelpEnabled(enabled: false)).called(1);
      verifyNever(() => repository.resetAll());
      verifyNever(() => repository.watchHelpEnabled());
    });
  });

  group('turning it on', () {
    test('writes the preference and never touches the registry', () async {
      when(() => repository.setHelpEnabled(enabled: true))
          .thenAnswer((_) async => const Right(unit));

      final result = await setTutorialsEnabled(enabled: true);

      expect(result.isRight(), isTrue);
      verify(() => repository.setHelpEnabled(enabled: true)).called(1);
      verifyNever(() => repository.resetAll());
      verifyNever(() => repository.watchHelpEnabled());
    });

    test('propagates a setHelpEnabled failure', () async {
      when(() => repository.setHelpEnabled(enabled: true)).thenAnswer(
        (_) async => const Left(DatabaseFailure('boom')),
      );

      final result = await setTutorialsEnabled(enabled: true);

      expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
    });
  });
}
