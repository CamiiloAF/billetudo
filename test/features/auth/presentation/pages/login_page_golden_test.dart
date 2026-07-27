import 'package:billetudo/features/auth/presentation/cubit/login_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/login_state.dart';
import 'package:billetudo/features/auth/presentation/pages/login_page.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockLoginCubit extends MockCubit<LoginState> implements LoginCubit {}

/// Login / invitation to back up (`fTetG` Android, HU-02/HU-03). On the test
/// host `Platform.isIOS` is false, so `AuthSignInButtonsGroup` renders the
/// Android variant (Google only) — the iOS variant (`RSzD1`, Apple + Google)
/// uses the native `SignInWithAppleButton`, which cannot render a font-stable
/// glyph in a golden, so it is not captured here (documented gap).
void main() {
  late MockLoginCubit cubit;

  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
    await loadGoogleButtonFontFallback();
  });
  setUp(() => cubit = MockLoginCubit());

  Future<void> golden(
    WidgetTester tester,
    LoginState state,
    String name, {
    required Brightness brightness,
    // The loading state's Google button spins a `CircularProgressIndicator`
    // that never settles — capture a single deterministic frame instead.
    bool settle = true,
  }) async {
    when(() => cubit.state).thenReturn(state);
    await pumpGolden(
      tester,
      BlocProvider<LoginCubit>.value(
        value: cubit,
        child: LoginPage(onSignedIn: () {}, onSkip: () {}),
      ),
      brightness: brightness,
      settle: settle,
    );
    await expectLater(
      find.byType(LoginPage),
      matchesGoldenFile('goldens/login_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('idle ($suffix)', (tester) async {
      await golden(
        tester,
        const LoginState(),
        'idle_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('loading, connecting with Google ($suffix)', (tester) async {
      await golden(
        tester,
        const LoginState(status: LoginStatus.loading),
        'loading_$suffix',
        brightness: brightness,
        settle: false,
      );
    });
  }
}
