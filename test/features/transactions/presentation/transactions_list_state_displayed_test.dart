import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../accounts/account_fixtures.dart';

/// Pure unit coverage for [TransactionsListState.displayedAccounts]: which
/// accounts the active account filter narrows to, in the account list's order.
/// It drives the FAB's account preselection, so it is worth pinning down
/// without a widget.
void main() {
  final nequi = buildAccountWithBalance(
    account: buildAccount(id: 'a1', name: 'Nequi', currency: 'COP'),
    balanceMinor: 124000000,
  );
  final bancolombia = buildAccountWithBalance(
    account: buildAccount(id: 'a2', name: 'Bancolombia', currency: 'COP'),
    balanceMinor: 300000000,
  );
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
}
