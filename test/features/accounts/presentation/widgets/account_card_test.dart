import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../account_fixtures.dart';
import 'pump_widget.dart';

void main() {
  Color colorOfAmount(WidgetTester tester, String text) =>
      tester.widget<Text>(find.text(text)).style!.color!;

  testWidgets('muestra nombre, tipo y saldo', (tester) async {
    await tester.pumpAppWidget(
      AccountCard(
        entry: buildAccountWithBalance(
          account: buildAccount(name: 'Bancolombia'),
          balanceMinor: 450000,
        ),
      ),
    );

    expect(find.text('Bancolombia'), findsOneWidget);
    expect(find.text('Banco'), findsOneWidget);
    expect(find.textContaining('4.500'), findsOneWidget);
  });

  testWidgets('un saldo positivo NO se pinta de rojo (tono de marca)',
      (tester) async {
    await tester.pumpAppWidget(
      AccountCard(
        entry: buildAccountWithBalance(
          account: buildAccount(),
          balanceMinor: 450000,
        ),
      ),
    );

    final amount = find.textContaining('4.500');
    expect(
      colorOfAmount(tester, tester.widget<Text>(amount).data!),
      AppColors.light.textPrimary,
    );
  });

  testWidgets('un saldo negativo sí se pinta en \$expense: es deuda real',
      (tester) async {
    await tester.pumpAppWidget(
      AccountCard(
        entry: buildAccountWithBalance(
          account: buildCard(creditLimitMinor: 300000000),
          balanceMinor: -45000000,
        ),
      ),
    );

    final amount = find.textContaining('450.000');
    expect(
      colorOfAmount(tester, tester.widget<Text>(amount).data!),
      AppColors.light.expense,
    );
  });

  testWidgets('el icono depende del tipo de cuenta', (tester) async {
    await tester.pumpAppWidget(
      AccountCard(
        entry: buildAccountWithBalance(
          account: buildAccount(type: AccountType.cash),
          balanceMinor: 0,
        ),
      ),
    );

    expect(find.byIcon(LucideIcons.banknote), findsOneWidget);
  });

  testWidgets('un nombre largo no desborda: se recorta', (tester) async {
    await tester.pumpAppWidget(
      AccountCard(
        entry: buildAccountWithBalance(
          account: buildAccount(
            name: 'Cuenta de ahorros programado para la casa en la playa',
          ),
          balanceMinor: 100,
        ),
      ),
    );

    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(
      find.text('Cuenta de ahorros programado para la casa en la playa'),
    );
    expect(name.overflow, TextOverflow.ellipsis);
    expect(name.maxLines, 1);
  });

  testWidgets('al tocarla, abre la cuenta', (tester) async {
    var tapped = false;
    await tester.pumpAppWidget(
      AccountCard(
        entry: buildAccountWithBalance(
          account: buildAccount(),
          balanceMinor: 0,
        ),
        onTap: () => tapped = true,
      ),
    );

    await tester.tap(find.byType(AccountCard));
    expect(tapped, isTrue);
  });
}
