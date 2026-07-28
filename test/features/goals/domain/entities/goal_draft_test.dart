import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/goals/domain/entities/goal_draft.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  ValidationFailure failureOf(Result<GoalDraft> result) =>
      result.getLeft().toNullable()! as ValidationFailure;

  const validDraft = GoalDraft(
    name: 'Vacaciones',
    targetMinor: 500000,
    currency: 'cop',
  );

  test('un draft válido normaliza la moneda a mayúsculas', () {
    final result = validDraft.validated();

    expect(result.isRight(), isTrue);
    expect(result.getRight().toNullable()!.currency, 'COP');
  });

  test('rechaza un nombre vacío', () {
    final result = validDraft.copyWithName('   ').validated();

    expect(failureOf(result).field, GoalDraft.fieldName);
  });

  test('rechaza un targetMinor cero o negativo', () {
    for (final amount in [0, -1]) {
      final result = GoalDraft(
        name: 'Meta',
        targetMinor: amount,
        currency: 'COP',
      ).validated();

      expect(failureOf(result).field, GoalDraft.fieldTargetMinor);
    }
  });

  test(
    'HU-01: al crear, una targetDate que ya pasó se rechaza',
    () {
      final result = GoalDraft(
        name: 'Meta',
        targetMinor: 100000,
        currency: 'COP',
        targetDate: DateTime.now().subtract(const Duration(days: 1)),
      ).validated(requireFutureTargetDate: true);

      expect(failureOf(result).field, GoalDraft.fieldTargetDate);
    },
  );

  test('al editar, una targetDate ya vencida no se re-valida (HU-05)', () {
    final result = GoalDraft(
      name: 'Meta',
      targetMinor: 100000,
      currency: 'COP',
      targetDate: DateTime.now().subtract(const Duration(days: 1)),
    ).validated();

    expect(result.isRight(), isTrue);
  });

  test('rechaza un avance inicial negativo', () {
    final result = const GoalDraft(
      name: 'Meta',
      targetMinor: 100000,
      currency: 'COP',
      initialSavedMinor: -1,
    ).validated();

    expect(failureOf(result).field, GoalDraft.fieldInitialSavedMinor);
  });
}

extension on GoalDraft {
  GoalDraft copyWithName(String name) => GoalDraft(
        id: id,
        name: name,
        targetMinor: targetMinor,
        currency: currency,
        accountId: accountId,
        targetDate: targetDate,
        icon: icon,
        initialSavedMinor: initialSavedMinor,
      );
}
