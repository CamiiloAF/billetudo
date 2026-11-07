import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/repositories/manual_movement_attempt_repository.dart';
import 'package:billetudo/features/capture/domain/usecases/register_manual_movement_attempt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockManualMovementAttemptRepository extends Mock
    implements ManualMovementAttemptRepository {}

/// `17-captura-voz.md` HU-02: the voice-gesture tutorial is offered on the
/// third manual `+` attempt — not on the first, and not again afterwards.
void main() {
  late _MockManualMovementAttemptRepository repository;

  setUp(() => repository = _MockManualMovementAttemptRepository());

  Future<bool> attemptNumber(int count) async {
    when(() => repository.registerAttempt())
        .thenAnswer((_) async => Right(count));
    final result = await RegisterManualMovementAttempt(repository)();
    return result.getOrElse((_) => throw StateError('expected Right'));
  }

  test('the 1st and 2nd manual attempts do not offer the tutorial', () async {
    expect(await attemptNumber(1), isFalse);
    expect(await attemptNumber(2), isFalse);
  });

  test('the 3rd manual attempt offers it', () async {
    expect(
      await attemptNumber(
        RegisterManualMovementAttempt.attemptsBeforeOfferingTutorial,
      ),
      isTrue,
    );
  });

  test(
      'the counter cycles, so resetting tutorials can bring it back: '
      '4/5 are not due, 6 is', () async {
    expect(await attemptNumber(4), isFalse);
    expect(await attemptNumber(5), isFalse);
    expect(await attemptNumber(6), isTrue);
  });

  test('a storage failure answers "not due" instead of offering blindly',
      () async {
    when(() => repository.registerAttempt()).thenAnswer(
      (_) async => const Left(UnexpectedFailure('boom')),
    );

    final result = await RegisterManualMovementAttempt(repository)();

    expect(result, isA<Left<Failure, bool>>());
  });
}
