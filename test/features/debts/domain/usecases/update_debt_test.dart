import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/domain/usecases/update_debt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late UpdateDebt usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = UpdateDebt(repository);
  });

  test('rejects a draft without an id before validating', () async {
    final result = await usecase(
      const DebtDraft(
        name: 'Deuda',
        direction: DebtDirection.iOwe,
        principalMinor: 1000,
        currency: 'COP',
      ),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldId,
    );
    verifyNever(() => repository.updateDebt(any()));
  });

  test('persists a valid edit', () async {
    final debt = Debt(
      id: 'd1',
      name: 'Deuda',
      direction: DebtDirection.iOwe,
      principalMinor: 2000,
      currency: 'COP',
      accrualMode: DebtAccrualMode.manual,
      createdAt: DateTime(2026),
      updatedAt: 0,
    );
    when(() => repository.updateDebt(any()))
        .thenAnswer((_) async => Right(debt));

    final result = await usecase(
      const DebtDraft(
        id: 'd1',
        name: 'Deuda',
        direction: DebtDirection.iOwe,
        principalMinor: 2000,
        currency: 'COP',
      ),
    );

    expect(result.isRight(), isTrue);
    verify(() => repository.updateDebt(any())).called(1);
  });

  group('fix 9 (scenario 2): direction-change guard', () {
    test(
        'rejects a direction change when the debt has movements beyond its '
        'opening, without ever touching the repository', () async {
      final result = await usecase(
        const DebtDraft(
          id: 'd1',
          name: 'Deuda',
          direction: DebtDirection.owedToMe,
          principalMinor: 2000,
          currency: 'COP',
        ),
        directionChanged: true,
        hasNonOpeningMovements: true,
      );

      expect(
        (result.getLeft().toNullable()! as ValidationFailure).field,
        DebtDraft.fieldDirection,
      );
      verifyNever(() => repository.updateDebt(any()));
    });

    test(
        'allows a direction change when the debt has no movements beyond its '
        'opening', () async {
      final debt = Debt(
        id: 'd1',
        name: 'Deuda',
        direction: DebtDirection.owedToMe,
        principalMinor: 2000,
        currency: 'COP',
        accrualMode: DebtAccrualMode.manual,
        createdAt: DateTime(2026),
        updatedAt: 0,
      );
      when(() => repository.updateDebt(any()))
          .thenAnswer((_) async => Right(debt));

      final result = await usecase(
        const DebtDraft(
          id: 'd1',
          name: 'Deuda',
          direction: DebtDirection.owedToMe,
          principalMinor: 2000,
          currency: 'COP',
        ),
        directionChanged: true,
        hasNonOpeningMovements: false,
      );

      expect(result.isRight(), isTrue);
      verify(() => repository.updateDebt(any())).called(1);
    });

    test('allows any edit when direction did not change, movements or not',
        () async {
      final debt = Debt(
        id: 'd1',
        name: 'Deuda',
        direction: DebtDirection.iOwe,
        principalMinor: 2000,
        currency: 'COP',
        accrualMode: DebtAccrualMode.manual,
        createdAt: DateTime(2026),
        updatedAt: 0,
      );
      when(() => repository.updateDebt(any()))
          .thenAnswer((_) async => Right(debt));

      final result = await usecase(
        const DebtDraft(
          id: 'd1',
          name: 'Deuda',
          direction: DebtDirection.iOwe,
          principalMinor: 2000,
          currency: 'COP',
        ),
        hasNonOpeningMovements: true,
      );

      expect(result.isRight(), isTrue);
    });
  });
}
