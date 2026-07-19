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

      final text = tester.widget<Text>(find.byType(Text));
      expect(text.data, contains('3'));
      expect(text.data, contains('Netflix'));
    });
  });

  group('ConfirmationSheetHead', () {
    testWidgets('sin categoría (transferencia): título usa "cuenta → cuenta destino"',
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

    testWidgets('con categoría: el título es la categoría, no la cuenta',
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
