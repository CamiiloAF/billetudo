import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/presentation/cubit/capture_prefill.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'usecase_mocks.dart';

/// HU-05: dispatching a capture opens the SAME form, pre-filled, and saving
/// goes through `ConfirmPendingCapture` — never a parallel screen with rules
/// of its own, and never `CreateTransaction` on the side.
void main() {
  late MockCreateTransaction createTransaction;
  late MockUpdateTransaction updateTransaction;
  late MockWatchTransactionDetail watchTransactionDetail;
  late MockGetTransactionEditImpact getTransactionEditImpact;
  late MockSetTransactionTags setTransactionTags;
  late MockWatchAccounts watchAccounts;
  late MockConfirmPendingCapture confirmPendingCapture;
  late MockGetCategory getCategory;

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    createTransaction = MockCreateTransaction();
    updateTransaction = MockUpdateTransaction();
    watchTransactionDetail = MockWatchTransactionDetail();
    getTransactionEditImpact = MockGetTransactionEditImpact();
    setTransactionTags = MockSetTransactionTags();
    watchAccounts = MockWatchAccounts();
    confirmPendingCapture = MockConfirmPendingCapture();
    getCategory = MockGetCategory();

    when(() => watchAccounts())
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));
  });

  TransactionFormCubit build() => TransactionFormCubit(
        createTransaction,
        updateTransaction,
        watchTransactionDetail,
        getTransactionEditImpact,
        setTransactionTags,
        watchAccounts,
        confirmPendingCapture,
        getCategory,
      );

  CapturePrefill prefill({String? categoryId}) => CapturePrefill(
        captureId: 'capture-1',
        amountMinor: 5847000,
        currency: 'COP',
        type: TransactionType.expense,
        postedAt: DateTime(2026, 9, 1, 8, 32),
        accountId: 'acc-1',
        note: 'TIENDA D1 SANTA ROSA',
        categoryId: categoryId,
      );

  test('the form opens pre-filled with what the issuer said', () async {
    final cubit = build();
    await cubit.load(null, capture: prefill());

    expect(cubit.state.status, TransactionFormStatus.ready);
    expect(cubit.state.amountMinor, 5847000);
    expect(cubit.state.currency, 'COP');
    expect(cubit.state.type, TransactionType.expense);
    expect(cubit.state.date, DateTime(2026, 9, 1, 8, 32));
    expect(cubit.state.note, 'TIENDA D1 SANTA ROSA');
    expect(cubit.state.accountId, 'acc-1');
    expect(cubit.state.source, TransactionSource.notification);
    await cubit.close();
  });

  test('the suggested category arrives resolved, with its name and kind',
      () async {
    when(() => getCategory('cat-1')).thenAnswer(
      (_) async => Right<Failure, Category>(
        Category(
          id: 'cat-1',
          name: 'Mercado',
          kind: CategoryKind.expense,
          sortOrder: 0,
          createdAt: DateTime(2026),
          updatedAt: 0,
        ),
      ),
    );

    final cubit = build();
    await cubit.load(null, capture: prefill(categoryId: 'cat-1'));

    expect(cubit.state.categoryId, 'cat-1');
    expect(cubit.state.categoryName, 'Mercado');
    expect(cubit.state.categoryKind, CategoryKind.expense);
    await cubit.close();
  });

  test('saving confirms the capture instead of creating a loose movement',
      () async {
    when(
      () => confirmPendingCapture(
        captureId: any(named: 'captureId'),
        draft: any(named: 'draft'),
      ),
    ).thenAnswer(
      (_) async => Right<Failure, Transaction>(
        Transaction(
          id: 'tx-1',
          accountId: 'acc-1',
          amountMinor: 5847000,
          currency: 'COP',
          type: TransactionType.expense,
          date: DateTime(2026, 9, 1, 8, 32),
          source: TransactionSource.notification,
          createdAt: DateTime(2026),
          updatedAt: 0,
        ),
      ),
    );
    when(() => setTransactionTags(any(), any()))
        .thenAnswer((_) async => const Right(unit));
    when(() => getCategory('cat-1')).thenAnswer(
      (_) async => Right<Failure, Category>(
        Category(
          id: 'cat-1',
          name: 'Mercado',
          kind: CategoryKind.expense,
          sortOrder: 0,
          createdAt: DateTime(2026),
          updatedAt: 0,
        ),
      ),
    );

    final cubit = build();
    await cubit.load(null, capture: prefill(categoryId: 'cat-1'));
    await cubit.submit();

    expect(cubit.state.status, TransactionFormStatus.saved);
    final captured = verify(
      () => confirmPendingCapture(
        captureId: captureAny(named: 'captureId'),
        draft: captureAny(named: 'draft'),
      ),
    ).captured;
    expect(captured[0], 'capture-1');
    expect((captured[1] as TransactionDraft).amountMinor, 5847000);
    // The ordinary create/update path must not have been used.
    verifyNever(() => createTransaction(any()));
    verifyNever(() => updateTransaction(any()));
    await cubit.close();
  });

  test('a form opened without a capture still creates normally', () async {
    when(() => createTransaction(any())).thenAnswer(
      (_) async => Right<Failure, Transaction>(
        Transaction(
          id: 'tx-2',
          accountId: 'acc-1',
          amountMinor: 100,
          currency: 'COP',
          type: TransactionType.expense,
          date: DateTime(2026),
          source: TransactionSource.manual,
          createdAt: DateTime(2026),
          updatedAt: 0,
        ),
      ),
    );
    when(() => setTransactionTags(any(), any()))
        .thenAnswer((_) async => const Right(unit));

    final cubit = build();
    await cubit.load(null, capture: prefill());
    // Reloading without a capture must clear the dispatch, not leak it into
    // the next form the same cubit instance drives.
    await cubit.load(null);
    cubit
      ..accountSelected('acc-1', 'Cuenta 1')
      ..amountDigitPressed(1)
      ..categorySelected('cat-1', CategoryKind.expense, 'Mercado');
    await cubit.submit();

    verifyNever(
      () => confirmPendingCapture(
        captureId: any(named: 'captureId'),
        draft: any(named: 'draft'),
      ),
    );
    verify(() => createTransaction(any())).called(1);
    await cubit.close();
  });
}
