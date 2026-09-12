import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../domain/entities/cloud_transcription_consent.dart';
import '../../domain/entities/speech_recognition.dart';
import '../../domain/entities/spoken_transaction_draft.dart';
import '../../domain/entities/spoken_transaction_input.dart';
import '../../domain/usecases/cancel_voice_capture.dart';
import '../../domain/usecases/get_cloud_transcription_consent.dart';
import '../../domain/usecases/get_voice_capture_availability.dart';
import '../../domain/usecases/open_microphone_settings.dart';
import '../../domain/usecases/parse_spoken_transaction.dart';
import '../../domain/usecases/request_microphone_permission.dart';
import '../../domain/usecases/set_cloud_transcription_consent.dart';
import '../../domain/usecases/start_voice_capture.dart';
import '../../domain/usecases/stop_voice_capture.dart';
import '../../domain/usecases/watch_voice_capture_updates.dart';
import 'voice_capture_state.dart';

/// Drives one dictation session for `VoiceCaptureSheet`.
///
/// Orchestrates use cases only — the `speech_to_text` plugin and the
/// permission plugin both stay behind their `domain` interfaces, so this
/// cubit is fully testable with fakes and no microphone (HU-10).
///
/// Two invariants it exists to protect:
/// - **Nothing is ever written.** The cubit produces a
///   [SpokenTransactionDraft] and stops; opening the prefilled form and
///   saving it are the caller's and the user's jobs (HU-01).
/// - **Nothing survives it.** The transcript lives in [VoiceCaptureState] and
///   the state dies with [close], which also cancels any open session. There
///   is no disk, no database and no sync path out of here (HU-06).
@injectable
class VoiceCaptureCubit extends Cubit<VoiceCaptureState> {
  VoiceCaptureCubit(
    this._getAvailability,
    this._requestPermission,
    this._openSettings,
    this._startCapture,
    this._stopCapture,
    this._cancelCapture,
    this._watchUpdates,
    this._parse,
    this._watchAccounts,
    this._watchCategories,
    this._getCloudConsent,
    this._setCloudConsent,
  ) : super(const VoiceCaptureState());

  final GetVoiceCaptureAvailability _getAvailability;
  final RequestMicrophonePermission _requestPermission;
  final OpenMicrophoneSettings _openSettings;
  final StartVoiceCapture _startCapture;
  final StopVoiceCapture _stopCapture;
  final CancelVoiceCapture _cancelCapture;
  final WatchVoiceCaptureUpdates _watchUpdates;
  final ParseSpokenTransaction _parse;
  final WatchAccounts _watchAccounts;
  final WatchCategories _watchCategories;
  final GetCloudTranscriptionConsent _getCloudConsent;
  final SetCloudTranscriptionConsent _setCloudConsent;

  StreamSubscription<SpeechRecognitionUpdate>? _updates;

  /// This device's answer about cloud transcription, read once per session so
  /// every decision below reads the same value.
  CloudTranscriptionConsent _cloudConsent = CloudTranscriptionConsent.unset;

  /// The user's vocabulary, loaded once per session so the parser stays a
  /// pure function (`SpokenTransactionInput` does no I/O of its own).
  List<Account> _accounts = const [];
  List<Category> _categories = const [];

  String _localeId = 'es_ES';
  String _languageCode = 'es';
  String _currency = 'COP';

  /// When the current session actually asked the plugin to listen, so a
  /// transient error can be told apart from a real "nothing was said".
  DateTime? _listeningStartedAt;

  /// Only one silent retry per session — a second transient error close to
  /// the start is treated as a real failure instead of retrying forever.
  bool _earlyErrorRetried = false;

  /// A transient plugin error (`error_busy`/`error_client`, or an on-device
  /// no-match that fires suspiciously fast) landing inside this window of
  /// `listen()` starting is close enough to session start that the user
  /// could not possibly have finished speaking yet — see
  /// `SpeechToTextRecognizer._kindOf`'s doc on `error_busy`/`error_client`
  /// being a known transient fault of `speech_to_text`, sometimes fired
  /// right after a previous session's teardown before the native recognizer
  /// is ready for a new one.
  static const Duration _earlyErrorRetryWindow = Duration(milliseconds: 1200);

  /// Small pause before asking the plugin to listen again, giving the native
  /// recognizer a beat to actually release the previous session.
  static const Duration _earlyErrorRetryDelay = Duration(milliseconds: 400);

