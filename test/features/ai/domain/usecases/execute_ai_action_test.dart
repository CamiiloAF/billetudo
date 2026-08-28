import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/ai/domain/entities/ai_action_outcome.dart';
import 'package:billetudo/features/ai/domain/usecases/execute_ai_action.dart';
import 'package:billetudo/features/budgets/domain/entities/budget.dart';
import 'package:billetudo/features/budgets/domain/entities/budget_draft.dart';
import 'package:billetudo/features/budgets/domain/usecases/create_budget.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/categories/domain/entities/category_draft.dart';
import 'package:billetudo/features/categories/domain/usecases/create_category.dart';
import 'package:billetudo/features/categories/domain/usecases/get_category.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/usecases/link_transaction_to_debt.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction_draft.dart';
import 'package:billetudo/features/transactions/domain/usecases/create_transaction.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/account_fixtures.dart';
import '../../../accounts/domain/usecases/account_repository_mock.dart';
import '../../../categories/domain/usecases/category_repository_mock.dart';
import '../../../debts/domain/debt_test_fixtures.dart';
import '../../../debts/domain/usecases/debt_repository_mock.dart';
import '../../../transactions/transaction_fixtures.dart' show buildTransaction;
import '../../ai_fixtures.dart';

class MockCreateBudget extends Mock implements CreateBudget {}

class MockCreateGoal extends Mock implements CreateGoal {}

class MockCreateCategory extends Mock implements CreateCategory {}

class MockCreateTransaction extends Mock implements CreateTransaction {}

class MockGetCategory extends Mock implements GetCategory {}

class MockLinkTransactionToDebt extends Mock implements LinkTransactionToDebt {}

