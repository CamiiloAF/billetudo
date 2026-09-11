import '../entities/speech_recognition.dart';

/// The microphone permission, behind a domain interface (HU-07).
///
/// The permission is asked for **in context**, at the moment the user triggers
/// the voice capture — never at startup and never during onboarding. The
/// caller is responsible for showing the plain-language explanation *before*
/// calling [request]: on iOS the system dialog appears exactly once, and a
/// "Don't allow" there is effectively irreversible for most people.
abstract class MicrophonePermissionGate {
  /// The current status, without prompting anyone.
  Future<MicrophonePermissionStatus> current();

  /// Shows the system dialog when the permission is still askable, and
  /// returns the resulting status.
  Future<MicrophonePermissionStatus> request();

  /// Opens the app's system settings, the only way back from
  /// [MicrophonePermissionStatus.permanentlyDenied]. Returns `false` when the
  /// settings screen could not be opened.
  Future<bool> openSystemSettings();
}
