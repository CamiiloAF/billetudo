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
      TransactionSource.recurring: 'Recurrente',
    };

    for (final entry in labelBySource.entries) {
      testWidgets('muestra "${entry.value}" para source ${entry.key.name}',
          (tester) async {
        await pumpBody(
          tester,
          TransactionWithDetails(
            transaction: buildTransaction(source: entry.key),
            accountName: 'Efectivo',
          ),
        );

        expect(
          find.text('Registrado como ${entry.value}'),
          findsOneWidget,
        );
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

    expect(find.textContaining('Efectivo'), findsWidgets);
    expect(find.textContaining('Comida'), findsWidgets);
    expect(find.textContaining('Almuerzo con el equipo'), findsWidgets);
    expect(find.textContaining('viaje'), findsWidgets);
  });
}
