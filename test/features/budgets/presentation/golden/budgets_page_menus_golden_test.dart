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
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';
import 'budget_golden_fixtures.dart';

class MockBudgetsListCubit extends MockCubit<BudgetsListState>
    implements BudgetsListCubit {}

class MockZeroBasedSummaryCubit extends MockCubit<ZeroBasedSummaryState>
    implements ZeroBasedSummaryCubit {}

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

/// The list header's overflow menu, which the spec splits in two rows because
/// its content depends on whether "Modo sobres" is on.
///
/// Pencil rows (`design-system/billetudo/pages/presupuestos.md`):
/// `list_menu` → `TmOGV` / `cOcbC` (Menú lista ⋮: "Ver histórico",
/// "Activar modo sobres" y "¿Qué es el modo sobres?") ·
/// `list_menu_envelope_on` → `tFZyK` / `qJAka` (Menú modo activo: la fila del
/// medio pasa a "Desactivar modo sobres").
///
/// Captured through a real tap on the header's "⋮" so the golden includes the
/// bottom sheet's own route and scrim, the way the design shows it. Both rows
/// are instances of `Bottom Sheet Base` (`PqTUt`), never a Material
/// `PopupMenuButton`.
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
    String name, {
    required Brightness brightness,
    required bool envelopeEnabled,
  }) async {
    when(() => listCubit.state).thenReturn(
      BudgetsListState(
        status: BudgetsListStatus.ready,
        budgets: [healthyEntry, overspentEntry],
      ),
    );
    when(() => envelopeCubit.state).thenReturn(
      ZeroBasedSummaryState(
        summary: envelopeEnabled
            ? const ZeroBasedSummary(
                currency: 'COP',
                incomeMinor: 820000000,
                assignedMinor: 618000000,
              )
            : null,
      ),
    );
    when(() => settingsCubit.state).thenReturn(
      AppSettingsState(
        settings: AppSettings(
          zeroBasedEnabled: envelopeEnabled,
          categoriesSeeded: true,
        ),
      ),
    );
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
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
      ),
    );
    await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/budgets_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('menú ⋮ de la lista, modo sobres apagado ($suffix)',
        (tester) async {
      await golden(
        tester,
        'list_menu_$suffix',
        brightness: brightness,
        envelopeEnabled: false,
      );
    });

    testWidgets('menú ⋮ de la lista, modo sobres activo ($suffix)',
        (tester) async {
      await golden(
        tester,
        'list_menu_envelope_on_$suffix',
        brightness: brightness,
        envelopeEnabled: true,
      );
    });
  }
}