  /// Checks every precondition and, if they hold, opens the microphone.
  ///
  /// [localeId] is the recognizer locale (`es_CO`) and [languageCode] the
  /// **app's** language — the parser is never asked to guess the language
  /// from the text (HU-08).
  Future<void> start({
    required String localeId,
    required String languageCode,
  }) async {
    _localeId = localeId;
    _languageCode = languageCode;
    _earlyErrorRetried = false;
    emit(const VoiceCaptureState());

    _cloudConsent = await _getCloudConsent();
    if (isClosed) {
      return;
    }
    await _loadVocabulary();
    final availability = await _getAvailability(localeId: localeId);
    if (isClosed) {
      return;
    }
    final resolved = availability.fold((_) => null, (value) => value);
    if (resolved == null || !resolved.recognizer.isAvailable) {
      _emitUnavailable(VoiceCaptureUnavailableReason.recognizer);
      return;
    }
    if (!resolved.hasPermission) {
      emit(
        state.copyWith(
          status: VoiceCaptureStatus.permissionNeeded,
          permission: resolved.permission,
        ),
      );
      return;
    }
    if (!resolved.recognizer.isLocaleSupported) {
      _emitUnavailable(VoiceCaptureUnavailableReason.recognizer);
      return;
    }
    emit(
      state.copyWith(
        status: VoiceCaptureStatus.listening,
        permission: resolved.permission,
        transcript: '',
        soundLevel: 0,
      ),
    );
    await _listen();
  }

  /// The primary CTA of the explainer while the permission is still askable:
  /// the system dialog only ever appears after the user has read what the
  /// microphone is for (HU-07).
  Future<void> requestPermission() async {
    final status = await _requestPermission();
    if (isClosed) {
      return;
    }
    if (status != MicrophonePermissionStatus.granted) {
      emit(
        state.copyWith(
          status: VoiceCaptureStatus.permissionNeeded,
          permission: status,
        ),
      );
      return;
    }
    await start(localeId: _localeId, languageCode: _languageCode);
  }

  /// The only way back from a permanently denied microphone. The app never
  /// re-prompts on every attempt (HU-07).
  Future<void> openSystemSettings() => _openSettings();

  /// "Listo": ends the session on purpose and keeps what was recognized. The
  /// accessible route that does not require holding a gesture down.
  ///
  /// Moves to [VoiceCaptureStatus.stopping] immediately so the button gives
  /// feedback the instant it is tapped — `speech_to_text`'s `stop()` is known
  /// to hang without ever resolving or firing a final result on some OEM
  /// builds of Android, and a silent no-op reads as a broken button. If the
  /// recognizer reports failure instead of a final transcript, whatever was
  /// heard so far is still kept rather than left stranded in `stopping`.
  Future<void> stopListening() async {
    if (state.status != VoiceCaptureStatus.listening) {
      return;
    }
    emit(state.copyWith(status: VoiceCaptureStatus.stopping));
    final result = await _stopCapture();
    if (isClosed) {
      return;
    }
    result.fold((_) => _finish(state.transcript), (_) {});
  }

  /// "Permitir y dictar" on `kJG43`: records the consent and starts a fresh
  /// session, this time allowed to continue through the vendor's service when
  /// on-device recognition fails again — which it will, since that is what
  /// brought us here.
  Future<void> allowCloudTranscription() async {
    await _setCloudConsent(CloudTranscriptionConsent.granted);
    if (isClosed) {
      return;
    }
    await start(localeId: _localeId, languageCode: _languageCode);
  }

  /// "Escribir a mano" on `kJG43`.
  ///
  /// The refusal is **persisted**, not just obeyed once: the two exits carry
  /// equal weight, so choosing the manual form is a real answer to the
  /// question. From here on this device falls straight back to the manual
  /// form instead of re-opening the sheet on every attempt, and Ajustes is
  /// the way back — exactly what the sheet's caption promises.
  Future<void> declineCloudTranscription() =>
      _setCloudConsent(CloudTranscriptionConsent.declined);

  /// "Intentar de nuevo" from the `lLKTv` / unavailable surfaces.
  Future<void> retry() =>
      start(localeId: _localeId, languageCode: _languageCode);

