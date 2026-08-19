import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/goals/domain/services/goal_category_seed.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_recurring_contribution_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_recurring_contribution_decision_page.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_recurring_contribution_form_page.dart';
import 'package:billetudo/features/goals/presentation/widgets/goal_scheduled_payment_picker_sheet.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment.dart';
import 'package:billetudo/features/scheduled_payments/domain/entities/scheduled_payment_summary.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';
import '../../../scheduled_payments/scheduled_payment_fixtures.dart';

class MockGoalRecurringContributionCubit
    extends MockCubit<GoalRecurringContributionState>
    implements GoalRecurringContributionCubit {}

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

/// HU-16's "Aporte recurrente" flow (`design-system/billetudo/pages/metas.md`
/// "Integración con Pagos Programados"): the decision sheet (`HOdfO`/`XB4rS`),
/// the config form for "Crear uno nuevo" (`ebcqG`/`G2AfJ`) and the "Enlazar
/// existente" picker (`RX8C9`/`LSwr8`) — each in light and dark.
void main() {
  late MockGoalRecurringContributionCubit cubit;
  late MockCategoryQuickPickerCubit categoryQuickPickerCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(CategoryKind.expense);
  });

  setUp(() {
    cubit = MockGoalRecurringContributionCubit();

    // `CategoryQuickPicker` resolves its own cubit through `getIt` — same
    // precedent as `goals_sheets_golden_test.dart`.
    categoryQuickPickerCubit = MockCategoryQuickPickerCubit();
    when(
      () => categoryQuickPickerCubit.start(
        kind: any(named: 'kind'),
        selectedId: any(named: 'selectedId'),
        accountId: any(named: 'accountId'),
      ),
    ).thenAnswer((_) async {});
    final savingsCategory = Category(
      id: GoalCategorySeed.savingsCategoryId,
      name: 'Ahorros',
      kind: CategoryKind.expense,
      icon: 'piggy-bank',
      color: 'mint',
      sortOrder: 0,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1).millisecondsSinceEpoch,
    );
    when(() => categoryQuickPickerCubit.state).thenReturn(
      CategoryQuickPickerState(
        status: CategoryQuickPickerStatus.ready,
        mostUsed: [savingsCategory],
        selected: savingsCategory,
      ),
    );
    getIt.registerFactory<CategoryQuickPickerCubit>(
      () => categoryQuickPickerCubit,
    );
  });

  tearDown(getIt.reset);

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Nequi'),
      balanceMinor: 1240000,
    ),
  ];

  GoalRecurringContributionState formState({
    List<AccountWithBalance> accountsList = const [],
    String? selectedAccountId,
    int amountMinor = 0,
    bool countsInBudget = true,
    String? categoryId,
    ScheduledPaymentFrequency frequency = ScheduledPaymentFrequency.monthly,
    GoalRecurringContributionStatus status =
        GoalRecurringContributionStatus.ready,
    List<ScheduledPaymentSummary> linkablePayments = const [],
  }) =>
      GoalRecurringContributionState(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        currency: 'COP',
        status: status,
        accounts: accountsList,
        selectedAccountId: selectedAccountId,
        amountMinor: amountMinor,
        frequency: frequency,
        countsInBudget: countsInBudget,
        categoryId: categoryId,
        nextDate: DateTime(2026, 8, 5),
        linkablePayments: linkablePayments,
      );

  Future<void> golden(
    WidgetTester tester,
    Widget child,
    String name, {
    required Brightness brightness,
  }) async {
    await pumpWithFixedClock(
      tester,
      BlocProvider<GoalRecurringContributionCubit>.value(
        value: cubit,
        child: child,
      ),
      brightness: brightness,
      size: goldenPhoneSize,
    );
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/goal_recurring_contribution_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('sheet de decisión ($suffix)', (tester) async {
      await pumpGolden(
        tester,
        const GoalRecurringContributionDecisionPage(
          goalName: 'Viaje a Cartagena',
        ),
        brightness: brightness,
      );
      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
          'goldens/goal_recurring_contribution_decision_$suffix.png',
        ),
      );
    });

    testWidgets('config "crear nuevo" ($suffix)', (tester) async {
      when(() => cubit.state).thenReturn(
        formState(
          accountsList: accounts,
          selectedAccountId: 'a1',
          amountMinor: 50000,
          categoryId: GoalCategorySeed.savingsCategoryId,
        ),
      );
      await golden(
        tester,
        const GoalRecurringContributionFormPage(),
        'form_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('picker de PP existente ($suffix)', (tester) async {
      final linkable = [
        ScheduledPaymentSummary(
          scheduledPayment: buildScheduledPayment(
            id: 'sp-1',
            amountMinor: 44900,
            frequency: ScheduledPaymentFrequency.monthly,
          ),
          accountName: 'Nequi',
          categoryName: 'Suscripciones',
        ),
      ];
      final state = formState(linkablePayments: linkable);
      when(() => cubit.state).thenReturn(state);
      await golden(
        tester,
        GoalScheduledPaymentPickerSheetBody(state: state),
        'picker_$suffix',
        brightness: brightness,
      );
    });
  }
}
