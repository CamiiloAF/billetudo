// `ios/Podfile` cannot be asserted from a unit test's point of view: the macro
// it sets changes what the native pod COMPILES, so the only honest check is a
// real iOS build. This test asks the OS, through the same plugin the app uses
// (`Permission.microphone`, behind `MicrophonePermissionGate`), and asserts the
// answer a user with the microphone allowed must get.
//
// ## What this catches
//
// `permission_handler_apple` compiles each iOS permission in at build time.
// Without `PERMISSION_MICROPHONE=1` in the Podfile's post_install block,
// `Permission.microphone` resolves to `UnknownPermissionStrategy`: `status` is
// always `denied` and `request()` answers `permanentlyDenied` without a
// prompt — even with the microphone already allowed in Settings. The voice
// capture flow then dead-ends on "open settings" and never listens.
//
// ## How to run it (macOS + a booted iOS Simulator)
//
// The system permission dialog cannot be tapped from a Dart test, so the TCC
// grant is seeded first. Use the bundle id of the build under test: plain
// `com.camiloagudelo.billetudo` for the default scheme, or
// `com.camiloagudelo.billetudo.dev` with `--flavor dev`.
//
//   xcrun simctl privacy <device-udid> grant microphone <bundle-id>
//   flutter test integration_test/ios_microphone_permission_test.dart \
//     -d <device-udid>
//
// `flutter test` (no arguments) never runs this file: it only picks up `test/`.
// The static counterpart is `test/ios/voice_capture_ios_config_test.dart`.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('the iOS build can report and grant the microphone', (
    tester,
  ) async {
    if (!Platform.isIOS) {
      // Android has its own runtime permission path and its own tests; this
      // file is about the iOS compile-time switch.
      return;
    }

    final status = await Permission.microphone.status;
    expect(
      status,
      PermissionStatus.granted,
      reason: 'The microphone TCC must be pre-granted for this test: '
          '`xcrun simctl privacy <device> grant microphone <bundle-id>`. '
          'If it is granted and this still fails, the iOS build compiled '
          'permission_handler without PERMISSION_MICROPHONE (ios/Podfile '
          'post_install) and voice capture can never listen on iOS.',
    );

    // This is the call the permission explainer makes. Already granted, so no
    // dialog can appear and the future resolves immediately.
    expect(await Permission.microphone.request(), PermissionStatus.granted);
  });
}
