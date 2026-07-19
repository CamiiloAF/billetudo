import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/confirmation_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Widget tests for the two smallest new pieces of the confirmation sheet
/// (item 2/3 of the design pass): the "Acumuladas" strip and the sheet head.
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

    testWidgets('sin nota: el título cae a la categoría, no a la cuenta',
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

      expect(find.text('Suscripciones'), findsOneWidget);
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