  /// "Cancelar": drops audio and transcript, opens nothing, writes nothing.
  Future<void> cancel() async {
    await _updates?.cancel();
    _updates = null;
    await _cancelCapture();
  }

  /// The draft the sheet hands back when the user chooses "Escribir a mano".
  ///
  /// Not an empty result: whatever was understood — including the transcript
  /// itself, which the form receives as its note — travels to the manual form
  /// so the user never retypes what they already said (HU-05).
  SpokenTransactionDraft draftForManualEntry() =>
      state.draft ??
      SpokenTransactionDraft(
        transcript: state.transcript,
        note: state.hasTranscript ? state.transcript.trim() : null,
      );

  @override
  Future<void> close() async {
    await _updates?.cancel();
    _updates = null;
    // Belt and braces: a sheet dismissed by the scrim or the back gesture must
    // not leave the microphone open a single frame longer than the UI.
    unawaited(_cancelCapture());
    return super.close();
  }

  Future<void> _listen() async {
    await _updates?.cancel();
    _updates = _watchUpdates().listen(_onUpdate);
    _listeningStartedAt = DateTime.now();
    final started = await _startCapture(
      localeId: _localeId,
      // Never true unless this device's owner said so on `kJG43`. The default
      // is still on-device first; this only decides whether the session may
      // continue when that turns out to be impossible.
      allowCloudRecognition: _cloudConsent.isGranted,
    );
    if (isClosed) {
      return;
    }
    started.fold(_onStartFailure, (_) {});
  }

  void _onStartFailure(Failure failure) {
    if (failure is ValidationFailure &&
        failure.field == StartVoiceCapture.fieldPermission) {
      emit(state.copyWith(status: VoiceCaptureStatus.permissionNeeded));
      return;
    }
    _emitUnavailable(VoiceCaptureUnavailableReason.recognizer);
  }

  void _onUpdate(SpeechRecognitionUpdate update) {
    if (isClosed) {
      return;
    }
    // A late callback from a `stop()` call the 2s timeout already gave up on
    // (see `SpeechToTextRecognizer.stop`) can still fire after the cubit left
    // `listening`/`stopping` — the subscription stays alive for the whole
    // session, not just while those two states hold. Once the session has
    // moved on to a terminal status, discarding it here is what stops that
    // stray `done` from overwriting a draft the user is already reviewing.
    if (state.status != VoiceCaptureStatus.listening &&
        state.status != VoiceCaptureStatus.stopping) {
      return;
    }
    switch (update.phase) {
      case SpeechRecognitionPhase.listening:
        emit(
          state.copyWith(
            status: VoiceCaptureStatus.listening,
            transcript: update.transcript,
            soundLevel: update.soundLevel,
          ),
        );
      case SpeechRecognitionPhase.done:
        // `speech_to_text`'s final result can arrive empty or shorter than
        // the last partial the user already saw live on screen — a known
        // Android quirk, not proof the words were never really heard.
        // `state.transcript` already holds the longest run-up-to-now
        // (updated on every `listening` phase above), so it wins whenever
        // the final event regresses instead of confirming what was shown.
        _finish(
          update.transcript.trim().length >= state.transcript.trim().length
              ? update.transcript
              : state.transcript,
        );
      case SpeechRecognitionPhase.error:
        _onError(update);
    }
  }

