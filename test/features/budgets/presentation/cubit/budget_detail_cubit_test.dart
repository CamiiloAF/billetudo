import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_detail_data.dart';
import 'package:billetudo/features/budgets/domain/usecases/close_budget.dart';
import 'package:billetudo/features/budgets/domain/usecases/delete_budget.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_state.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockGetBudgetById extends Mock implements GetBudgetById {}

class MockGetBudgetProgress extends Mock implements GetBudgetProgress {}

class MockCloseBudget extends Mock implements CloseBudget {}

class MockDeleteBudget extends Mock implements DeleteBudget {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

/// The undo mechanism (`notifyExternalDelete`/`undoDelete`/`dismissUndo`) is
/// the only cubit surface these tests exercise directly — the reactive
/// `start()` + period navigation path needs a full `BudgetDetailData` fixture
/// and is covered by `budget_detail_page_golden_test.dart` and
/// `budget_detail_page_test.dart` at the widget level instead. Mirrors
/// `transactions_list_cubit_test.dart`'s "borrar y deshacer" group.
void main() {
  late MockGetBudgetById getBudgetById;
  late MockGetBudgetProgress getBudgetProgress;
  late MockCloseBudget closeBudget;
  late MockDeleteBudget deleteBudget;
  late MockRestoreTransaction restoreTransaction;

  setUp(() {
    getBudgetById = MockGetBudgetById();
    getBudgetProgress = MockGetBudgetProgress();
    closeBudget = MockCloseBudget();
    deleteBudget = MockDeleteBudget();
    restoreTransaction = MockRestoreTransaction();
    // No test in this file drives `start()`, so the stream never needs to
    // emit; guard it anyway so an accidental call does not throw a
    // MissingStubError.
    when(() => getBudgetById(any()))
        .thenAnswer((_) => const Stream<Result<BudgetDetailData>>.empty());
  });

  BudgetDetailCubit build() => BudgetDetailCubit(
        getBudgetById,
        getBudgetProgress,
        closeBudget,
        deleteBudget,
        restoreTransaction,
      );

  group('borrar y deshacer desde la actividad (HU-05)', () {
    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'notifyExternalDelete ofrece deshacer con el id de la transacción',
      build: build,
      act: (cubit) => cubit.notifyExternalDelete('tx-1'),
      expect: () => [
        const BudgetDetailState(pendingUndoId: 'tx-1'),
      ],
      verify: (_) => verifyNever(() => restoreTransaction(any())),
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'undoDelete restaura la transacción y limpia el pendiente',
      setUp: () => when(() => restoreTransaction('tx-1'))
          .thenAnswer((_) async => const Right(unit)),
      build: build,
      act: (cubit) async {
        cubit.notifyExternalDelete('tx-1');
        await cubit.undoDelete();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, isNull);
        verify(() => restoreTransaction('tx-1')).called(1);
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'dismissUndo limpia el pendiente sin restaurar',
      build: build,
      act: (cubit) {
        cubit.notifyExternalDelete('tx-1');
        cubit.dismissUndo();
      },
      verify: (cubit) {
        expect(cubit.state.pendingUndoId, isNull);
        verifyNever(() => restoreTransaction(any()));
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'undoDelete sin pendiente no llama al caso de uso',
      build: build,
      act: (cubit) => cubit.undoDelete(),
      verify: (_) => verifyNever(() => restoreTransaction(any())),
    );
  });

  group('cerrar/eliminar (HU-10/HU-11) sin id cargado', () {
    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'closeToHistory antes de start() no invoca el caso de uso',
      build: build,
      verify: (cubit) async {
        final result = await cubit.closeToHistory();
        expect(result.getRight().toNullable(), unit);
        verifyNever(() => closeBudget(any()));
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'delete antes de start() no invoca el caso de uso',
      build: build,
      verify: (cubit) async {
        final result = await cubit.delete();
        expect(result.getRight().toNullable(), unit);
        verifyNever(() => deleteBudget(any()));
      },
    );
  });
}
