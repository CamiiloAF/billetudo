import 'package:injectable/injectable.dart';

import '../repositories/microphone_permission_gate.dart';

/// Sends the user to the system settings, the only way back from a
/// permanently denied microphone (HU-07).
@injectable
class OpenMicrophoneSettings {
  const OpenMicrophoneSettings(this._gate);

  final MicrophonePermissionGate _gate;

  Future<bool> call() => _gate.openSystemSettings();
}
