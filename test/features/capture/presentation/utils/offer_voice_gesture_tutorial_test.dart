import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/capture/domain/usecases/register_manual_movement_attempt.dart';
import 'package:billetudo/features/capture/presentation/utils/offer_voice_gesture_tutorial.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_content.dart';
import 'package:billetudo/features/tutorials/domain/entities/tutorial_key.dart';
import 'package:billetudo/features/tutorials/domain/usecases/mark_tutorial_seen.dart';
import 'package:billetudo/features/tutorials/presentation/cubit/tutorial_gate_cubit.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockTutorialGateCubit extends Mock implements TutorialGateCubit {}

class _MockMarkTutorialSeen extends Mock implements MarkTutorialSeen {}

class _MockRegisterManualMovementAttempt extends Mock
    implements RegisterManualMovementAttempt {}

/// Holds the action the button's async callback resolves with. A plain local
/// would be read before the sheet closes and the helper returns.
class _ActionRecorder {
  ManualMovementAddAction? action;
}

/// `17-captura-voz.md` HU-02: the voice-gesture tutorial is offered on the
/// 3rd manual `+` attempt, and its secondary button says "Hacerlo manual"
/// because opening the form is exactly what the user was doing.
void main() {
  late _MockTutorialGateCubit gateCubit;
  late _MockMarkTutorialSeen markTutorialSeen;
  late _MockRegisterManualMovementAttempt registerAttempt;

  setUpAll(() {
    registerFallbackValue(TutorialKey.voiceCaptureGesture);
    registerFallbackValue(
      const TutorialContent(
        key: TutorialKey.voiceCaptureGesture,
        title: 'fallback',
        points: [],
        iconName: 'mic',
      ),
    );
  });

  setUp(() {
    gateCubit = _MockTutorialGateCubit();
    markTutorialSeen = _MockMarkTutorialSeen();
    registerAttempt = _MockRegisterManualMovementAttempt();

    getIt
      ..registerFactory<TutorialGateCubit>(() => gateCubit)
      ..registerFactory<MarkTutorialSeen>(() => markTutorialSeen)
      ..registerFactory<RegisterManualMovementAttempt>(() => registerAttempt);

    when(() => markTutorialSeen(any()))
        .thenAnswer((_) async => const Right(unit));
    when(
      () => gateCubit.evaluate(
        content: any(named: 'content'),
        accountGateShown: any(named: 'accountGateShown'),
      ),
    ).thenAnswer((_) async => true);
  });

  tearDown(getIt.reset);

  Future<_ActionRecorder> pumpAndTap(
    WidgetTester tester, {
    required Future<bool> Function() due,
    Future<void> Function(BuildContext context)? startDictation,
  }) async {
    when(() => registerAttempt()).thenAnswer((_) async => Right(await due()));

    final recorder = _ActionRecorder();
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () async {
                recorder.action = await offerVoiceGestureTutorialOnManualAdd(
                  context,
                  startDictation: startDictation,
                );
              },
              child: const Text('add'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('add'));
    await tester.pumpAndSettle();
    return recorder;
  }

  testWidgets(
      'before the third attempt it shows nothing and the caller opens the '
      'manual form', (tester) async {
    final recorder = await pumpAndTap(tester, due: () async => false);

    expect(recorder.action, ManualMovementAddAction.openForm);
    expect(find.byType(BottomSheet), findsNothing);
    verifyNever(
      () => gateCubit.evaluate(
        content: any(named: 'content'),
        accountGateShown: any(named: 'accountGateShown'),
      ),
    );
  });

  testWidgets(
      'the third attempt shows the tutorial, and "Hacerlo manual" opens the '
      'form the user asked for', (tester) async {
    final recorder = await pumpAndTap(tester, due: () async => true);

    final l10n = AppLocalizations.of(tester.element(find.text('add')));
    expect(find.text(l10n.tutorialVoiceCaptureTitle), findsOneWidget);
    expect(find.text(l10n.tutorialVoiceCaptureCta), findsOneWidget);
    expect(find.text(l10n.tutorialVoiceCaptureSecondaryLabel), findsOneWidget);
    expect(find.text(l10n.tutorialGotIt), findsNothing);

    await tester.tap(find.text(l10n.tutorialVoiceCaptureSecondaryLabel));
    await tester.pumpAndSettle();

    expect(recorder.action, ManualMovementAddAction.openForm);
    verify(() => markTutorialSeen(TutorialKey.voiceCaptureGesture)).called(1);
  });

  testWidgets(
      '"Probar ahora" starts the real gesture and tells the caller not to '
      'open the form', (tester) async {
    var dictated = 0;

    final recorder = await pumpAndTap(
      tester,
      due: () async => true,
      startDictation: (_) async => dictated++,
    );

    final l10n = AppLocalizations.of(tester.element(find.text('add')));
    await tester.tap(find.text(l10n.tutorialVoiceCaptureCta));
    await tester.pumpAndSettle();

    expect(recorder.action, ManualMovementAddAction.handled);
    expect(dictated, 1);
  });
}
