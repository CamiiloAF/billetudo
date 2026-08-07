import 'dart:async';

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/budgets/presentation/widgets/sheets/budget_detail_actions_sheet.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../golden/budget_golden_fixtures.dart';

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

/// Regression coverage for the "Destacar en Inicio" race condition: before
/// this fix, [BudgetDetailActionsSheet] captured `isFeatured` as a static
/// `bool` at the moment it was opened, so if the caller's
/// `AppSettingsCubit.activeBudgets` stream had not emitted yet when the `⋮`
/// button was tapped, the sheet froze on the wrong label forever — even once
/// the real value arrived. The fix rebuilds the row from a
/// `BlocBuilder<AppSettingsCubit, AppSettingsState>`, so it self-corrects the
/// moment the stream catches up, with no need to close and reopen the sheet.
void main() {
  Future<void> pump(
    WidgetTester tester,
    AppSettingsCubit settingsCubit,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => BudgetDetailActionsSheet.show(
                context,
                budgetName: 'Mercado del mes',
                budgetId: globalEntry.budget.id,
                settingsCubit: settingsCubit,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'when the featured-budgets stream has not emitted yet, the sheet may '
      'open with the default (not-featured) label, but re-renders to '
      '"Quitar de Inicio" the instant the real value arrives — no close/'
      'reopen needed', (tester) async {
    final controller = StreamController<AppSettingsState>();
    addTearDown(controller.close);

    final cubit = MockAppSettingsCubit();
    // No value has been emitted on the stream yet: only the constructor's
    // default `AppSettingsState()` (no active budgets, mode automatic) is
    // available, which the selector reads as "not featured".
    whenListen(
      cubit,
      controller.stream,
      initialState: const AppSettingsState(),
    );

    await pump(tester, cubit);

    // Momentarily acceptable: the sheet shows the default, not-featured
    // label because the real settings state has not arrived yet.
    expect(find.text('Usar como destacado en Inicio'), findsOneWidget);
    expect(find.text('Quitar de Inicio'), findsNothing);

    // The stream's first real value arrives late: this budget is in fact
    // featured (via the automatic fallback, since it is the sole
    // global-monthly active budget).
    controller.add(
      AppSettingsState(
        settings: const AppSettings(
          zeroBasedEnabled: false,
          categoriesSeeded: true,
          onboardingCompleted: true,
        ),
        activeBudgets: [globalEntry],
      ),
    );
    await tester.pumpAndSettle();

    // This is the bug fix under test: the already-open sheet re-renders on
    // its own, without being closed and reopened.
    expect(find.text('Quitar de Inicio'), findsOneWidget);
    expect(find.text('Usar como destacado en Inicio'), findsNothing);
  });
}
