import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/settings/presentation/widgets/envelope_mode_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(
    WidgetTester tester, {
    required bool enabled,
    required ValueChanged<bool> onChanged,
    required VoidCallback onWhatIs,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: EnvelopeModeField(
              enabled: enabled,
              onChanged: onChanged,
              onWhatIs: onWhatIs,
            ),
          ),
        ),
      );

  group('EnvelopeModeField', () {
    testWidgets('the switch reflects `enabled`', (tester) async {
      await pump(tester, enabled: true, onChanged: (_) {}, onWhatIs: () {});

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isTrue);
    });

    testWidgets('the switch reflects `disabled`', (tester) async {
      await pump(tester, enabled: false, onChanged: (_) {}, onWhatIs: () {});

      final switchWidget = tester.widget<Switch>(find.byType(Switch));
      expect(switchWidget.value, isFalse);
    });

    testWidgets('toggling the switch reports the new value, not the old one',
        (tester) async {
      bool? reported;
      await pump(
        tester,
        enabled: false,
        onChanged: (value) => reported = value,
        onWhatIs: () {},
      );

      await tester.tap(find.byType(Switch));
      await tester.pump();

      expect(reported, isTrue);
    });

    testWidgets('tapping "¿Qué es?" calls onWhatIs', (tester) async {
      var whatIsOpened = false;
      await pump(
        tester,
        enabled: false,
        onChanged: (_) {},
        onWhatIs: () => whatIsOpened = true,
      );

      await tester.tap(find.text('¿Qué es?'));
      await tester.pump();

      expect(whatIsOpened, isTrue);
    });
  });
}
