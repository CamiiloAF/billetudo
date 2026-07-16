import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_with_details.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_detail_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/transaction_detail_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../transaction_fixtures.dart';
import 'usecase_mocks.dart';

void main() {
  late MockWatchTransactionDetail watchTransactionDetail;
  late MockDeleteTransaction deleteTransaction;

  final entry = TransactionWithDetails(
    transaction: buildTransaction(),
    accountName: 'Bancolombia',
  );

  setUpAll(registerPresentationFallbacks);

  setUp(() {
    watchTransactionDetail = MockWatchTransactionDetail();
    deleteTransaction = MockDeleteTransaction();
  });

  TransactionDetailCubit build() =>
      TransactionDetailCubit(watchTransactionDetail, deleteTransaction);

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'carga el detalle enriquecido',
    setUp: () => when(() => watchTransactionDetail('tx-1'))
        .thenAnswer((_) => Stream.value(Right(entry))),
    build: build,
    act: (cubit) => cubit.start('tx-1'),
    expect: () => [
      const TransactionDetailState(),
      TransactionDetailState(
        status: TransactionDetailStatus.ready,
        entry: entry,
      ),
    ],
  );

  blocTest<TransactionDetailCubit, TransactionDetailState>(
    'confirmar el borrado cierra el prompt y marca deleted en la misma emisión',
    setUp: () {
      when(() => watchTransactionDetail('tx-1'))
          .thenAnswer((_) => Stream.value(Right(entry)));
      when(() => deleteTransaction('tx-1')).thenAnswer(
        (_) async => const Right(unit),
      );
    },
    build: build,
    act: (cubit) async {
      await cubit.start('tx-1');
      await Future<void>.delayed(Duration.zero);
      cubit.requestDelete();
      await cubit.confirmDelete();
    },
    verify: (cubit) {
      expect(cubit.state.deletePrompt, isFalse);
      expect(cubit.state.deleted, isTrue);
    },
  );
}
