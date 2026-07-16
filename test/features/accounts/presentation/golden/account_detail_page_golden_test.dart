import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../account_fixtures.dart';
import 'golden_helpers.dart';

class MockAccountDetailCubit extends MockCubit<AccountDetailState>
    implements AccountDetailCubit {}

void main() {
  late MockAccountDetailCubit cubit;

  final bank = buildAccount(name: 'Bancolombia', last4: '4321');
  final card = buildAccount(
    id: 'card-1',
    name: 'Visa Oro',
    type: AccountType.card,
    last4: '4321',
    creditLimitMinor: 300000000,
    statementDay: 15,
    paymentDueDay: 5,
    cardBalancePrimary: CardBalanceView.debt,
  );

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => cubit = MockAccountDetailCubit());

  AccountDetailState readyState(Account account, {required int balanceMinor}) =>
      AccountDetailState(
        status: AccountDetailStatus.ready,
        entry: buildAccountWithBalance(
          account: account,
          balanceMinor: balanceMinor,
        ),
      );

  Future<void> golden(
    WidgetTester tester,
    AccountDetailState state,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<AccountDetailCubit>.value(
        value: cubit,
        child: AccountDetailPage(onEdit: (_) {}, onAddAccount: () {}),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(AccountDetailPage),
      matchesGoldenFile('goldens/account_detail_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('bank account ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(bank, balanceMinor: 450050),
        'bank_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('card, within limit ($suffix)', (tester) async {
      await golden(
        tester,
        readyState(card, balanceMinor: -45000000),
        'card_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('card, over limit ($suffix)', (tester) async {
      // creditLimitMinor is 300000000 (3M COP): a debt of 3.5M leaves the
      // account 500k over its limit (HU-04's over-limit badge).
      await golden(
        tester,
        readyState(card, balanceMinor: -350000000),
        'card_over_limit_$suffix',
        brightness: brightness,
      );
    });
  }
}
