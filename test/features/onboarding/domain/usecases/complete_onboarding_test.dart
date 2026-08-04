import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:billetudo/features/settings/domain/usecases/set_onboarding_completed.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSetOnboardingCompleted extends Mock
    implements SetOnboardingCompleted {}

void main() {
  late MockSetOnboardingCompleted setOnboardingCompleted;
  late CompleteOnboarding completeOnboarding;

  setUp(() {
    setOnboardingCompleted = MockSetOnboardingCompleted();
    completeOnboarding = CompleteOnboarding(setOnboardingCompleted);
  });

  test('closes the flow by delegating to SetOnboardingCompleted', () async {
    when(() => setOnboardingCompleted())
        .thenAnswer((_) async => const Right(unit));

    final result = await completeOnboarding();

    expect(result.isRight(), isTrue);
    verify(() => setOnboardingCompleted()).called(1);
  });

  test('propagates a failure', () async {
    when(() => setOnboardingCompleted()).thenAnswer(
      (_) async => const Left(DatabaseFailure('boom')),
    );

    final result = await completeOnboarding();

    expect(result.getLeft().toNullable(), isA<DatabaseFailure>());
  });
}
