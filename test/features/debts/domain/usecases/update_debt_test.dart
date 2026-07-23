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
}
