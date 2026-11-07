// Android half of the "ask for the microphone before initializing the
// recognizer" rule. `speech_to_text`'s `initialize()` requests `RECORD_AUDIO`
// itself (`initializeIfPermitted` → `ActivityCompat.requestPermissions`) the
// moment it is called without the permission, so an availability check that
// prepared the recognizer first would leave the system dialog on screen before
// the app's explainer — and would hand the permission answer to the plugin
// instead of to `permission_handler`, which is what produced the reported
// "inicializa, pide el permiso, lo acepto y me manda a ajustes".
//
// With the fixed order this call returns immediately and no dialog is ever
// started. With the old one it does not return at all (the future waits on a
// dialog nobody answers), which is why the call is bounded by a timeout: a
// hang here is the failure mode, and it must fail, not hang the suite.
//
// ## How to run it (a booted Android emulator or device)
//
// The precondition is a microphone permission that has not been granted yet;
// a freshly installed app always starts that way. To reset an existing one:
//
//   adb shell pm revoke <bundle-id> android.permission.RECORD_AUDIO
//   adb shell pm clear-permission-flags <bundle-id> \
//     android.permission.RECORD_AUDIO user-set user-fixed
//
//   flutter test integration_test/android_microphone_permission_test.dart \
//     -d <device> --flavor dev
//
// The iOS counterpart (compile-time macro + real grant) is
// `integration_test/ios_microphone_permission_test.dart`, and the fast static
// guards live in `test/ios/voice_capture_ios_config_test.dart`.
import 'dart:io';

import 'package:billetudo/features/capture/data/repositories/permission_handler_microphone_gate.dart';
import 'package:billetudo/features/capture/data/repositories/speech_to_text_recognizer.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:billetudo/features/capture/domain/usecases/get_voice_capture_availability.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets(
      'sin permiso de micrófono, consultar disponibilidad no dispara el '
      'diálogo del sistema antes del explicador', (tester) async {
    if (!Platform.isAndroid) {
      // iOS has the compile-time macro counterpart; see the header.
      return;
    }

    final status = await Permission.microphone.status;
    expect(
      status,
      PermissionStatus.denied,
      reason: 'Precondition: the microphone must not be granted yet. On a '
          'fresh install it is denied automatically; otherwise run '
          '`adb shell pm revoke <bundle> android.permission.RECORD_AUDIO` and '
          '`adb shell pm clear-permission-flags <bundle> '
          'android.permission.RECORD_AUDIO user-set user-fixed`.',
    );

    final availability = await GetVoiceCaptureAvailability(
      SpeechToTextRecognizer(),
      const PermissionHandlerMicrophoneGate(),
    )(localeId: 'es_CO')
        .timeout(
      const Duration(seconds: 10),
      onTimeout: () => fail(
        'Availability never resolved: preparing the recognizer while the '
        'microphone was denied opened the system permission dialog before the '
        'app could show its explainer. That is the bug this test guards '
        'against.',
      ),
    );

    final value = availability.getOrElse(
      (failure) => fail('Availability failed instead of reporting permission'),
    );
    expect(value.permission, MicrophonePermissionStatus.denied);
    expect(value.hasPermission, isFalse);
    expect(value.canListen, isFalse);
    // Nothing prompted on the platform side either, so the status is still the
    // untouched "not asked yet" one.
    expect(await Permission.microphone.status, PermissionStatus.denied);
  });
}
