import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/sync/presentation/utils/sync_relative_time.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';

/// El fraseo es SIEMPRE relativo ("hace 3 días"), nunca una fecha absoluta:
/// el punto de la pantalla es que nadie notó que habían pasado tres días, y
/// una fecha obliga al usuario a hacer la resta.
void main() {
  late AppLocalizations es;

  setUpAll(() async {
    es = await AppLocalizations.delegate.load(const Locale('es'));
  });

  group('elapsed (duración desnuda)', () {
    test('menos de un minuto se dice "un momento"', () {
      expect(
        SyncRelativeTime.elapsed(es, const Duration(seconds: 59)),
        'un momento',
      );
    });

    test('minutos: singular y plural', () {
      expect(
        SyncRelativeTime.elapsed(es, const Duration(minutes: 1)),
        '1 minuto',
      );
      expect(
        SyncRelativeTime.elapsed(es, const Duration(minutes: 5)),
        '5 minutos',
      );
    });

    test('a los 60 minutos cambia a horas', () {
      expect(
        SyncRelativeTime.elapsed(es, const Duration(minutes: 59)),
        '59 minutos',
      );
      expect(SyncRelativeTime.elapsed(es, const Duration(hours: 1)), '1 hora');
    });

    test('a las 24 h cambia a días — el mismo umbral que el ámbar', () {
      expect(
        SyncRelativeTime.elapsed(es, const Duration(hours: 23)),
        '23 horas',
      );
      expect(SyncRelativeTime.elapsed(es, const Duration(hours: 24)), '1 día');
      expect(SyncRelativeTime.elapsed(es, const Duration(days: 3)), '3 días');
    });
  });

  group('ago / since (referencia al pasado)', () {
    test('antepone "hace" a la duración', () {
      expect(SyncRelativeTime.ago(es, const Duration(days: 3)), 'hace 3 días');
    });

    test('since calcula contra el now recibido', () {
      final now = DateTime(2026, 7, 28, 12);
      expect(
        SyncRelativeTime.since(
          es,
          now.subtract(const Duration(minutes: 5)),
          now: now,
        ),
        'hace 5 minutos',
      );
    });

    test('un reloj adelantado nunca imprime "hace -2 días"', () {
      final now = DateTime(2026, 7, 28, 12);
      expect(
        SyncRelativeTime.since(es, now.add(const Duration(days: 2)), now: now),
        'hace un momento',
      );
    });

    test('nunca devuelve una fecha absoluta (ni año, ni mes escrito)', () {
      final now = DateTime(2026, 7, 28, 12);
      final rendered = SyncRelativeTime.since(
        es,
        now.subtract(const Duration(days: 3)),
        now: now,
      );
      expect(rendered, isNot(contains('2026')));
      expect(rendered, isNot(contains('julio')));
    });
  });
}
