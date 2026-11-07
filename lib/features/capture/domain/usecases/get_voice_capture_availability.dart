import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/speech_recognition.dart';
import '../entities/voice_capture_availability.dart';
import '../repositories/microphone_permission_gate.dart';
import '../repositories/speech_recognizer.dart';

/// Answers "can I dictate right now, and where would my audio go?" in one
/// call, without prompting for anything (HU-06/HU-07).
///
/// This is what makes the app able to be honest: the flow, the settings
/// screen and the privacy copy all read the same
/// [VoiceCaptureAvailability.audioStaysOnDevice] instead of each assuming
/// recognition is local.
///
/// **The microphone is asked for first, and the recognizer is not touched
/// until it is granted.** That order is load-bearing:
/// - On Android, `speech_to_text`'s `initialize()` requests `RECORD_AUDIO`
///   itself (`initializeIfPermitted` → `ActivityCompat.requestPermissions`)
///   when it is missing. Preparing first would pop the system dialog before
///   the app's explainer (HU-07), and the permission answer would then belong
///   to the plugin rather than to [MicrophonePermissionGate], leaving the
///   availability snapshot below already stale the moment it was built — the
///   reported "inicializa, pide el permiso, lo acepto y me manda a ajustes".
/// - On iOS, `initialize()` requests speech-recognition authorization
///   (`SFSpeechRecognizer.requestAuthorization`), which would also jump ahead
///   of the explainer.
///
/// So while the permission is missing this returns
/// [SpeechRecognizerAvailability.unprepared] and lets the sheet show the
/// explainer; once the user grants it, the session starts through
/// `StartVoiceCapture`, which prepares the recognizer after checking the
/// permission again.
@injectable
class GetVoiceCaptureAvailability {
  const GetVoiceCaptureAvailability(this._recognizer, this._permissionGate);

  final SpeechRecognizer _recognizer;
  final MicrophonePermissionGate _permissionGate;

  /// [knownPermission], when given, is trusted in place of re-querying
  /// [MicrophonePermissionGate.current] — the caller passes it right after
  /// its own [MicrophonePermissionGate.request] resolved `granted`.
  ///
  /// Bugfix 2026-09-12: on real devices, re-querying `Permission.microphone
  /// .status` (a *separate* platform-channel round trip from the `.request()`
  /// call that just granted it) can still read back the pre-grant value for
  /// a beat — the OS/plugin has not finished propagating it — so a user who
  /// just tapped "Allow" was immediately bounced to "El micrófono está
  /// desactivado" as if they had said no. Trusting the status the request
  /// itself already returned sidesteps that race entirely instead of racing
  /// a delay against it.
  FutureResult<VoiceCaptureAvailability> call({
    required String localeId,
    MicrophonePermissionStatus? knownPermission,
  }) async {
    final permission = knownPermission ?? await _permissionGate.current();
    if (permission != MicrophonePermissionStatus.granted) {
      // See the class doc: preparing here would let the platform prompt on
      // its own, before the app's explainer. Nothing about the recognizer is
      // known yet, and the caller only needs the permission to decide between
      // the explainer and the listening session.
      return Right(
        VoiceCaptureAvailability(
          recognizer: const SpeechRecognizerAvailability.unprepared(),
          permission: permission,
        ),
      );
    }
    final recognizer = await _recognizer.prepare(localeId: localeId);
    return recognizer.map(
      (availability) => VoiceCaptureAvailability(
        recognizer: availability,
        permission: permission,
      ),
    );
  }
}