/// The only place a suggestion becomes a row. It does not re-validate what the
/// drafts already validate; what it owns is the referential work a draft
/// cannot do, and the asymmetry between a budget (a stale id is filtered) and
/// a transaction (a stale id fails the action).
void main() {
  late MockCreateBudget createBudget;
  late MockCreateGoal createGoal;
  late MockCreateCategory createCategory;
  late MockCreateTransaction createTransaction;
  late MockGetCategory getCategory;
  late MockAccountRepository accounts;
  late MockLinkTransactionToDebt linkTransactionToDebt;
  late MockDebtRepository debts;
  late ExecuteAiAction usecase;

  final budget = Budget(
    id: 'budget-created',
    name: 'Comida',
    amountMinor: 45000000,
    currency: 'COP',
    period: BudgetPeriod.monthly,
    startDate: DateTime(2026, 8),
    recurring: true,
    rollover: false,
    createdAt: DateTime(2026, 8),
    updatedAt: 0,
  );

  final goal = Goal(
    id: 'goal-created',
    name: 'Viaje',
    targetMinor: 600000000,
    currency: 'COP',
    lastMilestonePct: 0,
    createdAt: DateTime(2026, 8),
    updatedAt: 0,
  );

  setUpAll(() {
    registerAccountFallbacks();
    registerCategoryFallbacks();
    registerDebtFallbacks();
    registerFallbackValue(
      BudgetDraft(
        name: 'fallback',
        amountMinor: 100,
        currency: 'COP',
        period: BudgetPeriod.monthly,
        startDate: DateTime(2026),
        recurring: true,
      ),
    );
    registerFallbackValue(
      const GoalDraft(name: 'fallback', targetMinor: 100, currency: 'COP'),
    );
    registerFallbackValue(
      TransactionDraft(
        accountId: 'acc-1',
        amountMinor: 100,
        currency: 'COP',
        type: TransactionType.expense,
        date: DateTime(2026),
      ),
    );
  });

  setUp(() {
    createBudget = MockCreateBudget();
    createGoal = MockCreateGoal();
    createCategory = MockCreateCategory();
    createTransaction = MockCreateTransaction();
    getCategory = MockGetCategory();
    accounts = MockAccountRepository();
    linkTransactionToDebt = MockLinkTransactionToDebt();
    debts = MockDebtRepository();
    usecase = ExecuteAiAction(
      createBudget,
      createGoal,
      createCategory,
      createTransaction,
      getCategory,
      accounts,
      linkTransactionToDebt,
      debts,
    );
  });

  group('create_budget', () {
    test('writes the budget and reports the created row', () async {
      when(() => createBudget(any())).thenAnswer((_) async => Right(budget));

      final result = await usecase(buildBudgetProposal());

      expect(
        result.getRight().toNullable(),
        const AiActionOutcome(
          proposalId: 'tc_0_0',
          entity: AiActionEntity.budget,
          entityId: 'budget-created',
        ),
      );
    });

    test('drops hallucinated category and account ids instead of failing the '
        'whole action', () async {
      when(() => getCategory('cat-real'))
          .thenAnswer((_) async => Right(buildCategory(id: 'cat-real')));
      when(() => getCategory('cat-ghost')).thenAnswer(
        (_) async => const Left(NotFoundFailure('no category with that id')),
      );
      when(() => accounts.getAccount('acc-real'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-real')));
      when(() => accounts.getAccount('acc-ghost')).thenAnswer(
        (_) async => const Left(NotFoundFailure('no account with that id')),
      );
      when(() => createBudget(any())).thenAnswer((_) async => Right(budget));

      final result = await usecase(
        buildBudgetProposal(
          categoryIds: {'cat-real', 'cat-ghost'},
          accountIds: {'acc-real', 'acc-ghost'},
        ),
      );

      final draft =
          verify(() => createBudget(captureAny())).captured.single as BudgetDraft;
      expect(draft.categoryIds, {'cat-real'});
      expect(draft.accountIds, {'acc-real'});
      expect(result.isRight(), isTrue);
    });

    test('passes the amount through as integer minor units', () async {
      when(() => createBudget(any())).thenAnswer((_) async => Right(budget));

      await usecase(buildBudgetProposal(amountMinor: 45000000));

      final draft =
          verify(() => createBudget(captureAny())).captured.single as BudgetDraft;
      expect(draft.amountMinor, 45000000);
      expect(draft.currency, 'COP');
    });

    test('propagates the write failure unwrapped', () async {
      const failure = DatabaseFailure('budget insert failed');
      when(() => createBudget(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(buildBudgetProposal());

      expect(result.getLeft().toNullable(), same(failure));
    });
  });

  group('create_goal', () {
    test('writes the goal and reports the created row', () async {
      when(() => createGoal(any())).thenAnswer((_) async => Right(goal));

      final result = await usecase(
        buildGoalProposal(accountId: 'acc-1', targetDate: DateTime(2027)),
      );

      expect(
        result.getRight().toNullable(),
        const AiActionOutcome(
          proposalId: 'tc_0_1',
          entity: AiActionEntity.goal,
          entityId: 'goal-created',
        ),
      );
      final draft =
          verify(() => createGoal(captureAny())).captured.single as GoalDraft;
      expect(draft.targetMinor, 600000000);
      expect(draft.accountId, 'acc-1');
      expect(draft.targetDate, DateTime(2027));
    });

    test('propagates a validation failure from CreateGoal unwrapped', () async {
      const failure = ValidationFailure('account not found', field: 'accountId');
      when(() => createGoal(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(buildGoalProposal());

      expect(result.getLeft().toNullable(), same(failure));
    });
  });

  group('create_category', () {
    test('writes the category and reports the created row', () async {
      when(() => createCategory(any())).thenAnswer(
        (_) async => Right(buildCategory(id: 'cat-created')),
      );

      final result = await usecase(
        buildCategoryProposal(parentId: 'cat-root', kind: CategoryKind.income),
      );

      expect(
        result.getRight().toNullable(),
        const AiActionOutcome(
          proposalId: 'tc_0_2',
          entity: AiActionEntity.category,
          entityId: 'cat-created',
        ),
      );
      final draft = verify(() => createCategory(captureAny())).captured.single
          as CategoryDraft;
      expect(draft.parentId, 'cat-root');
      expect(draft.kind, CategoryKind.income);
    });
  });

  group('create_transaction', () {
    test('resolves the category kind the draft demands from the bare id',
        () async {
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => getCategory('cat-salary')).thenAnswer(
        (_) async => Right(
          buildCategory(id: 'cat-salary', kind: CategoryKind.income),
        ),
      );
      when(() => createTransaction(any())).thenAnswer(
        (_) async => Right(buildTransaction(id: 'tx-created')),
      );

      final result = await usecase(
        buildTransactionProposal(
          categoryId: 'cat-salary',
          type: TransactionType.income,
        ),
      );

      final draft = verify(() => createTransaction(captureAny()))
          .captured
          .single as TransactionDraft;
      expect(draft.categoryId, 'cat-salary');
      expect(draft.categoryKind, CategoryKind.income);
      expect(draft.amountMinor, 4500000);
      expect(
        result.getRight().toNullable(),
        const AiActionOutcome(
          proposalId: 'tc_0_3',
          entity: AiActionEntity.transaction,
          entityId: 'tx-created',
        ),
      );
    });

    test('a transaction with no category leaves the kind unresolved', () async {
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => createTransaction(any())).thenAnswer(
        (_) async => Right(buildTransaction(id: 'tx-created')),
      );

      await usecase(buildTransactionProposal());

      final draft = verify(() => createTransaction(captureAny()))
          .captured
          .single as TransactionDraft;
      expect(draft.categoryId, isNull);
      expect(draft.categoryKind, isNull);
      verifyNever(() => getCategory(any()));
    });

    test('an unknown accountId fails as a validation error on that field',
        () async {
      when(() => accounts.getAccount('acc-ghost')).thenAnswer(
        (_) async => const Left(NotFoundFailure('no account with that id')),
      );

      final result = await usecase(
        buildTransactionProposal(accountId: 'acc-ghost'),
      );

      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>()
            .having((f) => f.field, 'field', TransactionDraft.fieldAccountId),
      );
      verifyNever(() => createTransaction(any()));
    });

    test('an unknown categoryId fails as a validation error on that field',
        () async {
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => getCategory('cat-ghost')).thenAnswer(
        (_) async => const Left(NotFoundFailure('no category with that id')),
      );

      final result = await usecase(
        buildTransactionProposal(categoryId: 'cat-ghost'),
      );

      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>()
            .having((f) => f.field, 'field', TransactionDraft.fieldCategoryId),
      );
      verifyNever(() => createTransaction(any()));
    });

    test('a database failure looking up the account is propagated as is',
        () async {
      const failure = DatabaseFailure('accounts table unreadable');
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(buildTransactionProposal());

      expect(result.getLeft().toNullable(), same(failure));
    });

    test('the write failure is propagated without being wrapped', () async {
      const failure = DatabaseFailure('transaction insert failed');
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => createTransaction(any()))
          .thenAnswer((_) async => const Left(failure));

      final result = await usecase(buildTransactionProposal());

      expect(result.getLeft().toNullable(), same(failure));
    });

    test('the note the user dictated reaches the draft verbatim', () async {
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => createTransaction(any())).thenAnswer(
        (_) async => Right(buildTransaction(id: 'tx-created')),
      );

      await usecase(buildTransactionProposal(note: 'almuerzo con Ana'));

      final draft = verify(() => createTransaction(captureAny()))
          .captured
          .single as TransactionDraft;
      expect(draft.note, 'almuerzo con Ana');
    });
  });

  group('create_transaction attributed to a debt', () {
    void stubAccount() {
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => createTransaction(any())).thenAnswer(
        (_) async => Right(buildTransaction(id: 'tx-created')),
      );
    }

    test('the movement is born linked: debtId reaches the draft', () async {
      stubAccount();
      when(() => debts.getDebt('debt-1')).thenAnswer(
        (_) async => Right(buildDebt(id: 'debt-1')),
      );

      final result = await usecase(
        buildTransactionProposal(debtId: 'debt-1'),
      );

      final draft = verify(() => createTransaction(captureAny()))
          .captured
          .single as TransactionDraft;
      expect(draft.debtId, 'debt-1');
      expect(result.isRight(), isTrue);
      // One write, one confirmation: linking afterwards would be a second
      // one the user never agreed to.
      verifyNever(
        () => linkTransactionToDebt(
          transactionId: any(named: 'transactionId'),
          debtId: any(named: 'debtId'),
        ),
      );
    });

    test('a repago recibido (owedToMe + income) counts in the budget',
        () async {
      stubAccount();
      when(() => debts.getDebt('debt-1')).thenAnswer(
        (_) async => Right(
          buildDebt(id: 'debt-1', direction: DebtDirection.owedToMe),
        ),
      );

      await usecase(
        buildTransactionProposal(
          debtId: 'debt-1',
          type: TransactionType.income,
          categoryId: null,
        ),
      );

      final draft = verify(() => createTransaction(captureAny()))
          .captured
          .single as TransactionDraft;
      expect(draft.countsInBudget, isTrue);
    });

    test('a closed debt is refused and nothing is written', () async {
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => debts.getDebt('debt-1')).thenAnswer(
        (_) async => Right(
          buildDebt(id: 'debt-1', closedAt: DateTime(2026, 7)),
        ),
      );

      final result = await usecase(
        buildTransactionProposal(debtId: 'debt-1'),
      );

      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'debtId'),
      );
      verifyNever(() => createTransaction(any()));
    });

    test('an unknown debtId fails on that field instead of dropping the link',
        () async {
      when(() => accounts.getAccount('acc-1'))
          .thenAnswer((_) async => Right(buildAccount(id: 'acc-1')));
      when(() => debts.getDebt('debt-ghost')).thenAnswer(
        (_) async => const Left(NotFoundFailure('no debt with that id')),
      );

      final result = await usecase(
        buildTransactionProposal(debtId: 'debt-ghost'),
      );

      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'debtId'),
      );
      verifyNever(() => createTransaction(any()));
    });
  });

  group('link_transaction_to_debt', () {
    test('delegates to LinkTransactionToDebt and creates nothing', () async {
      when(
        () => linkTransactionToDebt(
          transactionId: 'tx-1',
          debtId: 'debt-1',
        ),
      ).thenAnswer((_) async => const Right(unit));

      final result = await usecase(buildDebtLinkProposal());

      expect(
        result.getRight().toNullable(),
        const AiActionOutcome(
          proposalId: 'tc_0_5',
          entity: AiActionEntity.debtLink,
          entityId: 'debt-1',
        ),
      );
      verifyNever(() => createTransaction(any()));
    });

    test('a closed debt surfaces as a failure, never as an applied link',
        () async {
      when(
        () => linkTransactionToDebt(
          transactionId: 'tx-1',
          debtId: 'debt-closed',
        ),
      ).thenAnswer(
        (_) async => const Left(
          ValidationFailure(
            'a closed debt accepts no new links',
            field: 'closedAt',
          ),
        ),
      );

      final result = await usecase(
        buildDebtLinkProposal(debtId: 'debt-closed'),
      );

      expect(result.isLeft(), isTrue);
      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having((f) => f.field, 'field', 'closedAt'),
      );
      verifyNever(() => createTransaction(any()));
    });
  });

  group('unsupported proposal', () {
    test('is refused without touching any writer', () async {
      final result = await usecase(
        buildUnsupportedProposal(rawKind: 'create_spaceship'),
      );

      expect(
        result.getLeft().toNullable(),
        isA<ValidationFailure>().having(
          (f) => f.message,
          'message',
          contains('create_spaceship'),
        ),
      );
      verifyNever(() => createBudget(any()));
      verifyNever(() => createGoal(any()));
      verifyNever(() => createCategory(any()));
      verifyNever(() => createTransaction(any()));
    });
  });
}
