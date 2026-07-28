import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account.dart';
import 'package:billetudo/features/goals/domain/entities/goal.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:billetudo/features/goals/domain/usecases/create_goal.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../accounts/domain/usecases/account_repository_mock.dart';
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

void main() {
  late MockGoalRepository repository;
  late MockAccountRepository accounts;
  late CreateGoal usecase;

  setUpAll(() {
    registerGoalRepositoryFallbacks();
    registerAccountFallbacks();
  });

  setUp(() {
    repository = MockGoalRepository();
    accounts = MockAccountRepository();
    usecase = CreateGoal(repository, accounts);
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
}
