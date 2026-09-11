import '../../../../core/error/result.dart';
import '../entities/speech_recognition.dart';

/// The platform speech recognizer, behind a domain interface.
///
/// `presentation` -> `domain` <- `data`: the `speech_to_text` plugin lives in
/// `data` and never crosses this line, so every test above it fakes this
/// interface and no existing test ever grows a microphone dependency (HU-10).
///
/// Implementations must:
/// - **initialize lazily**, on the first call to [prepare], never at app
///   startup;
/// - **never persist** the audio or the transcription, not even briefly to
///   disk (HU-06);
/// - **never leave the microphone open**: every session ends by silence, by
///   [VoiceCaptureLimits.maxListenDuration], by [stop], by [cancel] or by the
///   app going to background.
abstract class SpeechRecognizer {
  /// Live partial and final results, plus sound level for the listening
  /// indicator. Broadcast: several listeners may observe one session.
  Stream<SpeechRecognitionUpdate> get updates;

  bool get isListening;

  /// Initializes the plugin if needed and reports what this device can do for
  /// [localeId]. Safe to call repeatedly; the plugin is only initialized once.
  Future<Result<SpeechRecognizerAvailability>> prepare({
    required String localeId,
  });

  /// Starts a session.
  ///
  /// On-device recognition is always requested first. When it is unavailable,
  /// the session fails with
  /// [SpeechRecognitionErrorKind.onDeviceUnavailable] unless
  /// [allowCloudRecognition] is explicitly true — the app never downgrades
  /// the privacy promise on its own (HU-06).
  Future<Result<Unit>> start({
    required String localeId,
    bool allowCloudRecognition = false,
    Duration maxDuration = VoiceCaptureLimits.maxListenDuration,
    Duration pauseFor = VoiceCaptureLimits.pauseForSilence,
  });

  /// Ends the session and keeps whatever was recognized.
  Future<Result<Unit>> stop();

  /// Ends the session and throws away audio and transcription alike.
  Future<Result<Unit>> cancel();
}
