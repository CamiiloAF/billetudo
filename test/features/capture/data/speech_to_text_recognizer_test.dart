import 'dart:async';
import 'dart:convert';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/data/repositories/speech_to_text_recognizer.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';
// `speech_to_text` re-exports only `ListenMode`/`SpeechConfigOption`/
// `SpeechListenOptions`, not `SpeechToTextPlatform` itself, so faking the
// native side means importing its platform interface directly. Kept out of
// `pubspec.yaml` on purpose: this is a test-only seam of an existing
// dependency, not a dependency of the app.
// ignore: depend_on_referenced_packages
import 'package:speech_to_text_platform_interface/speech_to_text_platform_interface.dart';

/// Stands in for the native side of `speech_to_text`, so the real plugin
/// object runs (its status filtering and result parsing are part of what these
/// tests exercise) without a microphone.
class _FakeSpeechToTextPlatform extends SpeechToTextPlatform {
  /// Whether [listen] reports that the platform actually started listening.
  /// `false` reproduces Android's `startListening` short circuit
  /// (`if (isListening()) { result.success(false); return }`), which the
  /// plugin does **not** turn into an exception.
  bool micOpens = true;

  /// When set, [stop] never completes — the OEM hang
  /// `SpeechToTextRecognizer.stop`'s 2s timeout exists for.
  bool stopHangs = false;

  int listenCalls = 0;
  int stopCalls = 0;
  int cancelCalls = 0;
  SpeechListenOptions? lastOptions;

  void reset() {
    micOpens = true;
    stopHangs = false;
    listenCalls = 0;
    stopCalls = 0;
    cancelCalls = 0;
    lastOptions = null;
  }

  @override
  Future<bool> hasPermission() async => true;

  @override
  Future<bool> initialize({
    dynamic debugLogging = false,
    List<SpeechConfigOption>? options,
  }) async =>
      true;

  @override
  Future<List<dynamic>> locales() async => <dynamic>[
        'es_CO:Español (Colombia)',
        'en_US:English (United States)',
      ];

  @override
  Future<bool> listen({
    String? localeId,
    dynamic partialResults = true,
    dynamic onDevice = false,
    int listenMode = 0,
    dynamic sampleRate = 0,
    SpeechListenOptions? options,
  }) async {
    listenCalls++;
    lastOptions = options;
    if (!micOpens) {
      return false;
    }
    // The platform reporting `listening` is what flips `SpeechToText
    // .isListening` to true — the very flag the "microphone did not open"
    // guard reads.
    onStatus?.call(SpeechToText.listeningStatus);
    return true;
  }

  @override
  Future<void> stop() async {
    stopCalls++;
    if (stopHangs) {
      await Completer<void>().future;
    }
  }

  @override
  Future<void> cancel() async {
    cancelCalls++;
  }
}

