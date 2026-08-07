import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/domain/usecases/has_seen_tutorial.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'tutorials_repository_mock.dart';

void main() {
  late MockTutorialsRepository repository;
  late HasSeenTutorial hasSeenTutorial;

  setUp(() {
    repository = MockTutorialsRepository();
    hasSeenTutorial = HasSeenTutorial(repository);
  });

  test('delegates to the repository and returns true when already seen',
      () async {
    when(() => repository.hasSeen(TutorialKey.budgetsScreen))
        .thenAnswer((_) async => const Right(true));

    final result = await hasSeenTutorial(TutorialKey.budgetsScreen);

    expect(result.getRight().toNullable(), isTrue);
    verify(() => repository.hasSeen(TutorialKey.budgetsScreen)).called(1);
  });

  test('returns false when never seen', () async {
    when(() => repository.hasSeen(TutorialKey.debtLinkMovement))
        .thenAnswer((_) async => const Right(false));

    final result = await hasSeenTutorial(TutorialKey.debtLinkMovement);

    expect(result.getRight().toNullable(), isFalse);
  });

  test('propagates a repository failure', () async {
    when(() => repository.hasSeen(TutorialKey.goalsScreen)).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await hasSeenTutorial(TutorialKey.goalsScreen);

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
