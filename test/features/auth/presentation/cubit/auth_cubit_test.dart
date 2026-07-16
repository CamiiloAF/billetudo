import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/auth/presentation/cubit/auth_cubit.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchAuthSession extends Mock implements WatchAuthSession {}

class MockSignOut extends Mock implements SignOut {}

void main() {
  late MockWatchAuthSession watchAuthSession;
  late MockSignOut signOut;

  const user = AuthUser(
    id: 'google-1',
    displayName: 'Camila',
    provider: AuthProvider.google,
  );

  setUp(() {
    watchAuthSession = MockWatchAuthSession();
    signOut = MockSignOut();
  });

  test('arranca con la sesión actual del caso de uso', () {
    when(() => watchAuthSession.current)
        .thenReturn(const AuthSession.signedIn(user));
    when(() => watchAuthSession()).thenAnswer((_) => const Stream.empty());

    final cubit = AuthCubit(watchAuthSession, signOut);

    expect(cubit.state, const AuthSession.signedIn(user));
  });

  blocTest<AuthCubit, AuthSession>(
    'start reemite cada cambio del stream de sesión (HU-01/HU-06)',
    setUp: () {
      when(() => watchAuthSession.current)
          .thenReturn(const AuthSession.signedOut());
      when(() => watchAuthSession()).thenAnswer(
        (_) => Stream.value(const AuthSession.signedIn(user)),
      );
    },
    build: () => AuthCubit(watchAuthSession, signOut),
    act: (cubit) => cubit.start(),
    expect: () => [const AuthSession.signedIn(user)],
  );

  test('signOut delega en el caso de uso sin tocar la sesión localmente',
      () async {
    when(() => watchAuthSession.current)
        .thenReturn(const AuthSession.signedOut());
    when(() => watchAuthSession()).thenAnswer((_) => const Stream.empty());
    when(() => signOut()).thenAnswer((_) async => const Right(unit));

    final cubit = AuthCubit(watchAuthSession, signOut);
    await cubit.signOut();

    verify(() => signOut()).called(1);
  });
}
