import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:speech_to_text/speech_recognition_error.dart';
import 'package:speech_to_text/speech_recognition_result.dart';
import 'package:speech_to_text/speech_to_text.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/speech_recognition.dart';
import '../../domain/repositories/speech_recognizer.dart';

/// `speech_to_text` implementation of [SpeechRecognizer].
///
/// Three properties this class exists to guarantee:
///
/// **Lazy.** The plugin is constructed and initialized on the first
/// [prepare], never at app startup, so an optional feature cannot slow the
/// cold start or pop a permission dialog the user did not ask for (HU-10).
///
/// **Zero retention.** The transcription is held in a single field that is
/// cleared when the session ends, and is emitted on a broadcast stream. It is
/// never written to a file, to Drift, to preferences, or to the sync queue
/// (HU-06). The plugin is likewise never asked to save audio.
///
/// **Honest routing.** Every session asks for on-device recognition first.
/// When the platform refuses, the session does **not** silently fall back to
/// the vendor's cloud: it reports
/// [SpeechRecognitionErrorKind.onDeviceUnavailable] and stops, unless the
/// caller explicitly passed `allowCloudRecognition: true`. That keeps the
/// "todo local" promise from quietly becoming false, and keeps
/// [SpeechRecognitionRoute] a fact the UI can show.
@LazySingleton(as: SpeechRecognizer)
class SpeechToTextRecognizer implements SpeechRecognizer {
  SpeechToTextRecognizer();

  final StreamController<SpeechRecognitionUpdate> _updates =
      StreamController<SpeechRecognitionUpdate>.broadcast();

  SpeechToText? _plugin;
  bool _initialized = false;
  bool _listening = false;
  bool _onDeviceRequested = false;
  bool _cloudAllowed = false;
  String? _activeLocaleId;
  Duration _activeMaxDuration = VoiceCaptureLimits.maxListenDuration;
  Duration _activePauseFor = VoiceCaptureLimits.pauseForSilence;

  /// In-memory only, cleared on every session end. See the class doc.
  String _transcript = '';

  SpeechRecognitionRoute _route = SpeechRecognitionRoute.unknown;

  /// Belt and braces on top of the plugin's own `listenFor`: if a platform
  /// ever fails to honour it, this timer still closes the microphone.
  Timer? _hardStop;

  /// How long [stop] waits for `speech_to_text` before giving up on it and
  /// closing the session itself. See [stop]'s doc comment.
  static const Duration _stopTimeout = Duration(seconds: 2);

  @override
  Stream<SpeechRecognitionUpdate> get updates => _updates.stream;

  @override
  bool get isListening => _listening;

