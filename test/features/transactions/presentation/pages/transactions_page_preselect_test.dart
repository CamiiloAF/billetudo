import 'package:billetudo/core/preferences/balance_carousel_cubit.dart';
import 'package:billetudo/core/preferences/balance_carousel_preference_datasource.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:billetudo/features/transactions/presentation/pages/transactions_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../categories/presentation/widgets/pump_widget.dart';

class MockTransactionsListCubit extends MockCubit<TransactionsListState>
    implements TransactionsListCubit {}

class _FakeCarouselPrefs implements BalanceCarouselPreferenceDatasource {
  @override
  Future<bool> readCollapsed() async => false;

  @override
  Future<void> writeCollapsed({required bool collapsed}) async {}
}

/// The FAB's account preselection (Mejora #2): the new-movement form opens on
/// the account of the carousel's active card, read from the carousel cubit's
/// remembered page and clamped against the shown accounts. Covers all three
/// filter states plus the shrink-below-current-page clamp.
void main() {
  late MockTransactionsListCubit listCubit;

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Nequi'),
      balanceMinor: 100000,
    ),
    buildAccountWithBalance(
      account: buildAccount(id: 'a2', name: 'Bancolombia'),
      balanceMinor: 200000,
    ),
    buildAccountWithBalance(
      account: buildAccount(id: 'a3', name: 'Efectivo'),
      balanceMinor: 300000,
    ),
  ];

  setUp(() => listCubit = MockTransactionsListCubit());

  Future<String?> pumpAndTapFab(
    WidgetTester tester, {
    required TransactionsListState state,
    required int currentPage,
  }) async {
    when(() => listCubit.state).thenReturn(state);
    String? captured;
    var called = false;
    final carousel = BalanceCarouselCubit(_FakeCarouselPrefs())
      ..pageChanged(currentPage);

    await tester.pumpAppWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<TransactionsListCubit>.value(value: listCubit),
          BlocProvider<BalanceCarouselCubit>.value(value: carousel),
        ],
        child: TransactionsPage(
          onAddTransaction: (id) {
            called = true;
            captured = id;
          },
          onOpenTransaction: (_) async => null,
          onOpenAccount: (_) {},
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.plus));
    await tester.pump();
    expect(called, isTrue, reason: 'el FAB debe invocar onAddTransaction');
    return captured;
  }

  TransactionsListState readyWith({Set<String> accountIds = const {}}) =>
      TransactionsListState(
        status: TransactionsListStatus.ready,
        accounts: accounts,
        filter: TransactionFilter(accountIds: accountIds),
      );

  testWidgets('preselecciona la cuenta de la tarjeta activa (Todas)', (
    tester,
  ) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(),
      currentPage: 1,
    );

    // Página 1 de las tres mostradas -> Bancolombia.
    expect(id, 'a2');
  });

  testWidgets('con una sola cuenta filtrada preselecciona esa', (tester) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(accountIds: {'a3'}),
      currentPage: 0,
    );

    expect(id, 'a3');
  });

  testWidgets(
    'si el set encogió por debajo de la página activa, hace clamp al último',
    (tester) async {
      // La página recordada (5) quedó fuera de rango tras filtrar: se recorta
      // al último índice mostrado en vez de reventar.
      final id = await pumpAndTapFab(
        tester,
        state: readyWith(),
        currentPage: 5,
      );

      expect(id, 'a3');
    },
  );

  testWidgets('sin cuentas mostradas preselecciona null', (tester) async {
    final id = await pumpAndTapFab(
      tester,
      state: readyWith(accountIds: {'zzz'}),
      currentPage: 0,
    );

    expect(id, isNull);
  });
}
