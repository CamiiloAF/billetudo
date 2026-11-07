// The real `MicrophonePermissionGate`, driven through permission_handler's own
// MethodChannel instead of a fake gate: what matters here is the translation
// from the platform's `PermissionStatus` to the app's
// `MicrophonePermissionStatus`, because that translation decides whether the
// voice-capture sheet offers "Permitir", sends the user to system settings, or
// gives up.
//
// The statuses are sent as the wire codes the plugin uses
// (`permission_handler_platform_interface` `PermissionStatusValue`): denied 0,
// granted 1, restricted 2, limited 3, permanentlyDenied 4, provisional 5.
//
// This is the Dart half only. Whether iOS can report anything other than
// `denied` at all is a native build-time switch and lives in
// `test/ios/voice_capture_ios_config_test.dart`.
import 'package:billetudo/features/capture/data/repositories/permission_handler_microphone_gate.dart';
import 'package:billetudo/features/capture/domain/entities/speech_recognition.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _denied = 0;
const _granted = 1;
const _restricted = 2;
const _limited = 3;
const _permanentlyDenied = 4;
const _provisional = 5;

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const channel = MethodChannel('flutter.baseflow.com/permissions/methods');
  const gate = PermissionHandlerMicrophoneGate();

  late int statusCode;
  late int requestCode;
  late bool settingsOpened;
  late List<String> calls;

  setUp(() {
    statusCode = _denied;
    requestCode = _granted;
    settingsOpened = true;
    calls = <String>[];

    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (call) async {
      calls.add(call.method);
      switch (call.method) {
        case 'checkPermissionStatus':
          return statusCode;
        case 'requestPermissions':
          final permission = (call.arguments as List<Object?>).first! as int;
          return <int, int>{permission: requestCode};
        case 'openAppSettings':
          return settingsOpened;
        default:
          return null;
      }
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  group('current', () {
    test('granted, limited and provisional all count as usable', () async {
      for (final code in [_granted, _limited, _provisional]) {
        statusCode = code;

        expect(
          await gate.current(),
          MicrophonePermissionStatus.granted,
          reason: 'wire code $code should be usable by the recognizer',
        );
      }
    });

    test('denied is still askable', () async {
      statusCode = _denied;

      expect(await gate.current(), MicrophonePermissionStatus.denied);
    });

    test('restricted is reported as blocked, not askable', () async {
      // Parental controls / MDM on iOS: requesting again cannot help.
      statusCode = _restricted;

      expect(await gate.current(), MicrophonePermissionStatus.restricted);
    });

    test('permanentlyDenied is reported as such', () async {
      // iOS returns this both for a real "Don't Allow" and — when the
      // PERMISSION_MICROPHONE macro is missing — for every status read. The
      // UI must send the user to settings instead of looping on a prompt.
      statusCode = _permanentlyDenied;

      expect(
        await gate.current(),
        MicrophonePermissionStatus.permanentlyDenied,
      );
    });
  });

  group('request', () {
    test('maps a granted request result', () async {
      requestCode = _granted;

      expect(await gate.request(), MicrophonePermissionStatus.granted);
      expect(calls, contains('requestPermissions'));
    });

    test('a request the platform refuses for good is not retried', () async {
      requestCode = _permanentlyDenied;

      expect(
        await gate.request(),
        MicrophonePermissionStatus.permanentlyDenied,
      );
    });
  });

  test('openSystemSettings opens the app settings page', () async {
    expect(await gate.openSystemSettings(), isTrue);
    expect(calls, contains('openAppSettings'));
  });
}
