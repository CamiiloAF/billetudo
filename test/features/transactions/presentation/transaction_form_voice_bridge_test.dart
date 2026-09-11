import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../transaction_fixtures.dart';
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

/// The puente from Captura por voz (`17-captura-voz.md`, HU-01/HU-05): the
/// voice never writes a transaction, it only prefills this form.
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
        confirmPendingCapture,
        getCategory,
      );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'pre-llena monto, tipo, categoría, fecha y nota, y marca el origen voz',
    build: build,
    act: (cubit) => cubit.loadFromVoice(
      amountMinor: 2000000,
      type: TransactionType.expense,
      accountId: 'acc-2',
      categoryId: 'cat-food',
      categoryName: 'Alimentación',
      categoryKind: CategoryKind.expense,
      date: DateTime(2026, 9, 8),
      note: 'almuerzo',
    ),
    verify: (cubit) {
      final state = cubit.state;
      expect(state.status, TransactionFormStatus.ready);
      expect(state.amountMinor, 2000000);
      expect(state.type, TransactionType.expense);
      expect(state.categoryId, 'cat-food');
      expect(state.categoryKind, CategoryKind.expense);
      expect(state.date, DateTime(2026, 9, 8));
      expect(state.note, 'almuerzo');
      expect(state.source, TransactionSource.voice);
      // La cuenta se resuelve por el mismo camino que el formulario manual,
      // así que llega con su nombre para el chip.
      expect(state.accountId, 'acc-2');
      expect(state.accountName, 'Nequi');
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'un parseo parcial (solo monto) abre el formulario igual',
    build: build,
    act: (cubit) => cubit.loadFromVoice(amountMinor: 350000),
    verify: (cubit) {
      expect(cubit.state.status, TransactionFormStatus.ready);
      expect(cubit.state.amountMinor, 350000);
      expect(cubit.state.categoryId, isNull);
      expect(cubit.state.source, TransactionSource.voice);
      expect(cubit.state.accountId, 'acc-1', reason: 'cuenta por defecto');
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'cero campos entendidos también abre el formulario, con la nota',
    build: build,
    act: (cubit) => cubit.loadFromVoice(note: 'bla bla bla'),
    verify: (cubit) {
      expect(cubit.state.status, TransactionFormStatus.ready);
      expect(cubit.state.note, 'bla bla bla');
      expect(cubit.state.amountMinor, 0);
      expect(cubit.state.source, TransactionSource.voice);
      expect(
        cubit.state.focusedField,
        TransactionFormFocusedField.amount,
        reason: 'el foco entra en el primer obligatorio vacío',
      );
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'un monto inferido por heurística queda marcado y enfocado',
    build: build,
    act: (cubit) => cubit.loadFromVoice(
      amountMinor: 2000000,
      amountIsUncertain: true,
    ),
    verify: (cubit) {
      expect(cubit.state.amountIsUncertain, isTrue);
      expect(cubit.state.focusedField, TransactionFormFocusedField.amount);
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'un monto confiable no reclama la atención del usuario',
    build: build,
    act: (cubit) => cubit.loadFromVoice(amountMinor: 2000000),
    verify: (cubit) {
      expect(cubit.state.amountIsUncertain, isFalse);
      expect(cubit.state.focusedField, TransactionFormFocusedField.none);
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'editar el monto confirma el valor y le quita la marca',
    build: build,
    act: (cubit) async {
      await cubit.loadFromVoice(amountMinor: 2000000, amountIsUncertain: true);
      cubit.amountDigitPressed(5);
    },
    verify: (cubit) {
      expect(cubit.state.amountIsUncertain, isFalse);
      expect(cubit.state.source, TransactionSource.voice);
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'editar campos pre-llenados no cambia el origen: se guarda como voz',
    setUp: () {
      when(() => createTransaction(any())).thenAnswer(
        (_) async => Right(buildTransaction()),
      );
      when(() => setTransactionTags(any(), any()))
          .thenAnswer((_) async => const Right(unit));
    },
    build: build,
    act: (cubit) async {
      await cubit.loadFromVoice(
        amountMinor: 2000000,
        type: TransactionType.expense,
        categoryId: 'cat-food',
        categoryKind: CategoryKind.expense,
        categoryName: 'Alimentación',
        note: 'almuerzo',
      );
      cubit
        ..categorySelected('cat-transport', CategoryKind.expense, 'Transporte')
        ..noteChanged('corregido a mano');
      await cubit.submit();
    },
    verify: (cubit) {
      final captured = verify(() => createTransaction(captureAny()))
          .captured
          .single as TransactionDraft;
      expect(captured.source, TransactionSource.voice);
      expect(captured.categoryId, 'cat-transport');
      expect(captured.note, 'corregido a mano');
      expect(captured.amountMinor, 2000000);
    },
  );

  blocTest<TransactionFormCubit, TransactionFormState>(
    'descartar el flujo no escribe nada',
    build: build,
    act: (cubit) => cubit.loadFromVoice(amountMinor: 2000000),
    verify: (_) => verifyNever(() => createTransaction(any())),
  );
}
