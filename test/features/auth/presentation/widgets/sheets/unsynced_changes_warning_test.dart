import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/l10n/gen/app_localizations_en.dart';
import 'package:billetudo/core/l10n/gen/app_localizations_es.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/unsynced_changes_warning.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../pump_widget.dart';

/// El aviso de cambios sin subir (HU-06) y, sobre todo, su plural: es ICU
/// sobre la frase entera, no sobre el sustantivo, porque la concordancia en
/// español alcanza cinco palabras (sigue/siguen, guardado/guardados,
/// ese/esos cambio(s), quedará/quedarán).
void main() {
  final AppLocalizations es = AppLocalizationsEs();
  final AppLocalizations en = AppLocalizationsEn();

  group('plural ICU (es)', () {
    test('N=1 pone las cinco palabras en singular', () {
      final body = es.authSignOutUnsyncedBody(1);

      expect(body, contains('1 cambio '));
      expect(body, contains('sigue guardado'));
      expect(body, contains('ese cambio'));
      expect(body, contains('no quedará en la nube'));

      // Ninguna forma plural puede colarse en la misma frase.
      expect(body, isNot(contains('siguen')));
      expect(body, isNot(contains('guardados')));
      expect(body, isNot(contains('esos')));
      expect(body, isNot(contains('quedarán')));
    });

    test('N=2 pone las cinco palabras en plural', () {
      final body = es.authSignOutUnsyncedBody(2);

      expect(body, contains('2 cambios '));
      expect(body, contains('siguen guardados'));
      expect(body, contains('esos cambios'));
      expect(body, contains('no quedarán en la nube'));
    });

    test('N=128 usa la misma rama plural con el número real', () {
      final body = es.authSignOutUnsyncedBody(128);

      expect(body, contains('128 cambios '));
      expect(body, contains('siguen guardados'));
      expect(body, contains('esos cambios'));
      expect(body, contains('quedarán'));
      expect(body, isNot(contains('1 cambio sigue')));
    });
  });

  group('plural ICU (en)', () {
    test('N=1 en singular, N=3 en plural', () {
      expect(en.authSignOutUnsyncedBody(1), contains('1 change is still'));
      expect(en.authSignOutUnsyncedBody(1), contains("that change won't"));
      expect(en.authSignOutUnsyncedBody(3), contains('3 changes are still'));
      expect(en.authSignOutUnsyncedBody(3), contains("those changes won't"));
    });
  });

  group('render', () {
    testWidgets('muestra título, cuerpo y el ícono `cloud-off`',
        (tester) async {
      await tester.pumpAuthWidget(
        UnsyncedChangesWarning(
          title: es.authSignOutUnsyncedTitle,
          body: es.authSignOutUnsyncedBody(2),
        ),
      );

      expect(find.text(es.authSignOutUnsyncedTitle), findsOneWidget);
      expect(find.text(es.authSignOutUnsyncedBody(2)), findsOneWidget);
      expect(find.byIcon(LucideIcons.cloudOff), findsOneWidget);
    });

    testWidgets(
        'el conteo se muestra agrupado en un total, nunca desglosado por tipo',
        (tester) async {
      await tester.pumpAuthWidget(
        UnsyncedChangesWarning(
          title: es.authSignOutUnsyncedTitle,
          body: es.authSignOutUnsyncedBody(5),
        ),
      );

      expect(find.textContaining('5 cambios'), findsOneWidget);
      expect(find.textContaining('movimientos'), findsNothing);
      expect(find.textContaining('presupuestos'), findsNothing);
    });
  });
}
