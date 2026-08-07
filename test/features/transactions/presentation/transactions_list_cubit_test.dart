import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/transactions/domain/entities/budget_period_option.dart';
import 'package:billetudo/features/transactions/domain/entities/date_period_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_filter.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../accounts/account_fixtures.dart';
import '../transaction_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchTransactions watchTransactions;
  late MockDeleteTransaction deleteTransaction;
  late MockRestoreTransaction restoreTransaction;
  late MockWatchAccounts watchAccounts;
  late MockWatchBudgetPeriodOptions watchBudgetPeriodOptions;
  late MockAccountFilterPreferenceDatasource accountFilterPreferences;
  late MockGetCategorySubtreeIds getCategorySubtreeIds;

  final entry = TransactionWithDetails(
    transaction: buildTransaction(),
    accountName: 'Bancolombia',
  );

  setUpAll(() {
    registerPresentationFallbacks();
    registerFallbackValue(<String>{});
  });

  setUp(() {
    watchTransactions = MockWatchTransactions();
    deleteTransaction = MockDeleteTransaction();
    restoreTransaction = MockRestoreTransaction();
    watchAccounts = MockWatchAccounts();
    watchBudgetPeriodOptions = MockWatchBudgetPeriodOptions();
    accountFilterPreferences = MockAccountFilterPreferenceDatasource();
    getCategorySubtreeIds = MockGetCategorySubtreeIds();
    when(() => watchAccounts()).thenAnswer((_) => const Stream.empty());
    when(() => watchBudgetPeriodOptions())
        .thenAnswer((_) => const Stream.empty());
    // Defaults to "sin filtro guardado" so existing tests keep behaving as
    // before this datasource existed; persistence-specific tests below
    // override this per case.
    when(() => accountFilterPreferences.readAccountIds())
        .thenAnswer((_) async => const <String>{});
    when(() => accountFilterPreferences.writeAccountIds(any()))
        .thenAnswer((_) async {});
    // Defaults to "no expansion needed" (a subcategory, or a root with no
    // subcategories) so existing tests keep behaving as before this use
    // case existed; drill-down-specific tests below override this per case.
    when(() => getCategorySubtreeIds(any())).thenAnswer(
      (invocation) async =>
          Right({invocation.positionalArguments.first as String}),
    );
  });

  TransactionsListCubit build() => TransactionsListCubit(
      watchTransactions,
      deleteTransaction,
      restoreTransaction,
      watchAccounts,
      watchBudgetPeriodOptions,
      accountFilterPreferences,
      getCategorySubtreeIds);

  group('carga inicial', () {
    blocTest<TransactionsListCubit, TransactionsListState>(
      'emite los movimientos cuando llegan del stream',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) => cubit.start(),
      expect: () => [
        TransactionsListState(),
        TransactionsListState(
          status: TransactionsListStatus.ready,
          items: [entry],
        ),
      ],
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'una lista vacía queda en ready, no en error (HU-06b)',
      setUp: () => when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(const Right(<TransactionWithDetails>[])),
      ),
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.isEmpty, isTrue);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'un fallo del stream deja el estado de error',
      setUp: () => when(() => watchTransactions(any())).thenAnswer(
        (_) => Stream.value(const Left(DatabaseFailure('boom'))),
      ),
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.status, TransactionsListStatus.failure);
      },
    );
  });

  group('filtros (HU-06)', () {
    blocTest<TransactionsListCubit, TransactionsListState>(
      'cambiar el texto de búsqueda se re-suscribe con el filtro actualizado',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.searchChanged('super');
      },
      verify: (cubit) {
        expect(cubit.state.filter.searchText, 'super');
        verify(() => watchTransactions(any())).called(2);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'aplicar el mismo filtro no vuelve a suscribirse',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.updateFilter(cubit.state.filter);
      },
      verify: (_) => verify(() => watchTransactions(any())).called(1),
    );
  });

  group('persistencia del filtro de cuentas (HU-06a)', () {
    blocTest<TransactionsListCubit, TransactionsListState>(
      'start() aplica los accountIds guardados como filtro inicial',
      setUp: () {
        when(() => accountFilterPreferences.readAccountIds())
            .thenAnswer((_) async => {'acc-1', 'acc-2'});
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
      },
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.filter.accountIds, {'acc-1', 'acc-2'});
        verify(
          () => watchTransactions(
            any(
              that: predicate<TransactionFilter>(
                (filter) => filter.accountIds.containsAll({'acc-1', 'acc-2'}),
              ),
            ),
          ),
        ).called(1);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'updateFilter con accountIds distintos persiste el nuevo set',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.updateFilter(
          cubit.state.filter.copyWith(accountIds: {'acc-1'}),
        );
      },
      verify: (_) => verify(
        () => accountFilterPreferences.writeAccountIds({'acc-1'}),
      ).called(1),
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'filterByAccount fija el filtro a solo esa cuenta y lo persiste '
      '(bugfix item 8)',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.updateFilter(
          cubit.state.filter.copyWith(accountIds: {'acc-1', 'acc-2'}),
        );
        await cubit.filterByAccount('acc-9');
      },
      verify: (cubit) {
        expect(cubit.state.filter.accountIds, {'acc-9'});
        verify(
          () => accountFilterPreferences.writeAccountIds({'acc-9'}),
        ).called(1);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'filterByCategoryAndRange fija categoría y rango de fechas '
      '(drill-down de Gráficas)',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.filterByCategoryAndRange(
          categoryId: 'cat-mercado',
          start: DateTime(2026, 2),
          endInclusive: DateTime(2026, 7, 31),
        );
      },
      verify: (cubit) {
        expect(cubit.state.filter.categoryIds, {'cat-mercado'});
        expect(cubit.state.filter.datePeriod.isCustomRange, isTrue);
        expect(cubit.state.filter.datePeriod.start, DateTime(2026, 2));
        expect(
          cubit.state.filter.datePeriod.endExclusive,
          DateTime(2026, 8),
        );
        // Default (criterion 8): Gráficas' cuentas filter en "todas" no
        // aplica ninguna restricción de cuenta en Movimientos.
        expect(cubit.state.filter.accountIds, isEmpty);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'filterByCategoryAndRange propaga el subconjunto de cuentas de '
      'Gráficas (criterion 7)',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.filterByCategoryAndRange(
          categoryId: 'cat-mercado',
          start: DateTime(2026, 2),
          endInclusive: DateTime(2026, 7, 31),
          accountIds: const {'acc-1', 'acc-2'},
        );
      },
      verify: (cubit) {
        expect(cubit.state.filter.categoryIds, {'cat-mercado'});
        expect(cubit.state.filter.accountIds, {'acc-1', 'acc-2'});
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      // Bug 2 regression: a root category whose own movements are tagged
      // with a subcategory's id (never its own) must expand to itself +
      // every active subcategory before filtering — a plain
      // `{categoryId}` filter would match nothing.
      'filterByCategoryAndRange expande una categoría raíz a sus '
      'subcategorías (drill-down desde una raíz sin movimientos propios)',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        when(() => getCategorySubtreeIds('cat-hogar')).thenAnswer(
          (_) async => const Right({'cat-hogar', 'cat-hogar-mercado'}),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.filterByCategoryAndRange(
          categoryId: 'cat-hogar',
          start: DateTime(2026, 2),
          endInclusive: DateTime(2026, 7, 31),
        );
      },
      verify: (cubit) {
        expect(
          cubit.state.filter.categoryIds,
          {'cat-hogar', 'cat-hogar-mercado'},
        );
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'filterByCategoryAndRange cae de vuelta a solo categoryId si la '
      'expansión de subcategorías falla',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        when(() => getCategorySubtreeIds('cat-borrada')).thenAnswer(
          (_) async => const Left(NotFoundFailure('category not found')),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.filterByCategoryAndRange(
          categoryId: 'cat-borrada',
          start: DateTime(2026, 2),
          endInclusive: DateTime(2026, 7, 31),
        );
      },
      verify: (cubit) {
        expect(cubit.state.filter.categoryIds, {'cat-borrada'});
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'updateFilter que solo cambia otro campo no persiste accountIds',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.updateFilter(
          cubit.state.filter.copyWith(searchText: 'super'),
        );
      },
      verify: (_) => verifyNever(
        () => accountFilterPreferences.writeAccountIds(any()),
      ),
    );

    test(
      'poda un id fantasma (cuenta archivada/eliminada) de la primera '
      'emisión de cuentas activas y persiste el resultado',
      () async {
        when(() => accountFilterPreferences.readAccountIds())
            .thenAnswer((_) async => {'acc-1', 'acc-2'});
        when(() => watchTransactions(any()))
            .thenAnswer((_) => const Stream.empty());
        final accountsController =
            StreamController<Result<List<AccountWithBalance>>>();
        when(() => watchAccounts())
            .thenAnswer((_) => accountsController.stream);

        final cubit = build();
        await cubit.start();

        // Only 'acc-1' is still active: 'acc-2' was archived/deleted since
        // the filter was persisted.
        accountsController.add(
          Right([
            buildAccountWithBalance(
              account: buildAccount(id: 'acc-1'),
              balanceMinor: 0,
            ),
          ]),
        );
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.filter.accountIds, {'acc-1'});
        verify(
          () => accountFilterPreferences.writeAccountIds({'acc-1'}),
        ).called(1);

        await cubit.close();
        await accountsController.close();
      },
    );

    test(
      'si TODOS los ids persistidos eran fantasma, el filtro cae a vacío '
      '("todas las cuentas")',
      () async {
        when(() => accountFilterPreferences.readAccountIds())
            .thenAnswer((_) async => {'acc-ghost'});
        when(() => watchTransactions(any()))
            .thenAnswer((_) => const Stream.empty());
        final accountsController =
            StreamController<Result<List<AccountWithBalance>>>();
        when(() => watchAccounts())
            .thenAnswer((_) => accountsController.stream);

        final cubit = build();
        await cubit.start();

        // 'acc-ghost' is nowhere in the active accounts.
        accountsController.add(
          Right([
            buildAccountWithBalance(
              account: buildAccount(id: 'acc-1'),
              balanceMinor: 0,
            ),
          ]),
        );
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.filter.accountIds, isEmpty);
        verify(
          () => accountFilterPreferences.writeAccountIds(<String>{}),
        ).called(1);

        await cubit.close();
        await accountsController.close();
      },
    );

    test(
      'si los ids persistidos siguen todos activos, no se re-persiste nada',
      () async {
        when(() => accountFilterPreferences.readAccountIds())
            .thenAnswer((_) async => {'acc-1'});
        when(() => watchTransactions(any()))
            .thenAnswer((_) => const Stream.empty());
        final accountsController =
            StreamController<Result<List<AccountWithBalance>>>();
        when(() => watchAccounts())
            .thenAnswer((_) => accountsController.stream);

        final cubit = build();
        await cubit.start();

        accountsController.add(
          Right([
            buildAccountWithBalance(
              account: buildAccount(id: 'acc-1'),
              balanceMinor: 0,
            ),
            buildAccountWithBalance(
              account: buildAccount(id: 'acc-2'),
              balanceMinor: 0,
            ),
          ]),
        );
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.filter.accountIds, {'acc-1'});
        verifyNever(() => accountFilterPreferences.writeAccountIds(any()));

        await cubit.close();
        await accountsController.close();
      },
    );

    test(
      'la poda solo ocurre en la primera emisión de cuentas: una emisión '
      'posterior (ej. el usuario archiva una cuenta ya seleccionada mientras '
      'mira la pantalla) no cambia el filtro activo',
      () async {
        when(() => accountFilterPreferences.readAccountIds())
            .thenAnswer((_) async => {'acc-1', 'acc-2'});
        when(() => watchTransactions(any()))
            .thenAnswer((_) => const Stream.empty());
        final accountsController =
            StreamController<Result<List<AccountWithBalance>>>();
        when(() => watchAccounts())
            .thenAnswer((_) => accountsController.stream);

        final cubit = build();
        await cubit.start();

        // First emission: 'acc-2' is already gone, so it gets pruned.
        accountsController.add(
          Right([
            buildAccountWithBalance(
              account: buildAccount(id: 'acc-1'),
              balanceMinor: 0,
            ),
          ]),
        );
        await Future<void>.delayed(Duration.zero);
        expect(cubit.state.filter.accountIds, {'acc-1'});
        verify(
          () => accountFilterPreferences.writeAccountIds({'acc-1'}),
        ).called(1);

        // Second emission, while the screen stays open: 'acc-1' (now the
        // only selected account) gets archived too. This must NOT be
        // pruned automatically — only the very first emission is checked.
        accountsController.add(const Right(<AccountWithBalance>[]));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.filter.accountIds, {'acc-1'});
        verifyNever(() => accountFilterPreferences.writeAccountIds(<String>{}));

        await cubit.close();
        await accountsController.close();
      },
    );
  });

  group('start() y el flujo "llegó desde Gráficas" (Bug 3, race)', () {
    blocTest<TransactionsListCubit, TransactionsListState>(
      'start() no pisa el accountIds recién aplicado por '
      'filterByCategoryAndRange cuando arrivedFromReports ya es true — '
      'la persistencia en disco no gana la carrera',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        // The persisted preference disagrees with what Gráficas just set —
        // if start() wins the race, this stale value leaks through.
        when(() => accountFilterPreferences.readAccountIds())
            .thenAnswer((_) async => const {'acc-persisted'});
      },
      build: build,
      act: (cubit) async {
        await cubit.filterByCategoryAndRange(
          categoryId: 'cat-mercado',
          start: DateTime(2026, 2),
          endInclusive: DateTime(2026, 7, 31),
          accountIds: const {'acc-graficas'},
        );
        cubit.markArrivedFromReports();
        // Mirrors the router: Movimientos' `GoRoute.builder` calls `start()`
        // again on the very same singleton right after the filter above and
        // `markArrivedFromReports()` already landed synchronously.
        await cubit.start();
      },
      verify: (cubit) {
        expect(cubit.state.filter.accountIds, {'acc-graficas'});
        expect(cubit.state.filter.categoryIds, {'cat-mercado'});
        expect(cubit.state.arrivedFromReports, isTrue);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'start() sí restaura el accountIds persistido cuando no viene de '
      'Gráficas (entrada normal)',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        when(() => accountFilterPreferences.readAccountIds())
            .thenAnswer((_) async => const {'acc-persisted'});
      },
      build: build,
      act: (cubit) => cubit.start(),
      verify: (cubit) {
        expect(cubit.state.filter.accountIds, {'acc-persisted'});
        expect(cubit.state.arrivedFromReports, isFalse);
      },
    );
  });

  group('filtro de presupuesto (Presupuesto chip)', () {
    BudgetPeriodOption option(String id) => BudgetPeriodOption(
          budgetId: id,
          name: 'Comida',
          start: DateTime(2026, 7),
          endExclusive: DateTime(2026, 8),
        );

    test(
      'poda el filtro de presupuesto cuando el presupuesto elegido ya no '
      'está activo (archivado/eliminado) en la primera emisión',
      () async {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => const Stream.empty());
        final optionsController =
            StreamController<Result<List<BudgetPeriodOption>>>();
        when(() => watchBudgetPeriodOptions())
            .thenAnswer((_) => optionsController.stream);

        final cubit = build();
        await cubit.start();
        await cubit.updateFilter(
          cubit.state.filter.copyWith(
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-ghost',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
        );

        // 'budget-ghost' is nowhere in the active budgets — it was archived
        // since the filter was applied.
        optionsController.add(Right([option('budget-1')]));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.filter.hasBudgetPeriodFilter, isFalse);

        await cubit.close();
        await optionsController.close();
      },
    );

    test(
      'si el presupuesto del filtro sigue activo, no se toca nada',
      () async {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => const Stream.empty());
        final optionsController =
            StreamController<Result<List<BudgetPeriodOption>>>();
        when(() => watchBudgetPeriodOptions())
            .thenAnswer((_) => optionsController.stream);

        final cubit = build();
        await cubit.start();
        await cubit.updateFilter(
          cubit.state.filter.copyWith(
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
        );

        optionsController.add(Right([option('budget-1')]));
        await Future<void>.delayed(Duration.zero);

        expect(cubit.state.filter.hasBudgetPeriodFilter, isTrue);
        expect(cubit.state.filter.budgetPeriod!.budgetId, 'budget-1');

        await cubit.close();
        await optionsController.close();
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'updateFilter combina budgetPeriod y datePeriod en la query emitida '
      'a WatchTransactions, sin que uno reemplace al otro',
      setUp: () => when(() => watchTransactions(any()))
          .thenAnswer((_) => Stream.value(Right([entry]))),
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.updateFilter(
          cubit.state.filter.copyWith(
            budgetPeriod: DatePeriodFilter.budget(
              budgetId: 'budget-1',
              start: DateTime(2026, 7),
              endExclusive: DateTime(2026, 8),
            ),
          ),
        );
      },
      verify: (cubit) {
        expect(cubit.state.filter.hasBudgetPeriodFilter, isTrue);
        expect(
          cubit.state.filter.datePeriod,
          DatePeriodFilter.thisMonth(),
        );
        verify(
          () => watchTransactions(
            any(
              that: predicate<TransactionFilter>(
                (filter) =>
                    filter.budgetPeriod?.budgetId == 'budget-1' &&
                    filter.datePeriod == DatePeriodFilter.thisMonth(),
              ),
            ),
          ),
        ).called(1);
      },
    );
  });

  group('borrar y deshacer (HU-05)', () {
    blocTest<TransactionsListCubit, TransactionsListState>(
      'borrar ofrece deshacer con el id de la transacción',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        when(() => deleteTransaction(any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.deleteTransaction('tx-1');
      },
      verify: (cubit) => expect(cubit.state.pendingUndoId, 'tx-1'),
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'deshacer restaura y limpia el pendiente',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        when(() => deleteTransaction(any()))
            .thenAnswer((_) async => const Right(unit));
        when(() => restoreTransaction(any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.deleteTransaction('tx-1');
        await cubit.undoDelete();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, isNull);
        verify(() => restoreTransaction('tx-1')).called(1);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'si borrar falla, el estado pasa a error y no ofrece deshacer',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        when(() => deleteTransaction(any())).thenAnswer(
          (_) async => const Left(DatabaseFailure('boom')),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.deleteTransaction('tx-1');
      },
      verify: (cubit) {
        expect(cubit.state.status, TransactionsListStatus.failure);
        expect(cubit.state.pendingUndoId, isNull);
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'dismissUndo limpia el pendiente sin restaurar',
      setUp: () {
        when(() => watchTransactions(any()))
            .thenAnswer((_) => Stream.value(Right([entry])));
        when(() => deleteTransaction(any()))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start();
        await cubit.deleteTransaction('tx-1');
        cubit.dismissUndo();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, isNull);
        verifyNever(() => restoreTransaction(any()));
      },
    );

    blocTest<TransactionsListCubit, TransactionsListState>(
      'notifyExternalDelete ofrece deshacer sin volver a llamar al caso de '
      'uso de borrado (regresión: HU-05 pide "Deshacer" tipo snackbar, pero '
      'el único borrado alcanzable desde la UI es TransactionDetailPage vía '
      'TransactionDetailCubit.confirmDelete, que nunca pasaba por este '
      'cubit — el snackbar de esta clase quedaba sin ningún llamador real)',
      build: build,
      act: (cubit) => cubit.notifyExternalDelete('tx-1'),
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, 'tx-1');
        verifyNever(() => deleteTransaction(any()));
      },
    );
  });

  test('cerrar el cubit cancela la suscripción al stream', () async {
    final controller =
        StreamController<Result<List<TransactionWithDetails>>>.broadcast();
    when(() => watchTransactions(any())).thenAnswer((_) => controller.stream);

    final cubit = build();
    await cubit.start();
    await cubit.close();

    expect(controller.hasListener, isFalse);
    await controller.close();
  });
}
