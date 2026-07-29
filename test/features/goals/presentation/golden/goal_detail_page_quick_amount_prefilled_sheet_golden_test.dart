import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/accounts/domain/entities/account_with_balance.dart';
import 'package:billetudo/features/accounts/domain/usecases/watch_accounts.dart';
import 'package:billetudo/features/goals/domain/entities/goal_projection.dart';
import 'package:billetudo/features/goals/domain/entities/goal_quick_amount.dart';
import 'package:billetudo/features/goals/domain/usecases/contribute_to_goal.dart';
import 'package:billetudo/features/goals/domain/usecases/withdraw_from_goal.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_contribution_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_cubit.dart';
import 'package:billetudo/features/goals/presentation/cubit/goal_detail_state.dart';
import 'package:billetudo/features/goals/presentation/pages/goal_detail_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import '../../../accounts/account_fixtures.dart';
import '../goals_presentation_fixtures.dart';

class MockGoalDetailCubit extends MockCubit<GoalDetailState>
    implements GoalDetailCubit {}

class MockContributeToGoal extends Mock implements ContributeToGoal {}

class MockWithdrawFromGoal extends Mock implements WithdrawFromGoal {}

class MockWatchAccounts extends Mock implements WatchAccounts {}

/// Closes the loop the plain sheet-state goldens in
/// `goals_sheets_golden_test.dart` cannot: those build `GoalContributionState`
/// by hand, simulating a prefilled amount without ever going through the real
/// trigger. This test taps an actual chip in `GoalQuickAmountRow` (`e9nrdh`)
/// from `GoalDetailPage`, letting `GoalDetailBody._openContribute` open the
/// real `GoalContributionSheet` with `initialAmountMinor` — the same path
/// production code takes — and captures the resulting sheet (`W6Kijx`),
/// confirming the amount lands prefilled with no visual trace of its chip
/// origin, indistinguishable from a manual aporte.
void main() {
  late MockGoalDetailCubit detailCubit;
  late MockContributeToGoal contribute;
  late MockWithdrawFromGoal withdraw;
  late MockWatchAccounts watchAccounts;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    detailCubit = MockGoalDetailCubit();
    contribute = MockContributeToGoal();
    withdraw = MockWithdrawFromGoal();
    watchAccounts = MockWatchAccounts();
    when(() => watchAccounts()).thenAnswer(
      (_) => Stream.value(
        Right<Failure, List<AccountWithBalance>>([
          buildAccountWithBalance(
            account: buildAccount(id: 'a1', name: 'Bancolombia'),
            balanceMinor: 3450000,
          ),
        ]),
      ),
    );

    // `GoalContributionSheet.show` resolves its cubit from `getIt`, exactly
    // like production — same precedent `goals_sheets_golden_test.dart` uses
    // for `CategoryQuickPickerCubit`.
    getIt.registerFactory<GoalContributionCubit>(
      () => GoalContributionCubit(contribute, withdraw, watchAccounts),
    );
  });

  tearDown(getIt.reset);

  // `CreateGoal` seeds this one as a real row right after the goal is
  // created — it is no longer a hardcoded chip in `GoalQuickAmountRow`, so
  // the fixture must carry it explicitly for the "chip fijo" case below.
  final seededChip = GoalQuickAmount(
    id: 'seed1',
    goalId: 'g1',
    amountMinor: 5000000,
    createdAt: DateTime(2026, 5, 1),
    updatedAt: DateTime(2026, 5, 1).millisecondsSinceEpoch,
  );

  final customChip = GoalQuickAmount(
    id: 'qa1',
    goalId: 'g1',
    amountMinor: 7500000,
    createdAt: DateTime(2026, 6, 1),
    updatedAt: DateTime(2026, 6, 1).millisecondsSinceEpoch,
  );

  final readyState = GoalDetailState(
    status: GoalDetailStatus.ready,
    quickAmounts: [seededChip, customChip],
    detail: buildGoalDetail(
      progress: buildGoalWithProgress(
        goal: buildGoal(
          id: 'g1',
          name: 'Viaje a Cartagena',
          targetMinor: 3000000,
          targetDate: DateTime(2026, 12, 1),
          accountId: 'a1',
        ),
        savedMinor: 1800000,
        displayedPercent: 60,
      ),
      projection: GoalProjection(
        kind: GoalProjectionKind.projected,
        estimatedDate: DateTime(2026, 11, 1),
        paceMinorPerMonth: 200000,
      ),
      history: [
        buildGoalContribution(
          id: 'm1',
          amountMinor: 1800000,
          date: DateTime(2026, 6, 1),
        ),
      ],
    ),
  );

  Future<void> openSheetFromChip(
    WidgetTester tester,
    String chipLabel, {
    required Brightness brightness,
  }) async {
    when(() => detailCubit.state).thenReturn(readyState);
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        BlocProvider<GoalDetailCubit>.value(
          value: detailCubit,
          child: GoalDetailPage(
            onEdit: (_) {},
            onOpenCompletedCelebration: (_) {},
            onOpenMilestone: (_, __) {},
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.pumpAndSettle();

    await tester.tap(find.text(chipLabel));
    await tester.pumpAndSettle();
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets(
      'chip sembrado (\$50.000): abre el sheet real con el monto prefilled ($suffix)',
      (tester) async {
        await openSheetFromChip(tester, '\$50.000', brightness: brightness);

        // The real trigger: tapping the seeded chip opened GoalContributionSheet
        // (not the hand-built state the other suite uses) with the amount
        // already in the field — same TextField a manual aporte
        // fills in, no extra badge/label revealing it came from a chip.
        expect(find.text('Aportar a Viaje a Cartagena'), findsOneWidget);
        final field = tester.widget<TextField>(
          find.byKey(const ValueKey('goal-amount-movement')),
        );
        expect(field.controller?.text, '50.000');

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/goal_detail_page_quick_amount_prefilled_sheet_$suffix.png',
          ),
        );
      },
    );

    testWidgets(
      'chip personalizado: abre el sheet real con el monto prefilled ($suffix)',
      (tester) async {
        await openSheetFromChip(tester, '\$75.000', brightness: brightness);

        expect(find.text('Aportar a Viaje a Cartagena'), findsOneWidget);
        final field = tester.widget<TextField>(
          find.byKey(const ValueKey('goal-amount-movement')),
        );
        expect(field.controller?.text, '75.000');

        await expectLater(
          find.byType(MaterialApp),
          matchesGoldenFile(
            'goldens/goal_detail_page_quick_amount_prefilled_custom_sheet_$suffix.png',
          ),
        );
      },
    );
  }
}
