import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
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

void main() {
  late MockSignInWithGoogle signInWithGoogle;
  late MockSignInWithApple signInWithApple;

  const user = AuthUser(
    id: 'google-1',
    displayName: 'Camila',
    provider: AuthProvider.google,
  );

  setUp(() {
    signInWithGoogle = MockSignInWithGoogle();
    signInWithApple = MockSignInWithApple();
  });

  Future<void> pumpLogin(
    WidgetTester tester, {
    VoidCallback? onSignedIn,
    VoidCallback? onSkip,
  }) =>
      tester.pumpAuthWidget(
        BlocProvider(
          create: (_) => LoginCubit(signInWithGoogle, signInWithApple),
          child: LoginPage(
            onSignedIn: onSignedIn ?? () {},
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
      return const Right(user);
    });

    await pumpLogin(tester, onSignedIn: () => signedIn = true);

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
}