  @override
  Future<Result<SpeechRecognizerAvailability>> prepare({
    required String localeId,
  }) async {
    try {
      final plugin = _plugin ??= SpeechToText();
      if (!_initialized) {
        _initialized = await plugin.initialize(
          onError: _onError,
          onStatus: _onStatus,
        );
      }
      if (!_initialized) {
        // Bugfix 2026-09-12: a failed `initialize()` on Android is not
        // reliably retryable on the SAME `SpeechToText` instance — a common
        // real-device trigger is the mic permission having just been
        // granted a beat before this ran, which the plugin's own internal
        // check can still miss the same way `Permission.microphone.status`
        // can (see `GetVoiceCaptureAvailability`'s doc). Once that happens,
        // calling `.initialize()` again on this same object kept failing
        // forever — the instance itself seems to latch onto the failure.
        // Dropping `_plugin` here means the *next* `prepare()` builds a
        // fresh `SpeechToText()` and gets a real second chance instead of
        // retrying against an instance already poisoned by the first miss.
        _plugin = null;
        return const Right(SpeechRecognizerAvailability.unavailable());
      }
      final locales = await plugin.locales();
      final wanted = _language(localeId);
      final supported =
          locales.any((locale) => _language(locale.localeId) == wanted);
      return Right(
        SpeechRecognizerAvailability(
          isAvailable: true,
          isLocaleSupported: supported,
          route: _route,
        ),
      );
    } on Exception catch (error, stackTrace) {
      // A plugin that fails to initialize must never take the app down: the
      // voice capture just becomes unavailable (HU-10).
      return Left(
        UnexpectedFailure(
          'Speech recognizer failed to initialize',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> start({
    required String localeId,
    bool allowCloudRecognition = false,
    Duration maxDuration = VoiceCaptureLimits.maxListenDuration,
    Duration pauseFor = VoiceCaptureLimits.pauseForSilence,
  }) async {
    final plugin = _plugin;
    if (plugin == null || !_initialized) {
      return const Left(UnexpectedFailure('Speech recognizer not prepared'));
    }
    _transcript = '';
    _cloudAllowed = allowCloudRecognition;
    _activeLocaleId = localeId;
    _activeMaxDuration = maxDuration;
    _activePauseFor = pauseFor;
    return _listen(plugin, onDevice: true);
  }

  Future<Result<Unit>> _listen(
    SpeechToText plugin, {
    required bool onDevice,
  }) async {
    try {
      _onDeviceRequested = onDevice;
      _listening = true;
      await plugin.listen(
        onResult: _onResult,
        onSoundLevelChange: _onSoundLevel,
        listenOptions: SpeechListenOptions(
          localeId: _activeLocaleId,
          onDevice: onDevice,
          listenFor: _activeMaxDuration,
          pauseFor: _activePauseFor,
          cancelOnError: true,
          // Reverted 2026-09-12: `ListenMode.dictation` was tried here
          // (2026-09-11, purely from the plugin's own docs, never verified
          // on a real device) to fix "no alcanzamos a captar el monto"
          // firing almost instantly. On a real device it made things worse
          // in a different way: `dictation` is built for continuous,
          // multi-phrase speech — Android treats each pause as a phrase
          // boundary *within the same session*, plays its own audio cue and
          // clears the partial transcript to start the next phrase, instead
          // of ending the session the way a single "gasté X en Y" utterance
          // should. On device that showed up as the recognized text
          // flashing and disappearing mid-session, a second mic sound, and
          // the app looping back into "listening" instead of finishing —
          // confirmed via real device logs and manual reproduction, not
          // theorized. Left at `ListenMode.confirmation`, the plugin's own
          // default (so no argument here) — built for one short utterance
          // with one clean start/stop cycle, the actual shape of this
          // feature. The original "no alcanzamos a captar el monto" symptom
          // this tried to fix is handled instead by `VoiceCaptureCubit`'s
          // own early-transient-error silent retry.
        ),
      );
      _hardStop?.cancel();
      _hardStop = Timer(_activeMaxDuration, () => unawaited(stop()));
      _emit(const SpeechRecognitionUpdate(
        phase: SpeechRecognitionPhase.listening,
      ));
      return const Right(unit);
    } on Exception catch (error, stackTrace) {
      _listening = false;
      return Left(
        UnexpectedFailure(
          'Speech recognizer failed to start',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> stop() async {
    _hardStop?.cancel();
    _hardStop = null;
    final plugin = _plugin;
    if (plugin == null) {
      return const Right(unit);
    }
    var timedOut = false;
    try {
      // Belt and braces on top of the plugin itself: `speech_to_text.stop()`
      // is known to never resolve, and never fire a final `onResult`, on some
      // Android OEM builds. Without this timeout that hangs "Listo" forever
      // with no feedback (5b) instead of closing the session with whatever
      // was already transcribed.
      await plugin.stop().timeout(
            _stopTimeout,
            onTimeout: () => timedOut = true,
          );
      _listening = false;
      if (timedOut) {
        _emit(
          SpeechRecognitionUpdate(
            phase: SpeechRecognitionPhase.done,
            transcript: _transcript,
            isFinal: true,
          ),
        );
        _transcript = '';
      }
      return const Right(unit);
    } on Exception catch (error, stackTrace) {
      _listening = false;
      return Left(
        UnexpectedFailure(
          'Speech recognizer failed to stop',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  @override
  Future<Result<Unit>> cancel() async {
    _hardStop?.cancel();
    _hardStop = null;
    // Cleared before awaiting the platform: a cancel must leave nothing
    // behind even if the plugin call itself throws.
    _transcript = '';
    final plugin = _plugin;
    if (plugin == null) {
      return const Right(unit);
    }
    try {
      await plugin.cancel();
      _listening = false;
      _emit(const SpeechRecognitionUpdate(phase: SpeechRecognitionPhase.done));
      return const Right(unit);
    } on Exception catch (error, stackTrace) {
      _listening = false;
      return Left(
        UnexpectedFailure(
          'Speech recognizer failed to cancel',
          cause: error,
          stackTrace: stackTrace,
        ),
      );
    }
  }

  void _onResult(SpeechRecognitionResult result) {
    _transcript = result.recognizedWords;
    if (_onDeviceRequested && _route != SpeechRecognitionRoute.cloud) {
      // A result arriving from a session that asked for on-device recognition
      // is the only proof the audio stayed here.
      _route = SpeechRecognitionRoute.onDevice;
    }
    if (result.finalResult) {
      _listening = false;
      _hardStop?.cancel();
      _hardStop = null;
    }
    _emit(
      SpeechRecognitionUpdate(
        phase: result.finalResult
            ? SpeechRecognitionPhase.done
            : SpeechRecognitionPhase.listening,
        transcript: _transcript,
        isFinal: result.finalResult,
      ),
    );
    if (result.finalResult) {
      _transcript = '';
    }
  }

  void _onSoundLevel(double level) {
    if (!_listening) {
      return;
    }
    _emit(
      SpeechRecognitionUpdate(
        phase: SpeechRecognitionPhase.listening,
        transcript: _transcript,
        soundLevel: _normalizeLevel(level),
      ),
    );
  }

  /// Platforms report the level on different scales (iOS in dB, Android
  /// roughly 0..10). Clamped into 0..1 for the indicator; it drives an
  /// animation, never a stored value.
  // TODO(cami): this `level > 1 ? level / 10 : level` split is an assumed
  // scale, not one verified against real `onSoundLevelChange` callbacks on
  // device. `VoiceWaveBars` was widened to react more visibly to whatever
  // comes out of here (see its `_heightFor`), but if the bars still look flat
  // or erratic on a real phone, capture actual values from both platforms
  // first and recalibrate this mapping — do not guess again.
  double _normalizeLevel(double level) {
    if (level <= 0) {
      return 0;
    }
    final normalized = level > 1 ? level / 10 : level;
    return normalized > 1 ? 1 : normalized;
  }

  void _onStatus(String status) {
    if (status == SpeechToText.doneStatus ||
        status == SpeechToText.notListeningStatus) {
      _listening = false;
      _hardStop?.cancel();
      _hardStop = null;
    }
  }

  void _onError(SpeechRecognitionError error) {
    final kind = _kindOf(error);
    if (kind == SpeechRecognitionErrorKind.onDeviceUnavailable) {
      _route = SpeechRecognitionRoute.cloud;
      final plugin = _plugin;
      if (_cloudAllowed && plugin != null) {
        // Only ever on the caller's explicit say-so.
        unawaited(_listen(plugin, onDevice: false));
        return;
      }
    }
    _listening = false;
    _hardStop?.cancel();
    _hardStop = null;
    _transcript = '';
    _emit(
      SpeechRecognitionUpdate(
        phase: SpeechRecognitionPhase.error,
        error: kind,
      ),
    );
  }

  SpeechRecognitionErrorKind _kindOf(SpeechRecognitionError error) {
    if (_onDeviceRequested && _onDeviceErrors.contains(error.errorMsg)) {
      return SpeechRecognitionErrorKind.onDeviceUnavailable;
    }
    return switch (error.errorMsg) {
      'error_no_match' ||
      'error_speech_timeout' =>
        SpeechRecognitionErrorKind.noSpeech,
      'error_network' ||
      'error_network_timeout' =>
        SpeechRecognitionErrorKind.network,
      'error_permission' ||
      'error_insufficient_permissions' =>
        SpeechRecognitionErrorKind.permission,
      'error_busy' || 'error_client' => SpeechRecognitionErrorKind.busy,
      'error_language_not_supported' ||
      'error_language_unavailable' ||
      'error_not_available' =>
        SpeechRecognitionErrorKind.unavailable,
      _ => SpeechRecognitionErrorKind.unknown,
    };
  }

  /// Errors the platforms raise when on-device recognition specifically is
  /// not possible, as opposed to recognition being broken altogether.
  static const Set<String> _onDeviceErrors = <String>{
    'error_language_not_supported',
    'error_language_unavailable',
    'error_server',
    'error_network',
  };

  String _language(String localeId) =>
      localeId.replaceAll('-', '_').split('_').first.toLowerCase();

  void _emit(SpeechRecognitionUpdate update) {
    if (!_updates.isClosed) {
      _updates.add(update);
    }
  }

  /// Releases the update stream. Not wired to injectable's disposal hook on
  /// purpose: `SpeechRecognizer` is the injected type and has no `dispose`.
  Future<void> dispose() async {
    _hardStop?.cancel();
    _transcript = '';
    await _updates.close();
  }
}
