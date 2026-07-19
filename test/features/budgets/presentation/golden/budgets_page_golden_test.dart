import 'package:billetudo/features/budgets/domain/entities/zero_based_summary.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/budgets_list_state.dart';
import 'package:billetudo/features/budgets/presentation/cubit/zero_based_summary_cubit.dart';
import 'package:billetudo/features/budgets/presentation/cubit/zero_based_summary_state.dart';
import 'package:billetudo/features/budgets/presentation/pages/budgets_page.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import 'budget_golden_fixtures.dart';

class MockBudgetsListCubit extends MockCubit<BudgetsListState>
    implements BudgetsListCubit {}

class MockZeroBasedSummaryCubit extends MockCubit<ZeroBasedSummaryState>
    implements ZeroBasedSummaryCubit {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

/// The budgets list (`BudgetsPage`) in every state the domain produces.
///
/// Pencil rows (`design-system/billetudo/pages/presupuestos.md`):
/// `list_with_data` → `s833Gk` / `vfPbV` (Lista — con datos; covers
/// `Budget Line` `FSL69` in its healthy, overspent, one-off and stranded
/// variants plus the "+ Nuevo presupuesto" CTA row) ·
/// `list_empty` → `Zqsi1` / `zIijv` (Lista — vacío) ·
/// `list_loading` → `L8A868` / `QiUJe` (Lista — carga, 4× `Budget Skeleton
/// Row` `iVri4`) ·
/// `envelope_with_data` → `D1G5hl` / `YiBcF` (Modo sobres, base-cero HU-06) ·
/// `envelope_all_assigned`, `envelope_over_assigned` and `envelope_empty` are
/// the other three `EnvelopeHero` outcomes (unassigned == 0, < 0, and the
/// hero over an empty list); the spec's table has a single "Modo sobres" row,
/// so they map to `D1G5hl` / `YiBcF` too ·
/// `list_error` has **no row in the spec table** — the code renders
/// `BudgetsErrorView` (shared `Error State` `ECG7D`) on
/// `BudgetsListStatus.failure`; flagged for the audit.
///
/// The overflow menu (`TmOGV`/`cOcbC`) and the active-mode menu
/// (`tFZyK`/`qJAka`) are `PopupMenuButton` routes, captured in
/// `budgets_page_menus_golden_test.dart`.
void main() {
  late MockBudgetsListCubit listCubit;
  late MockZeroBasedSummaryCubit envelopeCubit;
  late MockAppSettingsCubit settingsCubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() {
    listCubit = MockBudgetsListCubit();
    envelopeCubit = MockZeroBasedSummaryCubit();
    settingsCubit = MockAppSettingsCubit();
  });

  Future<void> golden(
    WidgetTester tester,
    BudgetsListState state,
    String name, {
    required Brightness brightness,
    ZeroBasedSummary? summary,
    bool envelopeEnabled = false,
    bool settle = true,
    double height = 1000,
  }) async {
    when(() => listCubit.state).thenReturn(state);
    when(() => envelopeCubit.state)
        .thenReturn(ZeroBasedSummaryState(summary: summary));
    when(() => settingsCubit.state).thenReturn(
      AppSettingsState(
        settings: AppSettings(
          zeroBasedEnabled: envelopeEnabled,
          categoriesSeeded: true,
        ),
      ),
    );
    await pumpGolden(
      tester,
      MultiBlocProvider(
        providers: [
          BlocProvider<BudgetsListCubit>.value(value: listCubit),
          BlocProvider<ZeroBasedSummaryCubit>.value(value: envelopeCubit),
          BlocProvider<AppSettingsCubit>.value(value: settingsCubit),
        ],
        child: BudgetsPage(
          onAddBudget: () {},
          onOpenBudget: (_) {},
          onOpenHistory: () {},
        ),
      ),
      brightness: brightness,
      size: tallGoldenPhoneSize(height: height),
      settle: settle,
    );
    await expectLater(
      find.byType(BudgetsPage),
      matchesGoldenFile('goldens/budgets_page_$name.png'),
    );
  }

  final withData = BudgetsListState(
    status: BudgetsListStatus.ready,
    budgets: [
      healthyEntry,
      globalEntry,
      overspentEntry,
      oneOffEntry,
      strandedEntry,
    ],
  );

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('lista con datos ($suffix)', (tester) async {
      await golden(tester, withData, 'list_with_data_$suffix',
          brightness: brightness);
    });

    testWidgets('lista vacía ($suffix)', (tester) async {
      await golden(
        tester,
        const BudgetsListState(status: BudgetsListStatus.ready),
        'list_empty_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('lista en carga (skeleton) ($suffix)', (tester) async {
      await golden(
        tester,
        const BudgetsListState(),
        'list_loading_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('lista con error ($suffix)', (tester) async {
      await golden(
        tester,
        const BudgetsListState(status: BudgetsListStatus.failure),
        'list_error_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('modo sobres: queda por asignar ($suffix)', (tester) async {
      await golden(
        tester,
        withData,
        'envelope_with_data_$suffix',
        brightness: brightness,
        envelopeEnabled: true,
        summary: const ZeroBasedSummary(
          currency: 'COP',
          incomeMinor: 820000000,
          assignedMinor: 618000000,
        ),
        height: 1200,
      );
    });

    testWidgets('modo sobres: todo asignado ($suffix)', (tester) async {
      await golden(
        tester,
        withData,
        'envelope_all_assigned_$suffix',
        brightness: brightness,
        envelopeEnabled: true,
        summary: const ZeroBasedSummary(
          currency: 'COP',
          incomeMinor: 820000000,
          assignedMinor: 820000000,
        ),
        height: 1200,
      );
    });

    testWidgets('modo sobres: sobreasignado ($suffix)', (tester) async {
      await golden(
        tester,
        withData,
        'envelope_over_assigned_$suffix',
        brightness: brightness,
        envelopeEnabled: true,
        summary: const ZeroBasedSummary(
          currency: 'COP',
          incomeMinor: 620000000,
          assignedMinor: 934500000,
        ),
        height: 1200,
      );
    });

    testWidgets('modo sobres sobre lista vacía ($suffix)', (tester) async {
      await golden(
        tester,
        const BudgetsListState(status: BudgetsListStatus.ready),
        'envelope_empty_$suffix',
        brightness: brightness,
        envelopeEnabled: true,
        summary: const ZeroBasedSummary(
          currency: 'COP',
          incomeMinor: 820000000,
          assignedMinor: 0,
        ),
        height: 900,
      );
    });
  }
}
