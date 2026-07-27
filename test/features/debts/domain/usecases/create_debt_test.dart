import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/entities/debt.dart';
import 'package:billetudo/features/debts/domain/entities/debt_draft.dart';
import 'package:billetudo/features/debts/domain/usecases/create_debt.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debt_repository_mock.dart';

void main() {
  late MockDebtRepository repository;
  late CreateDebt usecase;

  setUpAll(registerDebtFallbacks);

  setUp(() {
    repository = MockDebtRepository();
    usecase = CreateDebt(repository);
  });

  final debt = Debt(
    id: 'd1',
    name: 'Crédito carro',
    direction: DebtDirection.iOwe,
    principalMinor: 5000000,
    currency: 'COP',
    accrualMode: DebtAccrualMode.manual,
    createdAt: DateTime(2026),
    updatedAt: 0,
  );

  test('persists a valid, normalized draft', () async {
    when(() => repository.createDebt(any()))
        .thenAnswer((_) async => Right(debt));

    final result = await usecase(
      const DebtDraft(
        name: '  Crédito carro  ',
        direction: DebtDirection.iOwe,
        principalMinor: 5000000,
        currency: 'cop',
      ),
    );

    expect(result.isRight(), isTrue);
    final captured =
        verify(() => repository.createDebt(captureAny())).captured.single
            as DebtDraft;
    expect(captured.name, 'Crédito carro'); // trimmed
    expect(captured.currency, 'COP'); // upper-cased
  });

  test('rejects an empty name without touching the repository', () async {
    final result = await usecase(
      const DebtDraft(
        name: '   ',
        direction: DebtDirection.iOwe,
        principalMinor: 1000,
        currency: 'COP',
      ),
    );

    expect(result.getLeft().toNullable(), isA<ValidationFailure>());
    verifyNever(() => repository.createDebt(any()));
  });

  test('rejects a negative opening balance', () async {
    final result = await usecase(
      const DebtDraft(
        name: 'Deuda',
        direction: DebtDirection.iOwe,
        principalMinor: -1,
        currency: 'COP',
      ),
    );

    expect(
      (result.getLeft().toNullable()! as ValidationFailure).field,
      DebtDraft.fieldPrincipalMinor,
    );
    verifyNever(() => repository.createDebt(any()));
  });
}
