import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/core/widgets/empty_state.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/home/presentation/widgets/balance_mini_card.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/balances_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../accounts/account_fixtures.dart' as accounts;
import '../pump_widget.dart';

/// "Tu dinero" (criterios 3 y 4): agrupación estricta por moneda, total que
/// excluye card/investment, chip de conteo, nota condicional, y el tap de
/// fila que navega a Movimientos — nunca a un detalle de cuenta.
void main() {
  AccountWithBalance account({
    required String id,
    required AccountType type,
    required String currency,
    required int balanceMinor,
    int? creditLimitMinor,
  }) =>
      accounts.buildAccountWithBalance(
        account: accounts.buildAccount(
          id: id,
          type: type,
          currency: currency,
          creditLimitMinor: creditLimitMinor,
        ),
        balanceMinor: balanceMinor,
      );

  Widget sheet(
    List<AccountWithBalance> accounts, {
    ValueChanged<String>? onOpenAccountMovements,
  }) =>
      BalancesSheet(
        accounts: accounts,
        onOpenAccountMovements: onOpenAccountMovements,
      );

  testWidgets(
      'criterio 3: cuentas de la misma moneda se agrupan en una sola '
      'sección, nunca se mezclan con otra moneda', (tester) async {
    await tester.pumpHomeWidget(
      sheet([
        account(
            id: 'a1',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 100000),
        account(
            id: 'a2',
            type: AccountType.cash,
            currency: 'COP',
            balanceMinor: 50000),
        account(
            id: 'a3',
            type: AccountType.bank,
            currency: 'USD',
            balanceMinor: 20000),
      ]),
    );

    // COP: 100000 + 50000 = 150000 => $1.500. USD: 20000 => $200,00 (twice:
    // one is the group total, the other the single account's own row).
    expect(find.textContaining('1.500'), findsOneWidget);
    expect(find.textContaining('200'), findsWidgets);
  });

  testWidgets(
      'criterio 3: el total por grupo suma cash+bank+savings+other y '
      'excluye card e investment', (tester) async {
    await tester.pumpHomeWidget(
      sheet([
        account(
            id: 'a1',
            type: AccountType.cash,
            currency: 'COP',
            balanceMinor: 10000),
        account(
            id: 'a2',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 20000),
        account(
            id: 'a3',
            type: AccountType.savings,
            currency: 'COP',
            balanceMinor: 30000),
        account(
            id: 'a4',
            type: AccountType.other,
            currency: 'COP',
            balanceMinor: 40000),
        account(
          id: 'a5',
          type: AccountType.card,
          currency: 'COP',
          balanceMinor: -50000,
          creditLimitMinor: 500000,
        ),
        account(
            id: 'a6',
            type: AccountType.investment,
            currency: 'COP',
            balanceMinor: 999999),
      ]),
    );

    // Included total: 10000+20000+30000+40000 = 100000 => $1.000. The card's
    // -50000 and the investment's 999999 must never enter that sum.
    expect(find.textContaining('1.000'), findsOneWidget);
  });

  testWidgets('criterio 3: chip muted con el conteo de cuentas de la moneda',
      (tester) async {
    await tester.pumpHomeWidget(
      sheet([
        account(
            id: 'a1',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 100000),
        account(
            id: 'a2',
            type: AccountType.cash,
            currency: 'COP',
            balanceMinor: 50000),
      ]),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(BalancesSheet)),
    );

    expect(find.text(l10n.homeBalancesSheetCurrencyCount('COP', 2)),
        findsOneWidget);
  });

  testWidgets(
      'criterio 3: la nota "no incluye tarjetas ni inversiones" solo '
      'aparece cuando el grupo deja algo afuera', (tester) async {
    await tester.pumpHomeWidget(
      sheet([
        account(
            id: 'a1',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 100000),
        account(
          id: 'a2',
          type: AccountType.card,
          currency: 'COP',
          balanceMinor: -20000,
          creditLimitMinor: 500000,
        ),
        account(
            id: 'a3',
            type: AccountType.bank,
            currency: 'USD',
            balanceMinor: 5000),
      ]),
    );
    final localized = AppLocalizations.of(
      tester.element(find.byType(BalancesSheet)),
    );

    // COP has a card excluded from its total -> shows the note.
    // USD has no card/investment -> must not show it a second time for that
    // group (only one note total: COP's).
    expect(
      find.text(localized.homeBalancesSheetExcludesNote),
      findsOneWidget,
    );
  });

  testWidgets(
      'sin ninguna cuenta card/investment: ningún grupo muestra la nota',
      (tester) async {
    await tester.pumpHomeWidget(
      sheet([
        account(
            id: 'a1',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 100000),
        account(
            id: 'a2',
            type: AccountType.bank,
            currency: 'USD',
            balanceMinor: 5000),
      ]),
    );
    final l10n = AppLocalizations.of(
      tester.element(find.byType(BalancesSheet)),
    );

    expect(find.text(l10n.homeBalancesSheetExcludesNote), findsNothing);
  });

  testWidgets(
      'criterio 4: tocar una fila navega a Movimientos filtrados por esa '
      'cuenta (onOpenAccountMovements), no a un detalle', (tester) async {
    String? openedAccountId;
    await tester.pumpHomeWidget(
      sheet(
        [
          account(
              id: 'acc-42',
              type: AccountType.bank,
              currency: 'COP',
              balanceMinor: 100000)
        ],
        onOpenAccountMovements: (id) => openedAccountId = id,
      ),
    );

    await tester.tap(find.byType(BalanceMiniCard));
    await tester.pump();

    expect(openedAccountId, 'acc-42');
  });

  testWidgets(
      'bugfix: tocar una fila cierra la hoja además de navegar (reportado en '
      'dogfooding — la navegación funcionaba pero la hoja se quedaba abierta '
      'detrás)', (tester) async {
    String? openedAccountId;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BalancesSheet.show(
                context,
                accounts: [
                  account(
                    id: 'acc-42',
                    type: AccountType.bank,
                    currency: 'COP',
                    balanceMinor: 100000,
                  ),
                ],
                onOpenAccountMovements: (id) => openedAccountId = id,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(BalanceMiniCard));
    await tester.pumpAndSettle();

    expect(openedAccountId, 'acc-42');
    expect(find.byType(BalancesSheet), findsNothing);
  });

  testWidgets(
      'sin onOpenAccountMovements: la fila no dispara ninguna navegación '
      '(tap seguro, sin excepción)', (tester) async {
    await tester.pumpHomeWidget(
      sheet([
        account(
            id: 'acc-1',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 100000),
      ]),
    );

    await tester.tap(find.byType(BalanceMiniCard));
    await tester.pump();

    expect(tester.takeException(), isNull);
  });

  testWidgets(
      'GH-24: sin ninguna cuenta activa, la hoja muestra el Empty State de '
      'Cuentas (mismo copy) en vez de quedar vacía', (tester) async {
    await tester.pumpHomeWidget(sheet(const []));
    final l10n = AppLocalizations.of(
      tester.element(find.byType(BalancesSheet)),
    );

    expect(find.byType(EmptyState), findsOneWidget);
    expect(find.text(l10n.accountsEmptyMessage), findsOneWidget);
    expect(find.text(l10n.accountsAdd), findsOneWidget);
    expect(find.byType(BalanceMiniCard), findsNothing);
  });

  testWidgets(
      'GH-24: el CTA del Empty State cierra la hoja y luego dispara '
      'onAddAccount, igual que el tap de una fila cierra antes de navegar',
      (tester) async {
    var addAccountTapped = false;
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        locale: const Locale('es'),
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BalancesSheet.show(
                context,
                accounts: const [],
                onAddAccount: () => addAccountTapped = true,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(
      tester.element(find.byType(BalancesSheet)),
    );
    await tester.tap(find.text(l10n.accountsAdd));
    await tester.pumpAndSettle();

    expect(addAccountTapped, isTrue);
    expect(find.byType(BalancesSheet), findsNothing);
  });

  testWidgets('tema oscuro: renderiza sin excepción (HU-11)', (tester) async {
    await tester.pumpHomeWidget(
      sheet([
        account(
            id: 'a1',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 100000),
      ]),
      brightness: Brightness.dark,
    );

    expect(tester.takeException(), isNull);
  });
}
