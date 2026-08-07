import 'package:billetudo/features/budgets/domain/entities/budget_with_progress.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_detail_actions_sheet.dart';
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

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

/// The detail overflow ("⋮") sheet: Editar · Usar como destacado en Inicio
/// (o Quitar de Inicio) · Ajustar monto · Cerrar (guardar en histórico) ·
/// Eliminar (en `$expense-text`).
///
/// Pencil row (`design-system/billetudo/pages/presupuestos.md`):
/// `detail_actions` → `G26c4T` / `f1WviW` (Sheet — acciones del detalle ⋮);
/// the "Destacar en Inicio" row is `gFBcD` (OFF) / `yaRtv` (ON).
///
/// The sheet derives its one piece of business state — whether this budget
/// is featured — reactively from `AppSettingsCubit`
/// (`BudgetHeroSelector.pick`), not from a static `isFeatured` bool, so both
/// values here are driven by the mocked cubit's `activeBudgets` /
/// `featuredBudgetMode` / `featuredBudgetId`, exactly like a real caller.
/// Opened through a real trigger so the golden includes the scrim, the drag
/// handle and the `BottomSheetBase` chrome.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
    required bool isFeatured,
  }) async {
    final settingsCubit = MockAppSettingsCubit();
    when(() => settingsCubit.state).thenReturn(
      AppSettingsState(
        settings: AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
          featuredBudgetMode:
              isFeatured ? FeaturedBudgetMode.automatic : FeaturedBudgetMode.none,
        ),
        activeBudgets: isFeatured ? [globalEntry] : const <BudgetWithProgress>[],
      ),
    );
    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        BlocProvider<AppSettingsCubit>.value(
          value: settingsCubit,
          child: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BudgetDetailActionsSheet.show(
                context,
                budgetName: 'Mercado del mes',
                budgetId: globalEntry.budget.id,
                settingsCubit: context.read<AppSettingsCubit>(),
              ),
              child: const Text('open'),
            ),
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

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('acciones del detalle, no destacado ($suffix)',
        (tester) async {
      await golden(
        tester,
        'detail_actions_$suffix',
        brightness: brightness,
        isFeatured: false,
      );
    });

    testWidgets('acciones del detalle, ya destacado ($suffix)',
        (tester) async {
      await golden(
        tester,
        'detail_actions_featured_$suffix',
        brightness: brightness,
        isFeatured: true,
      );
    });
  }
}
