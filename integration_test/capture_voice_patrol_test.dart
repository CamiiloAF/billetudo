// Patrol e2e for voice capture (Fase 2, `docs/requirements/fase-2/17-captura-voz.md`).
// Runs the real app — real DI graph, real on-device Drift database, real
// go_router navigation. Every layer above `SpeechRecognizer` is real: the
// cubit, the parsing pipeline (`ParseSpokenTransaction` and its 5 extractors),
// the router puentes and `TransactionFormCubit.completeFromVoice`/`loadFromVoice`
// all run exactly as they would on a phone.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak state
// into each other even though they share one app process.
//
// ## Why the recognizer (and the microphone permission) are faked
//
// Patrol cannot simulate real audio or drive the OS speech recognizer, and
// `permission_handler`'s system dialog cannot be answered from a Patrol
// scenario without a native automator step this suite does not set up. Both
// live behind a `domain` interface for exactly this reason
// (`SpeechRecognizer`/`MicrophonePermissionGate`, both `@LazySingleton`), so
// this file swaps their `getIt` registration for a scripted fake right after
// `startApp` — the same "fake the one boundary Patrol cannot drive, keep
// everything above it real" approach `goals_patrol_test.dart`'s sibling
// suites use for a `MethodChannel`, just at the DI layer instead of the
// platform-channel layer since this boundary is a domain interface, not a
// channel. `getIt.reset()` runs inside every `startApp` call, so the fake
// must be reinstalled after each one.
//
// `_ScriptedSpeechRecognizer.transcript` stands in for "what the user said":
// `start()` opens the session (emits `listening`), `stop()` closes it and
// emits the scripted transcript as a final result — the same path
// `SpeechToTextRecognizer._onResult(finalResult: true)` takes on a real
// device, so `VoiceCaptureCubit._finish` and the real `ParseSpokenTransaction`
// run unmodified against it.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:billetudo/features/capture/domain/repositories/microphone_permission_gate.dart';
import 'package:billetudo/features/capture/domain/repositories/speech_recognizer.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

const _money = MoneyFormatter();

String _formatted(int amountMinor) =>
    _money.formatSymbol(amountMinor, currencyCode: 'COP');

/// Seeds one active account directly against the real Drift database — the
/// precondition `15-gate-cuenta.md` requires before either voice trigger will
/// proceed past its account gate.
Future<Account> _seedAccount(AppDatabase db, String name) =>
    db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: name,
            type: AccountType.cash,
            currency: 'COP',
          ),
        );

/// A scripted stand-in for the platform recognizer (see file header).
///
/// [transcript] is read lazily by [stop], not captured at construction, so
/// one instance can be reused across a scenario's retries if a future
/// scenario needs that; every scenario in this file only ever calls [start]
/// once, though.
class _ScriptedSpeechRecognizer implements SpeechRecognizer {
  _ScriptedSpeechRecognizer(this.transcript);

  String transcript;

  final StreamController<SpeechRecognitionUpdate> _updates =
      StreamController<SpeechRecognitionUpdate>.broadcast();

  bool _listening = false;

  @override
  Stream<SpeechRecognitionUpdate> get updates => _updates.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<Result<SpeechRecognizerAvailability>> prepare({
    required String localeId,
  }) async =>
      const Right(
        SpeechRecognizerAvailability(
          isAvailable: true,
          isLocaleSupported: true,
          route: SpeechRecognitionRoute.onDevice,
        ),
      );

  @override
  Future<Result<Unit>> start({
    required String localeId,
    bool allowCloudRecognition = false,
    Duration maxDuration = VoiceCaptureLimits.maxListenDuration,
    Duration pauseFor = VoiceCaptureLimits.pauseForSilence,
  }) async {
    _listening = true;
    _updates.add(
      const SpeechRecognitionUpdate(phase: SpeechRecognitionPhase.listening),
    );
    return const Right(unit);
  }

  /// Ends the session with [transcript] as the final result — what tapping
  /// "Listo" (`VoiceCaptureCubit.stopListening`) drives on a real device.
  @override
  Future<Result<Unit>> stop() async {
    _listening = false;
    _updates.add(
      SpeechRecognitionUpdate(
        phase: SpeechRecognitionPhase.done,
        transcript: transcript,
        isFinal: true,
      ),
    );
    return const Right(unit);
  }

