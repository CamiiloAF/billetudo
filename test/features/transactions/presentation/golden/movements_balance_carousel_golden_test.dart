import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/widgets/movements_balance_card.dart';
import 'package:billetudo/features/transactions/presentation/widgets/movements_balance_carousel.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';

/// In-memory prefs so the carousel renders without touching
/// `shared_preferences`; the collapse flag is seeded per-golden.
class _FakeCarouselPrefs implements BalanceCarouselPreferenceDatasource {
  _FakeCarouselPrefs({required bool collapsed}) : _collapsed = collapsed;

  bool _collapsed;

  @override
  Future<bool> readCollapsed() async => _collapsed;

  @override
  Future<void> writeCollapsed({required bool collapsed}) async =>
      _collapsed = collapsed;
}

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  // A normal account, a bank account and a credit card — the same mix the
  // widget test exercises, so the "card active" golden shows a real
  // `MovementsBalanceCardCredit` (deuda + cupo disponible + barra).
  final nequi = buildAccountWithBalance(
    account: buildAccount(id: 'a1', name: 'Nequi', type: AccountType.other),
    balanceMinor: 124000000,
  );
  final bancolombia = buildAccountWithBalance(
    account:
        buildAccount(id: 'a2', name: 'Bancolombia', type: AccountType.bank),
    balanceMinor: 300000000,
  );
  final visa = buildAccountWithBalance(
    account:
        buildCard(id: 'a3', name: 'Tarjeta Visa', creditLimitMinor: 300000000),
    balanceMinor: -68000000,
  );

  final state = TransactionsListState(
    status: TransactionsListStatus.ready,
    accounts: [nequi, bancolombia, visa],
    filter: TransactionFilter(),
  );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    // Collapsed state (Mejora #2): the compact bar "N cuentas · $total" with a
    // chevron-down. The page goldens force `collapsed:false`, so this bar is
    // otherwise never captured.
    testWidgets('collapsed ($suffix)', (tester) async {
      final cubit = BalanceCarouselCubit(_FakeCarouselPrefs(collapsed: true));
      await cubit.collapse();
      addTearDown(cubit.close);

      await pumpGolden(
        tester,
        BlocProvider<BalanceCarouselCubit>.value(
          value: cubit,
          child: MovementsBalanceCarousel(
            state: state,
            onOpenAccount: (_) {},
          ),
        ),
        brightness: brightness,
      );

      await expectLater(
        find.byType(MovementsBalanceCarouselCollapsed),
        matchesGoldenFile(
          'goldens/movements_balance_carousel_collapsed_$suffix.png',
        ),
      );
    });

    // Expanded with a credit card as the active card: the third card (the
    // Visa) is the current page, so the golden captures the
    // `MovementsBalanceCardCredit` variant (debt `$expense-text`, cupo
    // disponible and the progress bar) with its dot active.
    testWidgets('credit card active ($suffix)', (tester) async {
      final cubit = BalanceCarouselCubit(_FakeCarouselPrefs(collapsed: false))
        ..pageChanged(2);
      addTearDown(cubit.close);

      await pumpGolden(
        tester,
        BlocProvider<BalanceCarouselCubit>.value(
          value: cubit,
          child: MovementsBalanceCarousel(
            state: state,
            onOpenAccount: (_) {},
          ),
        ),
        brightness: brightness,
      );

      // Sanity-check the fixture landed on the credit variant before the
      // pixel compare, so a wrong active page fails loudly instead of quietly
      // baking a normal card into the golden.
      expect(find.byType(MovementsBalanceCardCredit), findsOneWidget);

      await expectLater(
        find.byType(MovementsBalanceCarousel),
        matchesGoldenFile(
          'goldens/movements_balance_carousel_card_active_$suffix.png',
        ),
      );
    });
  }
}
