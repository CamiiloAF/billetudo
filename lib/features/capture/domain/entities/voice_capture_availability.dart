import 'package:equatable/equatable.dart';

import 'speech_recognition.dart';

/// The full picture the capture flow needs before it offers to listen:
/// recognizer plus permission, in one value.
class VoiceCaptureAvailability extends Equatable {
  const VoiceCaptureAvailability({
    required this.recognizer,
    required this.permission,
  });

  final SpeechRecognizerAvailability recognizer;
  final MicrophonePermissionStatus permission;

  bool get hasPermission => permission == MicrophonePermissionStatus.granted;

  /// Whether a listen can start right now.
  bool get canListen =>
      recognizer.isAvailable && recognizer.isLocaleSupported && hasPermission;

  /// Whether the permission can still be asked for, or only the system
  /// settings can change it (HU-07).
  bool get isPermissionAskable =>
      permission == MicrophonePermissionStatus.denied;

  /// True only when the audio provably never leaves the device. Anything else
  /// — including [SpeechRecognitionRoute.unknown] — must not be presented to
  /// the user as "todo local".
  bool get audioStaysOnDevice =>
      recognizer.route == SpeechRecognitionRoute.onDevice;

  @override
  List<Object?> get props => [recognizer, permission];
}
