import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_detail_data.dart';
import 'package:billetudo/features/budgets/domain/entities/pending_budget_adjustment.dart';
import 'package:billetudo/features/budgets/domain/usecases/cancel_budget_adjustment.dart';
import 'package:billetudo/features/budgets/domain/usecases/close_budget.dart';
import 'package:billetudo/features/budgets/domain/usecases/delete_budget.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_progress.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_pending_budget_adjustment.dart';
import 'package:billetudo/features/budgets/domain/usecases/schedule_budget_adjustment.dart';
import 'package:billetudo/features/budgets/domain/usecases/update_budget_adjustment.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_detail_state.dart';
import 'package:billetudo/features/transactions/domain/usecases/restore_transaction.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../golden/budget_golden_fixtures.dart';

class MockGetBudgetById extends Mock implements GetBudgetById {}

class MockGetBudgetProgress extends Mock implements GetBudgetProgress {}

class MockCloseBudget extends Mock implements CloseBudget {}

class MockDeleteBudget extends Mock implements DeleteBudget {}

class MockRestoreTransaction extends Mock implements RestoreTransaction {}

class MockGetPendingBudgetAdjustment extends Mock
    implements GetPendingBudgetAdjustment {}

class MockScheduleBudgetAdjustment extends Mock
    implements ScheduleBudgetAdjustment {}

class MockUpdateBudgetAdjustment extends Mock
    implements UpdateBudgetAdjustment {}

class MockCancelBudgetAdjustment extends Mock
    implements CancelBudgetAdjustment {}

