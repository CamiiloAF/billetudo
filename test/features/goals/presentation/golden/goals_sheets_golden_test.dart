import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/widgets/bottom_sheet_base.dart';
import 'package:billetudo/features/categories/domain/entities/category.dart';
import 'package:billetudo/features/goals/domain/entities/goal_contribution.dart';
import 'package:billetudo/features/goals/domain/entities/goal_movement_accounts.dart';
import 'package:billetudo/features/goals/domain/services/goal_category_seed.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/edit_goal_movement_state.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_state.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_movement_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_movement_detail_state.dart';
import 'package:billetudo/features/goals/presentation/utils/goal_movement_delete_copy.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/confirm_archive_goal_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/confirm_delete_goal_movement_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/confirm_delete_goal_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/edit_goal_movement_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_account_picker_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_actions_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_contribution_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_currency_picker_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/goal_movement_detail_sheet.dart';
import 'package:billetudo/features/goals/presentation/widgets/sheets/new_goal_quick_amount_sheet.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_cubit.dart';
import 'package:billetudo/features/transactions/presentation/cubit/category_quick_picker_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';
import '../goals_presentation_fixtures.dart';

class MockGoalContributionCubit extends MockCubit<GoalContributionState>
    implements GoalContributionCubit {}

class MockCategoryQuickPickerCubit extends MockCubit<CategoryQuickPickerState>
    implements CategoryQuickPickerCubit {}

class MockGoalMovementDetailCubit extends MockCubit<GoalMovementDetailState>
    implements GoalMovementDetailCubit {}

class MockEditGoalMovementCubit extends MockCubit<EditGoalMovementState>
    implements EditGoalMovementCubit {}

