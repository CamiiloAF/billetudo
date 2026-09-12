import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:billetudo/features/capture/domain/usecases/cancel_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/get_voice_capture_availability.dart';
import 'package:billetudo/features/capture/domain/usecases/open_microphone_settings.dart';
import 'package:billetudo/features/capture/domain/usecases/request_microphone_permission.dart';
import 'package:billetudo/features/capture/domain/usecases/start_voice_capture.dart';
import 'package:billetudo/features/capture/domain/usecases/stop_voice_capture.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../fake_speech_recognizer.dart';

void main() {
  late FakeSpeechRecognizer recognizer;
  late FakeMicrophonePermissionGate gate;

  setUp(() {
    recognizer = FakeSpeechRecognizer();
    gate = FakeMicrophonePermissionGate();
  });

  group('GetVoiceCaptureAvailability', () {
    test('junta reconocedor y permiso sin pedir nada', () async {
      final result = await GetVoiceCaptureAvailability(recognizer, gate)(
        localeId: 'es_CO',
      );

      final availability = result.getOrElse((_) => throw StateError('Left'));
      expect(availability.canListen, isTrue);
      expect(availability.audioStaysOnDevice, isTrue);
      expect(gate.requestCalls, 0, reason: 'consultar no puede pedir permiso');
    });

    test('expone que el audio sale del dispositivo cuando va a la nube',
        () async {
      recognizer.availability = const SpeechRecognizerAvailability(
        isAvailable: true,
        isLocaleSupported: true,
        route: SpeechRecognitionRoute.cloud,
      );

      final result = await GetVoiceCaptureAvailability(recognizer, gate)(
        localeId: 'es_CO',
      );

      final availability = result.getOrElse((_) => throw StateError('Left'));
      expect(availability.audioStaysOnDevice, isFalse);
    });

    test('una ruta desconocida no se presenta como local', () async {
      recognizer.availability = const SpeechRecognizerAvailability(
        isAvailable: true,
        isLocaleSupported: true,
        route: SpeechRecognitionRoute.unknown,
      );

      final result = await GetVoiceCaptureAvailability(recognizer, gate)(
        localeId: 'es_CO',
      );

      final availability = result.getOrElse((_) => throw StateError('Left'));
      expect(availability.audioStaysOnDevice, isFalse);
    });

    test('sin idioma disponible no se puede escuchar', () async {
      recognizer.availability = const SpeechRecognizerAvailability(
        isAvailable: true,
        isLocaleSupported: false,
        route: SpeechRecognitionRoute.onDevice,
      );

      final result = await GetVoiceCaptureAvailability(recognizer, gate)(
        localeId: 'es_CO',
      );

      final availability = result.getOrElse((_) => throw StateError('Left'));
      expect(availability.canListen, isFalse);
    });
  });

  group('StartVoiceCapture', () {
    test('pide reconocimiento on-device por defecto', () async {
      final result =
          await StartVoiceCapture(recognizer, gate)(localeId: 'es_CO');

      expect(result.isRight(), isTrue);
      expect(recognizer.lastAllowCloudRecognition, isFalse);
      expect(recognizer.lastLocaleId, 'es_CO');
      expect(
        recognizer.lastMaxDuration,
        VoiceCaptureLimits.maxListenDuration,
        reason: 'toda escucha tiene tope duro',
      );
    });

    test('sin permiso no arranca y lo dice por campo', () async {
      gate.status = MicrophonePermissionStatus.denied;

      final result =
          await StartVoiceCapture(recognizer, gate)(localeId: 'es_CO');

      expect(recognizer.startCalls, 0);
      final failure = result.getLeft().toNullable();
      expect(failure, isA<ValidationFailure>());
      expect(
        (failure! as ValidationFailure).field,
        StartVoiceCapture.fieldPermission,
      );
    });

    test('sin reconocedor disponible no arranca', () async {
      recognizer.availability =
          const SpeechRecognizerAvailability.unavailable();

      final result =
          await StartVoiceCapture(recognizer, gate)(localeId: 'es_CO');

      expect(recognizer.startCalls, 0);
      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        StartVoiceCapture.fieldRecognizer,
      );
    });

    test('sin el idioma de la app no cae a otro idioma: falla', () async {
      recognizer.availability = const SpeechRecognizerAvailability(
        isAvailable: true,
        isLocaleSupported: false,
        route: SpeechRecognitionRoute.onDevice,
      );

      final result =
          await StartVoiceCapture(recognizer, gate)(localeId: 'es_CO');

      expect(recognizer.startCalls, 0);
      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        StartVoiceCapture.fieldLocale,
      );
    });

    test('la nube solo se usa si el llamador lo pide explícitamente', () async {
      await StartVoiceCapture(recognizer, gate)(
        localeId: 'es_CO',
        allowCloudRecognition: true,
      );

      expect(recognizer.lastAllowCloudRecognition, isTrue);
    });
  });

  group('permiso de micrófono', () {
    test('se pide solo cuando todavía es preguntable', () async {
      gate
        ..status = MicrophonePermissionStatus.denied
        ..statusAfterRequest = MicrophonePermissionStatus.granted;

      final status = await RequestMicrophonePermission(gate)();

      expect(status, MicrophonePermissionStatus.granted);
      expect(gate.requestCalls, 1);
    });

    test('un denegado permanente no vuelve a insistir', () async {
      gate.status = MicrophonePermissionStatus.permanentlyDenied;

      final status = await RequestMicrophonePermission(gate)();

      expect(status, MicrophonePermissionStatus.permanentlyDenied);
      expect(gate.requestCalls, 0);
    });

    test('el camino de vuelta son los ajustes del sistema', () async {
      expect(await OpenMicrophoneSettings(gate)(), isTrue);
      expect(gate.openSettingsCalls, 1);
    });
  });

  group('fin de la escucha', () {
    test('detener conserva lo reconocido', () async {
      await StartVoiceCapture(recognizer, gate)(localeId: 'es_CO');
      await StopVoiceCapture(recognizer)();

      expect(recognizer.stopCalls, 1);
      expect(recognizer.isListening, isFalse);
    });

    test('cancelar descarta y deja el micrófono cerrado', () async {
      await StartVoiceCapture(recognizer, gate)(localeId: 'es_CO');
      await CancelVoiceCapture(recognizer)();

      expect(recognizer.cancelCalls, 1);
      expect(recognizer.isListening, isFalse);
    });
  });
}
