import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/home/presentation/widgets/balance_mini_card.dart';
import 'package:billetudo/features/home/presentation/widgets/home_balances_strip.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../accounts/account_fixtures.dart' as accounts;
import '../../home_fixtures.dart';

void main() {
  dynamic accountEntry({required String name, required AccountType type}) =>
      accounts.buildAccountWithBalance(
        account: accounts.buildAccount(name: name, type: type),
        balanceMinor: 180000,
      );

  Future<void> pump(
    WidgetTester tester,
    List<dynamic> accounts, {
    VoidCallback? onSeeAll,
    ValueChanged<String>? onOpenAccountMovements,
  }) =>
      tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: HomeBalancesStrip(
              accounts: accounts.cast(),
              onSeeAll: onSeeAll ?? () {},
              onOpenAccountMovements: onOpenAccountMovements,
            ),
          ),
        ),
      );

  testWidgets('renderiza una mini-card por cuenta', (tester) async {
    await pump(tester, [
      buildActiveAccount(id: 'a', balanceMinor: 180000),
      buildActiveAccount(id: 'b', balanceMinor: 2300000),
      buildActiveAccount(id: 'c', balanceMinor: 340000),
    ]);

    expect(find.byType(BalanceMiniCard), findsNWidgets(3));
  });

  testWidgets('muestra el encabezado "Mis cuentas" y el enlace "Ver todas"',
      (tester) async {
    await pump(tester, [buildActiveAccount()]);

    expect(find.text('Mis cuentas'), findsOneWidget);
    expect(find.text('Ver todas'), findsOneWidget);
  });

  testWidgets('tocar "Ver todas" invoca onSeeAll (navega a Cuentas)',
      (tester) async {
    var seen = false;
    await pump(tester, [buildActiveAccount()], onSeeAll: () => seen = true);

    await tester.tap(find.text('Ver todas'));
    expect(seen, isTrue);
  });

  testWidgets(
      'tocar una mini-card invoca onOpenAccountMovements con el id de esa cuenta',
      (tester) async {
    String? opened;
    await pump(
      tester,
      [
        buildActiveAccount(id: 'a', balanceMinor: 180000),
        buildActiveAccount(id: 'b', balanceMinor: 2300000),
      ],
      onOpenAccountMovements: (id) => opened = id,
    );

    await tester.tap(find.byType(BalanceMiniCard).at(1));
    expect(opened, 'b');
  });

  testWidgets('sin onOpenAccountMovements la mini-card no es interactiva',
      (tester) async {
    await pump(tester, [buildActiveAccount(id: 'a')]);

    final miniCard = tester.widget<BalanceMiniCard>(
      find.byType(BalanceMiniCard),
    );
    expect(miniCard.onTap, isNull);
  });

  testWidgets('sin cuentas no renderiza nada (colapsa)', (tester) async {
    await pump(tester, const []);

    expect(find.byType(BalanceMiniCard), findsNothing);
    expect(find.text('Mis cuentas'), findsNothing);
  });

  testWidgets('la mini-card usa el ícono del tipo de cuenta', (tester) async {
    await pump(tester, [
      accountEntry(name: 'Efectivo', type: AccountType.cash),
    ]);

    expect(find.text('Efectivo'), findsOneWidget);
    expect(find.byIcon(LucideIcons.banknote), findsOneWidget);
  });

  testWidgets('un nombre largo se recorta a 1 línea con ellipsis',
      (tester) async {
    await pump(tester, [
      accountEntry(
        name: 'Cuenta de ahorros para la casa en la playa del sur',
        type: AccountType.savings,
      ),
    ]);

    expect(tester.takeException(), isNull);
    final name = tester.widget<Text>(
      find.text('Cuenta de ahorros para la casa en la playa del sur'),
    );
    expect(name.maxLines, 1);
    expect(name.overflow, TextOverflow.ellipsis);
  });
}
