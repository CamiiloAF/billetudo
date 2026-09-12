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

  /// [knownPermission], when given, is trusted in place of re-querying
  /// [MicrophonePermissionGate.current] — see `GetVoiceCaptureAvailability`'s
  /// doc for why: `VoiceCaptureCubit.start` already resolved an accurate
  /// permission a moment earlier in the very same call, and re-querying the
  /// OS again here (bugfix 2026-09-12) was a second, independent instance of
  /// the exact race that doc describes — the platform's permission status
  /// can still read stale right after a fresh grant, so this call could
  /// reject a session `start()` itself had just confirmed was allowed,
  /// bouncing the user straight back to "El micrófono está desactivado"
  /// after the listening screen had already appeared. A caller with no
  /// fresh confirmation (e.g. a retry well after the original `start()`
  /// call) should leave this null and get the real, current answer.
  FutureResult<Unit> call({
    required String localeId,
    bool allowCloudRecognition = false,
    Duration maxDuration = VoiceCaptureLimits.maxListenDuration,
    MicrophonePermissionStatus? knownPermission,
  }) async {
    final permission = knownPermission ?? await _permissionGate.current();
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
