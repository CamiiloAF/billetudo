import 'dart:ui';

import 'package:billetudo/features/capture/presentation/utils/voice_locale_id.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('borrows the device region when both speak the same language', () {
    expect(
      VoiceLocaleId.resolve(const Locale('es'), const Locale('es', 'CO')),
      'es_CO',
    );
  });

  test('falls back to a neutral region when the languages disagree', () {
    // The app's language always wins: transcribing Spanish with an English
    // model produces confident garbage (HU-08).
    expect(
      VoiceLocaleId.resolve(const Locale('es'), const Locale('en', 'US')),
      'es_ES',
    );
    expect(
      VoiceLocaleId.resolve(const Locale('en'), const Locale('es', 'CO')),
      'en_US',
    );
  });

  test('an explicit app region wins over the device', () {
    expect(
      VoiceLocaleId.resolve(
        const Locale('es', 'MX'),
        const Locale('es', 'CO'),
      ),
      'es_MX',
    );
  });

  test('a device locale with no region still yields a usable id', () {
    expect(
      VoiceLocaleId.resolve(const Locale('es'), const Locale('es')),
      'es_ES',
    );
  });
}