/// Every bottom sheet under `presentation/widgets/sheets/` for Metas:
/// registrar aporte/retiro (HU-03/HU-04), confirmar eliminar (HU-10),
/// confirmar archivar/desarchivar (HU-09), el menú de acciones del overflow,
/// y los pickers de cuenta (HU-02) y moneda (HU-01).
void main() {
  late MockGoalContributionCubit contributionCubit;
  late MockCategoryQuickPickerCubit categoryQuickPickerCubit;
  late MockGoalMovementDetailCubit movementDetailCubit;
  late MockEditGoalMovementCubit editMovementCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    registerFallbackValue(CategoryKind.expense);
  });
  setUp(() {
    contributionCubit = MockGoalContributionCubit();
    movementDetailCubit = MockGoalMovementDetailCubit();
    editMovementCubit = MockEditGoalMovementCubit();

    // The "Categoría" field (`CategoryQuickPicker`) resolves its own cubit
    // through `getIt` — same precedent as `transaction_form_page_golden_test`.
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
    bool moveMoney = false,
    String? selectedAccountId,
    bool countsInBudget = false,
    String? categoryId,
    bool hasLinkedAccount = true,
  }) =>
      GoalContributionState(
        goalId: 'g1',
        goalName: 'Viaje a Cartagena',
        direction: direction,
        currency: 'COP',
        maxWithdrawableMinor: maxWithdrawableMinor,
        status: GoalContributionStatus.ready,
        amountMinor: amountMinor,
        date: DateTime(2026, 7, 5),
        moveMoney: moveMoney,
        accounts: accounts,
        selectedAccountId: selectedAccountId,
        countsInBudget: countsInBudget,
        categoryId: categoryId,
        hasLinkedAccount: hasLinkedAccount,
      );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('aportar ($suffix)', (tester) async {
      final state =
          contributionState(direction: GoalMovementDirection.contribution);
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

    testWidgets(
        'aportar: sin cuenta vinculada, sin toggle mover dinero ($suffix)',
        (tester) async {
      final state = contributionState(
        direction: GoalMovementDirection.contribution,
        hasLinkedAccount: false,
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
        'goal_contribute_no_linked_account_$suffix',
        brightness: brightness,
      );
      expect(find.byIcon(LucideIcons.arrowLeftRight), findsNothing);
    });

    testWidgets('retirar: excede el ahorrado (error) ($suffix)',
        (tester) async {
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

    testWidgets('retirar: meta cumplida, retiro total disponible ($suffix)',
        (tester) async {
      final state = contributionState(
        direction: GoalMovementDirection.withdrawal,
        amountMinor: 2000000,
        maxWithdrawableMinor: 2000000,
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
        'goal_withdraw_completed_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('aportar: mover ON, sin presupuesto ($suffix)', (tester) async {
      final state = contributionState(
        direction: GoalMovementDirection.contribution,
        moveMoney: true,
        selectedAccountId: 'a2',
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
        'goal_contribute_move_on_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('aportar: mover ON, presupuestable ON ($suffix)',
        (tester) async {
      final state = contributionState(
        direction: GoalMovementDirection.contribution,
        moveMoney: true,
        selectedAccountId: 'a2',
        countsInBudget: true,
        categoryId: GoalCategorySeed.savingsCategoryId,
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
        'goal_contribute_move_on_budget_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('retirar: mover ON, sin presupuesto ($suffix)', (tester) async {
      final state = contributionState(
        direction: GoalMovementDirection.withdrawal,
        maxWithdrawableMinor: 500000,
        moveMoney: true,
        selectedAccountId: 'a2',
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
        'goal_withdraw_move_on_$suffix',
        brightness: brightness,
      );
    });

    // `DiDwa`/`e9QOrp`: the withdrawal symmetric to
    // "aportar: mover ON, presupuestable ON" — Category Quick Picker visible
    // when withdrawing with move-money and countsInBudget both on.
    testWidgets('retirar: mover ON, presupuestable ON ($suffix)',
        (tester) async {
      final state = contributionState(
        direction: GoalMovementDirection.withdrawal,
        maxWithdrawableMinor: 500000,
        moveMoney: true,
        selectedAccountId: 'a2',
        countsInBudget: true,
        categoryId: GoalCategorySeed.savingsCategoryId,
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
        'goal_withdraw_move_on_budget_$suffix',
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

    // `N8Dv2e`/`opOuE`: the movement detail sheet — Editar + Eliminar always
    // show together, whether the movement moved real money (Editar opens the
    // linked transaction) or is tracking-only (Editar opens
    // `EditGoalMovementSheet` on this same row).
    testWidgets('detalle de movimiento: con transferencia ($suffix)',
        (tester) async {
      final movement = buildGoalContribution(
        id: 'm1',
        amountMinor: 300000,
        date: DateTime(2026, 7, 20),
        transactionId: 't1',
        note: 'Ahorro de julio',
      );
      when(() => movementDetailCubit.state).thenReturn(
        const GoalMovementDetailState(
          status: GoalMovementDetailStatus.ready,
          accounts: GoalMovementAccounts(
            originName: 'Bancolombia',
            destinationName: 'Ahorros Bancolombia',
          ),
        ),
      );
      await golden(
        tester,
        (context) => BottomSheetBase.show<bool>(
          context,
          builder: (_) => BlocProvider<GoalMovementDetailCubit>.value(
            value: movementDetailCubit,
            child: GoalMovementDetailSheet(
              movement: movement,
              currency: 'COP',
              goalName: 'Viaje a Cartagena',
              goalCompleted: false,
            ),
          ),
        ),
        'goal_movement_detail_transfer_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('detalle de movimiento: manual/seguimiento ($suffix)',
        (tester) async {
      final movement = buildGoalContribution(
        id: 'm2',
        amountMinor: 150000,
        direction: GoalMovementDirection.withdrawal,
        date: DateTime(2026, 6, 15),
      );
      when(() => movementDetailCubit.state).thenReturn(
        const GoalMovementDetailState(status: GoalMovementDetailStatus.ready),
      );
      await golden(
        tester,
        (context) => BottomSheetBase.show<bool>(
          context,
          builder: (_) => BlocProvider<GoalMovementDetailCubit>.value(
            value: movementDetailCubit,
            child: GoalMovementDetailSheet(
              movement: movement,
              currency: 'COP',
              goalName: 'Viaje a Cartagena',
              goalCompleted: false,
            ),
          ),
        ),
        'goal_movement_detail_manual_$suffix',
        brightness: brightness,
      );
    });

    // "Editar movimiento" (`goal_movement_detail_sheet.dart`'s Editar for a
    // tracking-only movement): monto/fecha/nota of the SAME row, no account
    // picker, no "¿Mover dinero?" toggle — unlike `GoalContributionSheet`.
    testWidgets('editar movimiento: seguimiento puro ($suffix)',
        (tester) async {
      when(() => editMovementCubit.state).thenReturn(
        EditGoalMovementState(
          contributionId: 'm2',
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.withdrawal,
          currency: 'COP',
          amountMinor: 150000,
          date: DateTime(2026, 6, 15),
        ),
      );
      await golden(
        tester,
        (context) => BottomSheetBase.show<bool>(
          context,
          builder: (_) => BlocProvider<EditGoalMovementCubit>.value(
            value: editMovementCubit,
            child: const EditGoalMovementSheet(),
          ),
        ),
        'edit_goal_movement_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('editar movimiento: con error de guardado ($suffix)',
        (tester) async {
      when(() => editMovementCubit.state).thenReturn(
        EditGoalMovementState(
          contributionId: 'm2',
          goalId: 'g1',
          goalName: 'Viaje a Cartagena',
          direction: GoalMovementDirection.withdrawal,
          currency: 'COP',
          amountMinor: 999999999,
          date: DateTime(2026, 6, 15),
          status: EditGoalMovementStatus.failure,
          failure: const ValidationFailure(
            'a withdrawal cannot leave the goal\'s saved amount negative',
          ),
        ),
      );
      await golden(
        tester,
        (context) => BottomSheetBase.show<bool>(
          context,
          builder: (_) => BlocProvider<EditGoalMovementCubit>.value(
            value: editMovementCubit,
            child: const EditGoalMovementSheet(),
          ),
        ),
        'edit_goal_movement_error_$suffix',
        brightness: brightness,
      );
    });

    // `arr2T`/`H2ND7O`/`xCNxM`: the 3 copy variants of "Eliminar movimiento",
    // built the same way the real sheet builds them — through
    // `GoalMovementDeleteCopy`, never hand-typed strings — so a wording
    // change to the copy helper is caught here too.
    testWidgets('confirmar eliminar movimiento: con transferencia ($suffix)',
        (tester) async {
      final movement = buildGoalContribution(
        id: 'm1',
        amountMinor: 300000,
        date: DateTime(2026, 7, 20),
        transactionId: 't1',
      );
      const accounts = GoalMovementAccounts(
        originName: 'Bancolombia',
        destinationName: 'Ahorros Bancolombia',
      );
      await golden(
        tester,
        (context) {
          final l10n = AppLocalizations.of(context);
          final copy = GoalMovementDeleteCopy.build(
            l10n,
            movement: movement,
            currency: 'COP',
            goalName: 'Viaje a Cartagena',
            goalCompleted: false,
            accounts: accounts,
          );
          return ConfirmDeleteGoalMovementSheet.show(
            context,
            title: copy.title,
            message: copy.message,
          );
        },
        'goal_confirm_delete_movement_transfer_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirmar eliminar movimiento: manual ($suffix)',
        (tester) async {
      final movement = buildGoalContribution(
        id: 'm2',
        amountMinor: 150000,
        direction: GoalMovementDirection.withdrawal,
        date: DateTime(2026, 6, 15),
      );
      await golden(
        tester,
        (context) {
          final l10n = AppLocalizations.of(context);
          final copy = GoalMovementDeleteCopy.build(
            l10n,
            movement: movement,
            currency: 'COP',
            goalName: 'Viaje a Cartagena',
            goalCompleted: false,
          );
          return ConfirmDeleteGoalMovementSheet.show(
            context,
            title: copy.title,
            message: copy.message,
          );
        },
        'goal_confirm_delete_movement_manual_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('confirmar eliminar movimiento: meta cumplida ($suffix)',
        (tester) async {
      final movement = buildGoalContribution(
        id: 'm1',
        amountMinor: 2000000,
        date: DateTime(2026, 5, 1),
      );
      await golden(
        tester,
        (context) {
          final l10n = AppLocalizations.of(context);
          final copy = GoalMovementDeleteCopy.build(
            l10n,
            movement: movement,
            currency: 'COP',
            goalName: 'Fondo de emergencia',
            goalCompleted: true,
          );
          return ConfirmDeleteGoalMovementSheet.show(
            context,
            title: copy.title,
            message: copy.message,
          );
        },
        'goal_confirm_delete_movement_completed_$suffix',
        brightness: brightness,
      );
    });

    // "+ Nueva" (`urHlG`/`MqLys`): a minimal sheet — just the Monto field and
    // "Crear chip", disabled until an amount is entered (there is no separate
    // validation-error copy; the CTA staying disabled at $0 is the only
    // feedback the design gives, same precedent as the compact fields in
    // `goal_form_page_golden_test`).
    testWidgets('nuevo aporte rápido: vacío, CTA deshabilitado ($suffix)',
        (tester) async {
      await golden(
        tester,
        (context) => NewGoalQuickAmountSheet.show(context, currency: 'COP'),
        'goal_new_quick_amount_empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('nuevo aporte rápido: con monto, CTA habilitado ($suffix)',
        (tester) async {
      setGoldenViewport(tester);
      await tester.pumpWidget(
        wrapForGolden(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () =>
                  NewGoalQuickAmountSheet.show(context, currency: 'COP'),
              child: const Text('open'),
            ),
          ),
          brightness: brightness,
        ),
      );
      await tester.tap(find.byType(ElevatedButton));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.byKey(const ValueKey('goal-new-quick-amount')),
        '30000',
      );
      await tester.pumpAndSettle();

      await expectLater(
        find.byType(MaterialApp),
        matchesGoldenFile(
            'goldens/sheet_goal_new_quick_amount_filled_$suffix.png'),
      );
    });
  }
}
