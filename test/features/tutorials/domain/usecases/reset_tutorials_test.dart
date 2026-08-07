import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/tutorials/domain/usecases/reset_tutorials.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'tutorials_repository_mock.dart';

void main() {
  late MockTutorialsRepository repository;
  late ResetTutorials resetTutorials;

  setUp(() {
    repository = MockTutorialsRepository();
    resetTutorials = ResetTutorials(repository);
  });

  test('delegates to the repository', () async {
    when(() => repository.resetAll())
        .thenAnswer((_) async => const Right(unit));

    final result = await resetTutorials();

    expect(result.isRight(), isTrue);
    verify(() => repository.resetAll()).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.resetAll())
        .thenAnswer((_) async => const Left(DatabaseFailure('boom')));

    final result = await resetTutorials();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
