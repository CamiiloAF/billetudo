import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/domain/entities/ai_consent.dart';
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
    'reports granted when the consent was accepted against current copy',
    setUp: () => when(getAppSettings.call).thenAnswer(
      (_) => Stream.value(
        Right(
          const AppSettings.defaults().copyWith(
            aiConsentAcceptedAt: DateTime(2026, 8, 25),
            aiConsentVersion: currentAiConsentVersion,
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
    'asks again when the accepted version predates the current copy — a '
    'consent given to a narrower disclosure is not consent to this one '
    '(Apple 5.1.2(i))',
    setUp: () => when(getAppSettings.call).thenAnswer(
      (_) => Stream.value(
        Right(
          const AppSettings.defaults().copyWith(
            aiConsentAcceptedAt: DateTime(2026, 8, 25),
            aiConsentVersion: currentAiConsentVersion - 1,
          ),
        ),
      ),
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
    'asks again when a timestamp carries no version at all (read as 0)',
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
          .having((s) => s.status, 'status', AiConsentStatus.required),
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

  // This cubit has no withdrawal path of its own: withdrawing lives in Ajustes
  // (`AppSettingsCubit` → `ClearAiConsent`), which nulls the persisted columns
  // and nothing else. What makes the withdrawal actually close the chat is
  // this cubit reading the row back off `GetAppSettings` instead of trusting
  // an in-memory `granted` — so that is what gets tested here, against the
  // real path rather than a method call.
  blocTest<AiConsentCubit, AiConsentState>(
    'the gate is not cached in memory: once the settings row loses its '
    'consent, the stream re-reports required with no relaunch (RGPD art. 7.3)',
    setUp: () => when(getAppSettings.call).thenAnswer(
      // `AppSettings.defaults()` is the shape `ClearAiConsent` leaves behind:
      // both consent columns null.
      (_) => Stream.value(const Right(AppSettings.defaults())),
    ),
    build: build,
    seed: () => const AiConsentState(status: AiConsentStatus.granted),
    act: (cubit) => cubit.start(),
    verify: (cubit) => expect(cubit.state.status, AiConsentStatus.required),
  );
}
