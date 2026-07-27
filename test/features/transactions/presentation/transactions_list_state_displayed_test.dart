import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../accounts/account_fixtures.dart';

/// Pure unit coverage for the balance-carousel getters on
/// [TransactionsListState] (Mejora #2): which accounts the carousel shows, the
/// combined "Saldo total", and the currency the collapsed bar renders in.
/// These drive both the carousel and the FAB's account preselection, so they
/// are worth pinning down without a widget.
void main() {
  final nequi = buildAccountWithBalance(
    account: buildAccount(id: 'a1', name: 'Nequi', currency: 'COP'),
    balanceMinor: 124000000,
  );
  final bancolombia = buildAccountWithBalance(
    account: buildAccount(id: 'a2', name: 'Bancolombia', currency: 'COP'),
    balanceMinor: 300000000,
  );
  // A card carried as a negative real balance (debt): it must pull the
  // combined total down, never read as a positive.
  final visa = buildAccountWithBalance(
    account: buildCard(id: 'a3', name: 'Visa', creditLimitMinor: 300000000),
    balanceMinor: -680000000,
  );

  TransactionsListState stateWith({Set<String> accountIds = const {}}) =>
      TransactionsListState(
        status: TransactionsListStatus.ready,
        accounts: [nequi, bancolombia, visa],
        filter: TransactionFilter(accountIds: accountIds),
      );

  group('displayedAccounts', () {
    test('sin filtro de cuenta muestra todas, en el orden de la lista', () {
      final displayed = stateWith().displayedAccounts;

      expect(
        displayed.map((e) => e.account.id).toList(),
        ['a1', 'a2', 'a3'],
      );
    });

    test('con filtro reduce al subconjunto, preservando el orden', () {
      // Se pide en orden inverso; el resultado sigue el orden de `accounts`.
      final displayed = stateWith(accountIds: {'a3', 'a1'}).displayedAccounts;

      expect(displayed.map((e) => e.account.id).toList(), ['a1', 'a3']);
    });

    test('un id que no corresponde a ninguna cuenta da lista vacía', () {
      expect(stateWith(accountIds: {'zzz'}).displayedAccounts, isEmpty);
    });
  });

  group('displayedBalanceTotalMinor', () {
    test('suma en centavos, con la deuda de la tarjeta restando', () {
      // 1.240.000 + 3.000.000 - 6.800.000 = -2.560.000 ($) => -256000000 (¢).
      expect(stateWith().displayedBalanceTotalMinor, -256000000);
    });

    test('el total es un entero, nunca un double', () {
      final total = stateWith().displayedBalanceTotalMinor;

      expect(total, isA<int>());
    });

    test('el filtro cambia el total al del subconjunto', () {
      // Solo Bancolombia: 3.000.000.
      expect(
        stateWith(accountIds: {'a2'}).displayedBalanceTotalMinor,
        300000000,
      );
    });

    test('sin cuentas mostradas el total es 0', () {
      expect(stateWith(accountIds: {'zzz'}).displayedBalanceTotalMinor, 0);
    });
  });

  group('displayedCurrency', () {
    test('toma la moneda de la primera cuenta mostrada', () {
      final state = TransactionsListState(
        status: TransactionsListStatus.ready,
        accounts: [
          buildAccountWithBalance(
            account: buildAccount(id: 'usd', currency: 'USD'),
            balanceMinor: 100,
          ),
          bancolombia,
        ],
      );

      expect(state.displayedCurrency, 'USD');
    });

    test('sin cuentas mostradas cae a COP', () {
      expect(stateWith(accountIds: {'zzz'}).displayedCurrency, 'COP');
    });
  });
}
