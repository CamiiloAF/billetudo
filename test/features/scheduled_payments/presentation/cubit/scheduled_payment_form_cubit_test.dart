import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/accounts/domain/entities/account_balance.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_detail.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_draft.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_cubit.dart';
import 'package:billetudo/features/scheduled_payments/presentation/cubit/scheduled_payment_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../scheduled_payment_fixtures.dart';
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
  late MockCreateScheduledPayment createScheduledPayment;
  late MockUpdateScheduledPayment updateScheduledPayment;
  late MockGetScheduledPaymentDetail getScheduledPaymentDetail;
  late MockSetScheduledPaymentTags setScheduledPaymentTags;
  late MockDeleteScheduledPayment deleteScheduledPayment;
  late MockWatchAccounts watchAccounts;

  setUpAll(registerScheduledPaymentPresentationFallbacks);

  setUp(() {
    createScheduledPayment = MockCreateScheduledPayment();
    updateScheduledPayment = MockUpdateScheduledPayment();
    getScheduledPaymentDetail = MockGetScheduledPaymentDetail();
    setScheduledPaymentTags = MockSetScheduledPaymentTags();
    deleteScheduledPayment = MockDeleteScheduledPayment();
    watchAccounts = MockWatchAccounts();
    // Default: no accounts, so a new form opens with an empty account unless a
    // test stubs otherwise. Individual tests override this to assert the
    // preselection of the first account.
    when(() => watchAccounts())
        .thenAnswer((_) => Stream.value(const Right(<AccountWithBalance>[])));
  });

  ScheduledPaymentFormCubit build() => ScheduledPaymentFormCubit(
        createScheduledPayment,
        updateScheduledPayment,
        getScheduledPaymentDetail,
        setScheduledPaymentTags,
        deleteScheduledPayment,
        watchAccounts,
      );

  group('HU-01: crear plantilla', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'submit valida, crea la plantilla y guarda sus etiquetas',
      setUp: () {
        when(() => createScheduledPayment(any()))
            .thenAnswer((_) async => Right(buildScheduledPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.accountSelected('acc-1', 'Bancolombia');
        cubit.categorySelected('cat-1', CategoryKind.expense, 'Arriendo');
        cubit.amountTextChanged('100');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentFormStatus.saved);
        verify(() => createScheduledPayment(any())).called(1);
        verify(() => setScheduledPaymentTags(any(), any())).called(1);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'sin cuenta, submit falla sin llamar el caso de uso',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.failure, isNotNull);
        verifyNever(() => createScheduledPayment(any()));
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'una plantilla nueva preselecciona la primera cuenta por sortOrder',
      setUp: () => when(() => watchAccounts()).thenAnswer(
        (_) => Stream.value(
          Right(<AccountWithBalance>[
            _accountWithBalance(id: 'acc-1', name: 'Nequi'),
            _accountWithBalance(id: 'acc-2', name: 'Bancolombia', sortOrder: 1),
          ]),
        ),
      ),
      build: build,
      act: (cubit) => cubit.load(null),
      verify: (cubit) {
        expect(cubit.state.accountId, 'acc-1');
        expect(cubit.state.accountName, 'Nequi');
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'gasto sin categoría, submit falla con el campo categoría',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.accountSelected('acc-1', 'Bancolombia');
        cubit.amountTextChanged('100');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(
          cubit.state.failedField,
          ScheduledPaymentDraft.fieldCategoryId,
        );
        verifyNever(() => createScheduledPayment(any()));
      },
    );
  });

  group('HU-05: eliminar plantilla desde el formulario', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'delete tombstona la plantilla y emite status=deleted',
      setUp: () {
        when(() => deleteScheduledPayment('sp-1'))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      seed: () => ScheduledPaymentFormState(
        status: ScheduledPaymentFormStatus.ready,
        id: 'sp-1',
      ),
      act: (cubit) => cubit.delete(),
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentFormStatus.deleted);
        verify(() => deleteScheduledPayment('sp-1')).called(1);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'sin plantilla cargada (creación), delete no llama el caso de uso',
      build: build,
      act: (cubit) => cubit.delete(),
      verify: (cubit) {
        verifyNever(() => deleteScheduledPayment(any()));
      },
    );
  });

  group('criterion 16: transferencia no admite categoría ni etiquetas', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'elegir tipo transferencia limpia categoría y etiquetas seleccionadas',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.categorySelected('cat-1', null, 'Arriendo');
        cubit.tagsChanged({'tag-1'});
        cubit.typeSelected(ScheduledPaymentType.transfer);
      },
      verify: (cubit) {
        expect(cubit.state.categoryId, isNull);
        expect(cubit.state.tagIds, isEmpty);
        expect(cubit.state.isTransfer, isTrue);
      },
    );
  });

  group('item 17: cambiar tipo reinicia la categoría', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'gasto → ingreso limpia la categoría de gasto seleccionada',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.categorySelected('cat-exp', CategoryKind.expense, 'Comida');
        cubit.typeSelected(ScheduledPaymentType.income);
      },
      verify: (cubit) {
        expect(cubit.state.type, ScheduledPaymentType.income);
        expect(cubit.state.categoryId, isNull);
        expect(cubit.state.categoryKind, isNull);
        expect(cubit.state.categoryName, isNull);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'ingreso → gasto limpia la categoría de ingreso seleccionada',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.typeSelected(ScheduledPaymentType.income);
        cubit.categorySelected('cat-inc', CategoryKind.income, 'Salario');
        cubit.typeSelected(ScheduledPaymentType.expense);
      },
      verify: (cubit) {
        expect(cubit.state.type, ScheduledPaymentType.expense);
        expect(cubit.state.categoryId, isNull);
        expect(cubit.state.categoryKind, isNull);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'reelegir el mismo tipo no borra la categoría',
      build: build,
      act: (cubit) async {
        await cubit.load(null);
        cubit.categorySelected('cat-exp', CategoryKind.expense, 'Comida');
        cubit.typeSelected(ScheduledPaymentType.expense);
      },
      verify: (cubit) {
        expect(cubit.state.categoryId, 'cat-exp');
      },
    );
  });

  group('Fix: "Primer pago" no cambia solo (firstPaymentDate vs. nextDate)',
      () {
    // The cursor has already advanced past the immutable first payment date
    // — the exact drift the fix must not surface in the form.
    final firstPaymentDate = DateTime(2026, 1, 15);
    final advancedCursor = DateTime(2026, 4, 15);

    ScheduledPayment loadedPayment() => buildScheduledPayment(
          id: 'sp-1',
          // A gasto template is now categorized (category required); load()
          // re-derives its kind so an untouched edit still validates.
          categoryId: 'cat-1',
          firstPaymentDate: firstPaymentDate,
          nextDate: advancedCursor,
        );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'load() puebla el campo mostrado con firstPaymentDate, no con nextDate',
      setUp: () {
        when(() => getScheduledPaymentDetail('sp-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              ScheduledPaymentDetail(
                scheduledPayment: loadedPayment(),
                accountName: 'Bancolombia',
                historyTotalCount: 0,
              ),
            ),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.load('sp-1'),
      verify: (cubit) {
        expect(cubit.state.nextDate, firstPaymentDate);
        expect(cubit.state.originalNextDate, advancedCursor);
        expect(cubit.state.nextDateEdited, isFalse);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'guardar sin tocar la fecha preserva el cursor original, no lo resetea',
      setUp: () {
        when(() => getScheduledPaymentDetail('sp-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              ScheduledPaymentDetail(
                scheduledPayment: loadedPayment(),
                accountName: 'Bancolombia',
                historyTotalCount: 0,
              ),
            ),
          ),
        );
        when(() => updateScheduledPayment(any()))
            .thenAnswer((_) async => Right(loadedPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('sp-1');
        // No nextDateChanged() call: the user never touched the date field.
        await cubit.submit();
      },
      verify: (cubit) {
        final captured =
            verify(() => updateScheduledPayment(captureAny())).captured;
        final draft = captured.single as ScheduledPaymentDraft;
        expect(draft.nextDate, advancedCursor);
        expect(draft.nextDate, isNot(firstPaymentDate));
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'editar explícitamente la fecha y guardar usa el valor editado',
      setUp: () {
        when(() => getScheduledPaymentDetail('sp-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              ScheduledPaymentDetail(
                scheduledPayment: loadedPayment(),
                accountName: 'Bancolombia',
                historyTotalCount: 0,
              ),
            ),
          ),
        );
        when(() => updateScheduledPayment(any()))
            .thenAnswer((_) async => Right(loadedPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.load('sp-1');
        cubit.nextDateChanged(DateTime(2026, 6));
        await cubit.submit();
      },
      verify: (cubit) {
        final captured =
            verify(() => updateScheduledPayment(captureAny())).captured;
        final draft = captured.single as ScheduledPaymentDraft;
        expect(draft.nextDate, DateTime(2026, 6));
      },
    );
  });

  group('HU-03: modo cuota de deuda', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'crear cuota de "Yo debo" deriva tipo gasto, fija debtId y entra en modo '
      'cuota',
      setUp: () => when(() => watchAccounts()).thenAnswer(
        (_) => Stream.value(
          Right(<AccountWithBalance>[_accountWithBalance(id: 'acc-1')]),
        ),
      ),
      build: build,
      act: (cubit) => cubit.loadForDebtCuota(
        debtId: 'debt-1',
        debtName: 'Crédito vehicular',
        debtIsIOwe: true,
      ),
      verify: (cubit) {
        expect(cubit.state.isDebtInstallment, isTrue);
        expect(cubit.state.debtId, 'debt-1');
        expect(cubit.state.debtName, 'Crédito vehicular');
        expect(cubit.state.debtIsIOwe, isTrue);
        expect(cubit.state.type, ScheduledPaymentType.expense);
        expect(cubit.state.status, ScheduledPaymentFormStatus.ready);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'crear cuota de "Me deben" deriva tipo ingreso',
      build: build,
      act: (cubit) => cubit.loadForDebtCuota(
        debtId: 'debt-2',
        debtName: 'Préstamo a Juan',
        debtIsIOwe: false,
      ),
      verify: (cubit) {
        expect(cubit.state.type, ScheduledPaymentType.income);
        expect(cubit.state.debtIsIOwe, isFalse);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'submit persiste el debtId en el draft de la cuota',
      setUp: () {
        when(() => watchAccounts()).thenAnswer(
          (_) => Stream.value(
            Right(<AccountWithBalance>[_accountWithBalance(id: 'acc-1')]),
          ),
        );
        when(() => createScheduledPayment(any()))
            .thenAnswer((_) async => Right(buildScheduledPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.loadForDebtCuota(
          debtId: 'debt-1',
          debtName: 'Crédito vehicular',
          debtIsIOwe: true,
        );
        cubit.categorySelected('cat-1', CategoryKind.expense, 'Transporte');
        cubit.amountTextChanged('1250000');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentFormStatus.saved);
        final draft = verify(() => createScheduledPayment(captureAny()))
            .captured
            .single as ScheduledPaymentDraft;
        expect(draft.debtId, 'debt-1');
        expect(draft.type, ScheduledPaymentType.expense);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'editar una cuota existente carga sus campos y superpone el contexto de '
      'la deuda',
      setUp: () {
        when(() => getScheduledPaymentDetail('sp-1')).thenAnswer(
          (_) => Stream.value(
            Right(
              ScheduledPaymentDetail(
                scheduledPayment: buildScheduledPayment(
                  id: 'sp-1',
                  categoryId: 'cat-1',
                  debtId: 'debt-1',
                ),
                accountName: 'Bancolombia',
                historyTotalCount: 0,
              ),
            ),
          ),
        );
      },
      build: build,
      act: (cubit) => cubit.loadForDebtCuota(
        scheduledPaymentId: 'sp-1',
        debtId: 'debt-1',
        debtName: 'Crédito vehicular',
        debtIsIOwe: true,
      ),
      verify: (cubit) {
        expect(cubit.state.isEditing, isTrue);
        expect(cubit.state.isDebtInstallment, isTrue);
        expect(cubit.state.debtId, 'debt-1');
        expect(cubit.state.debtName, 'Crédito vehicular');
        expect(cubit.state.categoryId, 'cat-1');
      },
    );
  });

  group('HU-06/criterion 14: puente desde Transacciones', () {
    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      'loadFromBridge prellena cuenta/monto/categoría/nota y frequency=once',
      build: build,
      act: (cubit) => cubit.loadFromBridge(
        accountId: 'acc-1',
        accountName: 'Bancolombia',
        amountMinor: 50000,
        currency: 'COP',
        type: ScheduledPaymentType.expense,
        nextDate: DateTime(2026, 8, 1),
        categoryId: 'cat-1',
        categoryName: 'Arriendo',
        note: 'Arriendo de agosto',
        tagIds: {'tag-1'},
      ),
      verify: (cubit) {
        expect(cubit.state.accountId, 'acc-1');
        expect(cubit.state.frequency, ScheduledPaymentFrequency.once);
        expect(cubit.state.nextDate, DateTime(2026, 8, 1));
        expect(cubit.state.categoryId, 'cat-1');
        expect(cubit.state.note, 'Arriendo de agosto');
        expect(cubit.state.tagIds, {'tag-1'});
        expect(cubit.state.status, ScheduledPaymentFormStatus.ready);
      },
    );
  });

  group('HU-03: cuota de deuda (fixes 4a/4b)', () {
    void stubAccount() {
      when(() => watchAccounts()).thenAnswer(
        (_) => Stream.value(
          Right(<AccountWithBalance>[_accountWithBalance(id: 'acc-1')]),
        ),
      );
    }

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      '4a: loadForDebtCuota guarda los límites del contexto de la deuda',
      setUp: stubAccount,
      build: build,
      act: (cubit) => cubit.loadForDebtCuota(
        debtId: 'd1',
        debtName: 'Crédito vehicular',
        debtIsIOwe: true,
        debtCreatedAt: DateTime(2026, 3, 10),
        debtOutstandingMinor: 5000000,
      ),
      verify: (cubit) {
        expect(cubit.state.debtId, 'd1');
        expect(cubit.state.debtCreatedAt, DateTime(2026, 3, 10));
        expect(cubit.state.debtOutstandingMinor, 5000000);
        expect(cubit.state.type, ScheduledPaymentType.expense);
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      '4a-ii: una cuota mayor al saldo falla sin crear nada',
      setUp: stubAccount,
      build: build,
      act: (cubit) async {
        await cubit.loadForDebtCuota(
          debtId: 'd1',
          debtName: 'Crédito vehicular',
          debtIsIOwe: true,
          debtCreatedAt: DateTime(2026, 3, 10),
          debtOutstandingMinor: 5000000,
        );
        cubit.categorySelected('cat-1', CategoryKind.expense, 'Cuota');
        // 600.000 en centavos = 60.000.000, muy por encima del saldo.
        cubit.amountTextChanged('600000');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(
          cubit.state.failedField,
          ScheduledPaymentFormCubit.fieldAmountExceedsDebt,
        );
        verifyNever(() => createScheduledPayment(any()));
      },
    );

    blocTest<ScheduledPaymentFormCubit, ScheduledPaymentFormState>(
      '4a-ii: una cuota dentro del saldo sí se crea',
      setUp: () {
        stubAccount();
        when(() => createScheduledPayment(any()))
            .thenAnswer((_) async => Right(buildScheduledPayment()));
        when(() => setScheduledPaymentTags(any(), any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.loadForDebtCuota(
          debtId: 'd1',
          debtName: 'Crédito vehicular',
          debtIsIOwe: true,
          debtCreatedAt: DateTime(2026, 3, 10),
          debtOutstandingMinor: 60000000,
        );
        cubit.categorySelected('cat-1', CategoryKind.expense, 'Cuota');
        cubit.amountTextChanged('600000');
        await cubit.submit();
      },
      verify: (cubit) {
        expect(cubit.state.status, ScheduledPaymentFormStatus.saved);
        verify(() => createScheduledPayment(any())).called(1);
      },
    );

    test('4b: un segundo submit mientras guarda no crea una cuota duplicada',
        () async {
      stubAccount();
      final completer = Completer<Result<ScheduledPayment>>();
      when(() => createScheduledPayment(any()))
          .thenAnswer((_) => completer.future);
      when(() => setScheduledPaymentTags(any(), any()))
          .thenAnswer((_) async => const Right(unit));

      final cubit = build();
      await cubit.loadForDebtCuota(
        debtId: 'd1',
        debtName: 'Crédito vehicular',
        debtIsIOwe: true,
        debtOutstandingMinor: 60000000,
      );
      cubit.categorySelected('cat-1', CategoryKind.expense, 'Cuota');
      cubit.amountTextChanged('600000');

      // First submit is in flight (create not yet resolved); a second tap must
      // be ignored so no duplicate cuota is created.
      final first = cubit.submit();
      expect(cubit.state.isSaving, isTrue);
      await cubit.submit();
      completer.complete(Right(buildScheduledPayment()));
      await first;

      expect(cubit.state.status, ScheduledPaymentFormStatus.saved);
      verify(() => createScheduledPayment(any())).called(1);
      await cubit.close();
    });
  });
}