  void _onError(SpeechRecognitionUpdate update) {
    switch (update.error) {
      case SpeechRecognitionErrorKind.permission:
        emit(state.copyWith(status: VoiceCaptureStatus.permissionNeeded));
      // This phone cannot transcribe on its own. Nothing has left it: the
      // session asked for on-device recognition and stopped there, so the
      // question can still be asked before any audio travels (`kJG43`).
      case SpeechRecognitionErrorKind.onDeviceUnavailable:
        switch (_cloudConsent) {
          case CloudTranscriptionConsent.granted:
            // Consent is on record but the retry did not happen — treat it as
            // the recognizer being unavailable rather than asking again.
            _emitUnavailable(
              VoiceCaptureUnavailableReason.onDeviceUnavailable,
            );
          case CloudTranscriptionConsent.declined:
            _emitUnavailable(
              VoiceCaptureUnavailableReason.cloudConsentDeclined,
            );
          case CloudTranscriptionConsent.unset:
            emit(state.copyWith(
              status: VoiceCaptureStatus.cloudConsentNeeded,
              soundLevel: 0,
            ));
        }
      case SpeechRecognitionErrorKind.network:
        _emitUnavailable(VoiceCaptureUnavailableReason.network);
      case SpeechRecognitionErrorKind.unavailable:
        _emitUnavailable(VoiceCaptureUnavailableReason.recognizer);
      // Silence, noise or a covered microphone is not an error the user has to
      // read about as a failure: it lands on the same "no captamos el monto"
      // surface, which keeps both exits open and blames nobody.
      //
      // `busy` joins this group rather than `_emitUnavailable`: on Android it
      // is reported for both a genuinely busy recognizer and the plugin's own
      // `error_client`, a known transient fault of `speech_to_text` that can
      // fire even after audio was already recognized correctly. Discarding
      // the transcript on that error would throw away real, valid input for
      // a plugin quirk — so whatever was heard is kept, exactly like
      // `noSpeech`.
      //
      // But when one of these fires this early, with nothing heard yet, it
      // is not the user's silence — it is the plugin still settling from the
      // previous session (or, on Android, an aggressive on-device no-match
      // timeout tripping before the mic was truly ready). Surfacing "no
      // captamos el monto" on the very first frame reads as a broken mic, so
      // one silent retry is attempted first instead of asking the user to
      // read and act on a failure they never had a real chance to avoid.
      case SpeechRecognitionErrorKind.busy:
      case SpeechRecognitionErrorKind.noSpeech:
      case SpeechRecognitionErrorKind.unknown:
      case null:
        if (_shouldRetryEarlyError()) {
          _earlyErrorRetried = true;
          unawaited(_retryAfterEarlyError());
          return;
        }
        _finish(state.transcript);
    }
  }

  /// Whether the error just received is close enough to session start, with
  /// nothing heard yet, that it is worth one silent retry instead of ending
  /// the session. See the doc on [_earlyErrorRetryWindow].
  bool _shouldRetryEarlyError() {
    final startedAt = _listeningStartedAt;
    return !_earlyErrorRetried &&
        state.status == VoiceCaptureStatus.listening &&
        !state.hasTranscript &&
        startedAt != null &&
        DateTime.now().difference(startedAt) < _earlyErrorRetryWindow;
  }

  Future<void> _retryAfterEarlyError() async {
    await Future<void>.delayed(_earlyErrorRetryDelay);
    if (isClosed || state.status != VoiceCaptureStatus.listening) {
      // The user stopped, cancelled or the sheet closed while this was
      // waiting — reopening the microphone now would be a surprise, not
      // a fix.
      return;
    }
    await _listen();
  }

  void _finish(String transcript) {
    final draft = _parse(
      SpokenTransactionInput(
        transcript: transcript,
        languageCode: _languageCode,
        currency: _currency,
        categories: _categories,
        accounts: _accounts,
      ),
    );
    emit(
      state.copyWith(
        status: draft.hasAmount
            ? VoiceCaptureStatus.completed
            : VoiceCaptureStatus.noAmount,
        transcript: transcript,
        soundLevel: 0,
        draft: draft,
      ),
    );
  }

  void _emitUnavailable(VoiceCaptureUnavailableReason reason) {
    emit(
      state.copyWith(
        status: VoiceCaptureStatus.unavailable,
        soundLevel: 0,
        unavailableReason: reason,
      ),
    );
  }

  Future<void> _loadVocabulary() async {
    final accounts = await _watchAccounts().first;
    _accounts = accounts.fold(
      (_) => const <Account>[],
      (entries) => entries.map((entry) => entry.account).toList(),
    );
    if (_accounts.isNotEmpty) {
      // The movement lands on the first active account by default, the same
      // one the form preselects, so the magnitude heuristic is evaluated
      // against the currency the user is actually about to record in.
      _currency = _accounts.first.currency;
    }
    final expense = await _watchCategories(CategoryKind.expense).first;
    final income = await _watchCategories(CategoryKind.income).first;
    _categories = [
      ..._flatten(expense),
      ..._flatten(income),
    ];
  }

  /// Roots and subcategories alike, flattened: the matcher scores every name
  /// the user can say, and a subcategory is exactly the specific one they
  /// tend to say out loud.
  List<Category> _flatten(Result<List<CategoryNode>> result) => result.fold(
        (_) => const <Category>[],
        (nodes) => [
          for (final node in nodes) ...[node.root, ...node.subcategories],
        ],
      );
}
