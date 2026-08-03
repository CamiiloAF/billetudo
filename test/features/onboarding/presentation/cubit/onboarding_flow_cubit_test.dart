import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/onboarding/domain/entities/onboarding_progress.dart';
import 'package:billetudo/features/onboarding/domain/entities/onboarding_step.dart';
import 'package:billetudo/features/onboarding/domain/usecases/complete_onboarding.dart';
import 'package:billetudo/features/onboarding/presentation/cubit/onboarding_flow_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCompleteOnboarding extends Mock implements CompleteOnboarding {}

void main() {
  late MockCompleteOnboarding completeOnboarding;

  setUp(() {
    completeOnboarding = MockCompleteOnboarding();
  });

  OnboardingFlowCubit buildCubit() => OnboardingFlowCubit(completeOnboarding);

  test('starts on Bienvenida, no account skipped, not authenticated', () {
    final cubit = buildCubit();
    expect(cubit.state, const OnboardingProgress());
    unawaited(cubit.close());
  });

  blocTest<OnboardingFlowCubit, OnboardingProgress>(
    'stepped updates the current step',
    build: buildCubit,
    act: (cubit) => cubit.stepped(OnboardingStep.account),
    expect: () => [
      const OnboardingProgress(step: OnboardingStep.account),
    ],
  );

  blocTest<OnboardingFlowCubit, OnboardingProgress>(
    'accountCreated clears accountSkipped',
    build: buildCubit,
    seed: () => const OnboardingProgress(accountSkipped: true),
    act: (cubit) => cubit.accountCreated(),
    expect: () => [const OnboardingProgress()],
  );

  blocTest<OnboardingFlowCubit, OnboardingProgress>(
    'accountSkipped marks the account step as skipped',
    build: buildCubit,
    act: (cubit) => cubit.accountSkipped(),
    expect: () => [const OnboardingProgress(accountSkipped: true)],
  );

  blocTest<OnboardingFlowCubit, OnboardingProgress>(
    'authenticated marks the user as signed in via login',
    build: buildCubit,
    act: (cubit) => cubit.authenticated(),
    expect: () => [const OnboardingProgress(authenticatedViaLogin: true)],
  );

  test('finish delegates to CompleteOnboarding', () async {
    when(() => completeOnboarding())
        .thenAnswer((_) async => const Right(unit));
    final cubit = buildCubit();

    final result = await cubit.finish();

    expect(result.isRight(), isTrue);
    verify(() => completeOnboarding()).called(1);
    await cubit.close();
  });
}
