import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'usecase_mocks.dart';

AccountWithBalance _accountWithBalance({
  String id = 'acc-1',
  String name = 'Cuenta 1',
  int sortOrder = 0,
}) {
  final account = Account(
    id: id,
    name: name,
    type: AccountType.bank,
    currency: 'COP',
    initialBalanceMinor: 0,
    archived: false,
    sortOrder: sortOrder,
    createdAt: DateTime(2026),
    updatedAt: DateTime(2026).millisecondsSinceEpoch,
  );
  return AccountWithBalance(
    account: account,
    balance: AccountBalance.fromBalance(account: account, balanceMinor: 0),
  );
}

/// The **secondary** voice trigger (`D6inb` / `E1vEe7`): dictating from an
/// already open form completes what is still untouched and overwrites nothing
/// the user chose by hand (HU-05).
void main() {
  late MockCreateTransaction createTransaction;
  late MockUpdateTransaction updateTransaction;
  late MockWatchTransactionDetail watchTransactionDetail;
  late MockGetTransactionEditImpact getTransactionEditImpact;
  late MockSetTransactionTags setTransactionTags;
  late MockWatchAccounts watchAccounts;

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    createTransaction = MockCreateTransaction();
    updateTransaction = MockUpdateTransaction();
    watchTransactionDetail = MockWatchTransactionDetail();
    getTransactionEditImpact = MockGetTransactionEditImpact();
    setTransactionTags = MockSetTransactionTags();
    watchAccounts = MockWatchAccounts();
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(
        Right(<AccountWithBalance>[
          _accountWithBalance(),
          _accountWithBalance(id: 'acc-2', name: 'Nequi', sortOrder: 1),
        ]),
      ),
    );
  });

  TransactionFormCubit build() => TransactionFormCubit(
        createTransaction,
        updateTransaction,
        watchTransactionDetail,
        getTransactionEditImpact,
        setTransactionTags,
        watchAccounts,
      );

  Future<TransactionFormCubit> loaded() async {
    final cubit = build();
    await cubit.load(null);
    return cubit;
  }

  test('fills every field the user has not touched', () async {
    final cubit = await loaded();

    cubit.completeFromVoice(
      amountMinor: 2000000,
      categoryId: 'cat-food',
      categoryName: 'Alimentación',
      categoryKind: CategoryKind.expense,
      accountId: 'acc-2',
      note: 'almuerzo',
    );

    expect(cubit.state.amountMinor, 2000000);
    expect(cubit.state.categoryId, 'cat-food');
    expect(cubit.state.accountId, 'acc-2');
    expect(cubit.state.note, 'almuerzo');
    await cubit.close();
  });

  test('never overwrites an amount the user already typed', () async {
    final cubit = await loaded();
    cubit.amountDigitPressed(5);

    final typed = cubit.state.amountMinor;
    cubit.completeFromVoice(amountMinor: 2000000);

    expect(cubit.state.amountMinor, typed);
    await cubit.close();
  });

  test('never overwrites an account the user picked', () async {
    final cubit = await loaded();
    cubit.accountSelected('acc-2', 'Nequi');

    cubit.completeFromVoice(amountMinor: 100, accountId: 'acc-1');

    expect(cubit.state.accountId, 'acc-2');
    await cubit.close();
  });

  test('never overwrites a category the user picked', () async {
    final cubit = await loaded();
    cubit.categorySelected('cat-mine', CategoryKind.expense, 'Mía');

    cubit.completeFromVoice(
      amountMinor: 100,
      categoryId: 'cat-food',
      categoryName: 'Alimentación',
      categoryKind: CategoryKind.expense,
    );

    expect(cubit.state.categoryId, 'cat-mine');
    await cubit.close();
  });

  test('an uncertain amount lands with the amount focused and flagged',
      () async {
    final cubit = await loaded();

    cubit.completeFromVoice(amountMinor: 2000000, amountIsUncertain: true);

    expect(cubit.state.amountIsUncertain, isTrue);
    expect(cubit.state.focusedField, TransactionFormFocusedField.amount);
    expect(cubit.state.isKeypadVisible, isTrue);
    await cubit.close();
  });

  test('typing over an uncertain amount clears the flag', () async {
    final cubit = await loaded();
    cubit.completeFromVoice(amountMinor: 2000000, amountIsUncertain: true);

    cubit.amountDigitPressed(3);

    expect(cubit.state.amountIsUncertain, isFalse);
    await cubit.close();
  });

  test('dictating into a form does not restamp it as a voice capture',
      () async {
    final cubit = await loaded();

    cubit.completeFromVoice(amountMinor: 2000000);

    expect(cubit.state.source, TransactionSource.manual);
    await cubit.close();
  });

  test('nothing is written by dictating alone', () async {
    final cubit = await loaded();

    cubit.completeFromVoice(amountMinor: 2000000, note: 'almuerzo');

    verifyNever(() => createTransaction(any()));
    verifyNever(() => updateTransaction(any()));
    await cubit.close();
  });
}
