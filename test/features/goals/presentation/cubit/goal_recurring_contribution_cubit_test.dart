import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart'
    show CategoryKind;
import 'package:billetudo/features/goals/domain/services/goal_category_seed.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal_recurring_contribution.dart';
import 'package:billetudo/features/goals/domain/usecases/get_linkable_scheduled_payments.dart';
import 'package:billetudo/features/goals/domain/usecases/link_scheduled_payment_to_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_state.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart'
    show ScheduledPaymentFrequency;
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../scheduled_payments/scheduled_payment_fixtures.dart';

class MockWatchAccounts extends Mock implements WatchAccounts {}

class MockCreateGoalRecurringContribution extends Mock
    implements CreateGoalRecurringContribution {}

class MockLinkScheduledPaymentToGoal extends Mock
    implements LinkScheduledPaymentToGoal {}

class MockGetLinkableScheduledPayments extends Mock
    implements GetLinkableScheduledPayments {}

void main() {
  late MockWatchAccounts watchAccounts;
  late MockCreateGoalRecurringContribution createGoalRecurringContribution;
  late MockLinkScheduledPaymentToGoal linkScheduledPaymentToGoal;
  late MockGetLinkableScheduledPayments getLinkableScheduledPayments;

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Nequi'),
      balanceMinor: 500000,
    ),
  ];

  setUpAll(() {
    registerFallbackValue(ScheduledPaymentFrequency.monthly);
    registerFallbackValue(DateTime(2026));
  });

  setUp(() {
    watchAccounts = MockWatchAccounts();
    createGoalRecurringContribution = MockCreateGoalRecurringContribution();
    linkScheduledPaymentToGoal = MockLinkScheduledPaymentToGoal();
    getLinkableScheduledPayments = MockGetLinkableScheduledPayments();
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(Right<Failure, List<AccountWithBalance>>(accounts)),
    );
  });

  GoalRecurringContributionCubit build() => GoalRecurringContributionCubit(
        watchAccounts,
        createGoalRecurringContribution,
        linkScheduledPaymentToGoal,
        getLinkableScheduledPayments,
      );

  blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
    'start carga las cuentas, preselecciona la primera y la categoría '
    '"Ahorros"',
    build: build,
    act: (cubit) => cubit.start(
      goalId: 'g1',
      goalName: 'Viaje a Cartagena',
      currency: 'COP',
    ),
    verify: (cubit) {
      expect(cubit.state.status, GoalRecurringContributionStatus.ready);
      expect(cubit.state.accounts, accounts);
      expect(cubit.state.selectedAccountId, 'a1');
      expect(cubit.state.categoryId, GoalCategorySeed.savingsCategoryId);
      expect(cubit.state.countsInBudget, isTrue);
    },
  );

  group('submitCreate', () {
    blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
      'crea el aporte recurrente y expone el id del pago programado creado',
      build: build,
      setUp: () => when(
        () => createGoalRecurringContribution(
          goalId: any(named: 'goalId'),
          accountId: any(named: 'accountId'),
          amountMinor: any(named: 'amountMinor'),
          currency: any(named: 'currency'),
          frequency: any(named: 'frequency'),
          nextDate: any(named: 'nextDate'),
          interval: any(named: 'interval'),
          categoryId: any(named: 'categoryId'),
          categoryKind: any(named: 'categoryKind'),
        ),
      ).thenAnswer(
        (_) async => Right(buildScheduledPayment(id: 'sp-1', goalId: 'g1')),
      ),
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          currency: 'COP',
        );
        cubit.amountChanged(50000);
        await cubit.submitCreate();
      },
      verify: (cubit) {
        expect(cubit.state.status, GoalRecurringContributionStatus.saved);
        expect(cubit.state.createdScheduledPaymentId, 'sp-1');
        verify(
          () => createGoalRecurringContribution(
            goalId: 'g1',
            accountId: 'a1',
            amountMinor: 50000,
            currency: 'COP',
            frequency: any(named: 'frequency'),
            nextDate: any(named: 'nextDate'),
            interval: any(named: 'interval'),
            categoryId: GoalCategorySeed.savingsCategoryId,
            categoryKind: CategoryKind.expense,
          ),
        ).called(1);
      },
    );

    blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
      'una falla deja el estado en failure',
      build: build,
      setUp: () => when(
        () => createGoalRecurringContribution(
          goalId: any(named: 'goalId'),
          accountId: any(named: 'accountId'),
          amountMinor: any(named: 'amountMinor'),
          currency: any(named: 'currency'),
          frequency: any(named: 'frequency'),
          nextDate: any(named: 'nextDate'),
          interval: any(named: 'interval'),
          categoryId: any(named: 'categoryId'),
          categoryKind: any(named: 'categoryKind'),
        ),
      ).thenAnswer((_) async => const Left(UnexpectedFailure('nope'))),
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          currency: 'COP',
        );
        cubit.amountChanged(50000);
        await cubit.submitCreate();
      },
      verify: (cubit) {
        expect(cubit.state.status, GoalRecurringContributionStatus.failure);
        expect(cubit.state.failure, isNotNull);
      },
    );

    blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
      'sin cuenta seleccionada no llama al caso de uso',
      build: build,
      act: (cubit) => cubit.submitCreate(),
      verify: (_) => verifyNever(
        () => createGoalRecurringContribution(
          goalId: any(named: 'goalId'),
          accountId: any(named: 'accountId'),
          amountMinor: any(named: 'amountMinor'),
          currency: any(named: 'currency'),
          frequency: any(named: 'frequency'),
          nextDate: any(named: 'nextDate'),
          interval: any(named: 'interval'),
          categoryId: any(named: 'categoryId'),
          categoryKind: any(named: 'categoryKind'),
        ),
      ),
    );
  });

  blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
    'toggleCountsInBudget en false limpia la categoría; en true la restaura '
    'a "Ahorros"',
    build: build,
    act: (cubit) {
      cubit.toggleCountsInBudget(false);
      cubit.toggleCountsInBudget(true);
    },
    expect: () => [
      isA<GoalRecurringContributionState>()
          .having((s) => s.countsInBudget, 'countsInBudget', isFalse)
          .having((s) => s.categoryId, 'categoryId', isNull),
      isA<GoalRecurringContributionState>()
          .having((s) => s.countsInBudget, 'countsInBudget', isTrue)
          .having(
            (s) => s.categoryId,
            'categoryId',
            GoalCategorySeed.savingsCategoryId,
          ),
    ],
  );

  group('watchLinkablePayments', () {
    blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
      'expone los pagos programados enlazables emitidos por el stream',
      build: build,
      setUp: () {
        final summary = ScheduledPaymentSummary(
          scheduledPayment: buildScheduledPayment(id: 'sp-1'),
          accountName: 'Nequi',
        );
        when(() => getLinkableScheduledPayments()).thenAnswer(
          (_) => Stream.value(
            Right<Failure, List<ScheduledPaymentSummary>>([summary]),
          ),
        );
      },
      act: (cubit) => cubit.watchLinkablePayments(),
      expect: () => [
        isA<GoalRecurringContributionState>().having(
          (s) => s.linkablePayments.map((p) => p.scheduledPayment.id),
          'linkablePayments',
          ['sp-1'],
        ),
      ],
    );
  });

  group('linkExisting', () {
    blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
      'enlaza el pago programado existente y expone su id',
      build: build,
      setUp: () => when(
        () => linkScheduledPaymentToGoal(
          goalId: any(named: 'goalId'),
          scheduledPaymentId: any(named: 'scheduledPaymentId'),
        ),
      ).thenAnswer(
        (_) async => Right(buildScheduledPayment(id: 'sp-2', goalId: 'g1')),
      ),
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          currency: 'COP',
        );
        await cubit.linkExisting('sp-2');
      },
      verify: (cubit) {
        expect(cubit.state.status, GoalRecurringContributionStatus.saved);
        expect(cubit.state.createdScheduledPaymentId, 'sp-2');
      },
    );

    blocTest<GoalRecurringContributionCubit, GoalRecurringContributionState>(
      'una falla al enlazar deja el estado en failure',
      build: build,
      setUp: () => when(
        () => linkScheduledPaymentToGoal(
          goalId: any(named: 'goalId'),
          scheduledPaymentId: any(named: 'scheduledPaymentId'),
        ),
      ).thenAnswer((_) async => const Left(UnexpectedFailure('nope'))),
      act: (cubit) async {
        await cubit.start(
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          currency: 'COP',
        );
        await cubit.linkExisting('sp-2');
      },
      verify: (cubit) {
        expect(cubit.state.status, GoalRecurringContributionStatus.failure);
      },
    );
  });
}
