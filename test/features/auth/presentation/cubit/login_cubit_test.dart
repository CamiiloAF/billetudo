import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:billetudo/features/auth/presentation/cubit/login_cubit.dart';
import 'package:billetudo/features/auth/presentation/cubit/login_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

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

  LoginCubit build() => LoginCubit(signInWithGoogle, signInWithApple);

  blocTest<LoginCubit, LoginState>(
    'HU-02: continueWithGoogle emite loading y luego signedIn',
    build: build,
    setUp: () => when(() => signInWithGoogle())
        .thenAnswer((_) async => const Right(user)),
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
        .thenAnswer((_) async => const Right(user)),
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
    'una excepción (backend no cableado) se surface como error, no crashea',
    build: build,
    setUp: () => when(() => signInWithGoogle()).thenThrow(UnimplementedError()),
    act: (cubit) => cubit.continueWithGoogle(),
    expect: () => [
      const LoginState(
        status: LoginStatus.loading,
        lastProvider: AuthProvider.google,
      ),
      isA<LoginState>().having((s) => s.status, 'status', LoginStatus.error),
    ],
  );
}
