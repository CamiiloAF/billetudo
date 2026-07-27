import 'package:billetudo/core/error/failure.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_detail_state.dart';
import 'package:billetudo/features/accounts/presentation/pages/account_detail_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../account_fixtures.dart';

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

    testWidgets('card, over limit, available view ($suffix)', (tester) async {
      // Same over-limit balance as above, but with cardBalancePrimary set to
      // CardBalanceView.available: the carousel opens on the "Cupo
      // disponible" page, which is the only one that renders OverLimitBadge
      // (BalanceCardHero only sets showOverLimitBadge on the available page).
      final cardAvailableView = buildAccount(
        id: 'card-2',
        name: 'Visa Oro',
        type: AccountType.card,
        last4: '4321',
        creditLimitMinor: 300000000,
        statementDay: 15,
        paymentDueDay: 5,
        cardBalancePrimary: CardBalanceView.available,
      );
      await golden(
        tester,
        readyState(cardAvailableView, balanceMinor: -350000000),
        'card_over_limit_available_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('bank account, no institution ($suffix)', (tester) async {
      // No institution/last4/etc.: AccountInfoSection renders a single
      // "Tipo" row inside InfoCard, which must still stretch full width
      // (regression guard for the shrink-and-center bug fixed via
      // CrossAxisAlignment.stretch in info_card.dart).
      final noInstitution = buildAccount(
        name: 'Efectivo',
        type: AccountType.cash,
      );
      await golden(
        tester,
        readyState(noInstitution, balanceMinor: 450050),
        'no_institution_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('failure ($suffix)', (tester) async {
      // Shares the `AccountsErrorView`/`ErrorState` component fixed
      // 2026-07-20 (docs/dev-runs/bug-fixes-pixel-audit.md follow-up).
      await golden(
        tester,
        const AccountDetailState(
          status: AccountDetailStatus.failure,
          failure: DatabaseFailure('boom'),
        ),
        'failure_$suffix',
        brightness: brightness,
      );
    });
  }
}
