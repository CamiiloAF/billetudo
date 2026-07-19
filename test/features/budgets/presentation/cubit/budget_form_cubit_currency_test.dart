import 'package:billetudo/features/budgets/domain/usecases/create_budget.dart';
import 'package:billetudo/features/budgets/domain/usecases/get_budget_by_id.dart';
import 'package:billetudo/features/budgets/domain/usecases/update_budget.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budget_form_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockCreateBudget extends Mock implements CreateBudget {}

class MockUpdateBudget extends Mock implements UpdateBudget {}

class MockGetBudgetById extends Mock implements GetBudgetById {}

/// The currency pill of the amount field (`a3gGPM/EA3R5`) needs a seam on the
/// cubit; the amount itself stays in minor units, so switching currency must
/// change the code and nothing else.
void main() {
  late BudgetFormCubit cubit;

  BudgetFormCubit build() => BudgetFormCubit(
        MockCreateBudget(),
        MockUpdateBudget(),
        MockGetBudgetById(),
      );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'currencyChanged only swaps the currency code',
    build: () {
      cubit = build();
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      name: 'Mercado',
      amountMinor: 450000000,
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.currencyChanged('USD'),
    verify: (cubit) {
      expect(cubit.state.currency, 'USD');
      expect(cubit.state.amountMinor, 450000000);
      expect(cubit.state.name, 'Mercado');
    },
  );
}
