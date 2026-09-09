import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../../accounts/domain/entities/account.dart';
import '../../../accounts/domain/usecases/watch_accounts.dart';
import '../../../categories/domain/entities/category.dart';
import '../../../categories/domain/entities/category_node.dart';
import '../../../categories/domain/usecases/watch_categories.dart';
import '../../domain/entities/speech_recognition.dart';
import '../../domain/entities/spoken_transaction_draft.dart';
import '../../domain/entities/spoken_transaction_input.dart';
import '../../domain/usecases/cancel_voice_capture.dart';
import '../../domain/usecases/get_voice_capture_availability.dart';
import '../../domain/usecases/open_microphone_settings.dart';
import '../../domain/usecases/parse_spoken_transaction.dart';
import '../../domain/usecases/request_microphone_permission.dart';
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

  StreamSubscription<SpeechRecognitionUpdate>? _updates;

  /// The user's vocabulary, loaded once per session so the parser stays a
  /// pure function (`SpokenTransactionInput` does no I/O of its own).
  List<Account> _accounts = const [];
  List<Category> _categories = const [];

  String _localeId = 'es_ES';
  String _languageCode = 'es';
  String _currency = 'COP';

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
    emit(const VoiceCaptureState());

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
  Future<void> stopListening() async {
    if (state.status != VoiceCaptureStatus.listening) {
      return;
    }
    await _stopCapture();
  }

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
    final started = await _startCapture(localeId: _localeId);
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
        _finish(update.transcript);
      case SpeechRecognitionPhase.error:
        _onError(update);
    }
  }

  void _onError(SpeechRecognitionUpdate update) {
    switch (update.error) {
      case SpeechRecognitionErrorKind.permission:
        emit(state.copyWith(status: VoiceCaptureStatus.permissionNeeded));
      case SpeechRecognitionErrorKind.onDeviceUnavailable:
        _emitUnavailable(VoiceCaptureUnavailableReason.onDeviceUnavailable);
      case SpeechRecognitionErrorKind.network:
        _emitUnavailable(VoiceCaptureUnavailableReason.network);
      case SpeechRecognitionErrorKind.busy:
        _emitUnavailable(VoiceCaptureUnavailableReason.busy);
      case SpeechRecognitionErrorKind.unavailable:
        _emitUnavailable(VoiceCaptureUnavailableReason.recognizer);
      // Silence, noise or a covered microphone is not an error the user has to
      // read about as a failure: it lands on the same "no captamos el monto"
      // surface, which keeps both exits open and blames nobody.
      case SpeechRecognitionErrorKind.noSpeech:
      case SpeechRecognitionErrorKind.unknown:
      case null:
        _finish(state.transcript);
    }
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
