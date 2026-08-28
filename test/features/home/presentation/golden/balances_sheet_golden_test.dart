import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/balances_sheet.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart' as accounts;

/// "Tu dinero" (criterios 3 y 4): agrupación por moneda, sola-moneda y
/// multi-moneda, con y sin la nota de exclusión.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  AccountWithBalance account({
    required String id,
    required String name,
    required AccountType type,
    required String currency,
    required int balanceMinor,
    int? creditLimitMinor,
  }) =>
      accounts.buildAccountWithBalance(
        account: accounts.buildAccount(
          id: id,
          name: name,
          type: type,
          currency: currency,
          creditLimitMinor: creditLimitMinor,
        ),
        balanceMinor: balanceMinor,
      );

  Future<void> golden(
    WidgetTester tester,
    List<AccountWithBalance> accounts,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => BalancesSheet.show(
              context,
              accounts: accounts,
              onOpenAccountMovements: (_) {},
            ),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/balances_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('balances sheet — una sola moneda, sin exclusión ($suffix)',
        (tester) async {
      await golden(
        tester,
        [
          account(
            id: 'a1',
            name: 'Bancolombia',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 250000000,
          ),
          account(
            id: 'a2',
            name: 'Efectivo',
            type: AccountType.cash,
            currency: 'COP',
            balanceMinor: 5000000,
          ),
        ],
        'single_currency_$suffix',
        brightness: brightness,
      );
    });

    testWidgets(
        'balances sheet — multi-moneda con tarjeta excluida y nota ($suffix)',
        (tester) async {
      await golden(
        tester,
        [
          account(
            id: 'a1',
            name: 'Bancolombia',
            type: AccountType.bank,
            currency: 'COP',
            balanceMinor: 250000000,
          ),
          account(
            id: 'a2',
            name: 'Visa Oro',
            type: AccountType.card,
            currency: 'COP',
            balanceMinor: -80000000,
            creditLimitMinor: 500000000,
          ),
          account(
            id: 'a3',
            name: 'Cuenta en dólares',
            type: AccountType.savings,
            currency: 'USD',
            balanceMinor: 120000,
          ),
        ],
        'multi_currency_with_note_$suffix',
        brightness: brightness,
      );
    });
  }
}
