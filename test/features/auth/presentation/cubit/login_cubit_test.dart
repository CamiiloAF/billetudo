import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/entities/sign_in_outcome.dart';
import 'package:billetudo/features/auth/domain/usecases/cancel_account_conflict.dart';
import 'package:billetudo/features/auth/domain/usecases/resolve_account_conflict.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:billetudo/features/auth/presentation/cubit/login_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/login_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSignInWithGoogle extends Mock implements SignInWithGoogle {}

class MockSignInWithApple extends Mock implements SignInWithApple {}

class MockResolveAccountConflict extends Mock
    implements ResolveAccountConflict {}

class MockCancelAccountConflict extends Mock
    implements CancelAccountConflict {}

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

  LoginCubit build() => LoginCubit(
        signInWithGoogle,
        signInWithApple,
        resolveAccountConflict,
        cancelAccountConflict,
      );

  blocTest<LoginCubit, LoginState>(
    'HU-02: continueWithGoogle emite loading y luego signedIn',
    build: build,
    setUp: () => when(() => signInWithGoogle())
        .thenAnswer((_) async => const Right(SignedIn(user))),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      const LoginState(
        status: LoginStatus.loading,
        lastProvider: AuthProvider.google,
      ),
      const LoginState(
        status: LoginStatus.signedIn,
        lastProvider: AuthProvider.google,
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'cancelar el sign-in vuelve a idle sin mostrar error',
    build: build,
    setUp: () => when(() => signInWithGoogle()).thenAnswer(
      (_) async => const Left(AuthCancelledFailure('cancelled')),
    ),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      const LoginState(
        status: LoginStatus.loading,
        lastProvider: AuthProvider.google,
      ),
      const LoginState(
        status: LoginStatus.idle,
        lastProvider: AuthProvider.google,
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'un fallo real emite error con el failure',
    build: build,
    setUp: () => when(() => signInWithGoogle()).thenAnswer(
      (_) async => const Left(NetworkFailure('no connection')),
    ),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      const LoginState(
        status: LoginStatus.loading,
        lastProvider: AuthProvider.google,
      ),
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.error)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'HU-03: continueWithApple usa el caso de uso de Apple',
    build: build,
    setUp: () => when(() => signInWithApple())
        .thenAnswer((_) async => const Right(SignedIn(user))),
    act: (cubit) => cubit.continueWithApple(),
    verify: (_) => verify(() => signInWithApple()).called(1),
    expect: () => [
      const LoginState(
        status: LoginStatus.loading,
        lastProvider: AuthProvider.apple,
      ),
      const LoginState(
        status: LoginStatus.signedIn,
        lastProvider: AuthProvider.apple,
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'una excepción no mapeada se surface como UnexpectedFailure conservando '
    'la causa, no como un fallo de red genérico',
    build: build,
    setUp: () => when(() => signInWithGoogle()).thenThrow(UnimplementedError()),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      const LoginState(
        status: LoginStatus.loading,
        lastProvider: AuthProvider.google,
      ),
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.error)
          .having((s) => s.failure, 'failure', isA<UnexpectedFailure>())
          .having(
            (s) => s.failure!.message,
            'failure.message',
            'sign-in failed unexpectedly',
          )
          .having(
            (s) => s.failure!.cause,
            'failure.cause',
            isA<UnimplementedError>(),
          )
          .having((s) => s.failure!.stackTrace, 'stackTrace', isNotNull),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'un sign-in que reporta AccountConflictDetected emite '
    'accountConflictDetected, no signedIn',
    build: build,
    setUp: () => when(() => signInWithGoogle()).thenAnswer(
      (_) async => const Right(AccountConflictDetected()),
    ),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      const LoginState(
        status: LoginStatus.loading,
        lastProvider: AuthProvider.google,
      ),
      const LoginState(
        status: LoginStatus.accountConflictDetected,
        lastProvider: AuthProvider.google,
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'resolveConflict emite signedIn con signedInAfterConflict en true',
    build: build,
    setUp: () => when(() => resolveAccountConflict())
        .thenAnswer((_) async => const Right(user)),
    act: (cubit) => cubit.resolveConflict(),
    expect: () => [
      const LoginState(
        status: LoginStatus.signedIn,
        signedInAfterConflict: true,
      ),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'resolveConflict propaga un fallo como error, sin marcar signedIn',
    build: build,
    setUp: () => when(() => resolveAccountConflict()).thenAnswer(
      (_) async => const Left(UnexpectedFailure('wipe failed')),
    ),
    act: (cubit) => cubit.resolveConflict(),
    expect: () => [
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.error)
          .having((s) => s.failure, 'failure', isA<UnexpectedFailure>()),
    ],
  );

  blocTest<LoginCubit, LoginState>(
    'cancelConflict vuelve a idle sin marcar signedIn',
    build: build,
    setUp: () => when(() => cancelAccountConflict())
        .thenAnswer((_) async => const Right(unit)),
    act: (cubit) => cubit.cancelConflict(),
    expect: () => [const LoginState(status: LoginStatus.idle)],
  );

  blocTest<LoginCubit, LoginState>(
    'cancelConflict propaga un fallo como error',
    build: build,
    setUp: () => when(() => cancelAccountConflict()).thenAnswer(
      (_) async => const Left(NetworkFailure('sign-out failed')),
    ),
    act: (cubit) => cubit.cancelConflict(),
    expect: () => [
      isA<LoginState>()
          .having((s) => s.status, 'status', LoginStatus.error)
          .having((s) => s.failure, 'failure', isA<NetworkFailure>()),
    ],
  );

  test(
      'Sentry BILLETUDO-F: continueWithGoogle tras close() no lanza '
      '"Cannot emit new states after calling close" (una SnackBar '
      '"reintentar" puede sobrevivir a la pantalla y volver a llamar al '
      'cubit ya cerrado)', () async {
    final cubit = build();
    when(() => signInWithGoogle())
        .thenAnswer((_) async => const Right(SignedIn(user)));
    await cubit.close();

    await expectLater(cubit.continueWithGoogle(), completes);
  });
}
