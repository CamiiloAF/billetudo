import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/settings/presentation/widgets/sheets/envelope_info_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pump(WidgetTester tester) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => EnvelopeInfoSheet.show(context),
                child: const Text('open'),
              ),
            ),
          ),
        ),
      );

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
      expect(find.text('base-cero'), findsNothing);
      expect(find.text('YNAB'), findsNothing);
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
