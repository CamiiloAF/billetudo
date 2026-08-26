import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_cubit.dart';
import 'package:billetudo/features/ai/presentation/cubit/ai_consent_state.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/domain/usecases/get_app_settings.dart';
import 'package:billetudo/features/settings/domain/usecases/mark_ai_consent_accepted.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetAppSettings extends Mock implements GetAppSettings {}

class MockMarkAiConsentAccepted extends Mock implements MarkAiConsentAccepted {}

void main() {
  late MockGetAppSettings getAppSettings;
  late MockMarkAiConsentAccepted markAiConsentAccepted;

  setUp(() {
    getAppSettings = MockGetAppSettings();
    markAiConsentAccepted = MockMarkAiConsentAccepted();
  });

  AiConsentCubit build() =>
      AiConsentCubit(getAppSettings, markAiConsentAccepted);

  blocTest<AiConsentCubit, AiConsentState>(
    'reports required when aiConsentAcceptedAt is null',
    setUp: () => when(getAppSettings.call).thenAnswer(
      (_) => Stream.value(const Right(AppSettings.defaults())),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<AiConsentState>()
          .having((s) => s.status, 'status', AiConsentStatus.required),
    ],
  );

  blocTest<AiConsentCubit, AiConsentState>(
    'reports granted when aiConsentAcceptedAt is set',
    setUp: () => when(getAppSettings.call).thenAnswer(
      (_) => Stream.value(
        Right(
          const AppSettings.defaults().copyWith(
            aiConsentAcceptedAt: DateTime(2026, 8, 25),
          ),
        ),
      ),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<AiConsentState>()
          .having((s) => s.status, 'status', AiConsentStatus.granted),
    ],
  );

  blocTest<AiConsentCubit, AiConsentState>(
    'a stream failure fails closed to required',
    setUp: () => when(getAppSettings.call).thenAnswer(
      (_) => Stream.value(const Left(DatabaseFailure('boom'))),
    ),
    build: build,
    act: (cubit) => cubit.start(),
    skip: 1,
    expect: () => [
      isA<AiConsentState>()
          .having((s) => s.status, 'status', AiConsentStatus.required),
    ],
  );

  blocTest<AiConsentCubit, AiConsentState>(
    'accept() writes the consent and reports granted',
    setUp: () => when(markAiConsentAccepted.call)
        .thenAnswer((_) async => const Right(unit)),
    build: build,
    act: (cubit) => cubit.accept(),
    expect: () => [
      isA<AiConsentState>().having((s) => s.accepting, 'accepting', true),
      isA<AiConsentState>()
          .having((s) => s.accepting, 'accepting', false)
          .having((s) => s.status, 'status', AiConsentStatus.granted),
    ],
  );

  blocTest<AiConsentCubit, AiConsentState>(
    'a failed write stays required and clears the spinner',
    setUp: () => when(markAiConsentAccepted.call)
        .thenAnswer((_) async => const Left(DatabaseFailure('boom'))),
    build: build,
    act: (cubit) => cubit.accept(),
    expect: () => [
      isA<AiConsentState>().having((s) => s.accepting, 'accepting', true),
      isA<AiConsentState>()
          .having((s) => s.accepting, 'accepting', false)
          .having((s) => s.status, 'status', AiConsentStatus.checking),
    ],
  );
}
