import 'package:billetudo/features/accounts/presentation/widgets/account_number_row.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'pump_widget.dart';

void main() {
  final eye = find.byIcon(LucideIcons.eye);
  final eyeOff = find.byIcon(LucideIcons.eyeOff);
  final copy = find.byIcon(LucideIcons.copy);

  group('cuenta normal', () {
    testWidgets('arranca enmascarada: muestra last4, nunca el número entero',
        (tester) async {
      await tester.pumpAppWidget(
        const AccountNumberRow(last4: '4321', isCard: false),
      );

      expect(find.text('••••••• 4321'), findsOneWidget);
      expect(find.textContaining('1234567890'), findsNothing);
      expect(eye, findsOneWidget);
      expect(copy, findsOneWidget);
    });

    testWidgets('con el número revelado lo muestra y ofrece ocultarlo',
        (tester) async {
      await tester.pumpAppWidget(
        const AccountNumberRow(
          last4: '4321',
          isCard: false,
          revealedNumber: '1234567890',
        ),
      );

      expect(find.text('1234567890'), findsOneWidget);
      expect(find.text('••••••• 4321'), findsNothing);
      expect(eyeOff, findsOneWidget);
      expect(eye, findsNothing);
    });

    testWidgets('el ojo y el botón de copiar avisan a quien los escucha',
        (tester) async {
      var revealed = false;
      var copied = false;
      await tester.pumpAppWidget(
        AccountNumberRow(
          last4: '4321',
          isCard: false,
          onReveal: () => revealed = true,
          onCopy: () => copied = true,
        ),
      );

      await tester.tap(eye);
      await tester.tap(copy);
      expect(revealed, isTrue);
      expect(copied, isTrue);
    });
  });

  group('tarjeta de crédito (HU-03)', () {
    testWidgets(
        'no hay ojo ni copiar: de una tarjeta solo se guardan los last4',
        (tester) async {
      await tester.pumpAppWidget(
        const AccountNumberRow(last4: '4321', isCard: true),
      );

      expect(find.text('••••••• 4321'), findsOneWidget);
      // La asimetría es deliberada: no hay PAN guardado que revelar o copiar,
      // y ofrecer los botones prometería lo contrario.
      expect(eye, findsNothing);
      expect(eyeOff, findsNothing);
      expect(copy, findsNothing);
      expect(find.byType(IconButton), findsNothing);
    });
  });
}
