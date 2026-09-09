import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
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

  FutureResult<VoiceCaptureAvailability> call({
    required String localeId,
  }) async {
    final permission = await _permissionGate.current();
    final recognizer = await _recognizer.prepare(localeId: localeId);
    return recognizer.map(
      (availability) => VoiceCaptureAvailability(
        recognizer: availability,
        permission: permission,
      ),
    );
  }
}
