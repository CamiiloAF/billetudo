import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transactions_list_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../transaction_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchTransactions watchTransactions;
  late MockDeleteTransaction deleteTransaction;
  late MockRestoreTransaction restoreTransaction;
  late MockWatchAccounts watchAccounts;

  final entry = TransactionWithDetails(
    transaction: buildTransaction(),
    accountName: 'Bancolombia',
  );

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    watchTransactions = MockWatchTransactions();
    deleteTransaction = MockDeleteTransaction();
    restoreTransaction = MockRestoreTransaction();
    watchAccounts = MockWatchAccounts();
    when(() => watchAccounts()).thenAnswer((_) => const Stream.empty());
  });

  TransactionsListCubit build() => TransactionsListCubit(
      watchTransactions, deleteTransaction, restoreTransaction, watchAccounts);

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
