import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/settings/presentation/widgets/sheets/envelope_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool? result;

  Future<void> pump(WidgetTester tester, {bool envelopeEnabled = false}) {
    result = null;
    return tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () async => result = await EnvelopeInfoSheet.show(
                context,
                envelopeEnabled: envelopeEnabled,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
  }

  group('EnvelopeInfoSheet', () {
    testWidgets('shows the title, plain-language body and no jargon',
        (tester) async {
      await pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(EnvelopeInfoSheet));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.envelopeInfoTitle), findsOneWidget);
      expect(find.text(l10n.envelopeInfoBody), findsOneWidget);
      expect(find.text(l10n.envelopeInfoBulletJobs), findsOneWidget);
      expect(find.text(l10n.envelopeInfoBulletZero), findsOneWidget);
      expect(find.text(l10n.envelopeInfoReassure), findsOneWidget);
      expect(find.text('base-cero'), findsNothing);
      expect(find.text('YNAB'), findsNothing);
    });

    testWidgets('offers to turn the mode on when it is off', (tester) async {
      await pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(EnvelopeInfoSheet));
      final l10n = AppLocalizations.of(context);

      await tester.tap(find.text(l10n.envelopeInfoActivate));
      await tester.pumpAndSettle();

      expect(result, isTrue);
    });

    testWidgets('hides the activation call to action when already on',
        (tester) async {
      await pump(tester, envelopeEnabled: true);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(EnvelopeInfoSheet));
      final l10n = AppLocalizations.of(context);

      expect(find.text(l10n.envelopeInfoActivate), findsNothing);
      expect(find.text(l10n.envelopeInfoGotIt), findsOneWidget);
    });

    testWidgets('tapping the "got it" button closes the sheet', (tester) async {
      await pump(tester);
      await tester.tap(find.text('open'));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(EnvelopeInfoSheet));
      final l10n = AppLocalizations.of(context);
      expect(find.byType(EnvelopeInfoSheet), findsOneWidget);

      await tester.tap(find.text(l10n.envelopeInfoGotIt));
      await tester.pumpAndSettle();

      expect(find.byType(EnvelopeInfoSheet), findsNothing);
    });
  });
}
