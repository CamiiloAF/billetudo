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
    final recognizer = await _recognizer.prepare(localeId: localeId);
    return recognizer.map(
      (availability) => VoiceCaptureAvailability(
        recognizer: availability,
        permission: permission,
      ),
    );
  }
}
