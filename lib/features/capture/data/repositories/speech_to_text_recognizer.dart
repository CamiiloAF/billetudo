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

  /// Closes a session whose [stop] resolved without the platform ever
  /// reporting the end. See [_scheduleStopFallback].
  Timer? _stopFallback;

  /// Whether a terminal update (`done` or `error`) was already emitted for the
  /// current session, so no path emits a second one.
  ///
  /// Android ends a recognition on its own — `onEndOfSpeech`, the native
  /// `pauseFor` timer, `notifyListening(false)`, `doneNoResult` — and a
  /// genuine final `onResult` is followed by that same `done` status, so the
  /// paths that close a session routinely fire in pairs. Starts out `true`:
  /// before the first [_listen] there is no live session, so a status callback
  /// from `initialize()` is not one ending.
  bool _sessionEnded = true;

  /// Identifies the session [_listen] is opening, so its own `await`s can tell
  /// whether they still belong to the live session: [cancel] and any newer
  /// [_listen] invalidate an in-flight one.
  int _sessionToken = 0;

  /// How long [start] waits after tearing down a still-live previous session
  /// before asking the platform to listen again.
  ///
  /// Android's `startListening` replies `success(false)` while the previous
  /// recognizer is alive (`if (isListening()) { result.success(false) }`) and
  /// the plugin does not turn that into an exception, so a session started too
  /// eagerly reports success with the microphone shut.
  static const Duration _recognizerReleaseDelay = Duration(milliseconds: 150);

  /// How long [_listen] gives the platform to report an open microphone before
  /// treating the session as refused, and how often it re-checks. See
  /// [_waitForMicrophone] — this grace period is load-bearing, not padding.
  static const Duration _micOpenGrace = Duration(milliseconds: 400);
  static const Duration _micOpenPollInterval = Duration(milliseconds: 50);

  /// How long a resolved [stop] is given to produce the platform's own end of
  /// session before this class closes it. See [_scheduleStopFallback].
  static const Duration _stopFallbackDelay = Duration(milliseconds: 1200);

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
    if (plugin.isListening) {
      // The previous recognizer is still alive, so the platform would refuse
      // this session outright (see [_recognizerReleaseDelay]). Tear it down
      // and give it a beat to actually let go before asking again. Marking the
      // session ended first keeps the `notListening` this very cancel triggers
      // from reaching the caller as this new session's `done`.
      _sessionEnded = true;
      _stopFallback?.cancel();
      _stopFallback = null;
      try {
        await plugin.cancel();
      } on Exception catch (error, stackTrace) {
        return Left(
          UnexpectedFailure(
            'Speech recognizer failed to release the previous session',
            cause: error,
            stackTrace: stackTrace,
          ),
        );
      }
      await Future<void>.delayed(_recognizerReleaseDelay);
    }
    return _listen(plugin, onDevice: true);
  }

  Future<Result<Unit>> _listen(
    SpeechToText plugin, {
    required bool onDevice,
  }) async {
    final token = ++_sessionToken;
    _onDeviceRequested = onDevice;
    _listening = true;
    _stopFallback?.cancel();
    _stopFallback = null;
    // [_sessionEnded] stays `true` across the awaits below and only flips once
    // the microphone is confirmed open. When this runs as the cloud restart of
    // [_onError], the previous session died with `cancelOnError: true` and its
    // `notListening`/`done` arrives *during* those awaits: flipping the flag
    // up front would let that stale status close the session being opened.
    try {
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
    } on Exception catch (error, stackTrace) {
      return _failToStart(
        token,
        'Speech recognizer failed to start',
        SpeechRecognitionErrorKind.unknown,
        error,
        stackTrace,
      );
    }
    if (!await _waitForMicrophone(plugin, token)) {
      // `listen()` resolves normally even when the platform refused to start:
      // Android replies `success(false)`, which the plugin does not turn into
      // an exception. Reporting success here would leave the caller listening
      // with the microphone closed.
      return _failToStart(
        token,
        'Speech recognizer did not open the microphone',
        SpeechRecognitionErrorKind.busy,
      );
    }
    if (token != _sessionToken) {
      // A cancel (or a newer session) landed while the platform was starting
      // up; the session that owns the state now has already been reported.
      return _failToStart(
        token,
        'Speech recognizer session ended while starting',
        SpeechRecognitionErrorKind.unknown,
      );
    }
    _sessionEnded = false;
    _hardStop?.cancel();
    _hardStop = Timer(_activeMaxDuration, () => unawaited(stop()));
    // `transcript: _transcript`, never the empty default: this method also runs
    // as an internal restart (the cloud fallback in [_onError]), and a
    // `listening` update carrying an empty transcript is the one thing that can
    // wipe words the user is already reading on screen.
    _emit(
      SpeechRecognitionUpdate(
        phase: SpeechRecognitionPhase.listening,
        transcript: _transcript,
      ),
    );
    return const Right(unit);
  }

  /// Closes a session that never got off the ground, then reports the [Left].
  ///
  /// The terminal matters as much as the returned failure: the cloud restart in
  /// [_onError] is `unawaited`, so a `Left` alone would leave the caller on
  /// "listening" with a closed microphone and no timer left to end it.
  ///
  /// Nothing is touched when [token] is stale — a cancel or a newer session
  /// already owns this state and has already emitted its own terminal. Same
  /// when [_listening] is already `false`: a real error can land from
  /// [_onError] while this same attempt is still waiting on [_waitForMicrophone]
  /// (`_sessionEnded` stays `true` throughout that wait, so [_onError] reports
  /// it and closes the session on its own), and this call would otherwise
  /// follow with a second, spurious terminal for the same failed attempt.
  Result<Unit> _failToStart(
    int token,
    String message,
    SpeechRecognitionErrorKind kind, [
    Object? error,
    StackTrace? stackTrace,
  ]) {
    if (token == _sessionToken && _listening) {
      _listening = false;
      _hardStop?.cancel();
      _hardStop = null;
      _transcript = '';
      _sessionEnded = true;
      _emit(
        SpeechRecognitionUpdate(
          phase: SpeechRecognitionPhase.error,
          error: kind,
        ),
      );
    }
    return Left(
      UnexpectedFailure(message, cause: error, stackTrace: stackTrace),
    );
  }

  /// Whether the platform reports the microphone open, polled for up to
  /// [_micOpenGrace].
  ///
  /// **Do not collapse this into a single `plugin.isListening` check.** The
  /// value it reads is set by `notifyStatus('listening')`, a *native → Dart*
  /// `invokeMethod`, while `listen()` resolves off `result.success(true)`, the
  /// reply to our own call. Android's `startListening` does fire
  /// `notifyListening(true)` before replying, but those are two different
  /// directions of the channel and their relative delivery order is not part of
  /// any contract. Reading it too eagerly would declare "the microphone never
  /// opened" with a perfectly open microphone, which breaks voice capture
  /// outright — far worse than the refusal this guard exists to catch. Only a
  /// still-false value after the grace period is a real refusal.
  Future<bool> _waitForMicrophone(SpeechToText plugin, int token) async {
    final deadline = DateTime.now().add(_micOpenGrace);
    while (!plugin.isListening && DateTime.now().isBefore(deadline)) {
      if (token != _sessionToken) {
        // Cancelled mid-grace: `isListening` will never turn true again, and
        // waiting out the deadline would report a refusal for a session the
        // user already abandoned.
        return false;
      }
      await Future<void>.delayed(_micOpenPollInterval);
    }
    return plugin.isListening;
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
        _emitDone();
      } else {
        _scheduleStopFallback();
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

  /// Gives a resolved [stop] a short window to be followed by the platform's
  /// own end of session, and closes the session here when it is not.
  ///
  /// Android's `stopListening` returns early with `success(false)` when it is
  /// already not listening, and emits no status on that path, so a `stop` can
  /// resolve cleanly with no final `onResult` and no `done` ever arriving. That
  /// would leave the caller waiting and — the reason this lives in the
  /// recognizer rather than only in the caller — leave the transcription in
  /// memory after the session it belonged to, against this class's zero
  /// retention guarantee.
  void _scheduleStopFallback() {
    final token = _sessionToken;
    _stopFallback?.cancel();
    _stopFallback = Timer(_stopFallbackDelay, () {
      if (token != _sessionToken) {
        return;
      }
      _emitDone();
    });
  }

  @override
  Future<Result<Unit>> cancel() async {
    _hardStop?.cancel();
    _hardStop = null;
    _stopFallback?.cancel();
    _stopFallback = null;
    // Invalidates any `_listen` still waiting on the platform, so it does not
    // come back and mark a session the user abandoned as open.
    _sessionToken++;
    // Cleared before awaiting the platform: a cancel must leave nothing behind
    // even if the plugin call itself throws.
    _transcript = '';
    final plugin = _plugin;
    if (plugin == null) {
      _sessionEnded = true;
      return const Right(unit);
    }
    try {
      await plugin.cancel();
      _listening = false;
      // Through the shared terminal path with an already-empty transcript: the
      // `notListening` this cancel triggers lands on the same path, and only
      // one of the two may reach the caller.
      _emitDone();
      return const Right(unit);
    } on Exception catch (error, stackTrace) {
      _listening = false;
      _sessionEnded = true;
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
    if (_sessionEnded) {
      // Zero retention (see the class doc): a late result must not put the
      // user's words back in memory. Android does deliver one — when the
      // platform ends the session itself, [_onStatus] closes it with the last
      // partial, and the real final `onResult` can land after that.
      return;
    }
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
      // Emitted through the shared terminal path so the `done` status that
      // Android fires right after this final result is recognized as a
      // duplicate and stays silent.
      _emitDone();
      return;
    }
    _emit(
      SpeechRecognitionUpdate(
        phase: SpeechRecognitionPhase.listening,
        transcript: _transcript,
      ),
    );
  }

  /// Closes the current session with whatever was transcribed, once, and drops
  /// the transcription from memory.
  ///
  /// Every terminal `done` goes through here: a final `onResult`, a
  /// platform-driven end of session ([_onStatus]), [stop]'s timeout and its
  /// [_scheduleStopFallback], [cancel], and the bail-out in [_onError]. The
  /// [_sessionEnded] guard is what keeps those paths — which routinely fire in
  /// pairs on Android — from ending one session twice.
  void _emitDone() {
    if (_sessionEnded) {
      return;
    }
    _sessionEnded = true;
    _stopFallback?.cancel();
    _stopFallback = null;
    _emit(
      SpeechRecognitionUpdate(
        phase: SpeechRecognitionPhase.done,
        transcript: _transcript,
        isFinal: true,
      ),
    );
    _transcript = '';
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
      if (_sessionEnded) {
        // Stale status from a session that already ended, or from one that
        // has not been confirmed open yet (`_sessionEnded` also stays `true`
        // for the whole [_waitForMicrophone] wait in [_listen]). `_listening`
        // is a single shared field, not scoped per session: touching it here
        // for a dead session could clobber the flag a session still starting
        // up depends on to tell its own future failure from one already
        // reported elsewhere (see [_failToStart]).
        return;
      }
      _listening = false;
      _hardStop?.cancel();
      _hardStop = null;
      // A closed microphone is itself the end of the session, so it is
      // reported with whatever was heard. Android ends a recognition by itself
      // (`onEndOfSpeech` → the native `pauseFor` timer →
      // `notifyListening(false)` → `doneNoResult`) with no final `onResult`,
      // and native `stopListening` short circuits with `success(false)` once it
      // is not listening: without this, nothing would close the session.
      _emitDone();
    }
  }

  void _onError(SpeechRecognitionError error) {
    final kind = _kindOf(error);
    if (kind == SpeechRecognitionErrorKind.onDeviceUnavailable) {
      _route = SpeechRecognitionRoute.cloud;
      final plugin = _plugin;
      if (_cloudAllowed && plugin != null && _transcript.isEmpty) {
        // Only ever on the caller's explicit say-so, and only while nothing has
        // been understood yet. The dying session is marked ended first so the
        // `notListening` that `cancelOnError: true` produces cannot be read as
        // the end of the one being opened.
        _sessionEnded = true;
        _hardStop?.cancel();
        _hardStop = null;
        unawaited(_listen(plugin, onDevice: false));
        return;
      }
      if (_cloudAllowed && _transcript.isNotEmpty) {
        // This error can land mid-sentence, several seconds into a correctly
        // recognized phrase. Restarting would wipe it and reopen the microphone
        // onto the room, ending the session on ambient noise instead: once
        // there are words, delivering them beats listening again.
        _listening = false;
        _hardStop?.cancel();
        _hardStop = null;
        _emitDone();
        return;
      }
    }
    if (_sessionEnded && !_listening) {
      // Same rule as [_emitDone]: one terminal per session. Android delivers
      // errors for a session that is already closed — `ERROR_SPEECH_TIMEOUT`
      // lands after the plugin's own pause timer already ended it — and a
      // terminal emitted then would reach a caller that has already moved on.
      // `_listening` is what separates that from a session still starting up,
      // where [_sessionEnded] is also `true` (see [_listen]) but the error is
      // this session's own and must be reported with its real kind.
      return;
    }
    _listening = false;
    _hardStop?.cancel();
    _hardStop = null;
    _stopFallback?.cancel();
    _stopFallback = null;
    _transcript = '';
    _sessionEnded = true;
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
    _stopFallback?.cancel();
    _sessionEnded = true;
    _transcript = '';
    await _updates.close();
  }
}
