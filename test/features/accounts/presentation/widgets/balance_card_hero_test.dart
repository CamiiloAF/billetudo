import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/presentation/widgets/balance_card_hero.dart';
import 'package:billetudo/features/accounts/presentation/widgets/over_limit_badge.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../account_fixtures.dart';
import 'pump_widget.dart';

void main() {
  const creditLimitMinor = 300000000; // 3.000.000

  AccountBalance balanceOf(int balanceMinor) => AccountBalance.fromBalance(
        account: buildCard(creditLimitMinor: creditLimitMinor),
        balanceMinor: balanceMinor,
      );

  Widget buildHero({
    required int balanceMinor,
    CardBalanceView view = CardBalanceView.available,
    ValueChanged<CardBalanceView>? onViewChanged,
  }) =>
      BalanceCardHero(
        balance: balanceOf(balanceMinor),
        currency: 'COP',
        creditLimitMinor: creditLimitMinor,
        view: view,
        onViewChanged: onViewChanged,
      );

  testWidgets('abre en la página que dice la preferencia guardada',
      (tester) async {
    await tester.pumpAppWidget(
      buildHero(balanceMinor: -45000000, view: CardBalanceView.debt),
    );

    // `debt` es la segunda página del carrusel.
    expect(find.text('Deuda actual'), findsOneWidget);
  });

  testWidgets('el swipe cambia de página y avisa del cambio de preferencia',
      (tester) async {
    final views = <CardBalanceView>[];
    await tester.pumpAppWidget(
      buildHero(balanceMinor: -45000000, onViewChanged: views.add),
    );

    expect(find.text('Cupo disponible'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.text('Deuda actual'), findsOneWidget);
    expect(views, [CardBalanceView.debt]);
  });

  testWidgets('los dos dots existen y anuncian la página activa',
      (tester) async {
    await tester.pumpAppWidget(buildHero(balanceMinor: -45000000));

    expect(find.bySemanticsLabel('Página 1 de 2'), findsOneWidget);

    await tester.drag(find.byType(PageView), const Offset(-400, 0));
    await tester.pumpAndSettle();

    expect(find.bySemanticsLabel('Página 2 de 2'), findsOneWidget);
  });

  testWidgets('sin sobrecupo, el caption dice cuánto se usó del cupo',
      (tester) async {
    await tester.pumpAppWidget(buildHero(balanceMinor: -45000000));

    expect(find.textContaining('de'), findsWidgets);
    expect(find.byType(OverLimitBadge), findsNothing);
  });

  group('sobrecupo (qhp7k)', () {
    testWidgets('el cupo disponible se muestra en 0 con el badge Sobrecupo',
        (tester) async {
      // Deuda 3.150.000 sobre cupo de 3.000.000.
      await tester.pumpAppWidget(buildHero(balanceMinor: -315000000));

      expect(find.text('Cupo disponible'), findsOneWidget);
      expect(find.byType(OverLimitBadge), findsOneWidget);
      expect(find.text('Sobrecupo'), findsOneWidget);
      // El caption dice exactamente en cuánto se excedió.
      expect(find.textContaining('Excedido en'), findsOneWidget);
      expect(find.textContaining('150.000'), findsOneWidget);
    });

    testWidgets('el badge vive en la página del cupo, no en la de la deuda',
        (tester) async {
      await tester.pumpAppWidget(buildHero(balanceMinor: -315000000));

      await tester.drag(find.byType(PageView), const Offset(-400, 0));
      await tester.pumpAndSettle();

      expect(find.text('Deuda actual'), findsOneWidget);
      // El badge matiza el "$0 disponible"; junto a la deuda sería ruido.
      expect(find.byType(OverLimitBadge), findsNothing);
    });
  });
}
