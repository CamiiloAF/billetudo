import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/auth_user.dart';
import 'package:billetudo/features/auth/domain/entities/merge_summary.dart';
import 'package:billetudo/features/auth/domain/usecases/delete_account.dart';
import 'package:billetudo/features/auth/domain/usecases/merge_local_data.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_apple.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_in_with_google.dart';
import 'package:billetudo/features/auth/domain/usecases/sign_out.dart';
import 'package:billetudo/features/auth/domain/usecases/watch_auth_session.dart';
import 'package:billetudo/features/auth/domain/usecases/wipe_local_data.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'auth_repository_mock.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() {
    repository = MockAuthRepository();
  });

  const user = AuthUser(
    id: 'google-1',
    displayName: 'Camila Agudelo',
    provider: AuthProvider.google,
  );

  test('HU-02: SignInWithGoogle delega en el repositorio', () async {
    when(() => repository.signInWithGoogle())
        .thenAnswer((_) async => const Right(user));

    final result = await SignInWithGoogle(repository)();

    expect(result.getOrElse((_) => throw StateError('left')), user);
    verify(() => repository.signInWithGoogle()).called(1);
  });

  test('HU-03: SignInWithApple delega en el repositorio', () async {
    when(() => repository.signInWithApple())
        .thenAnswer((_) async => const Right(user));

    final result = await SignInWithApple(repository)();

    expect(result.isRight(), isTrue);
    verify(() => repository.signInWithApple()).called(1);
  });

  test('HU-04: MergeLocalData reporta el resumen', () async {
    const summary = MergeSummary(
      accountsCount: 2,
      transactionsCount: 10,
      categoriesCount: 5,
    );
    when(() => repository.mergeLocalData())
        .thenAnswer((_) async => const Right(summary));

    final result = await MergeLocalData(repository)();

    expect(result.getOrElse((_) => throw StateError('left')), summary);
  });

  test('HU-06: SignOut no toca datos locales, solo el repositorio', () async {
    when(() => repository.signOut()).thenAnswer((_) async => const Right(unit));

    final result = await SignOut(repository)();

    expect(result.isRight(), isTrue);
    verify(() => repository.signOut()).called(1);
  });

  test('HU-07: DeleteAccount delega en el repositorio', () async {
    when(() => repository.deleteAccount())
        .thenAnswer((_) async => const Right(unit));

    final result = await DeleteAccount(repository)();

    expect(result.isRight(), isTrue);
  });

  test('HU-07 paso 2: WipeLocalData delega en el repositorio', () async {
    when(() => repository.wipeLocalData())
        .thenAnswer((_) async => const Right(unit));

    final result = await WipeLocalData(repository)();

    expect(result.isRight(), isTrue);
  });

  test('WatchAuthSession expone el stream y el valor actual', () async {
    when(() => repository.currentSession)
        .thenReturn(const AuthSession.signedOut());
    when(() => repository.watchSession())
        .thenAnswer((_) => Stream.value(const AuthSession.signedIn(user)));

    final usecase = WatchAuthSession(repository);

    expect(usecase.current, const AuthSession.signedOut());
    await expectLater(
      usecase(),
      emits(const AuthSession.signedIn(user)),
    );
  });

  test('propaga el fallo del repositorio', () async {
    when(() => repository.signInWithGoogle()).thenAnswer(
      (_) async => const Left(AuthCancelledFailure('cancelled')),
    );

    final result = await SignInWithGoogle(repository)();

    expect(result.getLeft().toNullable(), isA<AuthCancelledFailure>());
  });
}
