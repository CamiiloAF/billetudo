import 'package:billetudo/core/widgets/sheet_buttons_row.dart';
import 'package:billetudo/features/auth/presentation/widgets/sheets/confirm_sign_out_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../pump_widget.dart';

void main() {
  testWidgets(
      'HU-06: explica que los datos locales quedan intactos y que dejará de '
      'sincronizar, con tono neutral (no destructivo)', (tester) async {
    await tester.pumpAuthWidget(const ConfirmSignOutSheet());

    expect(find.text('Cerrar sesión'), findsWidgets);
    expect(
      find.textContaining('seguirán guardados en este dispositivo'),
      findsOneWidget,
    );
    expect(
      find.textContaining('no se sincronizarán hasta que vuelvas'),
      findsOneWidget,
    );
    // Neutral log-out tone, not the `$expense`/warning tone used by the
    // genuinely destructive delete-account sheet.
    expect(find.byIcon(LucideIcons.logOut), findsWidgets);
    expect(find.byIcon(LucideIcons.triangleAlert), findsNothing);
  });

  testWidgets('cancelar resuelve `show` en false', (tester) async {
    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmSignOutSheet.show(context);
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    expect(result, isFalse);
  });

  testWidgets('confirmar "Cerrar sesión" resuelve `show` en true',
      (tester) async {
    bool? result;
    await tester.pumpAuthWidget(
      Builder(
        builder: (context) => ElevatedButton(
          onPressed: () async {
            result = await ConfirmSignOutSheet.show(context);
          },
          child: const Text('open'),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();

    final row = tester.widget<SheetButtonsRow>(find.byType(SheetButtonsRow));
    expect(row.right, isA<FilledButton>());

    // "Cerrar sesión" appears twice on screen (the sheet's title and its
    // CTA) — only the one inside `SheetButtonsRow` is the button.
    await tester.tap(
      find.descendant(
        of: find.byType(SheetButtonsRow),
        matching: find.text('Cerrar sesión'),
      ),
    );
    await tester.pumpAndSettle();

    expect(result, isTrue);
  });
}
