import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_content.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/domain/usecases/has_seen_tutorial.dart';
import 'package:billetudo/features/tutorials/domain/usecases/watch_help_enabled.dart';
import 'package:billetudo/features/tutorials/presentation/cubit/tutorial_gate_cubit.dart';
import 'package:billetudo/features/tutorials/presentation/cubit/tutorial_gate_state.dart';
import 'package:billetudo/features/tutorials/presentation/utils/tutorial_navigation_guard.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockHasSeenTutorial extends Mock implements HasSeenTutorial {}

class MockWatchHelpEnabled extends Mock implements WatchHelpEnabled {}

void main() {
  late MockHasSeenTutorial hasSeenTutorial;
  late MockWatchHelpEnabled watchHelpEnabled;
  late TutorialNavigationGuard navigationGuard;

  const content = TutorialContent(
    key: TutorialKey.budgetsScreen,
    title: 'Así funcionan los presupuestos',
    iconName: 'wallet',
    points: [TutorialPoint(heading: 'Por periodo', body: '...')],
    ctaLabel: 'Crear mi primer presupuesto',
  );

  setUpAll(() {
    registerFallbackValue(TutorialKey.budgetsScreen);
  });

  setUp(() {
    hasSeenTutorial = MockHasSeenTutorial();
    watchHelpEnabled = MockWatchHelpEnabled();
    navigationGuard = TutorialNavigationGuard();
    // Defaults every "should show" test relies on; individual tests override.
    when(watchHelpEnabled.call)
        .thenAnswer((_) => Stream.value(const Right(true)));
    when(() => hasSeenTutorial(any()))
        .thenAnswer((_) async => const Right(false));
  });

  TutorialGateCubit build() =>
      TutorialGateCubit(hasSeenTutorial, watchHelpEnabled, navigationGuard);

  blocTest<TutorialGateCubit, TutorialGateState>(
    'shows when help is enabled, never seen and nothing else claimed the '
    'navigation slot',
    build: build,
    act: (cubit) => cubit.evaluate(content: content),
    expect: () => [
      const TutorialGateState(
        status: TutorialGateStatus.shouldShow,
        content: content,
      ),
    ],
  );

  blocTest<TutorialGateCubit, TutorialGateState>(
    'skips when already seen',
    setUp: () => when(() => hasSeenTutorial(TutorialKey.budgetsScreen))
        .thenAnswer((_) async => const Right(true)),
    build: build,
    act: (cubit) => cubit.evaluate(content: content),
    expect: () => [
      const TutorialGateState(
        status: TutorialGateStatus.skipped,
        skipReason: TutorialSkipReason.alreadySeen,
      ),
    ],
  );

  blocTest<TutorialGateCubit, TutorialGateState>(
    'skips when "Mostrar ayuda al entrar a una sección" is off (HU-04)',
    setUp: () => when(watchHelpEnabled.call)
        .thenAnswer((_) => Stream.value(const Right(false))),
    build: build,
    act: (cubit) => cubit.evaluate(content: content),
    expect: () => [
      const TutorialGateState(
        status: TutorialGateStatus.skipped,
        skipReason: TutorialSkipReason.helpDisabled,
      ),
    ],
  );

  blocTest<TutorialGateCubit, TutorialGateState>(
    'criterion 7: the account gate wins — skips outright and never even '
    'reads the "seen" registry',
    build: build,
    act: (cubit) => cubit.evaluate(content: content, accountGateShown: true),
    expect: () => [
      const TutorialGateState(
        status: TutorialGateStatus.skipped,
        skipReason: TutorialSkipReason.blockedByAccountGate,
      ),
    ],
    verify: (_) => verifyNever(() => hasSeenTutorial(any())),
  );

  test(
    'criterion 5: never chains two tutorials in the same navigation — the '
    'second evaluate() to claim the shared guard loses even though it '
    'otherwise qualifies',
    () async {
      final first = build();
      final second = build();
      addTearDown(first.close);
      addTearDown(second.close);

      await first.evaluate(content: content);
      await second.evaluate(
        content: content.copyWith(key: TutorialKey.debtScheduledInstallment),
      );

      expect(first.state.status, TutorialGateStatus.shouldShow);
      expect(second.state.status, TutorialGateStatus.skipped);
      expect(
        second.state.skipReason,
        TutorialSkipReason.chainedInSameNavigation,
      );
    },
  );

  test(
    'a later evaluate() outside the chaining window claims the slot again',
    () async {
      final first = build();
      final second = build();
      addTearDown(first.close);
      addTearDown(second.close);

      await first.evaluate(content: content);
      // Simulate two evaluations far apart in time (two unrelated visits),
      // not the same navigation.
      navigationGuard.reset();
      await second.evaluate(
        content: content.copyWith(key: TutorialKey.debtScheduledInstallment),
      );

      expect(second.state.status, TutorialGateStatus.shouldShow);
    },
  );
}

extension on TutorialContent {
  TutorialContent copyWith({TutorialKey? key}) => TutorialContent(
        key: key ?? this.key,
        title: title,
        iconName: iconName,
        points: points,
        ctaLabel: ctaLabel,
      );
}
