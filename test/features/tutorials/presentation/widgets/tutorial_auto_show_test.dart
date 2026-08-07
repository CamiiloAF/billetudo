import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_content.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/domain/usecases/has_seen_tutorial.dart';
import 'package:billetudo/features/tutorials/domain/usecases/mark_tutorial_seen.dart';
import 'package:billetudo/features/tutorials/presentation/cubit/tutorial_gate_cubit.dart';
import 'package:billetudo/features/tutorials/presentation/widgets/tutorial_auto_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockTutorialGateCubit extends Mock implements TutorialGateCubit {}

class MockHasSeenTutorial extends Mock implements HasSeenTutorial {}

class MockMarkTutorialSeen extends Mock implements MarkTutorialSeen {}

/// `TutorialAutoShow`/`maybeShowTutorial`/`reopenTutorial` orchestrate the
/// exact "evaluate, then show, then mark seen, then optionally navigate"
/// sequence every one of the 11 trigger points needs
/// (`docs/requirements/16-minitutoriales.md`). This is the only place that
/// exercises that sequence end to end, criteria 1, 2, 3 and 6.
void main() {
  late MockTutorialGateCubit gateCubit;
  late MockHasSeenTutorial hasSeenTutorial;
  late MockMarkTutorialSeen markTutorialSeen;

  setUpAll(() {
    registerFallbackValue(TutorialKey.budgetsScreen);
    registerFallbackValue(
      const TutorialContent(
        key: TutorialKey.budgetsScreen,
        title: 'fallback',
        points: [],
        iconName: 'wallet',
      ),
    );
  });

  setUp(() {
    gateCubit = MockTutorialGateCubit();
    hasSeenTutorial = MockHasSeenTutorial();
    markTutorialSeen = MockMarkTutorialSeen();

    getIt
      ..registerFactory<TutorialGateCubit>(() => gateCubit)
      ..registerFactory<HasSeenTutorial>(() => hasSeenTutorial)
      ..registerFactory<MarkTutorialSeen>(() => markTutorialSeen);

    when(() => markTutorialSeen(any()))
        .thenAnswer((_) async => const Right(unit));
  });

  tearDown(getIt.reset);

  Widget wrap(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('TutorialAutoShow (criterion 1)', () {
    testWidgets(
        'when the gate says shouldShow, the sheet appears on mount and '
        'markTutorialSeen is called once it closes', (tester) async {
      when(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        wrap(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.budgetsScreen,
            child: Text('screen body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('screen body'), findsOneWidget);
      expect(find.byType(BottomSheet), findsOneWidget);

      final l10n = AppLocalizations.of(
        tester.element(find.byType(BottomSheet)),
      );
      await tester.tap(find.text(l10n.tutorialGotIt));
      await tester.pumpAndSettle();

      verify(() => markTutorialSeen(TutorialKey.budgetsScreen)).called(1);
    });

    testWidgets(
        'when the gate skips (already seen / help off / gate precedence / '
        'chained), no sheet appears and nothing is marked seen',
        (tester) async {
      when(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        wrap(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.budgetsScreen,
            child: Text('screen body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      verifyNever(() => markTutorialSeen(any()));
    });

    testWidgets(
        'passes accountGateShown through to the cubit (criterion 7 wiring)',
        (tester) async {
      when(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      ).thenAnswer((_) async => false);

      await tester.pumpWidget(
        wrap(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.budgetsScreen,
            accountGateShown: true,
            child: Text('screen body'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verify(
        () => gateCubit.evaluate(
            content: any(named: 'content'), accountGateShown: true),
      ).called(1);
    });

    testWidgets(
        'skipIfSeen (e.g. Modo sobres already covered by budgetsScreen): '
        'when that other tutorial was already seen, the gate is never even '
        'evaluated', (tester) async {
      when(() => hasSeenTutorial(TutorialKey.budgetsScreen))
          .thenAnswer((_) async => const Right(true));

      await tester.pumpWidget(
        wrap(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.envelopeMode,
            skipIfSeen: TutorialKey.budgetsScreen,
            child: Text('toggle'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      verifyNever(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      );
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('closing a tutorial sheet (criterion 3)', () {
    testWidgets(
        'dismissing via the standard gesture (tap the scrim) still marks '
        'it seen, exactly like tapping "Entendido"', (tester) async {
      when(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      ).thenAnswer((_) async => true);

      await tester.pumpWidget(
        wrap(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.budgetsScreen,
            child: Text('screen body'),
          ),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(BottomSheet), findsOneWidget);

      // Tap the scrim above the sheet to dismiss via gesture, not a button.
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsNothing);
      verify(() => markTutorialSeen(TutorialKey.budgetsScreen)).called(1);
    });
  });

  group('reopenTutorial ("Ver ayuda", criterion 6 / HU-03)', () {
    testWidgets('shows the sheet directly, without touching the registry',
        (tester) async {
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () =>
                  reopenTutorial(context, TutorialKey.budgetsScreen),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      expect(find.byType(BottomSheet), findsOneWidget);
      verifyNever(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      );
      verifyNever(() => markTutorialSeen(any()));
    });

    testWidgets('tapping its CTA invokes onCta', (tester) async {
      var ctaCalled = false;
      await tester.pumpWidget(
        wrap(
          Builder(
            builder: (context) => TextButton(
              onPressed: () => reopenTutorial(
                context,
                TutorialKey.budgetsScreen,
                onCta: (_) async => ctaCalled = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final l10n = AppLocalizations.of(
        tester.element(find.byType(BottomSheet)),
      );
      await tester.tap(find.text(l10n.tutorialBudgetsCta));
      await tester.pumpAndSettle();

      expect(ctaCalled, isTrue);
    });
  });
}
