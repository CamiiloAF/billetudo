import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/debts/domain/usecases/link_transaction_to_debt.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_link_cubit.dart';
import 'package:billetudo/features/debts/presentation/cubit/debt_link_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'debts_presentation_fixtures.dart';

class MockLinkTransactionToDebt extends Mock
    implements LinkTransactionToDebt {}

void main() {
  late MockLinkTransactionToDebt linkTransactionToDebt;

  setUp(() => linkTransactionToDebt = MockLinkTransactionToDebt());

  DebtLinkCubit build() => DebtLinkCubit(linkTransactionToDebt)
    ..start(buildDebt(id: 'd1', name: 'Crédito vehicular'));

  test('link exitoso devuelve true y atribuye la transacción a la deuda',
      () async {
    when(() => linkTransactionToDebt.call(
          transactionId: any(named: 'transactionId'),
          debtId: any(named: 'debtId'),
        )).thenAnswer((_) async => const Right(unit));

    final cubit = build();
    final linked = await cubit.link('t9');

    expect(linked, isTrue);
    expect(cubit.state.status, DebtLinkStatus.idle);
    verify(() => linkTransactionToDebt.call(
          transactionId: 't9',
          debtId: 'd1',
        )).called(1);
  });

  test('link fallido devuelve false y expone la falla', () async {
    when(() => linkTransactionToDebt.call(
          transactionId: any(named: 'transactionId'),
          debtId: any(named: 'debtId'),
        )).thenAnswer(
      (_) async => const Left(UnexpectedFailure('nope')),
    );

    final cubit = build();
    final linked = await cubit.link('t9');

    expect(linked, isFalse);
    expect(cubit.state.status, DebtLinkStatus.failure);
  });
}
