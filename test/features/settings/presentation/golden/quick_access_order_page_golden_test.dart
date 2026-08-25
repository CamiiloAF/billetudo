import 'package:billetudo/features/home/domain/entities/quick_access_item.dart';
import 'package:billetudo/features/settings/domain/entities/app_settings.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_cubit.dart';
import 'package:billetudo/features/settings/presentation/cubit/app_settings_state.dart';
import 'package:billetudo/features/settings/presentation/pages/quick_access_order_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockAppSettingsCubit extends MockCubit<AppSettingsState>
    implements AppSettingsCubit {}

/// "Orden del acceso rápido" (Ajustes ▸ Preferencias), criterion 5 of
/// quick-access-reorder: the reorderable list of Home's 3 quick-access chips.
///
/// A single business state to distinguish: the persisted order rendered as a
/// list of surface-card rows with a drag handle — there is no empty/error
/// state (`AppSettingsState.quickAccessOrder` always falls back to
/// [QuickAccessItem.defaultOrder], see `AppSettingsRepositoryImpl`), so both
/// light and dark capture that one state.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Future<void> golden(
    WidgetTester tester,
    String name, {
    required Brightness brightness,
  }) async {
    final cubit = MockAppSettingsCubit();
    const state = AppSettingsState(
      settings: AppSettings(
        zeroBasedEnabled: false,
        categoriesSeeded: true,
        onboardingCompleted: true,
      ),
    );
    when(() => cubit.state).thenReturn(state);
    whenListen(
      cubit,
      const Stream<AppSettingsState>.empty(),
      initialState: state,
    );

    await pumpGolden(
      tester,
      BlocProvider<AppSettingsCubit>.value(
        value: cubit,
        child: const QuickAccessOrderPage(),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(QuickAccessOrderPage),
      matchesGoldenFile('goldens/quick_access_order_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('orden persistido ($suffix)', (tester) async {
      await golden(tester, suffix, brightness: brightness);
    });
  }
}
