import 'package:billetudo/core/widgets/sheet_buttons_row.dart';
import 'package:billetudo/features/accounts/presentation/widgets/sheets/cannot_delete_last_account_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

void main() {
  testWidgets('explica el bloqueo sin tono punitivo', (tester) async {
    await tester.pumpAppWidget(const CannotDeleteLastAccountSheet());

    expect(find.text('No se puede eliminar'), findsOneWidget);
    expect(
      find.textContaining('Necesitas al menos una cuenta'),
      findsOneWidget,
    );
    // Es una restricción del sistema, no un acto destructivo: icono neutral.
    expect(find.byIcon(LucideIcons.info), findsOneWidget);
    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
  });

  testWidgets(
      '"Entendido" es el primario y "Agregar cuenta" el secundario: en una hoja '
      'que bloquea, cerrar es la acción dominante', (tester) async {
    await tester.pumpAppWidget(const CannotDeleteLastAccountSheet());

    final row = tester.widget<SheetButtonsRow>(find.byType(SheetButtonsRow));
    expect(row.left, isA<FilledButton>());
    expect(row.right, isA<OutlinedButton>());

    // Y el primario es exactamente el que cierra, no el que navega.
    expect(
      find.descendant(
        of: find.byType(FilledButton),
        matching: find.text('Entendido'),
      ),
      findsOneWidget,
    );
    expect(
      find.descendant(
        of: find.byType(OutlinedButton),
        matching: find.text('Agregar cuenta'),
      ),
      findsOneWidget,
    );
  });
}
