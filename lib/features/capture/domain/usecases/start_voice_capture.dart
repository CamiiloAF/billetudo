import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/speech_recognition.dart';
import '../repositories/microphone_permission_gate.dart';
import '../repositories/speech_recognizer.dart';

/// Starts one listening session, after checking every precondition (HU-03).
///
/// It refuses rather than degrades: without the permission, without a working
/// recognizer, or without the app's locale available, it returns a failure and
/// the flow falls back to the manual form — which stays 100% functional,
/// because it is Nivel 0 and cannot depend on a permission (HU-07).
///
/// `allowCloudRecognition` defaults to false: the session asks for on-device
/// recognition and fails loudly when it cannot get it, instead of quietly
/// sending the user's audio to Apple or Google (HU-06).
@injectable
class StartVoiceCapture {
  const StartVoiceCapture(this._recognizer, this._permissionGate);

  final SpeechRecognizer _recognizer;
  final MicrophonePermissionGate _permissionGate;

  /// `ValidationFailure.field` values, so the presentation layer can pick the
  /// right message without parsing text.
  static const String fieldPermission = 'microphonePermission';
  static const String fieldRecognizer = 'recognizer';
  static const String fieldLocale = 'locale';

  FutureResult<Unit> call({
    required String localeId,
    bool allowCloudRecognition = false,
    Duration maxDuration = VoiceCaptureLimits.maxListenDuration,
  }) async {
    final permission = await _permissionGate.current();
    if (permission != MicrophonePermissionStatus.granted) {
      return const Left(
        ValidationFailure(
          'Microphone permission not granted',
          field: fieldPermission,
        ),
      );
    }

    final prepared = await _recognizer.prepare(localeId: localeId);
    switch (prepared) {
      case Left(value: final failure):
        return Left(failure);
      case Right(value: final availability):
        if (!availability.isAvailable) {
          return const Left(
            ValidationFailure(
              'Speech recognizer unavailable',
              field: fieldRecognizer,
            ),
          );
        }
        if (!availability.isLocaleSupported) {
          return const Left(
            ValidationFailure(
              'Locale not available for recognition',
              field: fieldLocale,
            ),
          );
        }
    }

    return _recognizer.start(
      localeId: localeId,
      allowCloudRecognition: allowCloudRecognition,
      maxDuration: maxDuration,
    );
  }
}
