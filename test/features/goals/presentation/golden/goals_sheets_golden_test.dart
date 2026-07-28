import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_state.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/confirm_archive_goal_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/confirm_delete_goal_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_account_picker_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_actions_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_currency_picker_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';

class MockGoalContributionCubit extends MockCubit<GoalContributionState>
    implements GoalContributionCubit {}

/// Every bottom sheet under `presentation/widgets/sheets/` for Metas:
/// registrar aporte/retiro (HU-03/HU-04), confirmar eliminar (HU-10),
/// confirmar archivar/desarchivar (HU-09), el menú de acciones del overflow,
/// y los pickers de cuenta (HU-02) y moneda (HU-01).
void main() {
  late MockGoalContributionCubit contributionCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });
  setUp(() => contributionCubit = MockGoalContributionCubit());

  /// Opens [openSheet] through a real trigger button (mirrors how a sheet
  /// actually reaches the screen — scrim, drag handle and the bottom sheet
  /// theme included) and captures the whole screen.
  Future<void> golden(
    WidgetTester tester,
    Future<void> Function(BuildContext context) openSheet,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => openSheet(context),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sheet_$name.png'),
    );
  }

  final accounts = [
    buildAccountWithBalance(
      account: buildAccount(id: 'a1', name: 'Bancolombia'),
      balanceMinor: 3450000,
    ),
    buildAccountWithBalance(
      account: buildAccount(id: 'a2', name: 'Nequi'),
      balanceMinor: 120000,
    ),
  ];

  GoalContributionState contributionState({
    required GoalMovementDirection direction,
    int amountMinor = 300000,
    int maxWithdrawableMinor = 0,
  }) =>
      GoalContributionState(
        goalId: 'g1',
        direction: direction,
        currency: 'COP',
        maxWithdrawableMinor: maxWithdrawableMinor,
        status: GoalContributionStatus.ready,
        amountMinor: amountMinor,
        date: DateTime(2026, 7, 5),
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('aportar ($suffix)', (tester) async {
      final state = contributionState(direction: GoalMovementDirection.contribution);
      when(() => contributionCubit.state).thenReturn(state);
      await golden(
        tester,
        (context) => BottomSheetBase.show<void>(
          context,
          builder: (_) => BlocProvider<GoalContributionCubit>.value(
            value: contributionCubit,
            child: GoalContributionSheetBody(state: state),
          ),
        ),
        'goal_contribute_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('retirar: excede el ahorrado (error) ($suffix)', (tester) async {
      final state = contributionState(
        direction: GoalMovementDirection.withdrawal,
        amountMinor: 900000,
        maxWithdrawableMinor: 500000,
      );
      when(() => contributionCubit.state).thenReturn(state);
      await golden(
        tester,
        (context) => BottomSheetBase.show<void>(
          context,
          builder: (_) => BlocProvider<GoalContributionCubit>.value(
            value: contributionCubit,
            child: GoalContributionSheetBody(state: state),
          ),
        ),
        'goal_withdraw_error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirmar eliminar (papelera reversible, HU-10) ($suffix)',
        (tester) async {
      await golden(
        tester,
        ConfirmDeleteGoalSheet.show,
        'goal_confirm_delete_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirmar archivar ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => ConfirmArchiveGoalSheet.show(context, archiving: true),
        'goal_confirm_archive_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirmar desarchivar ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => ConfirmArchiveGoalSheet.show(context, archiving: false),
        'goal_confirm_unarchive_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('menú de acciones: meta activa ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => GoalActionsSheet.show(
          context,
          goalName: 'Viaje a Cartagena',
          archived: false,
        ),
        'goal_actions_active_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('menú de acciones: meta archivada ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => GoalActionsSheet.show(
          context,
          goalName: 'Portátil nuevo',
          archived: true,
        ),
        'goal_actions_archived_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('selector de cuenta (HU-02) ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => GoalAccountPickerSheet.show(
          context,
          accounts: accounts,
          selectedId: 'a1',
        ),
        'goal_account_picker_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('selector de moneda (HU-01) ($suffix)', (tester) async {
      await golden(
        tester,
        (context) => GoalCurrencyPickerSheet.show(context, selected: 'COP'),
        'goal_currency_picker_$suffix',
        brightness: brightness,
      );
    });
  }
}
