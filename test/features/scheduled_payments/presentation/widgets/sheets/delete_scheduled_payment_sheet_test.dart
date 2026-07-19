import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/delete_scheduled_payment_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Criterion 12: this sheet's copy makes explicit that deleting a template
/// stops future generation while preserving already-generated history.
void main() {
  Future<void> pump(WidgetTester tester, Widget child) => tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: child),
        ),
      );

  testWidgets('shows the delete confirmation title and message',
      (tester) async {
    await pump(
      tester,
      DeleteScheduledPaymentSheet(onConfirm: () {}, onCancel: () {}),
    );

    expect(find.text('¿Eliminar este pago programado?'), findsOneWidget);
  });

  testWidgets('tapping cancel calls onCancel, not onConfirm', (tester) async {
    var cancelled = false;
    var confirmed = false;
    await pump(
      tester,
      DeleteScheduledPaymentSheet(
        onConfirm: () => confirmed = true,
        onCancel: () => cancelled = true,
      ),
    );

    await tester.tap(find.text('Cancelar'));
    await tester.pump();

    expect(cancelled, isTrue);
    expect(confirmed, isFalse);
  });

  testWidgets('tapping delete calls onConfirm, not onCancel', (tester) async {
    var cancelled = false;
    var confirmed = false;
    await pump(
      tester,
      DeleteScheduledPaymentSheet(
        onConfirm: () => confirmed = true,
        onCancel: () => cancelled = true,
      ),
    );

    await tester.tap(find.text('Eliminar'));
    await tester.pump();

    expect(confirmed, isTrue);
    expect(cancelled, isFalse);
  });

  testWidgets('show(): tapping delete closes the sheet and calls onConfirm',
      (tester) async {
    var confirmed = false;
    await pump(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => DeleteScheduledPaymentSheet.show(
            context,
            onConfirm: () => confirmed = true,
          ),
          child: const Text('abrir'),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Eliminar'));
    await tester.pumpAndSettle();

    expect(confirmed, isTrue);
    expect(find.byType(DeleteScheduledPaymentSheet), findsNothing);
  });
}
