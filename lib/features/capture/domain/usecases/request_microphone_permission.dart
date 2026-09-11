import 'package:injectable/injectable.dart';

import '../entities/speech_recognition.dart';
import '../repositories/microphone_permission_gate.dart';

/// Asks for the microphone, in context (HU-07).
///
/// The caller must have shown the one-line explanation first. When the
/// permission is already permanently denied this does **not** prompt again —
/// the app never nags on every attempt; it offers the settings shortcut
/// instead (see `OpenMicrophoneSettings`).
@injectable
class RequestMicrophonePermission {
  const RequestMicrophonePermission(this._gate);

  final MicrophonePermissionGate _gate;

  Future<MicrophonePermissionStatus> call() async {
    final current = await _gate.current();
    if (current != MicrophonePermissionStatus.denied) {
      return current;
    }
    return _gate.request();
  }
}
