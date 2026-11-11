import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/features/capture/presentation/utils/capture_presentation.dart';
import 'package:clock/clock.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';

/// The two "última captura" footers of HU-09 print the day relative and
/// lower-case after the colon ("Última captura: hoy, 9:19 a. m."), and follow
/// the build's locale instead of pinning `es_CO`. The capture cards keep the
/// capitalised default so their committed goldens do not move.
void main() {
  late AppLocalizations es;
  late AppLocalizations en;

  final DateTime now = DateTime(2026, 8, 7, 12);
  final DateTime todayAt = DateTime(2026, 8, 7, 9, 19);
  // intl's es_CO pattern joins "a. m." with a narrow no-break space.
  const String esTime = '9:19 a.\u202Fm.';

  setUpAll(() async {
    await initializeDateFormatting('es_CO');
    await initializeDateFormatting('en');
    es = await AppLocalizations.delegate.load(const Locale('es'));
    en = await AppLocalizations.delegate.load(const Locale('en'));
  });

  group('captureWhenLabel', () {
    test('keeps the card form by default: capitalised day, es_CO', () {
      withClock(Clock.fixed(now), () {
        expect(captureWhenLabel(es, todayAt), 'Hoy, $esTime');
      });
    });

    test('lower-cases only the relative day and follows the locale', () {
      withClock(Clock.fixed(now), () {
        expect(
          captureWhenLabel(es, todayAt, lowercaseRelativeDay: true),
          'hoy, $esTime',
        );
        expect(
          captureWhenLabel(
            en,
            todayAt,
            localeName: 'en',
            lowercaseRelativeDay: true,
          ),
          'today, 9:19 AM',
        );
      });
    });

    test('leaves a calendar day untouched when asked to lower-case', () {
      withClock(Clock.fixed(now), () {
        final DateTime calendarDay = DateTime(2026, 7, 21, 9, 19);
        expect(
          captureWhenLabel(es, calendarDay, lowercaseRelativeDay: true),
          captureWhenLabel(es, calendarDay),
        );
        expect(captureWhenLabel(es, calendarDay), '21 de julio, $esTime');
      });
    });
  });

  group('captureRelativeDayLabel', () {
    test('returns only the lower-case relative day, following the locale', () {
      withClock(Clock.fixed(now), () {
        expect(
          captureRelativeDayLabel(es, todayAt, localeName: 'es_CO'),
          'hoy',
        );
        expect(
          captureRelativeDayLabel(
            es,
            DateTime(2026, 8, 6, 9, 19),
            localeName: 'es_CO',
          ),
          'ayer',
        );
        expect(
          captureRelativeDayLabel(en, todayAt, localeName: 'en'),
          'today',
        );
      });
    });

    test('keeps the calendar day when it is not today or yesterday', () {
      withClock(Clock.fixed(now), () {
        expect(
          captureRelativeDayLabel(
            es,
            DateTime(2026, 7, 21, 9, 19),
            localeName: 'es_CO',
          ),
          '21 de julio',
        );
      });
    });
  });

  group('capture background footers', () {
    test('print the lower-case relative day in Spanish', () {
      withClock(Clock.fixed(now), () {
        expect(
          captureBackgroundLastCaptureLabel(es, todayAt, localeName: 'es_CO'),
          'Última captura: hoy, $esTime',
        );
        expect(
          captureBackgroundSheetFooterLabel(es, todayAt, localeName: 'es_CO'),
          'Última captura: hoy, $esTime Si algo no llega, registralo a '
          'mano.',
        );
      });
    });

    test('follow the build locale in English', () {
      withClock(Clock.fixed(now), () {
        expect(
          captureBackgroundLastCaptureLabel(en, todayAt, localeName: 'en'),
          'Last capture: today, 9:19 AM',
        );
      });
    });
  });
}
