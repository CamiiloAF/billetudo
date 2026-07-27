import 'dart:ui';

import 'package:billetudo/core/l10n/app_locale.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('elige es cuando el idioma preferido del dispositivo es es', () {
    expect(
      AppLocale.resolveLanguageCode(
        preferredLocales: [const Locale('es', 'CO')],
      ),
      'es',
    );
  });

  test('elige en cuando el idioma preferido del dispositivo es en', () {
    expect(
      AppLocale.resolveLanguageCode(
        preferredLocales: [const Locale('en', 'US')],
      ),
      'en',
    );
  });

  test(
      'cae a es (no al primero de supportedLocales) cuando ningún idioma '
      'preferido está soportado — HU-06, docs/requirements/05-auth-sync.md '
      'decisión #12', () {
    expect(
      AppLocale.resolveLanguageCode(
        preferredLocales: [const Locale('pt', 'BR'), const Locale('fr', 'FR')],
      ),
      'es',
    );
  });

  test(
      'respeta el orden de preferencia del dispositivo: usa el primero '
      'soportado, no el primero de la lista', () {
    expect(
      AppLocale.resolveLanguageCode(
        preferredLocales: [
          const Locale('pt', 'BR'),
          const Locale('en', 'US'),
          const Locale('es', 'MX'),
        ],
      ),
      'en',
    );
  });

  test('sin argumento, usa PlatformDispatcher.instance.locales por defecto',
      () {
    expect(
      AppLocale.resolveLanguageCode(),
      isA<String>(),
    );
  });
}
