import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_detail_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../transaction_fixtures.dart';

void main() {
  Future<void> pumpBody(
    WidgetTester tester,
    TransactionWithDetails entry,
  ) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(body: TransactionDetailBody(entry: entry)),
        ),
      );

  group('HU-08 criterion 10: legible label for every TxSource', () {
    final labelBySource = {
      TransactionSource.manual: 'Manual',
      TransactionSource.voice: 'Voz',
      TransactionSource.ocr: 'Foto de recibo',
      TransactionSource.notification: 'Notificación bancaria',
      TransactionSource.imported: 'Importado',
      TransactionSource.scheduled: 'Programado',
    };

    for (final entry in labelBySource.entries) {
      testWidgets('muestra "${entry.value}" para source ${entry.key.name}',
          (tester) async {
        await pumpBody(
          tester,
          TransactionWithDetails(
            transaction: buildTransaction(source: entry.key),
            accountName: 'Efectivo',
            categoryName: 'Comida',
          ),
        );

        expect(find.text('Origen'), findsOneWidget);
        expect(find.text(entry.value), findsOneWidget);
      });
    }
  });

  testWidgets('muestra cuenta, categoría, nota y etiquetas cuando existen',
      (tester) async {
    await pumpBody(
      tester,
      TransactionWithDetails(
        transaction: buildTransaction(note: 'Almuerzo con el equipo'),
        accountName: 'Efectivo',
        categoryName: 'Comida',
        tags: [buildTag()],
      ),
    );

    expect(find.text('Cuenta'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('Categoría'), findsOneWidget);
    expect(find.text('Comida'), findsWidgets);
    expect(find.text('Nota'), findsOneWidget);
    expect(find.text('Almuerzo con el equipo'), findsOneWidget);
    expect(find.text('Etiquetas'), findsOneWidget);
    expect(find.text('viaje'), findsOneWidget);
  });

  testWidgets('sin nota muestra el placeholder "Sin nota"', (tester) async {
    await pumpBody(
      tester,
      TransactionWithDetails(
        transaction: buildTransaction(),
        accountName: 'Efectivo',
        categoryName: 'Comida',
      ),
    );

    expect(find.text('Sin nota'), findsOneWidget);
  });

  testWidgets('sin etiquetas oculta la sección completa', (tester) async {
    await pumpBody(
      tester,
      TransactionWithDetails(
        transaction: buildTransaction(),
        accountName: 'Efectivo',
        categoryName: 'Comida',
      ),
    );

    expect(find.text('Etiquetas'), findsNothing);
  });

  testWidgets('transferencia muestra cuenta origen/destino y no categoría',
      (tester) async {
    await pumpBody(
      tester,
      TransactionWithDetails(
        transaction: buildTransaction(
          type: TransactionType.transfer,
          transferAccountId: 'acc-2',
        ),
        accountName: 'Efectivo',
        transferAccountName: 'Nequi',
      ),
    );

    expect(find.text('Cuenta origen'), findsOneWidget);
    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.text('Cuenta destino'), findsOneWidget);
    expect(find.text('Nequi'), findsOneWidget);
    expect(find.text('Categoría'), findsNothing);
    expect(find.text('Transferencia'), findsOneWidget);
  });
}
