import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/update_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/domain/usecases/account_repository_mock.dart';
import 'goal_repository_mock.dart';

Account _account({String id = 'acc2', String currency = 'USD'}) => Account(
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

Goal _goal({
  String id = 'g1',
  String currency = 'COP',
  String? accountId,
}) =>
    Goal(
      id: id,
      name: 'Meta',
      targetMinor: 100000,
      currency: currency,
      accountId: accountId,
      lastMilestonePct: 0,
      createdAt: DateTime(2026),
      updatedAt: 0,
    );

void main() {
  late MockGoalRepository repository;
  late MockAccountRepository accounts;
  late UpdateGoal usecase;

  setUpAll(() {
    registerGoalRepositoryFallbacks();
    registerAccountFallbacks();
  });

  setUp(() {
    repository = MockGoalRepository();
    accounts = MockAccountRepository();
    usecase = UpdateGoal(repository, accounts);
  });

  test('rejects a draft without an id before validating', () async {
    final result = await usecase(
      const GoalDraft(name: 'Meta', targetMinor: 1000, currency: 'COP'),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      GoalDraft.fieldId,
    );
    verifyNever(() => repository.updateGoal(any()));
  });

  test('a nonexistent or tombstoned new linked account is rejected',
      () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal()));
    when(() => accounts.getAccount('acc2')).thenAnswer(
      (_) async => const Left(NotFoundFailure('account does not exist')),
    );

    final result = await usecase(
      const GoalDraft(
        id: 'g1',
        name: 'Meta',
        targetMinor: 100000,
        currency: 'COP',
        accountId: 'acc2',
      ),
    );

    expect(result.isLeft(), isTrue);
    verifyNever(() => repository.updateGoal(any()));
  });

  test(
      'switching to an account of a different currency is blocked once the '
      'goal already has movements (HU-02)', () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(currency: 'COP')));
    when(() => accounts.getAccount('acc2'))
        .thenAnswer((_) async => Right(_account(currency: 'USD')));
    when(() => repository.hasContributions('g1'))
        .thenAnswer((_) async => const Right(true));

    final result = await usecase(
      const GoalDraft(
        id: 'g1',
        name: 'Meta',
        targetMinor: 100000,
        currency: 'COP',
        accountId: 'acc2',
      ),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      GoalDraft.fieldCurrency,
    );
    verifyNever(() => repository.updateGoal(any()));
  });

  test(
      'switching to an account of a different currency is allowed when the '
      'goal has no movements yet, forcing the account currency', () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(currency: 'COP')));
    when(() => accounts.getAccount('acc2'))
        .thenAnswer((_) async => Right(_account(currency: 'USD')));
    when(() => repository.hasContributions('g1'))
        .thenAnswer((_) async => const Right(false));
    when(() => repository.updateGoal(any()))
        .thenAnswer((_) async => Right(_goal(currency: 'USD', accountId: 'acc2')));

    final result = await usecase(
      const GoalDraft(
        id: 'g1',
        name: 'Meta',
        targetMinor: 100000,
        currency: 'COP',
        accountId: 'acc2',
      ),
    );

    expect(result.isRight(), isTrue);
    final captured =
        verify(() => repository.updateGoal(captureAny())).captured.single
            as GoalDraft;
    expect(captured.currency, 'USD');
  });

  test('same currency account switch never checks contribution history',
      () async {
    when(() => repository.getGoal('g1'))
        .thenAnswer((_) async => Right(_goal(currency: 'USD')));
    when(() => accounts.getAccount('acc2'))
        .thenAnswer((_) async => Right(_account(currency: 'USD')));
    when(() => repository.updateGoal(any()))
        .thenAnswer((_) async => Right(_goal(currency: 'USD', accountId: 'acc2')));

    final result = await usecase(
      const GoalDraft(
        id: 'g1',
        name: 'Meta',
        targetMinor: 100000,
        currency: 'USD',
        accountId: 'acc2',
      ),
    );

    expect(result.isRight(), isTrue);
    verifyNever(() => repository.hasContributions(any()));
  });
}
