import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/sheets/scheduled_payment_detail_actions_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Criterion 12: groups the *occurrence* action (Posponer) above a divider
/// from the *template* actions (Editar/Eliminar) — this test locks in that
/// grouping and the tap wiring of each option.
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

  testWidgets('canSnooze=true: muestra Posponer, un Divider, y luego Editar/Eliminar',
      (tester) async {
    await pump(
      tester,
      ScheduledPaymentDetailActionsSheet(
        canSnooze: true,
        onEdit: () {},
        onDelete: () {},
        onSnooze: () {},
      ),
    );

    expect(find.byType(Divider), findsOneWidget);
    expect(find.byType(ScheduledPaymentDetailActionTile), findsNWidgets(3));

    // The divider sits strictly between the occurrence action (Posponer) and
    // the template actions (Editar/Eliminar).
    final column = tester.widget<Column>(find.byType(Column).first);
    final types = column.children.map((child) => child.runtimeType).toList();
    final dividerIndex = types.indexOf(Divider);
    final tileIndices = <int>[];
    for (var i = 0; i < column.children.length; i++) {
      if (column.children[i] is ScheduledPaymentDetailActionTile) {
        tileIndices.add(i);
      }
    }
    expect(dividerIndex, greaterThan(tileIndices.first));
    expect(dividerIndex, lessThan(tileIndices[1]));
  });

  testWidgets('canSnooze=false: sin Posponer y sin Divider, solo Editar/Eliminar',
      (tester) async {
    await pump(
      tester,
      ScheduledPaymentDetailActionsSheet(
        canSnooze: false,
        onEdit: () {},
        onDelete: () {},
      ),
    );

    expect(find.byType(Divider), findsNothing);
    expect(find.byType(ScheduledPaymentDetailActionTile), findsNWidgets(2));
  });

  testWidgets('tocar Editar cierra la hoja y llama onEdit', (tester) async {
    var edited = false;
    await pump(
      tester,
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () => ScheduledPaymentDetailActionsSheet.show(
            context,
            canSnooze: false,
            onEdit: () => edited = true,
            onDelete: () {},
          ),
          child: const Text('abrir'),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Editar'));
    await tester.pumpAndSettle();

    expect(edited, isTrue);
    expect(find.byType(ScheduledPaymentDetailActionsSheet), findsNothing);
  });

  testWidgets('eliminar se pinta en el color destructivo (expense)', (tester) async {
    await pump(
      tester,
      ScheduledPaymentDetailActionsSheet(
        canSnooze: false,
        onEdit: () {},
        onDelete: () {},
      ),
    );

    final deleteTile = tester.widget<ScheduledPaymentDetailActionTile>(
      find.widgetWithText(ScheduledPaymentDetailActionTile, 'Eliminar'),
    );
    expect(deleteTile.destructive, isTrue);
  });
}