void main() {
  // One platform, one plugin and one recognizer for the whole file, on
  // purpose: `SpeechToText()` is a process-wide singleton that latches
  // `_initWorked` on the first successful `initialize()` and then ignores
  // later `onStatus`/`onError` listeners, and it stores its callbacks on the
  // platform object. A per-test recognizer would therefore never be the one
  // the platform talks to. The production object is a `@LazySingleton` driving
  // one session at a time, so sequential sessions on a single instance is also
  // how it really runs; [setUp] resets the session state between tests.
  late _FakeSpeechToTextPlatform platform;
  late SpeechToText plugin;
  late SpeechToTextRecognizer recognizer;
  late List<SpeechRecognitionUpdate> updates;
  late StreamSubscription<SpeechRecognitionUpdate> subscription;

  /// Long enough that neither the plugin's own `pauseFor`/`listenFor` timers
  /// nor the recognizer's `_hardStop` can fire mid-test.
  const never = Duration(minutes: 5);

  setUpAll(() async {
    platform = _FakeSpeechToTextPlatform();
    SpeechToTextPlatform.instance = platform;
    plugin = SpeechToText();
    recognizer = SpeechToTextRecognizer();
    final prepared = await recognizer.prepare(localeId: 'es_CO');
    expect(prepared.isRight(), isTrue);
  });

  setUp(() async {
    // Clears transcript, marks the session ended and drops `isListening`.
    await recognizer.cancel();
    platform.reset();
    updates = [];
    subscription = recognizer.updates.listen(updates.add);
  });

  tearDown(() async {
    await subscription.cancel();
  });

  Future<Result<Unit>> start({bool allowCloudRecognition = false}) async {
    final result = await recognizer.start(
      localeId: 'es_CO',
      allowCloudRecognition: allowCloudRecognition,
      maxDuration: never,
      pauseFor: never,
    );
    await pumpEventQueue();
    return result;
  }

  /// Feeds a recognition result the way the native side does: as JSON through
  /// the platform callback, so the plugin's own parsing and final-result
  /// bookkeeping (which decides whether a later `done` status is forwarded)
  /// really run.
  Future<void> emitResult(String words, {required bool isFinal}) async {
    platform.onTextRecognition!(
      jsonEncode(<String, dynamic>{
        'alternates': <Map<String, dynamic>>[
          <String, dynamic>{'recognizedWords': words, 'confidence': 0.9},
        ],
        'resultType':
            (isFinal ? ResultType.finalResult : ResultType.partial).value,
      }),
    );
    // The recognizer emits on a broadcast controller, so its updates land a
    // microtask later, never synchronously with the callback.
    await pumpEventQueue();
  }

  /// A platform status, through the plugin's own status translation.
  Future<void> emitStatus(String status) async {
    platform.onStatus!(status);
    await pumpEventQueue();
  }

  /// The error callback the recognizer registered in `initialize`, invoked
  /// directly: going through `onError` JSON would also trigger the plugin's
  /// `cancelOnError` teardown and interleave it with the recognizer's own
  /// reaction, which is not what any of these cases is about.
  Future<void> emitError(String errorMsg) async {
    plugin.errorListener!(SpeechRecognitionError(errorMsg, true));
    await pumpEventQueue();
  }

  List<SpeechRecognitionUpdate> dones() => updates
      .where((update) => update.phase == SpeechRecognitionPhase.done)
      .toList();

  group('start', () {
    test('opens the microphone and reports listening', () async {
      final result = await start();

      expect(result.isRight(), isTrue);
      expect(recognizer.isListening, isTrue);
      expect(platform.listenCalls, 1);
      expect(platform.lastOptions!.onDevice, isTrue);
      expect(updates.single.phase, SpeechRecognitionPhase.listening);
    });

    test(
      'fails when listen() resolves but the microphone never opened — the '
      'device bug that painted "Escuchando…" onto a closed microphone',
      () async {
        platform.micOpens = false;

        final result = await start();

        expect(result.isLeft(), isTrue);
        expect(
          result.fold((failure) => failure, (_) => null),
          isA<UnexpectedFailure>(),
        );
        expect(recognizer.isListening, isFalse);
        // Nothing ever told the UI it was listening...
        expect(
          updates.where(
            (update) => update.phase == SpeechRecognitionPhase.listening,
          ),
          isEmpty,
        );
        // ...and the refusal is reported as a terminal too, not only as the
        // `Left`: the cloud restart in `_onError` is `unawaited`, so a `Left`
        // nobody reads would strand the caller on "Escuchando…".
        expect(updates.single.phase, SpeechRecognitionPhase.error);
        expect(updates.single.error, SpeechRecognitionErrorKind.busy);
      },
    );

    test(
      'tears down a still-live recognizer before asking to listen again '
      '(Android refuses a second startListening outright)',
      () async {
        await start();
        expect(recognizer.isListening, isTrue);

        final result = await start();

        expect(result.isRight(), isTrue);
        expect(platform.cancelCalls, 1);
        expect(platform.listenCalls, 2);
      },
    );
  });

  group('_onStatus closing the session', () {
    test(
      'notListening with no final result ends the session with what was heard',
      () async {
        await start();
        await emitResult('gasté cien mil en un almuerzo', isFinal: false);

        await emitStatus(SpeechToText.notListeningStatus);

        expect(dones(), hasLength(1));
        expect(dones().single.transcript, 'gasté cien mil en un almuerzo');
        expect(dones().single.isFinal, isTrue);
        expect(recognizer.isListening, isFalse);
      },
    );

    test(
      'doneNoResult — Android ending the recognition by itself — ends the '
      'session too instead of leaving the sheet on "Escuchando…"',
      () async {
        await start();
        await emitResult('gasté cien mil', isFinal: false);

        // `doneNoResult` is the status the native side fires when it ends
        // with no final result; the plugin maps it to `done`.
        await emitStatus('doneNoResult');

        expect(dones(), hasLength(1));
        expect(dones().single.transcript, 'gasté cien mil');
      },
    );

    test('a done status after a final result does not end the session twice',
        () async {
      await start();
      await emitResult('gasté cien mil en un almuerzo', isFinal: true);
      expect(dones(), hasLength(1));

      // Android fires the `done` status right after the final result.
      await emitStatus(SpeechToText.doneStatus);

      expect(dones(), hasLength(1));
    });

    test('a status after cancel() does not end the session twice', () async {
      await start();
      await emitResult('gasté cien mil', isFinal: false);

      await recognizer.cancel();
      await pumpEventQueue();
      // The cancel's own terminal: no transcript survives it.
      expect(dones(), hasLength(1));
      expect(dones().single.transcript, isEmpty);

      // The platform reports the end it was just asked for.
      await emitStatus(SpeechToText.notListeningStatus);

      expect(dones(), hasLength(1));
    });

    test(
      'a status after stop() already timed out does not end the session twice',
      () async {
        await start();
        await emitResult('gasté cien mil', isFinal: false);
        platform.stopHangs = true;

        // Resolves only through the recognizer's own 2s timeout, which closes
        // the session itself.
        await recognizer.stop();
        await pumpEventQueue();
        expect(dones(), hasLength(1));
        expect(dones().single.transcript, 'gasté cien mil');

        await emitStatus(SpeechToText.notListeningStatus);

        expect(dones(), hasLength(1));
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'a stop() that resolves cleanly but is never followed by a platform '
      'terminal still closes the session — Android\'s stopListening returns '
      'success(false) and emits nothing when it is already not listening',
      () async {
        await start();
        await emitResult('gasté cien mil', isFinal: false);

        await recognizer.stop();
        await pumpEventQueue();
        // Nothing yet: the platform is still given its window to deliver the
        // final result itself.
        expect(dones(), isEmpty);

        await Future<void>.delayed(const Duration(milliseconds: 1300));
        await pumpEventQueue();

        expect(dones(), hasLength(1));
        expect(dones().single.transcript, 'gasté cien mil');
        expect(dones().single.isFinal, isTrue);
      },
    );

    test(
      'the stop fallback does not fire on top of a final result that did '
      'arrive',
      () async {
        await start();
        await recognizer.stop();
        await emitResult('gasté cien mil', isFinal: true);
        expect(dones(), hasLength(1));

        await Future<void>.delayed(const Duration(milliseconds: 1300));
        await pumpEventQueue();

        expect(dones(), hasLength(1));
      },
    );

    test('a new session can end again after the previous one ended', () async {
      await start();
      await emitResult('gasté cien mil', isFinal: false);
      await emitStatus(SpeechToText.notListeningStatus);
      expect(dones(), hasLength(1));

      await start();
      await emitResult('gasté veinte mil', isFinal: false);
      await emitStatus(SpeechToText.notListeningStatus);

      expect(dones(), hasLength(2));
      expect(dones().last.transcript, 'gasté veinte mil');
    });
  });

  group('partial results', () {
    test('a partial result stays on the listening phase', () async {
      await start();

      await emitResult('gasté cien', isFinal: false);

      expect(updates.last.phase, SpeechRecognitionPhase.listening);
      expect(updates.last.transcript, 'gasté cien');
      expect(updates.last.isFinal, isFalse);
      expect(dones(), isEmpty);
    });
  });

  group('on-device unavailable', () {
    test(
      'with words already heard it delivers them instead of reopening the '
      'microphone onto the room',
      () async {
        await start(allowCloudRecognition: true);
        await emitResult('gasté 100.000 en un almuerzo', isFinal: false);

        await emitError('error_language_not_supported');
        await pumpEventQueue();

        expect(dones(), hasLength(1));
        expect(dones().single.transcript, 'gasté 100.000 en un almuerzo');
        expect(recognizer.isListening, isFalse);
        // The session was not restarted: no second listen, and no error
        // surface for the user either.
        expect(platform.listenCalls, 1);
        expect(
          updates.where(
            (update) => update.phase == SpeechRecognitionPhase.error,
          ),
          isEmpty,
        );
      },
    );

    test(
      'with nothing heard yet, and only then, it falls back to the cloud',
      () async {
        await start(allowCloudRecognition: true);

        await emitError('error_language_not_supported');
        await pumpEventQueue();

        expect(platform.listenCalls, 2);
        expect(platform.lastOptions!.onDevice, isFalse);
        expect(dones(), isEmpty);
        expect(updates.last.phase, SpeechRecognitionPhase.listening);
      },
    );

    test('without consent it is surfaced as an error, never downgraded',
        () async {
      await start();

      await emitError('error_language_not_supported');
      await pumpEventQueue();

      expect(platform.listenCalls, 1);
      expect(updates.last.phase, SpeechRecognitionPhase.error);
      expect(
        updates.last.error,
        SpeechRecognitionErrorKind.onDeviceUnavailable,
      );
    });

    test('a status arriving after the error ends nothing a second time',
        () async {
      await start(allowCloudRecognition: true);
      await emitResult('gasté cien mil', isFinal: false);

      await emitError('error_language_not_supported');
      await pumpEventQueue();
      expect(dones(), hasLength(1));

      await emitStatus(SpeechToText.notListeningStatus);

      expect(dones(), hasLength(1));
    });
  });

  group('_onError session guard', () {
    test(
      'a late error after the platform already closed the session on its '
      'own is dropped instead of producing a second terminal — Android '
      'fires error_speech_timeout right after its own pause timer already '
      'ended the session with doneNoResult',
      () async {
        await start();
        await emitResult('gasté cien mil', isFinal: false);
        await emitStatus('doneNoResult');
        expect(dones(), hasLength(1));

        await emitError('error_speech_timeout');

        expect(dones(), hasLength(1));
        expect(
          updates.where(
            (update) => update.phase == SpeechRecognitionPhase.error,
          ),
          isEmpty,
        );
      },
    );

    test(
      'a genuine error while a new session is still starting up (mic not '
      'confirmed open yet) is still reported, never swallowed as a stale '
      'terminal',
      () async {
        // Keeps `SpeechToText.isListening` false so `_waitForMicrophone`
        // is still polling — and `_sessionEnded` still `true` because the
        // microphone was never confirmed open — when the error below lands.
        platform.micOpens = false;
        final startFuture = recognizer.start(
          localeId: 'es_CO',
          allowCloudRecognition: false,
          maxDuration: never,
          pauseFor: never,
        );
        await Future<void>.delayed(const Duration(milliseconds: 50));

        await emitError('error_insufficient_permissions');

        await startFuture;
        await pumpEventQueue();

        expect(
          updates.any(
            (update) =>
                update.phase == SpeechRecognitionPhase.error &&
                update.error == SpeechRecognitionErrorKind.permission,
          ),
          isTrue,
        );
        expect(recognizer.isListening, isFalse);
      },
    );
  });
}
