import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/accounts/domain/usecases/create_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/get_account_number.dart';
import 'package:billetudo/features/accounts/domain/usecases/update_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_account_detail.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_cubit.dart';
import 'package:billetudo/features/accounts/presentation/cubit/account_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateAccount extends Mock implements CreateAccount {}

class MockUpdateAccount extends Mock implements UpdateAccount {}

class MockWatchAccountDetail extends Mock implements WatchAccountDetail {}

class MockGetAccountNumber extends Mock implements GetAccountNumber {}

/// Picking another currency re-renders every money field of the draft with the
/// new precision. It is never an FX conversion — the figure stays the user's,
/// only its decimals are re-cut, so nothing keeps reading `1.234,56` under a
/// COP that has no cents.
void main() {
  AccountFormCubit build() => AccountFormCubit(
        MockCreateAccount(),
        MockUpdateAccount(),
        MockWatchAccountDetail(),
        MockGetAccountNumber(),
        const MoneyFormatter(),
      );

  blocTest<AccountFormCubit, AccountFormState>(
    'COP to USD gains the decimals on balance and credit limit alike',
    build: build,
    seed: () => const AccountFormState(
      status: AccountFormStatus.ready,
      initialBalanceText: '4.500.000',
      creditLimitText: '2.000.000',
    ),
    act: (cubit) => cubit.currencySelected('USD'),
    verify: (cubit) {
      expect(cubit.state.currency, 'USD');
      expect(cubit.state.initialBalanceText, '4.500.000,00');
      expect(cubit.state.creditLimitText, '2.000.000,00');
    },
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'USD to COP rounds the cents half-up instead of dropping them',
    build: build,
    seed: () => const AccountFormState(
      status: AccountFormStatus.ready,
      currency: 'USD',
      initialBalanceText: '1.234,56',
      creditLimitText: '999,49',
    ),
    act: (cubit) => cubit.currencySelected('COP'),
    verify: (cubit) {
      expect(cubit.state.currency, 'COP');
      expect(cubit.state.initialBalanceText, '1.235');
      expect(cubit.state.creditLimitText, '999');
    },
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'a negative balance keeps its sign through the change',
    build: build,
    seed: () => const AccountFormState(
      status: AccountFormStatus.ready,
      currency: 'USD',
      initialBalanceText: '-1.234,56',
    ),
    act: (cubit) => cubit.currencySelected('COP'),
    verify: (cubit) => expect(cubit.state.initialBalanceText, '-1.235'),
  );

  blocTest<AccountFormCubit, AccountFormState>(
    'empty money fields stay empty, never become a zero',
    build: build,
    seed: () => const AccountFormState(
      status: AccountFormStatus.ready,
      currency: 'USD',
    ),
    act: (cubit) => cubit.currencySelected('COP'),
    verify: (cubit) {
      expect(cubit.state.initialBalanceText, '');
      expect(cubit.state.creditLimitText, '');
    },
  );

  blocTest<AccountFormCubit, AccountFormState>(
    're-picking the same currency emits nothing',
    build: build,
    seed: () => const AccountFormState(
      status: AccountFormStatus.ready,
      currency: 'USD',
      initialBalanceText: '1.234,56',
    ),
    act: (cubit) => cubit.currencySelected('USD'),
    expect: () => <AccountFormState>[],
  );
}
