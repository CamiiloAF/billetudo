import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

import '../../domain/entities/speech_recognition.dart';
import '../../domain/repositories/microphone_permission_gate.dart';

/// `permission_handler` implementation of the microphone gate.
///
/// Only the microphone is handled here. On iOS the speech-recognition
/// authorization (`NSSpeechRecognitionUsageDescription`) is requested by the
/// `speech_to_text` plugin itself during its own initialization, so asking for
/// it twice from two places would double the prompts for the same capability.
@LazySingleton(as: MicrophonePermissionGate)
class PermissionHandlerMicrophoneGate implements MicrophonePermissionGate {
  const PermissionHandlerMicrophoneGate();

  @override
  Future<MicrophonePermissionStatus> current() async =>
      _map(await Permission.microphone.status);

  @override
  Future<MicrophonePermissionStatus> request() async =>
      _map(await Permission.microphone.request());

  @override
  Future<bool> openSystemSettings() => openAppSettings();

  MicrophonePermissionStatus _map(PermissionStatus status) => switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.limited ||
        PermissionStatus.provisional =>
          MicrophonePermissionStatus.granted,
        PermissionStatus.permanentlyDenied =>
          MicrophonePermissionStatus.permanentlyDenied,
        PermissionStatus.restricted => MicrophonePermissionStatus.restricted,
        PermissionStatus.denied => MicrophonePermissionStatus.denied,
      };
}
