import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_edit_impact.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../transaction_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockCreateTransaction createTransaction;
  late MockUpdateTransaction updateTransaction;
  late MockWatchTransactionDetail watchTransactionDetail;
  late MockGetTransactionEditImpact getTransactionEditImpact;
  late MockSetTransactionTags setTransactionTags;

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    createTransaction = MockCreateTransaction();
    updateTransaction = MockUpdateTransaction();
    watchTransactionDetail = MockWatchTransactionDetail();
    getTransactionEditImpact = MockGetTransactionEditImpact();
    setTransactionTags = MockSetTransactionTags();
  });

  TransactionFormCubit build() => TransactionFormCubit(
        createTransaction,
        updateTransaction,
        watchTransactionDetail,
        getTransactionEditImpact,
        setTransactionTags,
      );

  group('teclado numérico anclado (criterio 11)', () {
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
      'construye el monto dígito a dígito',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..amountDigitPressed(1)
          ..amountDigitPressed(2)
          ..amountDigitPressed(3)
          ..amountDigitPressed(4);
      },
      verify: (cubit) => expect(cubit.state.amountMinor, 1234),
    );

    blocTest<TransactionFormCubit, TransactionFormState>(
      'borrar quita el último dígito',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit
          ..amountDigitPressed(1)
          ..amountDigitPressed(2)
          ..amountBackspace();
      },
      verify: (cubit) => expect(cubit.state.amountMinor, 1),
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
  });

  group('editar (HU-04)', () {
    final original = buildTransaction(recurringId: 'rec-1');

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
            affectsRecurring: true,
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
            affectsRecurring: true,
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
