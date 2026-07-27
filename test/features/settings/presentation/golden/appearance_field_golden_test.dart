import 'package:billetudo/core/theme/theme_mode_cubit.dart';
import 'package:billetudo/features/settings/presentation/widgets/appearance_field.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockThemeModeCubit extends MockCubit<ThemeMode>
    implements ThemeModeCubit {}

/// The "Apariencia" card in Ajustes (Pencil `h4jCV`/`B0uqd` light theme,
/// `onPZR`/`eabgk` dark): its only distinguishable business state is which
/// of the three [ThemeMode] segments is active, since the card always
/// applies the choice immediately (no sheet, no loading/error state).
void main() {
  late MockThemeModeCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  setUp(() => cubit = MockThemeModeCubit());

  Future<void> golden(
    WidgetTester tester,
    ThemeMode mode,
    String name, {
    required Brightness brightness,
  }) async {
    when(() => cubit.state).thenReturn(mode);
    whenListen(cubit, const Stream<ThemeMode>.empty(), initialState: mode);

    await pumpGolden(
      tester,
      BlocProvider<ThemeModeCubit>.value(
        value: cubit,
        // `AppearanceField`'s inner `Column` defaults to
        // `MainAxisSize.max` — fine inside the real page's `ListView`
        // (unbounded height, so the column shrinks to its content), but it
        // would stretch to fill the whole bounded golden canvas under a
        // bare `Scaffold` body. `SingleChildScrollView` offers the same
        // unbounded height a `ListView` would, so the card renders at its
        // natural size here too.
        child: const SingleChildScrollView(child: AppearanceField()),
      ),
      brightness: brightness,
    );
    await expectLater(
      find.byType(AppearanceField),
      matchesGoldenFile('goldens/appearance_field_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('Claro seleccionado ($suffix)', (tester) async {
      await golden(tester, ThemeMode.light, 'light_selected_$suffix',
          brightness: brightness);
    });

    testWidgets('Oscuro seleccionado ($suffix)', (tester) async {
      await golden(tester, ThemeMode.dark, 'dark_selected_$suffix',
          brightness: brightness);
    });

    testWidgets('Sistema seleccionado ($suffix)', (tester) async {
      await golden(tester, ThemeMode.system, 'system_selected_$suffix',
          brightness: brightness);
    });
  }
}
