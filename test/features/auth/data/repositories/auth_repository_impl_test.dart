import 'dart:async';
import 'dart:io';

import 'package:billetudo/core/database/database_connection.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/auth/data/datasources/apple_auth_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/google_auth_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_ownership_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_summary_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/local_data_wipe_datasource.dart';
import 'package:billetudo/features/auth/data/datasources/powersync_connector.dart';
import 'package:billetudo/features/auth/data/models/social_credential.dart';
import 'package:billetudo/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:billetudo/features/auth/domain/entities/auth_provider.dart';
import 'package:billetudo/features/auth/domain/entities/auth_session.dart';
import 'package:billetudo/features/auth/domain/entities/merge_summary.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:path/path.dart' as p;
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

class MockGoogleAuthDatasource extends Mock implements GoogleAuthDatasource {}

class MockAppleAuthDatasource extends Mock implements AppleAuthDatasource {}

class MockLocalDataSummaryDatasource extends Mock
    implements LocalDataSummaryDatasource {}

class MockLocalDataWipeDatasource extends Mock
    implements LocalDataWipeDatasource {}

class MockLocalDataOwnershipDatasource extends Mock
    implements LocalDataOwnershipDatasource {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockFunctionsClient extends Mock implements FunctionsClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPowerSyncConnector extends Mock implements PowerSyncConnector {}

void main() {
  late MockGoogleAuthDatasource google;
  late MockAppleAuthDatasource apple;
  late MockLocalDataSummaryDatasource summaries;
  late MockLocalDataWipeDatasource wipe;
  late MockLocalDataOwnershipDatasource ownership;
  late MockSupabaseClient supabase;
  late MockFunctionsClient functions;
  late MockGoTrueClient auth;
  // `PowerSyncDatabase` is a `base class` in its own library, so mocktail
  // cannot subtype it (see functions_client.dart docs). A real, throwaway
  // instance is cheap enough here — same pattern as `test/core/di_test.dart`.
  late PowerSyncDatabase powerSync;
  late Directory tempDir;
  late MockPowerSyncConnector connector;
  late AuthRepositoryImpl repository;
  // Feeds `GoTrueClient.onAuthStateChange`, which the repository's
  // constructor now subscribes to. Broadcast so more than one repository
  // instance (a test that rebuilds one with a restored session) can listen,
  // and never closed mid-test so no listener sees an unexpected `onDone`.
  late StreamController<AuthState> authStateChanges;
  late List<AuthRepositoryImpl> builtRepositories;

  /// Builds a repository against the current stubs. Every instance is torn
  /// down in `tearDown` so its auth-state listener doesn't leak into the
  /// next test.
  AuthRepositoryImpl buildRepository() {
    final built = AuthRepositoryImpl(
      google,
      apple,
      summaries,
      wipe,
      ownership,
      supabase,
      powerSync,
      connector,
    );
    builtRepositories.add(built);
    return built;
  }

  /// A Supabase session for [user], as `auth.currentSession` would return it
  /// after `supabase_flutter` restored it from disk on relaunch.
  Session sessionFor(User user) => Session(
        accessToken: 'access-token',
        tokenType: 'bearer',
        user: user,
      );

  User supabaseUser({
    required String id,
    Map<String, dynamic> appMetadata = const {},
    Map<String, dynamic> userMetadata = const {},
    String? email,
  }) =>
      User(
        id: id,
        appMetadata: appMetadata,
        userMetadata: userMetadata,
        email: email,
        aud: 'authenticated',
        createdAt: DateTime(2026, 7, 15).toIso8601String(),
      );

  setUp(() async {
    google = MockGoogleAuthDatasource();
    apple = MockAppleAuthDatasource();
    summaries = MockLocalDataSummaryDatasource();
    wipe = MockLocalDataWipeDatasource();
    ownership = MockLocalDataOwnershipDatasource();
    supabase = MockSupabaseClient();
    functions = MockFunctionsClient();
    auth = MockGoTrueClient();
    tempDir = await Directory.systemTemp.createTemp(
      'auth_repository_impl_test',
    );
    powerSync = await openPowerSyncDatabase(
      path: p.join(tempDir.path, 'test.sqlite'),
    );
    connector = MockPowerSyncConnector();

    authStateChanges = StreamController<AuthState>.broadcast();
    builtRepositories = [];

    when(() => supabase.functions).thenReturn(functions);
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => google.signOutSilently()).thenAnswer((_) async {});
    when(() => auth.onAuthStateChange)
        .thenAnswer((_) => authStateChanges.stream);
    // Default for every existing test: no session persisted from a previous
    // run, i.e. the app relaunches signed out.
    when(() => auth.currentSession).thenReturn(null);
    // `PowerSyncDatabase` cannot be mocked (see above), so the connector is
    // the observable proxy for "did the repository connect?": a real
    // `connect()` asks it for credentials within milliseconds. Returning null
    // keeps the sync loop from ever reaching the network.
    when(() => connector.fetchCredentials()).thenAnswer((_) async => null);
    when(() => connector.getCredentialsCached()).thenAnswer((_) async => null);
    when(() => connector.prefetchCredentials()).thenAnswer((_) async => null);

    repository = buildRepository();
  });

  tearDown(() async {
    for (final built in builtRepositories) {
      await built.dispose();
    }
    await authStateChanges.close();
    await powerSync.close();
    await tempDir.delete(recursive: true);
  });

  /// Collects everything `watchSession()` emits, starting with the current
  /// session it replays on subscription. Shared by the sign-out groups, which
  /// care as much about what is *not* emitted as about the returned `Result`.
  Future<List<AuthSession>> watchSessions(AuthRepositoryImpl repo) async {
    final emitted = <AuthSession>[];
    repo.watchSession().listen(emitted.add);
    await pumpEventQueue();
    return emitted;
  }

  /// A repository whose constructor found a persisted Supabase session, i.e.
  /// the signed-in starting point every sign-out test needs.
  AuthRepositoryImpl buildSignedInRepository({String id = 'user-7'}) {
    when(() => auth.currentSession).thenReturn(sessionFor(supabaseUser(id: id)));
    return buildRepository();
  }

  group('signOut (HU-06)', () {
    test(
      'devuelve Right, deja la sesion cerrada y lo reporta a la UI cuando '
      'los tres pasos salen bien',
      () async {
        await repository.dispose();
        final signedIn = buildSignedInRepository();
        final emitted = await watchSessions(signedIn);

        final result = await signedIn.signOut();
        await pumpEventQueue();

        expect(result, const Right<Failure, Unit>(unit));
        expect(signedIn.currentSession, const AuthSession.signedOut());
        expect(emitted.last, const AuthSession.signedOut());
        verify(() => google.signOutSilently()).called(1);
        verify(() => auth.signOut()).called(1);
      },
    );

    test(
      'devuelve Left cuando falla el signOut de Supabase, SIN emitir '
      'signedOut ni cambiar la sesion actual',
      () async {
        await repository.dispose();
        final signedIn = buildSignedInRepository();
        final sessionBefore = signedIn.currentSession;
        final emitted = await watchSessions(signedIn);
        when(() => auth.signOut())
            .thenThrow(const AuthException('no se pudo cerrar sesion'));

        final result = await signedIn.signOut();
        await pumpEventQueue();

        expect(result, isA<Left<Failure, Unit>>());
        expect((result as Left).value, isA<NetworkFailure>());
        // Lo que de verdad protege este test: la sesion sobrevive en disco, y
        // decirle a la UI que esta deslogueada crea un estado que se revierte
        // solo al reabrir la app (`_restoreSession` encuentra el token,
        // PowerSync reconecta y repuebla).
        expect(signedIn.currentSession, sessionBefore);
        expect(signedIn.currentSession.isSignedIn, isTrue);
        expect(
          emitted,
          [sessionBefore],
          reason: 'watchSession() solo debio replayar la sesion vigente: nada '
              'de signedOut mientras el token sigue en disco',
        );
      },
    );

    test(
      'la desconexion de PowerSync esta COMPLETADA cuando signOut resuelve, '
      'no solo disparada',
      () async {
        // `PowerSyncDatabase` no es mockeable (es `base`), asi que el gancho
        // observable es su propio estado: mientras una peticion de
        // credenciales sigue en vuelo el status queda en `connecting`, y solo
        // un `disconnect()` **esperado** lo baja. Con el `unawaited(...)`
        // anterior, este `connecting` seguia en true al resolver signOut.
        Future<Null> slowCredentials() => Future<Null>.delayed(
              const Duration(seconds: 2),
              () => null,
            );
        when(() => connector.fetchCredentials())
            .thenAnswer((_) => slowCredentials());
        when(() => connector.getCredentialsCached())
            .thenAnswer((_) => slowCredentials());
        when(() => connector.prefetchCredentials())
            .thenAnswer((_) => slowCredentials());

        await repository.dispose();
        final signedIn = buildSignedInRepository();
        await untilCalled(() => connector.fetchCredentials())
            .timeout(const Duration(seconds: 5));
        expect(
          powerSync.currentStatus.connecting,
          isTrue,
          reason: 'precondicion: el sync debe estar levantandose para que '
              'apagarlo signifique algo',
        );

        final result = await signedIn.signOut();

        expect(result, const Right<Failure, Unit>(unit));
        expect(
          powerSync.currentStatus.connecting,
          isFalse,
          reason: 'un wipe posterior correria contra un stream vivo: es '
              'exactamente la carrera que HU-06 evita',
        );
        expect(powerSync.connected, isFalse);
      },
      timeout: const Timeout(Duration(seconds: 30)),
    );

    test(
      'espera de verdad al signOut de Supabase antes de resolver',
      () async {
        await repository.dispose();
        final signedIn = buildSignedInRepository();
        final supabaseSignOut = Completer<void>();
        when(() => auth.signOut()).thenAnswer((_) => supabaseSignOut.future);

        var resolved = false;
        final pending = signedIn.signOut().then((_) => resolved = true);
        await pumpEventQueue();

        expect(
          resolved,
          isFalse,
          reason: 'con `unawaited` esto ya habria devuelto Right sin que la '
              'sesion de Supabase estuviera cerrada',
        );
        expect(signedIn.currentSession.isSignedIn, isTrue);

        supabaseSignOut.complete();
        await pending;

        expect(resolved, isTrue);
        expect(signedIn.currentSession, const AuthSession.signedOut());
      },
    );
  });

  group('GoogleAuthDatasource.signOutSilently (contrato de HU-06)', () {
    test(
      'se traga sus propios errores, asi que nunca puede tumbar el cierre de '
      'sesion',
      () async {
        // Sin plugin de `google_sign_in` bajo `flutter test`, `initialize()`
        // falla de verdad. El datasource real debe absorberlo: si alguien
        // quita ese try/catch, `_clearLocalSession` empieza a propagar la
        // excepcion y el usuario no puede cerrar sesion.
        await expectLater(
          GoogleAuthDatasource().signOutSilently(),
          completes,
        );
      },
    );
  });

  group('deleteAccount', () {
    test(
      'invokes the delete-account Edge Function and clears the local '
      'session on success',
      () async {
        when(() => functions.invoke('delete-account')).thenAnswer(
          (_) async => const FunctionResponse(
            data: {'success': true},
            status: 200,
          ),
        );

        final result = await repository.deleteAccount();

        expect(result, const Right<Failure, Unit>(unit));
        verify(() => functions.invoke('delete-account')).called(1);
        verify(() => google.signOutSilently()).called(1);
        verify(() => auth.signOut()).called(1);
        expect(powerSync.connected, isFalse);
      },
    );

    test(
      'sigue devolviendo Right y emitiendo signedOut aunque falle el signOut '
      'de Supabase: la cuenta en la nube ya no existe',
      () async {
        await repository.dispose();
        final signedIn = buildSignedInRepository();
        final emitted = await watchSessions(signedIn);
        when(() => functions.invoke('delete-account')).thenAnswer(
          (_) async => const FunctionResponse(
            data: {'success': true},
            status: 200,
          ),
        );
        when(() => auth.signOut())
            .thenThrow(const AuthException('no se pudo cerrar sesion'));

        final result = await signedIn.deleteAccount();
        await pumpEventQueue();

        // Al reves que HU-06: aca un fallo de limpieza local no puede
        // convertir un borrado ya consumado en un error que el usuario lea
        // como "no paso nada".
        expect(result, const Right<Failure, Unit>(unit));
        expect(signedIn.currentSession, const AuthSession.signedOut());
        expect(emitted.last, const AuthSession.signedOut());
        expect(powerSync.connected, isFalse);
      },
    );

    test(
      'maps a body that reports success: false without keeping a local '
      'session',
      () async {
        when(() => functions.invoke('delete-account')).thenAnswer(
          (_) async => const FunctionResponse(
            data: {'error': 'unexpected shape'},
            status: 200,
          ),
        );

        final result = await repository.deleteAccount();

        expect(result, isA<Left<Failure, Unit>>());
        expect((result as Left).value, isA<NetworkFailure>());
        verifyNever(() => google.signOutSilently());
      },
    );

    test(
      'maps a FunctionException to a NetworkFailure carrying the server '
      'error message',
      () async {
        when(() => functions.invoke('delete-account')).thenThrow(
          const FunctionException(
            status: 401,
            details: {'error': 'invalid or expired session'},
          ),
        );

        final result = await repository.deleteAccount();

        expect(result, isA<Left<Failure, Unit>>());
        final failure = (result as Left).value as NetworkFailure;
        expect(failure.message, contains('invalid or expired session'));
        verifyNever(() => google.signOutSilently());
      },
    );

    test(
      'keeps the dataDeleted signal in the failure message when the rows '
      'were wiped but deleting the auth user failed',
      () async {
        when(() => functions.invoke('delete-account')).thenThrow(
          const FunctionException(
            status: 500,
            details: {
              'error': 'auth.admin.deleteUser failed',
              'dataDeleted': true,
            },
          ),
        );

        final result = await repository.deleteAccount();

        final failure = (result as Left).value as NetworkFailure;
        expect(failure.message, contains('auth.admin.deleteUser failed'));
        expect(failure.message, contains('dataDeleted'));
      },
    );
  });

  group('mergeLocalData', () {
    /// Signs the repository in via Google (HU-02) so `mergeLocalData` (HU-04)
    /// has a `currentSession.user` to claim rows for.
    Future<void> signIn() async {
      when(() => google.signIn()).thenAnswer(
        (_) async => const SocialCredential(
          providerUserId: 'google-1',
          displayName: 'Ana',
          idToken: 'id-token',
        ),
      );
      when(
        () => auth.signInWithIdToken(
          provider: OAuthProvider.google,
          idToken: 'id-token',
        ),
      ).thenAnswer(
        (_) async => AuthResponse(
          user: User(
            id: 'user-1',
            appMetadata: const {},
            userMetadata: const {},
            aud: 'authenticated',
            createdAt: DateTime(2026, 7, 15).toIso8601String(),
          ),
        ),
      );

      final result = await repository.signInWithGoogle();
      expect(result.isRight(), isTrue);
    }

    test(
      'claims unowned local rows for the signed-in account (decision #6, '
      'docs/requirements/05-auth-sync.md)',
      () async {
        await signIn();
        const summary = MergeSummary(
          accountsCount: 1,
          transactionsCount: 2,
          categoriesCount: 3,
        );
        when(() => summaries.getSummary()).thenAnswer((_) async => summary);
        when(() => ownership.claimUnownedRows('user-1'))
            .thenAnswer((_) async => const Right(unit));

        final result = await repository.mergeLocalData();

        expect(result, const Right<Failure, MergeSummary>(summary));
        verify(() => ownership.claimUnownedRows('user-1')).called(1);
      },
    );

    test(
      'propagates a NetworkFailure from claimUnownedRows (decision #12: the '
      'seed-category ownership check against Postgres can fail) instead of '
      'swallowing it',
      () async {
        await signIn();
        when(() => summaries.getSummary()).thenAnswer(
          (_) async => const MergeSummary(
            accountsCount: 0,
            transactionsCount: 0,
            categoriesCount: 0,
          ),
        );
        when(() => ownership.claimUnownedRows('user-1')).thenAnswer(
          (_) async => const Left(NetworkFailure('sin conexión')),
        );

        final result = await repository.mergeLocalData();

        expect(result.isLeft(), isTrue);
        expect((result as Left).value, isA<NetworkFailure>());
      },
    );
  });

  group('session restore on construction', () {
    /// Waits until the repository asked the connector for credentials, which
    /// only happens because `PowerSyncDatabase.connect()` was called.
    Future<void> expectConnected() => untilCalled(
          () => connector.fetchCredentials(),
        ).timeout(
          const Duration(seconds: 5),
          onTimeout: () => fail(
            'PowerSync was never connected: the connector was never asked '
            'for credentials.',
          ),
        );

    test(
      'rebuilds the signed-in session from the persisted Supabase session '
      'and starts sync (regression: every relaunch used to come up signed '
      'out with sync off)',
      () async {
        await repository.dispose();
        when(() => auth.currentSession).thenReturn(
          sessionFor(
            supabaseUser(
              id: 'user-7',
              userMetadata: const {
                'full_name': 'Ana',
                'avatar_url': 'https://example.com/ana.png',
              },
              email: 'ana@example.com',
            ),
          ),
        );

        final restored = buildRepository();

        expect(restored.currentSession.isSignedIn, isTrue);
        final user = restored.currentSession.user!;
        expect(user.id, 'user-7');
        expect(user.displayName, 'Ana');
        expect(user.email, 'ana@example.com');
        expect(user.avatarUrl, 'https://example.com/ana.png');
        expect(user.provider, AuthProvider.google);
        await expectConnected();
      },
    );

    test(
      'stays signed out and does not start sync when there is no persisted '
      'session',
      () async {
        // `repository` was built in setUp with `currentSession` == null.
        expect(repository.currentSession, const AuthSession.signedOut());
        await Future<void>.delayed(const Duration(milliseconds: 300));
        verifyNever(() => connector.fetchCredentials());
      },
    );

    test('maps the Apple provider from the Supabase app metadata', () async {
      await repository.dispose();
      when(() => auth.currentSession).thenReturn(
        sessionFor(
          supabaseUser(
            id: 'user-1',
            appMetadata: const {'provider': 'apple'},
          ),
        ),
      );

      final restored = buildRepository();

      expect(restored.currentSession.user!.provider, AuthProvider.apple);
    });

    test(
      'falls back to the email as display name when the user metadata has '
      'no name',
      () async {
        await repository.dispose();
        when(() => auth.currentSession).thenReturn(
          sessionFor(supabaseUser(id: 'user-1', email: 'sin.nombre@example.com')),
        );

        final restored = buildRepository();

        expect(
          restored.currentSession.user!.displayName,
          'sin.nombre@example.com',
        );
      },
    );

    test(
      'falls back to an empty display name rather than dropping a session '
      'with neither name nor email',
      () async {
        await repository.dispose();
        when(() => auth.currentSession).thenReturn(sessionFor(supabaseUser(id: 'user-1')));

        final restored = buildRepository();

        expect(restored.currentSession.isSignedIn, isTrue);
        expect(restored.currentSession.user!.displayName, '');
      },
    );

    test('prefers name over email when full_name is absent', () async {
      await repository.dispose();
      when(() => auth.currentSession).thenReturn(
        sessionFor(
          supabaseUser(
            id: 'user-1',
            userMetadata: const {'name': 'Ana G.'},
            email: 'ana@example.com',
          ),
        ),
      );

      final restored = buildRepository();

      expect(restored.currentSession.user!.displayName, 'Ana G.');
    });
  });

  group('onAuthStateChange', () {
    /// Collects everything `watchSession()` emits, starting with the current
    /// session it replays on subscription.
    Future<List<AuthSession>> watch(AuthRepositoryImpl repo) async {
      final emitted = <AuthSession>[];
      repo.watchSession().listen(emitted.add);
      await pumpEventQueue();
      return emitted;
    }

    test(
      'emits signedOut when Supabase reports the session is gone (expired '
      'refresh token, sign-out elsewhere)',
      () async {
        await repository.dispose();
        when(() => auth.currentSession)
            .thenReturn(sessionFor(supabaseUser(id: 'user-7')));
        final restored = buildRepository();
        final emitted = await watch(restored);

        authStateChanges.add(
          const AuthState(AuthChangeEvent.signedOut, null),
        );
        await pumpEventQueue();

        expect(restored.currentSession, const AuthSession.signedOut());
        expect(emitted.last, const AuthSession.signedOut());
      },
    );

    test('ignores a null session while already signed out', () async {
      final emitted = await watch(repository);

      authStateChanges.add(const AuthState(AuthChangeEvent.signedOut, null));
      await pumpEventQueue();

      expect(emitted, [const AuthSession.signedOut()]);
    });

    test(
      'does not re-emit for the same user id, keeping the richer identity '
      'from the interactive sign-in (Apple only returns the name once)',
      () async {
        when(() => google.signIn()).thenAnswer(
          (_) async => const SocialCredential(
            providerUserId: 'google-1',
            displayName: 'Ana',
            idToken: 'id-token',
            avatarUrl: 'https://example.com/ana.png',
          ),
        );
        when(
          () => auth.signInWithIdToken(
            provider: OAuthProvider.google,
            idToken: 'id-token',
          ),
        ).thenAnswer(
          (_) async => AuthResponse(user: supabaseUser(id: 'user-1')),
        );
        await repository.signInWithGoogle();
        final emitted = await watch(repository);

        // Same account, but the bare Supabase user has no name/avatar.
        authStateChanges.add(
          AuthState(
            AuthChangeEvent.tokenRefreshed,
            sessionFor(supabaseUser(id: 'user-1')),
          ),
        );
        await pumpEventQueue();

        expect(emitted.length, 1, reason: 'no new session should be emitted');
        expect(repository.currentSession.user!.displayName, 'Ana');
        expect(
          repository.currentSession.user!.avatarUrl,
          'https://example.com/ana.png',
        );
      },
    );

    test('emits the new session when a different user id signs in', () async {
      final emitted = await watch(repository);

      authStateChanges.add(
        AuthState(
          AuthChangeEvent.signedIn,
          sessionFor(
            supabaseUser(
              id: 'user-2',
              userMetadata: const {'full_name': 'Beto'},
            ),
          ),
        ),
      );
      await pumpEventQueue();

      expect(repository.currentSession.isSignedIn, isTrue);
      expect(repository.currentSession.user!.id, 'user-2');
      expect(emitted.length, 2);
      expect(emitted.last.user!.displayName, 'Beto');
      await untilCalled(() => connector.fetchCredentials())
          .timeout(const Duration(seconds: 5));
    });

    test(
      'swallows an error on the stream (a failed token refresh, typically '
      'just being offline) without touching the session',
      () async {
        await repository.dispose();
        when(() => auth.currentSession)
            .thenReturn(sessionFor(supabaseUser(id: 'user-7')));
        final restored = buildRepository();
        final signedIn = restored.currentSession;
        final emitted = await watch(restored);

        // Supabase reports a failed refresh as an *error* on this stream, not
        // as an event. Without the listener's `onError` this escapes into the
        // test's zone as an uncaught async error and fails the test on its
        // own — which is exactly the regression this guards.
        authStateChanges.addError(
          const AuthException('Invalid Refresh Token'),
          StackTrace.current,
        );
        await pumpEventQueue();

        expect(restored.currentSession, signedIn);
        expect(restored.currentSession.isSignedIn, isTrue);
        expect(restored.currentSession.user!.id, 'user-7');
        expect(
          emitted,
          [signedIn],
          reason: 'watchSession() should only have replayed the current '
              'session, with nothing emitted for the error',
        );
      },
    );

    test('dispose() stops listening without throwing', () async {
      await repository.dispose();
      builtRepositories.remove(repository);

      authStateChanges.add(
        AuthState(AuthChangeEvent.signedIn, sessionFor(supabaseUser(id: 'user-1'))),
      );
      await pumpEventQueue();

      expect(repository.currentSession, const AuthSession.signedOut());
    });
  });
}