  @override
  Future<Result<Unit>> cancel() async {
    _listening = false;
    _updates.add(
      const SpeechRecognitionUpdate(phase: SpeechRecognitionPhase.done),
    );
    return const Right(unit);
  }
}

/// Always-granted microphone gate: the system permission dialog is not
/// something Patrol can answer here (see file header), so this reflects the
/// state a real device would be in once the user has granted it once.
class _AlwaysGrantedMicrophoneGate implements MicrophonePermissionGate {
  const _AlwaysGrantedMicrophoneGate();

  @override
  Future<MicrophonePermissionStatus> current() async =>
      MicrophonePermissionStatus.granted;

  @override
  Future<MicrophonePermissionStatus> request() async =>
      MicrophonePermissionStatus.granted;

  @override
  Future<bool> openSystemSettings() async => true;
}

/// Swaps `getIt`'s `SpeechRecognizer`/`MicrophonePermissionGate`
/// registrations for the fakes above. Must run after `startApp` (which
/// resets the whole `getIt` graph) and before anything that resolves
/// `VoiceCaptureCubit`, which is every `@injectable` class transitively built
/// on top of both.
Future<_ScriptedSpeechRecognizer> _installFakeVoiceCapture(
  String transcript,
) async {
  final recognizer = _ScriptedSpeechRecognizer(transcript);
  if (getIt.isRegistered<SpeechRecognizer>()) {
    await getIt.unregister<SpeechRecognizer>();
  }
  getIt.registerLazySingleton<SpeechRecognizer>(() => recognizer);
  if (getIt.isRegistered<MicrophonePermissionGate>()) {
    await getIt.unregister<MicrophonePermissionGate>();
  }
  getIt.registerLazySingleton<MicrophonePermissionGate>(
    () => const _AlwaysGrantedMicrophoneGate(),
  );
  return recognizer;
}

/// Bounded poll for [finder], same pattern every sibling Patrol suite in this
/// repo uses for content behind an async Drift stream or a chain of awaited
/// use cases (`goals_patrol_test.dart`'s own `_pumpUntilFound`) — here it
/// covers `VoiceCaptureCubit.start`'s own await chain (cloud consent, the
/// vocabulary load, `GetVoiceCaptureAvailability`) between the long-press and
/// the sheet actually reaching `VoiceCaptureStatus.listening`.
Future<void> _pumpUntilFound(
  PatrolIntegrationTester $,
  Finder finder, {
  int maxFrames = 50,
}) async {
  for (var i = 0; i < maxFrames && finder.evaluate().isEmpty; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
  }
  if (finder.evaluate().isEmpty) {
    throw TestFailure(
      'Timed out after ${maxFrames * 100}ms waiting for $finder',
    );
  }
}

/// Waits for the sheet to actually be listening (as opposed to still
/// `preparing`, when "Listo" is rendered but disabled — see
/// `VoiceCaptureListeningBody`), then taps "Listo".
Future<void> _finishListening(PatrolIntegrationTester $) async {
  await _pumpUntilFound($, find.text('Escuchando…'));
  await $.tester.tap(find.text('Listo'));
  await $.tester.pumpAndSettle();
}

/// The form's own scroll zone, scoped to descend from
/// [TransactionFormPage] — the plain `find.byType(Scrollable).first` this
/// suite started with instead matched the *previous* route's `Scrollable`
/// (Home's), which `go_router`'s `Navigator` keeps mounted offstage under
/// the pushed form; dragging that one for 50 iterations never brought the
/// Nota field's `TextField` into the tree, only ever hitting
/// `dragUntilVisible`'s own "No element" failure. Scoping to a descendant of
/// the page actually on screen is what `transactions_patrol_test.dart`'s
/// sibling suite gets "for free" because it never has another route's
/// `Scrollable` still mounted at the point it calls its own `_enterNote`.
Finder get _formScrollable => find.descendant(
      of: find.byType(TransactionFormPage),
      matching: find.byType(Scrollable),
    ).first;

