import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_content.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/domain/usecases/has_seen_tutorial.dart';
import 'package:billetudo/features/tutorials/domain/usecases/mark_tutorial_seen.dart';
import 'package:billetudo/features/tutorials/presentation/cubit/tutorial_gate_cubit.dart';
import 'package:billetudo/features/tutorials/presentation/widgets/tutorial_auto_show.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockTutorialGateCubit extends Mock implements TutorialGateCubit {}

class MockHasSeenTutorial extends Mock implements HasSeenTutorial {}

class MockMarkTutorialSeen extends Mock implements MarkTutorialSeen {}

/// Golden coverage for [TutorialAutoShow]/[reopenTutorial]
/// (`lib/features/tutorials/presentation/widgets/tutorial_auto_show.dart`) —
/// the actual production entry point the 12 minitutorial trigger sites use.
///
/// `test/core/widgets/tutorial_sheet_test.dart` already covers the shared
/// `TutorialSheet` content itself (all 12 `TutorialKey`s x both themes), so
/// this file does not repeat that per-key sweep. What was missing (see
/// `docs/dev-runs/minitutoriales.md`, "no hay goldens de imagen bajo
/// `test/features/tutorials/`") is coverage of the actual overlay behavior:
/// the sheet auto-showing over a real host screen's content, the host
/// rendering undisturbed when the gate skips, and the "Ver ayuda" reopen
/// path — none of which the sheet-only goldens exercise.
void main() {
  late MockTutorialGateCubit gateCubit;
  late MockHasSeenTutorial hasSeenTutorial;
  late MockMarkTutorialSeen markTutorialSeen;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
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

  // A generic stand-in for a real screen's chrome (app bar with a "..." menu
  // affordance + a couple of content cards) — enough to show the sheet
  // rendering over actual host content and its dimmed scrim, without
  // wiring a whole feature's cubit/DI just for a golden of this overlay.
  Widget hostScreen(Widget child) => Scaffold(
        appBar: AppBar(
          title: const Text('Presupuestos'),
          actions: const [
            Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.more_vert),
            ),
          ],
        ),
        body: Column(
          children: [
            const Padding(
              padding: EdgeInsets.all(16),
              child: Card(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Mercado', style: TextStyle(fontWeight: FontWeight.w700)),
                      SizedBox(height: 8),
                      Text('\$450.000 de \$600.000'),
                    ],
                  ),
                ),
              ),
            ),
            Expanded(child: child),
          ],
        ),
      );

  Future<void> golden(
    WidgetTester tester,
    String name,
    Widget widgetUnderTest, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(widgetUnderTest, brightness: brightness),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/tutorial_auto_show_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('HU-01 screen tutorial auto-shows over host screen ($suffix)',
        (tester) async {
      when(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      ).thenAnswer((_) async => true);

      await golden(
        tester,
        'screen_shown_$suffix',
        hostScreen(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.budgetsScreen,
            child: SizedBox.shrink(),
          ),
        ),
        brightness: brightness,
      );
    });

    testWidgets(
        'HU-02 sub-flow tutorial auto-shows over host content ($suffix)',
        (tester) async {
      when(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      ).thenAnswer((_) async => true);

      await golden(
        tester,
        'subflow_shown_$suffix',
        hostScreen(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.debtLinkMovement,
            child: SizedBox.shrink(),
          ),
        ),
        brightness: brightness,
      );
    });

    testWidgets(
        'gate skips (already seen / help off / gate precedence): host '
        'renders undisturbed, no overlay ($suffix)', (tester) async {
      when(
        () => gateCubit.evaluate(
          content: any(named: 'content'),
          accountGateShown: any(named: 'accountGateShown'),
        ),
      ).thenAnswer((_) async => false);

      await golden(
        tester,
        'skipped_$suffix',
        hostScreen(
          const TutorialAutoShow(
            tutorialKey: TutorialKey.budgetsScreen,
            child: SizedBox.shrink(),
          ),
        ),
        brightness: brightness,
      );
    });

    testWidgets(
        '"Ver ayuda" reopens the sheet over the host screen without the '
        'gate ($suffix)', (tester) async {
      await golden(
        tester,
        'reopen_$suffix',
        hostScreen(
          Builder(
            builder: (context) {
              WidgetsBinding.instance.addPostFrameCallback(
                (_) => reopenTutorial(context, TutorialKey.budgetsScreen),
              );
              return const SizedBox.shrink();
            },
          ),
        ),
        brightness: brightness,
      );
    });
  }
}
