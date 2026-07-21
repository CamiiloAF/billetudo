import 'package:billetudo/features/accounts/presentation/cubit/archived_accounts_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/archived_accounts_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/archived_accounts_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../account_fixtures.dart';

class MockArchivedAccountsCubit extends MockCubit<ArchivedAccountsState>
    implements ArchivedAccountsCubit {}

void main() {
  late MockArchivedAccountsCubit cubit;

  final entries = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a', name: 'Ahorros viejos', archived: true),
      balanceMinor: 120000,
    ),
    buildAccountWithBalance(
      account: buildCard(
        id: 'b',
        name: 'Tarjeta cancelada',
        creditLimitMinor: 100000000,
      ),
      balanceMinor: 0,
    ),
  ];

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockArchivedAccountsCubit());

  Future<void> golden(
    WidgetTester tester,
    ArchivedAccountsState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<ArchivedAccountsCubit>.value(
        value: cubit,
        child: const ArchivedAccountsPage(),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(ArchivedAccountsPage),
      matchesGoldenFile('goldens/archived_accounts_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('with archived accounts ($suffix)', (tester) async {
      await golden(
        tester,
        ArchivedAccountsState(
          status: ArchivedAccountsStatus.ready,
          accounts: entries,
        ),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty ($suffix)', (tester) async {
      await golden(
        tester,
        const ArchivedAccountsState(status: ArchivedAccountsStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('failure ($suffix)', (tester) async {
      // Shares the `AccountsErrorView`/`ErrorState` component fixed
      // 2026-07-20 (docs/dev-runs/bug-fixes-pixel-audit.md follow-up).
      await golden(
        tester,
        const ArchivedAccountsState(status: ArchivedAccountsStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