/// Scrolls the form's Nota field into view (see `transactions_patrol_test
/// .dart`'s own `_enterNote` for why: the anchored amount keypad, expanded by
/// default, squeezes it out of the `ListView`'s built range) and types
/// [text] into it.
Future<void> _enterNote(PatrolIntegrationTester $, String text) async {
  final field = find.byType(TextField);
  await $.tester.scrollUntilVisible(
    field,
    200,
    scrollable: _formScrollable,
  );
  await $.tester.pumpAndSettle();
  await $.tester.enterText(field, text);
  await $.tester.pumpAndSettle();
}

/// Scrolls the Nota field into view and asserts its current value —
/// `find.text` matches an `EditableText`'s live content, not just a plain
/// `Text` widget, so this reads what the field actually shows on screen.
Future<void> _expectNoteText(PatrolIntegrationTester $, String text) async {
  final field = find.byType(TextField);
  await $.tester.scrollUntilVisible(
    field,
    200,
    scrollable: _formScrollable,
  );
  await $.tester.pumpAndSettle();
  expect(find.text(text), findsOneWidget);
}

void main() {
  patrolTest(
    'Disparador primario: mantener presionado el FAB de Inicio abre la hoja '
    'de escucha y, con una transcripción con monto, el formulario de '
    'movimiento se abre pre-llenado con el monto correcto',
    ($) async {
      await startApp($);
      await _installFakeVoiceCapture('gasté veinte mil en almuerzo');
      await _seedAccount(getIt<AppDatabase>(), 'Nu');
      // First Home visit always auto-shows the HU-02 minitutorial
      // (`TutorialAutoShow`/`TutorialKey.voiceCaptureGesture`) before
      // anything else can be tapped — see this suite's minitutorial scenario
      // below for that surface on its own.
      await dismissAutoTutorialIfShown($);

      await $.tester.longPress(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();

      // `f8OP8a`/`Z6imP`: the listening surface, with nothing recognized yet.
      expect(find.text('El audio no se guarda. Solo se usa para llenar el '
          'formulario.'), findsOneWidget);

      await _finishListening($);

      // Same route the manual path uses (`AppRoutes.newTransactionFromVoice`
      // still resolves to `TransactionFormPage`), prefilled from the parsed
      // draft: "veinte mil" is an explicit scale ("mil"), so the amount is
      // exact, never flagged uncertain.
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text(_formatted(2000000)), findsOneWidget); // $20.000
      expect(
        find.text('Supusimos ${_formatted(2000000)} por «veinte»'),
        findsNothing,
      );
      await _expectNoteText($, 'almuerzo');
    },
  );

  patrolTest(
    'Pastilla "Dictar" dentro del formulario: abre la misma hoja de escucha '
    'y, al completar, dicta sobre el formulario ya abierto sin perder los '
    'campos ya tecleados',
    ($) async {
      await startApp($);
      await _installFakeVoiceCapture('gasté quince mil en cine');
      await _seedAccount(getIt<AppDatabase>(), 'Nu');
      await dismissAutoTutorialIfShown($);

      // Reaches the plain manual form directly through the router
      // (`push`, matching every sibling suite's own convention for a
      // destination the current screen state does not expose, e.g.
      // `goals_patrol_test.dart`'s `_goToGoals`), instead of tapping the
      // Home FAB: a bare `tap()` on the same button `AppFab` also wires to
      // `onLongPress` was observed landing on the listening sheet instead of
      // the plain form on a real emulator (`LiveTestWidgetsFlutterBinding`
      // times gestures against the wall clock, unlike a widget test's fake
      // clock, so a `tap()`'s down-to-up gap can occasionally cross the
      // long-press threshold on real device hardware). This scenario is
      // about the "Dictar" pill inside an already-open form, not about how
      // the form was reached, so a direct push sidesteps that ambiguous
      // gesture entirely rather than trying to out-time it.
      final context = $.tester.element(find.byType(Scaffold).first);
      unawaited(GoRouter.of(context).push(AppRoutes.newTransaction));
      await $.tester.pumpAndSettle();
      expect(find.byType(TransactionFormPage), findsOneWidget);

      // Types a note by hand first — this is the field `completeFromVoice`
      // must never overwrite once it is non-empty.
      await _enterNote($, 'Compra en el mercado');

      // Typing in Nota gave it focus, which collapses the anchored amount
      // zone (`TransactionAmountFixedZone`'s own "Monto y Nota never hold
      // focus at once" rule) — and the "Dictar" pill only renders in the
      // *expanded* zone's header, so it has to be reopened first.
      await $.tester.tap(find.byTooltip('Editar monto'));
      await $.tester.pumpAndSettle();

      await $.tester.tap(find.byTooltip('Dictar el movimiento'));
      await $.tester.pumpAndSettle();

      await _finishListening($);

      // The amount was empty, so voice filled it in ($15.000 for "quince
      // mil", an explicit scale). The note was not empty, so voice's own
      // leftover ("cine") never overwrites what was already typed by hand.
      expect(find.text(_formatted(1500000)), findsOneWidget); // $15.000
      await _expectNoteText($, 'Compra en el mercado');
    },
  );

  patrolTest(
    'Marca de monto incierto: "gasté veinte" activa la heurística ×1000 y el '
    'formulario marca el monto como supuesto; tocar o teclear el monto '
    'limpia la marca',
    ($) async {
      await startApp($);
      await _installFakeVoiceCapture('gasté veinte');
      await _seedAccount(getIt<AppDatabase>(), 'Nu');
      await dismissAutoTutorialIfShown($);

      await $.tester.longPress(find.byTooltip('Agregar movimiento'));
      await $.tester.pumpAndSettle();
      await _finishListening($);

      expect(find.byType(TransactionFormPage), findsOneWidget);
      // The magnitude-elision heuristic (`SpokenAmountParser`, HU-04a): no
      // explicit scale word ("mil"/"lucas"/etc.) was said, so "veinte" is
      // read as 20.000 COP and flagged uncertain — the amount lands already
      // expanded (`bwaHq` pill under the value) instead of the collapsed bar
      // the previous scenario's exact amount used.
      expect(find.text(_formatted(2000000)), findsOneWidget); // $20.000
      final hint = find.text('Supusimos ${_formatted(2000000)} por «veinte»');
      expect(hint, findsOneWidget);

      // Any digit key press is "the user editing the amount"
      // (`TransactionFormCubit.amountDigitPressed`), which drops the mark
      // immediately — it appends onto the existing digits (whole-number-mode
      // entry, same convention `transactions_patrol_test.dart`'s own
      // `_enterAmount` documents), landing on $200.005.
      await $.tester.tap(find.text('5').first);
      await $.tester.pumpAndSettle();

      expect(hint, findsNothing);
      expect(find.text(_formatted(20000500)), findsOneWidget); // $200.005
    },
  );

  patrolTest(
    'Minitutorial: la primera vez en Inicio, el coach mark de "mantén '
    'presionado para dictar" se muestra antes de abrir la hoja de escucha, y '
    'su CTA realiza el gesto real',
    ($) async {
      await startApp($);
      await _installFakeVoiceCapture('gasté veinte mil en mercado');
      await _seedAccount(getIt<AppDatabase>(), 'Nu');

      // No `dismissAutoTutorialIfShown` here on purpose: this scenario is
      // about that exact auto-show (`TutorialKey.voiceCaptureGesture`,
      // `docs/requirements/fase-2/17-captura-voz.md` HU-02), so it has to
      // observe the sheet itself rather than dismiss it blindly.
      await _pumpUntilFound($, find.text('Dicta un gasto sin teclear'));
      // `_pumpUntilFound` only waits for the CTA to exist in the tree, not
      // for the sheet's entrance slide-in to finish — tapping mid-animation
      // hits whatever offset the button is passing through, which can still
      // be below the viewport while it slides up, unrelated to whether the
      // resting layout itself fits.
      await $.tester.pumpAndSettle();
      expect(find.text('Probar ahora'), findsOneWidget);

      // The CTA performs the real gesture (`onCta: startVoiceCaptureFlow`),
      // not just a navigation stub — the listening sheet opens straight from
      // it, with no long-press needed.
      await $.tester.tap(find.text('Probar ahora'));
      await $.tester.pumpAndSettle();
      await _finishListening($);
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text(_formatted(2000000)), findsOneWidget); // $20.000
    },
  );
}
