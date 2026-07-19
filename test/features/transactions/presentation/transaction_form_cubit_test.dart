import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_edit_impact.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
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
    // No accounts by default, so `load(null)` never auto-preselects one and
    // the existing "no account picked" scenarios stay meaningful — tests
    // that care about the preselection stub their own account list.
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
      );

  group('teclado numérico anclado (criterio 11)', () {
    blocTest<TransactionFormCubit, TransactionFormState>(
      'el formulario abre con el Monto enfocado y el teclado visible',
      build: build,
      act: (cubit) => cubit.load(null),
      verify: (cubit) {
        expect(cubit.state.focusedField, TransactionFormFocusedField.amount);
        expect(cubit.state.isKeypadVisible, isTrue);
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'el foco en Monto muestra el teclado y el foco en Nota lo oculta',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.amountFocused();
        cubit.noteFocused();
      },
      verify: (cubit) {
        expect(cubit.state.focusedField, TransactionFormFocusedField.note);
        expect(cubit.state.isKeypadVisible, isFalse);
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'construye el monto dígito a dígito (entrada de números enteros)',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..amountDigitPressed(1)
          ..amountDigitPressed(2)
          ..amountDigitPressed(3)
          ..amountDigitPressed(4);
      },
      // Whole-number entry: 1234 stored as minor units (×100) = 123400.
      verify: (cubit) => expect(cubit.state.amountMinor, 123400),
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'el punto decimal (USD) construye centavos',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..currencySelected('USD')
          ..amountDigitPressed(1)
          ..amountDigitPressed(2)
          ..amountDecimalPressed()
          ..amountDigitPressed(3)
          ..amountDigitPressed(4);
      },
      // 12.34 USD → 1234 minor units.
      verify: (cubit) => expect(cubit.state.amountMinor, 1234),
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'borrar quita el último dígito entero',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..amountDigitPressed(1)
          ..amountDigitPressed(2)
          ..amountBackspace();
      },
      // 12 → 1 whole unit = 100 minor units.
      verify: (cubit) => expect(cubit.state.amountMinor, 100),
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'los operadores evalúan en centavos sin double: 45 × 3 = 135',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..amountDigitPressed(4)
          ..amountDigitPressed(5)
          ..amountOperatorPressed(CalcOperator.multiply)
          ..amountDigitPressed(3)
          ..amountEqualsPressed();
      },
      // $45 × 3 = $135 → 13500 minor units.
      verify: (cubit) => expect(cubit.state.amountMinor, 13500),
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'dividir redondea half-up a centavos: 10 ÷ 3 = 3,33',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..amountDigitPressed(1)
          ..amountDigitPressed(0)
          ..amountOperatorPressed(CalcOperator.divide)
          ..amountDigitPressed(3)
          ..amountEqualsPressed();
      },
      // $10 / 3 = $3.333… → 333 minor units (round half-up).
      verify: (cubit) => expect(cubit.state.amountMinor, 333),
    );
  });

  group('crear (HU-01/02/03)', () {
    blocTest<TransactionFormCubit, TransactionFormState>(
      'un gasto válido se persiste y aplica sus etiquetas',
      setUp: () {
        when(() => createTransaction(any()))
            .thenAnswer((_) async => Right(buildTransaction()));
        when(() => setTransactionTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..accountSelected('acc-1', 'Cuenta 1')
          ..categorySelected('cat-1', CategoryKind.expense, 'Comida')
          ..amountDigitPressed(1)
          ..amountDigitPressed(0)
          ..amountDigitPressed(0)
          ..amountDigitPressed(0);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, TransactionFormStatus.saved);
        verify(() => createTransaction(any())).called(1);
        verify(() => setTransactionTags('tx-1', any())).called(1);
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'sin cuenta seleccionada no llama al caso de uso',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isNotNull);
        verifyNever(() => createTransaction(any()));
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'sin categoría seleccionada no llama al caso de uso (bug fix 11a)',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..accountSelected('acc-1', 'Cuenta 1')
          ..amountDigitPressed(1);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.failedField, TransactionDraft.fieldCategoryId);
        verifyNever(() => createTransaction(any()));
      },
    );
  });

  group('preselección de cuenta al crear (bug fix 11b)', () {
    blocTest<TransactionFormCubit, TransactionFormState>(
      'load(null) preselecciona la primera cuenta por sortOrder',
      setUp: () => when(() => watchAccounts()).thenAnswer(
        // `WatchAccounts` already returns the list ordered by `sortOrder`
        // (same source `AccountPickerSheetBody` uses); the cubit trusts that
        // order and just takes the first entry.
        (_) => Stream.value(
          Right([
            _accountWithBalance(name: 'Bancolombia'),
            _accountWithBalance(id: 'acc-2', name: 'Nequi', sortOrder: 1),
          ]),
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(null),
      verify: (cubit) {
        expect(cubit.state.accountId, 'acc-1');
        expect(cubit.state.accountName, 'Bancolombia');
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'load(null) sin cuentas no preselecciona nada',
      build: build,
      act: (cubit) => cubit.load(null),
      verify: (cubit) {
        expect(cubit.state.accountId, isNull);
        expect(cubit.state.accountName, isNull);
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'load(null, accountId: ...) respeta la cuenta del llamador y no consulta',
      setUp: () => when(() => watchAccounts()).thenAnswer(
        (_) =>
            Stream.value(Right([_accountWithBalance(id: 'acc-2', name: 'Nequi')])),
      ),
      build: build,
      act: (cubit) => cubit.load(null, accountId: 'acc-caller'),
      verify: (cubit) {
        expect(cubit.state.accountId, 'acc-caller');
        verifyNever(() => watchAccounts());
      },
    );
  });

  group('editar (HU-04)', () {
    final original = buildTransaction(
      categoryId: 'cat-1',
      scheduledPaymentId: 'rec-1',
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'un cambio que afecta un vínculo se detiene con la advertencia, sin persistir',
      setUp: () {
        when(() => watchTransactionDetail('tx-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              TransactionWithDetails(
                transaction: original,
                accountName: 'Bancolombia',
              ),
            ),
          ),
        );
        when(
          () => getTransactionEditImpact(
            original: any(named: 'original'),
            draft: any(named: 'draft'),
          ),
        ).thenReturn(
          const TransactionEditImpact(
            affectsScheduledPayment: true,
            affectsGoal: false,
            affectsDebt: false,
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.load('tx-1');
        cubit.amountDigitPressed(9);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.isAwaitingEditImpactConfirmation, isTrue);
        verifyNever(() => updateTransaction(any()));
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'confirmado, el cambio se persiste sin volver a preguntar',
      setUp: () {
        when(() => watchTransactionDetail('tx-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              TransactionWithDetails(
                transaction: original,
                accountName: 'Bancolombia',
              ),
            ),
          ),
        );
        when(
          () => getTransactionEditImpact(
            original: any(named: 'original'),
            draft: any(named: 'draft'),
          ),
        ).thenReturn(
          const TransactionEditImpact(
            affectsScheduledPayment: true,
            affectsGoal: false,
            affectsDebt: false,
          ),
        );
        when(() => updateTransaction(any()))
            .thenAnswer((_) async => Right(original));
        when(() => setTransactionTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('tx-1');
        cubit.amountDigitPressed(9);
        await cubit.submit(confirmed: true);
      },
      verify: (cubit) {
        expect(cubit.state.status, TransactionFormStatus.saved);
        verify(() => updateTransaction(any())).called(1);
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'source nunca cambia al editar: el draft mantiene el original',
      setUp: () {
        when(() => watchTransactionDetail('tx-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              TransactionWithDetails(
                transaction: buildTransaction(source: TransactionSource.imported),
                accountName: 'Bancolombia',
              ),
            ),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.load('tx-1'),
      verify: (cubit) => expect(cubit.state.source, TransactionSource.imported),
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'loading an existing transaction resolves the account/category display '
      'names into the state (regression: the picker button used to show only '
      'its static label — never the actual selection — because these names '
      'were resolved by TransactionWithDetails but never copied out of it)',
      setUp: () => when(() => watchTransactionDetail('tx-1')).thenAnswer(
        (_) => Stream.value(
          Right(
            TransactionWithDetails(
              transaction: buildTransaction(categoryId: 'cat-1'),
              accountName: 'Bancolombia',
              categoryName: 'Comida',
            ),
          ),
        ),
      ),
      build: build,
      act: (cubit) => cubit.load('tx-1'),
      verify: (cubit) {
        expect(cubit.state.accountName, 'Bancolombia');
        expect(cubit.state.categoryName, 'Comida');
      },
    );
  });

  group('nombres visibles al elegir (regresión)', () {
    blocTest<TransactionFormCubit, TransactionFormState>(
      'accountSelected guarda el nombre junto al id, no solo el id',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.accountSelected('acc-2', 'Nequi');
      },
      verify: (cubit) {
        expect(cubit.state.accountId, 'acc-2');
        expect(cubit.state.accountName, 'Nequi');
      },
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'categorySelected guarda el nombre junto al id y el kind',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.categorySelected('cat-2', CategoryKind.expense, 'Transporte');
      },
      verify: (cubit) {
        expect(cubit.state.categoryId, 'cat-2');
        expect(cubit.state.categoryName, 'Transporte');
      },
    );
  });
}
