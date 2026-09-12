import 'package:equatable/equatable.dart';

/// Where the audio is actually turned into text.
///
/// This is a **privacy fact, not a technical detail**. Both
/// `SFSpeechRecognizer` (iOS) and `SpeechRecognizer` (Android) fall back to
/// their vendor's servers when on-device recognition is unavailable for the
/// device or the language pack. Zero retention (HU-06) settles what the app
/// *stores* — nothing — but not where the audio *goes* while it is being
/// transcribed. So the route is exposed as data the UI and the privacy policy
/// can both read, instead of being buried in the data layer.
enum SpeechRecognitionRoute {
  /// Recognition provably stayed on the device.
  onDevice,

  /// Recognition ran through the operating system's cloud service: the audio
  /// left the device, even though the app stored none of it.
  cloud,

  /// Not known yet — no listen attempt has resolved it.
  unknown,
}

/// Why a listen attempt could not continue. Deliberately coarse: the UI must
/// speak about the app's state, never about how well the user spoke.
enum SpeechRecognitionErrorKind {
  /// The recognizer returned nothing usable (silence, noise, covered mic).
  noSpeech,

  /// On-device recognition was demanded and is not available here. Never
  /// downgraded silently — the caller decides (HU-06).
  onDeviceUnavailable,

  /// The recognizer needs a network it does not have.
  network,

  /// The microphone permission is missing or was revoked mid-session.
  permission,

  /// Another app holds the microphone, or a system interruption arrived.
  busy,

  /// The recognizer or the requested locale is not available on this device.
  unavailable,

  unknown,
}

/// Stage of the listening session.
enum SpeechRecognitionPhase { listening, done, error }

/// One live update from the recognizer.
///
/// [transcript] lives in memory for exactly as long as the capture flow is
/// open. Nothing in this feature writes it to disk, to the database, or to
/// the sync queue (HU-06, retención cero).
class SpeechRecognitionUpdate extends Equatable {
  const SpeechRecognitionUpdate({
    required this.phase,
    this.transcript = '',
    this.isFinal = false,
    this.soundLevel = 0,
    this.error,
  });

  final SpeechRecognitionPhase phase;

  /// What has been recognized so far. Partial results arrive while the user is
  /// still talking so the flow can show them live (HU-03).
  final String transcript;

  final bool isFinal;

  /// Normalized 0..1 microphone level, for the live listening indicator. Not
  /// money — a `double` is fine here.
  final double soundLevel;

  final SpeechRecognitionErrorKind? error;

  @override
  List<Object?> get props => [phase, transcript, isFinal, soundLevel, error];
}

/// What the recognizer can do on this device, for this locale.
class SpeechRecognizerAvailability extends Equatable {
  const SpeechRecognizerAvailability({
    required this.isAvailable,
    required this.isLocaleSupported,
    required this.route,
  });

  const SpeechRecognizerAvailability.unavailable()
      : isAvailable = false,
        isLocaleSupported = false,
        route = SpeechRecognitionRoute.unknown;

  /// Whether the platform recognizer initialized at all.
  final bool isAvailable;

  /// Whether the **app's** locale is recognizable here. There is no fallback
  /// to another language: transcribing Spanish with an English model produces
  /// confident garbage, which is worse than an honest message (HU-08).
  final bool isLocaleSupported;

  /// Best known route so far. Only a completed on-device listen proves
  /// [SpeechRecognitionRoute.onDevice].
  final SpeechRecognitionRoute route;

  @override
  List<Object?> get props => [isAvailable, isLocaleSupported, route];
}

/// Runtime limits of a listening session.
///
/// The hard cap exists so a session can never leave the microphone open:
/// battery, privacy and the user's trust all depend on it (HU-03, edge cases).
/// The exact number is still an open product question in
/// `17-captura-voz.md`; 30 s is the working default and is long enough for
/// slow or interrupted speech (HU-09), not a measured decision.
abstract final class VoiceCaptureLimits {
  static const Duration maxListenDuration = Duration(seconds: 30);

  /// Safety net for the "the user never said anything at all" case, **not**
  /// the end-of-phrase detector.
  ///
  /// `speech_to_text` maps this to its `pauseFor`, and it initializes its
  /// `_lastSpeechEventAt` to the moment the session started — on Android the
  /// same value also goes out as
  /// `EXTRA_SPEECH_INPUT_COMPLETE_SILENCE_LENGTH_MILLIS`. So it is counted
  /// from the *start of the session*, not from the last recognized word: a
  /// short value cuts the user off before they have had time to speak, and the
  /// empty transcript that follows reads as "no amount" and loops on retry.
  /// Hence the generous value. The real end of phrase is
  /// `VoiceCaptureCubit._autoStopSilenceDelay` (1.5 s measured from the last
  /// recognized word, which is the correct measure); [maxListenDuration] stays
  /// the hard cap.
  static const Duration pauseForSilence = Duration(seconds: 10);
}

/// State of the microphone permission (HU-07).
enum MicrophonePermissionStatus {
  granted,

  /// Denied, but askable again.
  denied,

  /// Denied for good: only the system settings can undo it, so the app links
  /// there instead of nagging.
  permanentlyDenied,

  /// Blocked by the OS (parental controls, MDM). Not askable.
  restricted,
}
