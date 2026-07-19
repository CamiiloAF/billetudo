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

    when(() => supabase.functions).thenReturn(functions);
    when(() => supabase.auth).thenReturn(auth);
    when(() => auth.signOut()).thenAnswer((_) async {});
    when(() => google.signOutSilently()).thenAnswer((_) async {});

    repository = AuthRepositoryImpl(
      google,
      apple,
      summaries,
      wipe,
      ownership,
      supabase,
      powerSync,
      connector,
    );
  });

  tearDown(() async {
    await powerSync.close();
    await tempDir.delete(recursive: true);
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
}
