import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:billetudo/features/auth/domain/usecases/cancel_account_conflict.dart';
import 'package:billetudo/features/auth/domain/usecases/resolve_account_conflict.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:billetudo/features/auth/presentation/cubit/login_cubit.dart';
import 'package:billetudo/features/auth/presentation/pages/login_page.dart';
import 'package:billetudo/features/auth/presentation/widgets/google_sign_in_button.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:mocktail/mocktail.dart';
import 'package:sign_in_with_apple/sign_in_with_apple.dart'
    show SignInWithAppleButton;
import '../widgets/pump_widget.dart';

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSignInWithApple extends Mock implements SignInWithApple {}

class MockResolveAccountConflict extends Mock
    implements ResolveAccountConflict {}

class MockCancelAccountConflict extends Mock implements CancelAccountConflict {}

void main() {
  late MockSignInWithGoogle signInWithGoogle;
  late MockSignInWithApple signInWithApple;
  late MockResolveAccountConflict resolveAccountConflict;
  late MockCancelAccountConflict cancelAccountConflict;

  const user = AuthUser(
    id: 'google-1',
    displayName: 'Camila',
    provider: AuthProvider.google,
  );

  setUp(() {
    signInWithGoogle = MockSignInWithGoogle();
    signInWithApple = MockSignInWithApple();
    resolveAccountConflict = MockResolveAccountConflict();
    cancelAccountConflict = MockCancelAccountConflict();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    void Function({required bool signedInAfterConflict})? onSignedIn,
    VoidCallback? onSkip,
  }) =>
      tester.pumpAuthWidget(
        BlocProvider(
          create: (_) => LoginCubit(
            signInWithGoogle,
            signInWithApple,
            resolveAccountConflict,
            cancelAccountConflict,
          ),
          child: LoginPage(
            onSignedIn: onSignedIn ?? ({required signedInAfterConflict}) {},
            onSkip: onSkip ?? () {},
          ),
        ),
        wrapInScaffold: false,
      );

  testWidgets('HU-01/HU-02: muestra el copy, el botón de Google y el skip',
      (tester) async {
    await pumpLogin(tester);

    expect(find.text('Nunca pierdas tu progreso'), findsOneWidget);
    expect(
      find.textContaining('Un respaldo automático de tus cuentas'),
      findsOneWidget,
    );
    expect(find.byType(GoogleSignInButton), findsOneWidget);
    expect(find.text('Continuar sin cuenta'), findsOneWidget);
    // Apple never shows on the host running `flutter test` (dart:io
    // Platform.isIOS reflects the real OS, not a mocked target) — same
    // condition production Android hits (HU-03 is iOS-only).
    expect(find.byType(SignInWithAppleButton), findsNothing);
  });

  testWidgets('HU-01: "Continuar sin cuenta" nunca bloquea salir de Login',
      (tester) async {
    var skipped = false;
    await pumpLogin(tester, onSkip: () => skipped = true);

    await tester.tap(find.text('Continuar sin cuenta'));
    await tester.pump();

    expect(skipped, isTrue);
  });

  testWidgets('HU-01: el botón de cerrar también permite posponer sin fricción',
      (tester) async {
    var skipped = false;
    await pumpLogin(tester, onSkip: () => skipped = true);

    await tester.tap(find.byIcon(LucideIcons.x));
    await tester.pump();

    expect(skipped, isTrue);
  });

  testWidgets('HU-02: continuar con Google muestra loading y luego navega',
      (tester) async {
    var signedIn = false;
    when(() => signInWithGoogle()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Right(SignedIn(user));
    });

    await pumpLogin(
      tester,
      onSignedIn: ({required signedInAfterConflict}) => signedIn = true,
    );

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pump();

    // Mid-flight: the button swaps its content for a spinner.
    final button =
        tester.widget<GoogleSignInButton>(find.byType(GoogleSignInButton));
    expect(button.isLoading, isTrue);

    await tester.pumpAndSettle();

    expect(signedIn, isTrue);
  });

  testWidgets(
      'GH-25: un login con Apple no muestra el botón de Google como '
      'cargando', (tester) async {
    late LoginCubit cubit;
    when(() => signInWithApple()).thenAnswer((_) async {
      await Future<void>.delayed(const Duration(milliseconds: 10));
      return const Right(
        SignedIn(
          AuthUser(
            id: 'apple-1',
            displayName: 'Camila',
            provider: AuthProvider.apple,
          ),
        ),
      );
    });

    await tester.pumpAuthWidget(
      BlocProvider(
        create: (_) => cubit = LoginCubit(
          signInWithGoogle,
          signInWithApple,
          resolveAccountConflict,
          cancelAccountConflict,
        ),
        child: LoginPage(
          onSignedIn: ({required signedInAfterConflict}) {},
          onSkip: () {},
        ),
      ),
      wrapInScaffold: false,
    );

    unawaited(cubit.continueWithApple());
    await tester.pump();

    // Mid-flight: only the provider that is actually loading shows a
    // spinner — the Google button (the only one this test host can render,
    // see the `SignInWithAppleButton` note above) must stay in its resting
    // state.
    final button =
        tester.widget<GoogleSignInButton>(find.byType(GoogleSignInButton));
    expect(button.isLoading, isFalse);

    await tester.pumpAndSettle();
  });

  testWidgets(
      'HU-02: un fallo real muestra un snackbar con acción de reintentar',
      (tester) async {
    when(() => signInWithGoogle())
        .thenAnswer((_) async => const Left(NetworkFailure('offline')));

    await pumpLogin(tester);

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pumpAndSettle();

    expect(find.text('No pudimos iniciar sesión con Google'), findsOneWidget);
    expect(find.text('Reintentar'), findsOneWidget);
  });

  testWidgets('cancelar el sign-in de Google no muestra ningún snackbar',
      (tester) async {
    when(() => signInWithGoogle()).thenAnswer(
      (_) async => const Left(AuthCancelledFailure('cancelled')),
    );

    await pumpLogin(tester);

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pumpAndSettle();

    expect(find.byType(SnackBar), findsNothing);
  });

  testWidgets(
      'un conflicto de cuenta muestra la hoja bloqueante y "Borrar y '
      'continuar" completa el sign-in tras resolveConflict', (tester) async {
    var lastSignedInAfterConflict = false;
    when(() => signInWithGoogle()).thenAnswer(
      (_) async => const Right(AccountConflictDetected()),
    );
    when(() => resolveAccountConflict())
        .thenAnswer((_) async => const Right(user));

    await pumpLogin(
      tester,
      onSignedIn: ({required signedInAfterConflict}) =>
          lastSignedInAfterConflict = signedInAfterConflict,
    );

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pumpAndSettle();

    expect(
      find.text('Hay datos de otra cuenta en este dispositivo'),
      findsOneWidget,
    );

    await tester.tap(find.text('Borrar y continuar'));
    await tester.pumpAndSettle();

    verify(() => resolveAccountConflict()).called(1);
    expect(lastSignedInAfterConflict, isTrue);
  });

  testWidgets(
      'cancelar la hoja de conflicto cierra la sesión sin completar el '
      'sign-in', (tester) async {
    var signedIn = false;
    when(() => signInWithGoogle()).thenAnswer(
      (_) async => const Right(AccountConflictDetected()),
    );
    when(() => cancelAccountConflict())
        .thenAnswer((_) async => const Right(unit));

    await pumpLogin(
      tester,
      onSignedIn: ({required signedInAfterConflict}) => signedIn = true,
    );

    await tester.tap(find.byType(GoogleSignInButton));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Cancelar'));
    await tester.pumpAndSettle();

    verify(() => cancelAccountConflict()).called(1);
    verifyNever(() => resolveAccountConflict());
    expect(signedIn, isFalse);
    expect(
      find.text('Hay datos de otra cuenta en este dispositivo'),
      findsNothing,
    );
  });
}