/// The undo mechanism (`notifyExternalDelete`/`undoDelete`/`dismissUndo`) and
/// "Ajustar monto — solo el próximo período" (`pendingAdjustment` +
/// schedule/update/cancel) are the cubit surfaces these tests exercise
/// directly — the reactive `start()` + period navigation path otherwise needs
/// a full `BudgetDetailData` fixture and is covered by
/// `budget_detail_page_golden_test.dart` and `budget_detail_page_test.dart` at
/// the widget level instead. Mirrors `transactions_list_cubit_test.dart`'s
/// "borrar y deshacer" group.
void main() {
  late MockGetBudgetById getBudgetById;
  late MockGetBudgetProgress getBudgetProgress;
  late MockCloseBudget closeBudget;
  late MockDeleteBudget deleteBudget;
  late MockRestoreTransaction restoreTransaction;
  late MockGetPendingBudgetAdjustment getPendingBudgetAdjustment;
  late MockScheduleBudgetAdjustment scheduleBudgetAdjustment;
  late MockUpdateBudgetAdjustment updateBudgetAdjustment;
  late MockCancelBudgetAdjustment cancelBudgetAdjustment;

  final data = BudgetDetailData(
    budget: healthyEntry.budget,
    scope: healthyEntry.scope,
    expenses: const [],
    categoryChildren: const {},
    scheduledTemplates: const [],
    pendingScheduledOccurrences: const [],
  );
  final view = buildPeriodView(healthyEntry);

  setUpAll(() {
    registerFallbackValue(data);
  });
  final adjustment = PendingBudgetAdjustment(
    newAmountMinor: 50000,
    effectiveFrom: DateTime(2025, 8, 21),
    resumeAmountMinor: 450000000,
    resumeFrom: DateTime(2025, 9, 21),
  );

  setUp(() {
    getBudgetById = MockGetBudgetById();
    getBudgetProgress = MockGetBudgetProgress();
    closeBudget = MockCloseBudget();
    deleteBudget = MockDeleteBudget();
    restoreTransaction = MockRestoreTransaction();
    getPendingBudgetAdjustment = MockGetPendingBudgetAdjustment();
    scheduleBudgetAdjustment = MockScheduleBudgetAdjustment();
    updateBudgetAdjustment = MockUpdateBudgetAdjustment();
    cancelBudgetAdjustment = MockCancelBudgetAdjustment();
    // No test in this file drives `start()`, so the stream never needs to
    // emit; guard it anyway so an accidental call does not throw a
    // MissingStubError.
    when(() => getBudgetById(any()))
        .thenAnswer((_) => const Stream<Result<BudgetDetailData>>.empty());
    when(
      () => getBudgetProgress(
        any(),
        now: any(named: 'now'),
        index: any(named: 'index'),
      ),
    ).thenReturn(view);
    // Every emission of detail data re-reads the pending fork; default to
    // "nothing pending" so tests that don't care about it stay quiet.
    when(() => getPendingBudgetAdjustment(any()))
        .thenAnswer((_) async => const Right(null));
  });

  BudgetDetailCubit build() => BudgetDetailCubit(
        getBudgetById,
        getBudgetProgress,
        closeBudget,
        deleteBudget,
        restoreTransaction,
        getPendingBudgetAdjustment,
        scheduleBudgetAdjustment,
        updateBudgetAdjustment,
        cancelBudgetAdjustment,
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

  group(
      'ajustar monto — solo el próximo período: pendingAdjustment se '
      'refresca en cada emisión de detalle', () {
    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'start() sin fork pendiente deja pendingAdjustment en null',
      setUp: () {
        when(() => getBudgetById('bud-tarjeta'))
            .thenAnswer((_) => Stream.value(Right(data)));
      },
      build: build,
      act: (cubit) => cubit.start('bud-tarjeta'),
      verify: (cubit) {
        expect(cubit.state.pendingAdjustment, isNull);
        verify(() => getPendingBudgetAdjustment('bud-tarjeta')).called(1);
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'start() con un fork pendiente puebla pendingAdjustment',
      setUp: () {
        when(() => getBudgetById('bud-tarjeta'))
            .thenAnswer((_) => Stream.value(Right(data)));
        when(() => getPendingBudgetAdjustment('bud-tarjeta'))
            .thenAnswer((_) async => Right(adjustment));
      },
      build: build,
      act: (cubit) => cubit.start('bud-tarjeta'),
      verify: (cubit) {
        expect(cubit.state.pendingAdjustment, adjustment);
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'a repository failure while refreshing the pending fork clears it '
      'instead of surfacing as the detail failure',
      setUp: () {
        when(() => getBudgetById('bud-tarjeta'))
            .thenAnswer((_) => Stream.value(Right(data)));
        when(() => getPendingBudgetAdjustment('bud-tarjeta')).thenAnswer(
          (_) async =>
              const Left(NotFoundFailure('budget "bud-tarjeta" not found')),
        );
      },
      build: build,
      act: (cubit) => cubit.start('bud-tarjeta'),
      verify: (cubit) {
        expect(cubit.state.status, BudgetDetailStatus.ready);
        expect(cubit.state.pendingAdjustment, isNull);
      },
    );
  });

  group('scheduleAmountAdjustment (crear)', () {
    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'sin id cargado no invoca el caso de uso',
      build: build,
      verify: (cubit) async {
        final result = await cubit.scheduleAmountAdjustment(50000);
        expect(result.getRight().toNullable(), unit);
        verifyNever(
          () => scheduleBudgetAdjustment(
            any(),
            newAmountMinor: any(named: 'newAmountMinor'),
          ),
        );
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'con éxito aplica el fork y refresca pendingAdjustment',
      setUp: () {
        when(() => getBudgetById('bud-tarjeta'))
            .thenAnswer((_) => Stream.value(Right(data)));
        when(
          () => scheduleBudgetAdjustment(
            'bud-tarjeta',
            newAmountMinor: 50000,
          ),
        ).thenAnswer((_) async => const Right(unit));
        when(() => getPendingBudgetAdjustment('bud-tarjeta'))
            .thenAnswer((_) async => Right(adjustment));
      },
      build: build,
      act: (cubit) async {
        await cubit.start('bud-tarjeta');
        // start() sets up the stream listener but does not await its first
        // emission; flush the pending microtasks so `_data` lands before the
        // next call.
        await pumpEventQueue();
        await cubit.scheduleAmountAdjustment(50000);
      },
      verify: (cubit) {
        expect(cubit.state.pendingAdjustment, adjustment);
        verify(
          () => scheduleBudgetAdjustment(
            'bud-tarjeta',
            newAmountMinor: 50000,
          ),
        ).called(1);
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'si el caso de uso falla no vuelve a refrescar pendingAdjustment',
      setUp: () {
        when(() => getBudgetById('bud-tarjeta'))
            .thenAnswer((_) => Stream.value(Right(data)));
        when(
          () => scheduleBudgetAdjustment(
            'bud-tarjeta',
            newAmountMinor: 50000,
          ),
        ).thenAnswer(
          (_) async => const Left(
            ValidationFailure(
              'budget already has a pending adjustment',
              field: 'amountMinor',
            ),
          ),
        );
      },
      build: build,
      act: (cubit) async {
        await cubit.start('bud-tarjeta');
        await pumpEventQueue();
        // The first refresh from start() already happened; count from here.
        clearInteractions(getPendingBudgetAdjustment);
        final result = await cubit.scheduleAmountAdjustment(50000);
        expect(result.isLeft(), isTrue);
      },
      verify: (_) => verifyNever(() => getPendingBudgetAdjustment(any())),
    );
  });

  group('updateAmountAdjustment (editar)', () {
    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'sin id cargado no invoca el caso de uso',
      build: build,
      verify: (cubit) async {
        final result = await cubit.updateAmountAdjustment(75000);
        expect(result.getRight().toNullable(), unit);
        verifyNever(
          () => updateBudgetAdjustment(
            any(),
            newAmountMinor: any(named: 'newAmountMinor'),
          ),
        );
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'con éxito reescribe el monto del fork y refresca pendingAdjustment',
      setUp: () {
        when(() => getBudgetById('bud-tarjeta'))
            .thenAnswer((_) => Stream.value(Right(data)));
        when(
          () => updateBudgetAdjustment(
            'bud-tarjeta',
            newAmountMinor: 75000,
          ),
        ).thenAnswer((_) async => const Right(unit));
        final edited = PendingBudgetAdjustment(
          newAmountMinor: 75000,
          effectiveFrom: DateTime(2025, 8, 21),
          resumeAmountMinor: 450000000,
          resumeFrom: DateTime(2025, 9, 21),
        );
        when(() => getPendingBudgetAdjustment('bud-tarjeta'))
            .thenAnswer((_) async => Right(edited));
      },
      build: build,
      act: (cubit) async {
        await cubit.start('bud-tarjeta');
        await pumpEventQueue();
        await cubit.updateAmountAdjustment(75000);
      },
      verify: (cubit) {
        expect(cubit.state.pendingAdjustment?.newAmountMinor, 75000);
        verify(
          () => updateBudgetAdjustment(
            'bud-tarjeta',
            newAmountMinor: 75000,
          ),
        ).called(1);
      },
    );
  });

  group('cancelAmountAdjustment (quitar ajuste)', () {
    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'sin id cargado no invoca el caso de uso',
      build: build,
      verify: (cubit) async {
        final result = await cubit.cancelAmountAdjustment();
        expect(result.getRight().toNullable(), unit);
        verifyNever(() => cancelBudgetAdjustment(any()));
      },
    );

    blocTest<BudgetDetailCubit, BudgetDetailState>(
      'con éxito cancela el fork y limpia pendingAdjustment',
      setUp: () {
        when(() => getBudgetById('bud-tarjeta'))
            .thenAnswer((_) => Stream.value(Right(data)));
        when(() => getPendingBudgetAdjustment('bud-tarjeta'))
            .thenAnswer((_) async => Right(adjustment));
        when(() => cancelBudgetAdjustment('bud-tarjeta'))
            .thenAnswer((_) async => const Right(unit));
      },
      build: build,
      act: (cubit) async {
        await cubit.start('bud-tarjeta');
        await pumpEventQueue();
        expect(cubit.state.pendingAdjustment, adjustment);
        // From here on, the budget has no pending fork any more.
        when(() => getPendingBudgetAdjustment('bud-tarjeta'))
            .thenAnswer((_) async => const Right(null));
        await cubit.cancelAmountAdjustment();
      },
      verify: (cubit) {
        expect(cubit.state.pendingAdjustment, isNull);
        verify(() => cancelBudgetAdjustment('bud-tarjeta')).called(1);
      },
    );
  });
}
