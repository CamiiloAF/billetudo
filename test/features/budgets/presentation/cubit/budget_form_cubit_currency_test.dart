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
/// cubit. The amount stays in minor units and is never converted — switching
/// currency only re-cuts its precision, because COP shows no cents and the
/// field must not display a figure the state does not hold.
void main() {
  late BudgetFormCubit cubit;

  BudgetFormCubit build() => BudgetFormCubit(
        MockCreateBudget(),
        MockUpdateBudget(),
        MockGetBudgetById(),
      );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'currencyChanged to a currency with cents keeps the whole amount',
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

  blocTest<BudgetFormCubit, BudgetFormState>(
    'currencyChanged to COP rounds the cents half-up into whole units',
    build: () {
      cubit = build();
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      name: 'Mercado',
      currency: 'USD',
      amountMinor: 123456,
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.currencyChanged('COP'),
    verify: (cubit) {
      expect(cubit.state.currency, 'COP');
      expect(cubit.state.amountMinor, 123500);
    },
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    'currencyChanged with no amount typed leaves it null, never a zero',
    build: () {
      cubit = build();
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      currency: 'USD',
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.currencyChanged('COP'),
    verify: (cubit) {
      expect(cubit.state.currency, 'COP');
      expect(cubit.state.amountMinor, isNull);
    },
  );

  blocTest<BudgetFormCubit, BudgetFormState>(
    're-picking the same currency emits nothing',
    build: () {
      cubit = build();
      return cubit;
    },
    seed: () => BudgetFormState(
      status: BudgetFormStatus.ready,
      currency: 'USD',
      amountMinor: 123456,
      startDate: DateTime(2026, 7, 21),
    ),
    act: (cubit) => cubit.currencyChanged('USD'),
    expect: () => <BudgetFormState>[],
  );
}
