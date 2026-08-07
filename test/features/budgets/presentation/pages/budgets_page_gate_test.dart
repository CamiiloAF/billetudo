import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/accounts/domain/usecases/has_any_active_account.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_active_accounts_count.dart';
import 'package:billetudo/features/accounts/presentation/widgets/account_gate_bridge_sheet.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budgets_page.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../categories/presentation/widgets/pump_widget.dart';

class MockBudgetsListCubit extends MockCubit<BudgetsListState>
    implements BudgetsListCubit {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

class MockHasAnyActiveAccount extends Mock implements HasAnyActiveAccount {}

class MockWatchActiveAccountsCount extends Mock
    implements WatchActiveAccountsCount {}

/// `15-gate-cuenta.md` HU-04: tapping "+" in Presupuestos without any active
/// account must open the bridge sheet **directly over this screen**, never
/// by pushing `/presupuestos/nuevo` first and letting `AccountGatedRoute`
/// resolve the same check one frame later (that flashed a black/empty
/// screen behind the sheet — a real bug this test pins the fix for).
void main() {
  void registerAccountGate({required bool hasAny}) {
    final hasAnyActiveAccount = MockHasAnyActiveAccount();
    when(hasAnyActiveAccount.call).thenAnswer((_) => Stream.value(hasAny));
    getIt.registerFactory<HasAnyActiveAccount>(() => hasAnyActiveAccount);
    final watchActiveAccountsCount = MockWatchActiveAccountsCount();
    when(watchActiveAccountsCount.call)
        .thenAnswer((_) => Stream.value(hasAny ? 1 : 0));
    getIt.registerFactory<WatchActiveAccountsCount>(
      () => watchActiveAccountsCount,
    );
  }

  tearDown(getIt.reset);

  Future<void> pumpAndTapAdd(
    WidgetTester tester, {
    required VoidCallback onAdd,
  }) async {
    final listCubit = MockBudgetsListCubit();
    when(() => listCubit.state).thenReturn(
      const BudgetsListState(status: BudgetsListStatus.ready, budgets: []),
    );
    final settingsCubit = MockAppSettingsCubit();
    when(() => settingsCubit.state).thenReturn(
      const AppSettingsState(
        settings: AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
        ),
      ),
    );

    await tester.pumpAppWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<BudgetsListCubit>.value(value: listCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: BudgetsPage(
          onAddBudget: onAdd,
          onOpenBudget: (_) {},
          onOpenHistory: () {},
        ),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.plus).first);
    await tester.pumpAndSettle();
  }

  testWidgets(
      'sin ninguna cuenta activa, "+" abre el puente sobre Presupuestos en '
      'vez de invocar onAddBudget', (tester) async {
    registerAccountGate(hasAny: false);
    var tapped = 0;

    await pumpAndTapAdd(tester, onAdd: () => tapped++);

    expect(find.byType(AccountGateBridgeSheet), findsOneWidget);
    expect(tapped, 0);
  });

  testWidgets(
      'con al menos una cuenta activa, "+" invoca onAddBudget directamente, '
      'sin puente', (tester) async {
    registerAccountGate(hasAny: true);
    var tapped = 0;

    await pumpAndTapAdd(tester, onAdd: () => tapped++);

    expect(find.byType(AccountGateBridgeSheet), findsNothing);
    expect(tapped, 1);
  });
}
