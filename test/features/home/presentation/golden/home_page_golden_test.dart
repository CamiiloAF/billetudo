import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/home/domain/entities/home_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../home_fixtures.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  late MockHomeCubit cubit;

  final month = DateTime(2026, 7);

  HomeState readyWith(
    List<dynamic> transactions, {
    AuthUser? user,
  }) =>
      HomeState(
        month: month,
        currentMonth: month,
        status: HomeStatus.ready,
        user: user,
        snapshot: HomeSnapshot.from(
          month: month,
          accounts: [buildActiveAccount()],
          transactions: transactions.cast(),
        ),
      );

  setUpAll(() async {
    await initializeDateFormatting();
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockHomeCubit());

  Future<void> golden(
    WidgetTester tester,
    HomeState state,
    String name, {
    required Brightness brightness,
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    whenListen(cubit, const Stream<HomeState>.empty(), initialState: state);
    await pumpGolden(
      tester,
      BlocProvider<HomeCubit>.value(
        value: cubit,
        child: HomePage(
          onAddTransaction: () {},
          onSeeAllTransactions: () {},
          onOpenTransaction: (_) async => null,
          onCreateBudget: () {},
          onOpenAccounts: () {},
          onOpenScheduledPayments: () {},
          onOpenDebts: () {},
          onOpenReports: () {},
        ),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(HomePage),
      matchesGoldenFile('goldens/home_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        HomeState.initial(month),
        'loading_$suffix',
        brightness: brightness,
        // HU-09: the loading state renders an indeterminate spinner nowhere,
        // but the skeleton rows use fixed widths — still avoid settling in
        // case an ancestor introduces an animation later; `pump()` alone is
        // enough since there is nothing indeterminate here today.
      );
    });

    testWidgets('empty (HU-08) ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith(const []),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data, no session ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith([
          buildActivity(id: 'tx-1', categoryName: 'Mercado', amountMinor: 45000),
          buildActivity(
            id: 'tx-2',
            categoryName: 'Transporte',
            amountMinor: 8000,
            date: DateTime(2026, 7, 10),
          ),
          buildActivity(
            id: 'tx-3',
            categoryName: 'Restaurantes',
            amountMinor: 32000,
            date: DateTime(2026, 7, 5),
          ),
          // Income row so the "+" sign (recent_activity_row_test covers it
          // in unit-test isolation, but no golden had captured it yet).
          buildActivity(
            id: 'tx-4',
            categoryName: 'Salario',
            amountMinor: 250000,
            type: TransactionType.income,
            date: DateTime(2026, 7, 1),
          ),
        ]),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data, signed in ($suffix)', (tester) async {
      await golden(
        tester,
        readyWith(
          [
            buildActivity(id: 'tx-1', categoryName: 'Mercado', amountMinor: 45000),
            buildActivity(
              id: 'tx-2',
              categoryName: 'Transporte',
              amountMinor: 8000,
              date: DateTime(2026, 7, 10),
            ),
          ],
          user: const AuthUser(
            id: 'user-1',
            displayName: 'Camila Restrepo',
            provider: AuthProvider.google,
            email: 'camila@example.com',
          ),
        ),
        'with_data_signed_in_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error, local-first (HU-10) ($suffix)', (tester) async {
      // `HomeCubit._recompute` never clears `snapshot` on a failure (see
      // `copyWith`'s `snapshot ?? this.snapshot`), so the reachable failure
      // state is "a later fetch failed after an earlier one already landed" —
      // hero/quick access keep the last good snapshot, only the recent-feed
      // sliver swaps to `HomeFailureView`. A `HomeState` with `snapshot: null`
      // and `status: failure` (the very first load failing) is NOT safely
      // renderable: `HomePage` calls `state.spending!` for any non-loading
      // status, which null-check-crashes on that combination — a real bug,
      // reported separately, not modeled here since a golden can't capture a
      // crash.
      await golden(
        tester,
        readyWith([buildActivity(id: 'tx-1', categoryName: 'Mercado')])
            .copyWith(status: HomeStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
