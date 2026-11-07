// Native iOS configuration the voice-capture feature depends on, and that no
// Dart test can exercise: `permission_handler` compiles each iOS permission in
// at BUILD time from `GCC_PREPROCESSOR_DEFINITIONS`, so a missing macro turns
// `Permission.microphone` into `UnknownPermissionStrategy` — status `denied`
// forever, `request()` answering `permanentlyDenied` without ever showing the
// system prompt. The app then dead-ends on "open settings" and voice capture
// never listens on iOS.
//
// That switch lives in `ios/Podfile`, not in Dart, which is why this test reads
// the native files. `integration_test/ios_microphone_permission_test.dart`
// proves the same thing on a real build; this one fails fast, on any machine,
// before anyone waits for an Xcode build.
//
// Sources: `docs/requirements/fase-2/17-captura-voz.md` (HU-06/HU-07) and the
// permission_handler iOS setup docs.
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

/// The `<string>` a top-level `<key>key</key>` maps to in an XML plist.
String? plistStringValue(String plist, String key) {
  final match = RegExp(
    '<key>$key</key>\\s*<string>([^<]*)</string>',
  ).firstMatch(plist);
  return match?.group(1)?.trim();
}

/// The value a `.strings` file maps [key] to.
String? stringsValue(String strings, String key) {
  final match = RegExp('"$key"\\s*=\\s*"([^"]*)"').firstMatch(strings);
  return match?.group(1)?.trim();
}

/// The body of the Podfile's `post_install` block, where CocoaPods build
/// settings are injected. Empty when the block is missing.
String postInstallBlock(String podfile) {
  final start = podfile.indexOf('post_install do |installer|');
  if (start < 0) {
    return '';
  }
  final end = podfile.indexOf('\nend', start);
  return end < 0 ? podfile.substring(start) : podfile.substring(start, end);
}

void main() {
  // `flutter test` runs from the package root.
  final infoPlist = File('ios/Runner/Info.plist').readAsStringSync();
  final podfile = File('ios/Podfile').readAsStringSync();
  final podfileLock = File('ios/Podfile.lock').readAsStringSync();

  group('Info.plist usage descriptions', () {
    test('declares the microphone with a real, non-empty reason', () {
      final description = plistStringValue(
        infoPlist,
        'NSMicrophoneUsageDescription',
      );

      expect(
        description,
        isNotNull,
        reason: 'Without NSMicrophoneUsageDescription iOS kills the app the '
            'moment it touches the microphone.',
      );
      expect(description, isNotEmpty);
    });

    test('declares speech recognition with a real, non-empty reason', () {
      final description = plistStringValue(
        infoPlist,
        'NSSpeechRecognitionUsageDescription',
      );

      expect(
        description,
        isNotNull,
        reason: 'SFSpeechRecognizer requires its own string, separate from '
            'the microphone one; without it authorization crashes the app.',
      );
      expect(description, isNotEmpty);
    });
  });

  group('localized usage descriptions (Apple requires them localized)', () {
    // The permission dialogs are system UI: `Info.plist` only carries the
    // development-language fallback, and iOS picks the text from the
    // `<lang>.lproj/InfoPlist.strings` that matches the device language. A key
    // present in the plist but missing from the lproj files is what the store
    // bundle review sees as "not localized".
    final project = File(
      'ios/Runner.xcodeproj/project.pbxproj',
    ).readAsStringSync();

    for (final language in ['es', 'en']) {
      test('$language localizes both permission strings', () {
        final file = File('ios/Runner/$language.lproj/InfoPlist.strings');

        expect(
          file.existsSync(),
          isTrue,
          reason: 'ios/Runner/$language.lproj/InfoPlist.strings is missing; '
              'the system permission dialog would fall back to the plist '
              'language for $language devices.',
        );

        final strings = file.readAsStringSync();
        final microphone = stringsValue(
          strings,
          'NSMicrophoneUsageDescription',
        );
        final speech = stringsValue(
          strings,
          'NSSpeechRecognitionUsageDescription',
        );

        expect(microphone, isNotNull);
        expect(microphone, isNotEmpty);
        expect(speech, isNotNull);
        expect(speech, isNotEmpty);

        // Existing in the folder is not enough: Xcode only ships it if the
        // variant group is referenced by the Runner target.
        expect(
          project,
          contains('$language.lproj/InfoPlist.strings'),
          reason: 'the $language localization exists on disk but is not '
              'wired into ios/Runner.xcodeproj; it will not be bundled.',
        );
      });
    }

    test('the base Info.plist keeps both keys (fallback language)', () {
      expect(
        plistStringValue(infoPlist, 'NSMicrophoneUsageDescription'),
        isNotEmpty,
      );
      expect(
        plistStringValue(infoPlist, 'NSSpeechRecognitionUsageDescription'),
        isNotEmpty,
      );
    });
  });

  group('permission_handler iOS build settings', () {
    test('compiles the microphone permission into the pod', () {
      final postInstall = postInstallBlock(podfile);

      expect(
        postInstall,
        isNotEmpty,
        reason: 'ios/Podfile lost its post_install block, so no permission '
            'macro is injected and every Permission.* is compiled out.',
      );
      expect(
        postInstall,
        contains('PERMISSION_MICROPHONE=1'),
        reason: 'permission_handler_apple defaults PERMISSION_MICROPHONE to 0 '
            '(PermissionHandlerEnums.h). With it off, '
            'Permission.microphone.status is always denied and request() '
            'always permanentlyDenied without a system prompt, which blocks '
            'voice capture on iOS entirely. Add the macro to the Podfile '
            'post_install block and run `pod install`.',
      );
    });
  });

  test('speech_to_text is actually installed for iOS', () {
    // The pubspec could declare the plugin while a stale Podfile.lock/
    // Podfile make the iOS build link something else.
    expect(podfileLock, contains('speech_to_text ('));

    final iosPodfile = podfileLock.contains('speech_to_text (from');
    expect(iosPodfile, isTrue);
  });
}
