import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/domain/usecases/mark_tutorial_seen.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'tutorials_repository_mock.dart';

void main() {
  late MockTutorialsRepository repository;
  late MarkTutorialSeen markTutorialSeen;

  setUp(() {
    repository = MockTutorialsRepository();
    markTutorialSeen = MarkTutorialSeen(repository);
  });

  test('delegates to the repository', () async {
    when(() => repository.markSeen(TutorialKey.debtsScreen))
        .thenAnswer((_) async => const Right(unit));

    final result = await markTutorialSeen(TutorialKey.debtsScreen);

    expect(result.isRight(), isTrue);
    verify(() => repository.markSeen(TutorialKey.debtsScreen)).called(1);
  });

  test('propagates a repository failure', () async {
    when(() => repository.markSeen(TutorialKey.envelopeMode)).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await markTutorialSeen(TutorialKey.envelopeMode);

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
