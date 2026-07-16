import 'package:billetudo/features/accounts/domain/entities/accounts_overview.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/accounts_list_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/accounts_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';
import 'golden_helpers.dart';

class MockAccountsListCubit extends MockCubit<AccountsListState>
    implements AccountsListCubit {}

void main() {
  late MockAccountsListCubit cubit;

  final entries = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a', name: 'Bancolombia'),
      balanceMinor: 450050,
    ),
    buildAccountWithBalance(
      account:
          buildCard(id: 'b', name: 'Visa Oro', creditLimitMinor: 300000000),
      balanceMinor: -45000000,
    ),
  ];

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockAccountsListCubit());

  Future<void> golden(
    WidgetTester tester,
    AccountsListState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<AccountsListCubit>.value(
        value: cubit,
        child: AccountsPage(
          onAddAccount: () {},
          onOpenAccount: (_) {},
          onOpenArchived: () {},
        ),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(AccountsPage),
      matchesGoldenFile('goldens/accounts_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('loading ($suffix)', (tester) async {
      await golden(
        tester,
        const AccountsListState(),
        'loading_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('empty ($suffix)', (tester) async {
      await golden(
        tester,
        const AccountsListState(status: AccountsListStatus.ready),
        'empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('with data ($suffix)', (tester) async {
      await golden(
        tester,
        AccountsListState(
          status: AccountsListStatus.ready,
          accounts: entries,
          overview: AccountsOverview.from(entries),
        ),
        'with_data_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('error ($suffix)', (tester) async {
      await golden(
        tester,
        const AccountsListState(status: AccountsListStatus.failure),
        'error_$suffix',
        brightness: brightness,
      );
    });
  }
}
