import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/confirmation_sheet.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payment_view_details_link.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the smallest pieces of the confirmation sheet (item 2/3 of
/// the design pass): the "Acumuladas" strip, the sheet head and the
/// "Ver historial y detalles" link.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  group('ScheduledAccumulatedStrip', () {
    testWidgets('muestra el conteo y el nombre de la plantilla en el texto',
        (tester) async {
      await tester.pumpWidget(
        appWith(
          ScheduledAccumulatedStrip(
            count: 3,
            templateTitle: 'Netflix',
            oldestDate: DateTime(2026, 5),
          ),
        ),
      );

      expect(find.textContaining('3'), findsWidgets);
      expect(find.textContaining('Netflix'), findsOneWidget);
      // The sub-line is the part that says the rest of the backlog stays put.
      expect(find.textContaining('siguen en tu lista'), findsOneWidget);
    });
  });

  group('ScheduledPaymentViewDetailsLink', () {
    testWidgets(
        'muestra la etiqueta de l10n en español ("Ver historial y detalles")',
        (tester) async {
      await tester.pumpWidget(
        appWith(ScheduledPaymentViewDetailsLink(onTap: () {})),
      );

      expect(find.text('Ver historial y detalles'), findsOneWidget);
    });

    testWidgets('tocar la fila llama onTap', (tester) async {
      var taps = 0;
      await tester.pumpWidget(
        appWith(ScheduledPaymentViewDetailsLink(onTap: () => taps++)),
      );

      await tester.tap(find.text('Ver historial y detalles'));
      await tester.pump();

      expect(taps, 1);
    });

    testWidgets('la fila mide 44px de alto (tap target del diseño)',
        (tester) async {
      await tester.pumpWidget(
        appWith(ScheduledPaymentViewDetailsLink(onTap: () {})),
      );

      expect(
        tester.getSize(find.byType(ScheduledPaymentViewDetailsLink)).height,
        44,
      );
    });
  });

  group('ConfirmationSheetHead', () {
    testWidgets(
        'sin categoría (transferencia): título usa "cuenta → cuenta destino"',
        (tester) async {
      await tester.pumpWidget(
        appWith(
          ConfirmationSheetHead(
            isTransfer: true,
            accountName: 'Bancolombia',
            transferAccountName: 'Nequi',
            frequency: ScheduledPaymentFrequency.monthly,
            onEdit: () {},
          ),
        ),
      );

      expect(find.text('Bancolombia → Nequi'), findsOneWidget);
    });

    testWidgets(
        'sin nota: el título es el genérico, nunca la categoría (item 3/19)',
        (tester) async {
      await tester.pumpWidget(
        appWith(
          ConfirmationSheetHead(
            isTransfer: false,
            accountName: 'Bancolombia',
            categoryName: 'Suscripciones',
            frequency: ScheduledPaymentFrequency.monthly,
            onEdit: () {},
          ),
        ),
      );

      // The big title falls back to the generic name, not the category — the
      // category stays in the sub-line ("Suscripciones · cada mes").
      expect(find.text('Pago programado'), findsOneWidget);
      expect(find.text('Suscripciones'), findsNothing);
      expect(find.text('Suscripciones · cada mes'), findsOneWidget);
    });

    testWidgets(
        'con nota: el nombre es la nota y la categoría vive solo en el sub',
        (tester) async {
      await tester.pumpWidget(
        appWith(
          ConfirmationSheetHead(
            isTransfer: false,
            accountName: 'Bancolombia',
            note: 'Netflix',
            categoryName: 'Suscripciones',
            frequency: ScheduledPaymentFrequency.monthly,
            onEdit: () {},
          ),
        ),
      );

      expect(find.text('Netflix'), findsOneWidget);
      expect(find.text('Suscripciones · cada mes'), findsOneWidget);
    });

    testWidgets('tocar el ícono de lápiz llama onEdit', (tester) async {
      var called = false;
      await tester.pumpWidget(
        appWith(
          ConfirmationSheetHead(
            isTransfer: false,
            accountName: 'Bancolombia',
            categoryName: 'Suscripciones',
            frequency: ScheduledPaymentFrequency.monthly,
            onEdit: () => called = true,
          ),
        ),
      );

      await tester.tap(find.byType(IconButton));
      await tester.pump();

      expect(called, isTrue);
    });
  });
}
