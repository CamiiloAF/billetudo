import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/entities/goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal_quick_amount.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/domain/usecases/account_repository_mock.dart';
import 'goal_quick_amounts_repository_mock.dart';
import 'goal_repository_mock.dart';

Account _account({
  String id = 'acc1',
  String currency = 'USD',
}) =>
    Account(
      id: id,
      name: 'Cuenta',
      type: AccountType.bank,
      currency: currency,
      initialBalanceMinor: 0,
      archived: false,
      sortOrder: 0,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026).millisecondsSinceEpoch,
    );

Goal _goal({String currency = 'COP', String? accountId}) => Goal(
      id: 'g1',
      name: 'Meta',
      targetMinor: 100000,
      currency: currency,
      accountId: accountId,
      lastMilestonePct: 0,
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

GoalQuickAmount _quickAmount({required String goalId, required int amountMinor}) =>
    GoalQuickAmount(
      id: 'qa-$amountMinor',
      goalId: goalId,
      amountMinor: amountMinor,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026).millisecondsSinceEpoch,
    );

void main() {
  late MockGoalRepository repository;
  late MockAccountRepository accounts;
  late MockGoalQuickAmountsRepository quickAmounts;
  late CreateGoal usecase;

  setUpAll(() {
    registerGoalRepositoryFallbacks();
    registerAccountFallbacks();
  });

  setUp(() {
    repository = MockGoalRepository();
    accounts = MockAccountRepository();
    quickAmounts = MockGoalQuickAmountsRepository();
    usecase = CreateGoal(
      repository,
      accounts,
      CreateGoalQuickAmount(quickAmounts),
    );
    when(
      () => quickAmounts.createQuickAmount(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
      ),
    ).thenAnswer(
      (invocation) async => Right(
        _quickAmount(
          goalId: invocation.namedArguments[#goalId] as String,
          amountMinor: invocation.namedArguments[#amountMinor] as int,
        ),
      ),
    );
  });

  test('rejects an invalid draft before touching either repository',
      () async {
    final result = await usecase(
      const GoalDraft(name: '', targetMinor: 1000, currency: 'COP'),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => accounts.getAccount(any()));
    verifyNever(() => repository.createGoal(any()));
  });

  test('a nonexistent or tombstoned linked account is rejected (HU-02)',
      () async {
    when(() => accounts.getAccount('acc1')).thenAnswer(
      (_) async => const Left(NotFoundFailure('account does not exist')),
    );

    final result = await usecase(
      const GoalDraft(
        name: 'Viaje',
        targetMinor: 100000,
        currency: 'COP',
        accountId: 'acc1',
      ),
    );

    expect(result.isLeft(), isTrue);
    expect(result.getLeft().toNullable(), isA<NotFoundFailure>());
    verifyNever(() => repository.createGoal(any()));
  });

  test(
      'linking an account forces the goal currency to the account currency, '
      'overriding whatever the form carried', () async {
    when(() => accounts.getAccount('acc1'))
        .thenAnswer((_) async => Right(_account(currency: 'USD')));
    when(() => repository.createGoal(any()))
        .thenAnswer((_) async => Right(_goal(currency: 'USD', accountId: 'acc1')));

    final result = await usecase(
      const GoalDraft(
        name: 'Viaje',
        targetMinor: 100000,
        currency: 'COP',
        accountId: 'acc1',
      ),
    );

    expect(result.isRight(), isTrue);
    final captured =
        verify(() => repository.createGoal(captureAny())).captured.single
            as GoalDraft;
    expect(captured.currency, 'USD');
    expect(captured.accountId, 'acc1');
  });

  test('no linked account keeps the form currency untouched', () async {
    when(() => repository.createGoal(any()))
        .thenAnswer((_) async => Right(_goal()));

    final result = await usecase(
      const GoalDraft(name: 'Colchón', targetMinor: 500000, currency: 'cop'),
    );

    expect(result.isRight(), isTrue);
    verifyNever(() => accounts.getAccount(any()));
    final captured =
        verify(() => repository.createGoal(captureAny())).captured.single
            as GoalDraft;
    expect(captured.currency, 'COP');
  });

  test(
      r'seeds the two default $50.000/$100.000 quick-amount chips after '
      'successfully creating the goal', () async {
    when(() => repository.createGoal(any()))
        .thenAnswer((_) async => Right(_goal()));

    final result = await usecase(
      const GoalDraft(name: 'Colchón', targetMinor: 500000, currency: 'COP'),
    );

    expect(result.isRight(), isTrue);
    verify(
      () => quickAmounts.createQuickAmount(goalId: 'g1', amountMinor: 5000000),
    ).called(1);
    verify(
      () => quickAmounts.createQuickAmount(
        goalId: 'g1',
        amountMinor: 10000000,
      ),
    ).called(1);
  });

  test('does not seed any quick-amount chip when creation fails', () async {
    when(() => repository.createGoal(any())).thenAnswer(
      (_) async => const Left(DatabaseFailure('disco lleno')),
    );

    final result = await usecase(
      const GoalDraft(name: 'Colchón', targetMinor: 500000, currency: 'COP'),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(
      () => quickAmounts.createQuickAmount(
        goalId: any(named: 'goalId'),
        amountMinor: any(named: 'amountMinor'),
      ),
    );
  });
}
