import 'dart:async';

import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/merge_summary.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/apple_auth_datasource.dart';
import '../datasources/google_auth_datasource.dart';
import '../datasources/local_data_summary_datasource.dart';
import '../datasources/local_data_wipe_datasource.dart';
import '../models/social_credential.dart';

/// Real Google/Apple SDK integration plus the local-only halves of HU-04/06/07
/// (counting what already lives on this device, stopping sync, wiping local
/// rows on request). Everything that requires an authenticated backend —
/// creating/merging/deleting the *cloud* account — is not implemented yet:
/// PowerSync/Supabase are not wired into this project (see CLAUDE.md →
/// "Estado del repo" and `docs/requirements/05-auth-sync.md`). Those methods
/// throw `UnimplementedError` with a comment pointing at what is missing,
/// rather than silently pretending to succeed.
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._google,
    this._apple,
    this._summaries,
    this._wipe,
  );

  final GoogleAuthDatasource _google;
  final AppleAuthDatasource _apple;
  final LocalDataSummaryDatasource _summaries;
  final LocalDataWipeDatasource _wipe;

  AuthSession _current = const AuthSession.signedOut();
  final _controller = StreamController<AuthSession>.broadcast();

  @override
  AuthSession get currentSession => _current;

  @override
  Stream<AuthSession> watchSession() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  FutureResult<AuthUser> signInWithGoogle() async {
    try {
      final credential = await _google.signIn();
      final user = await _completeSignIn(credential, AuthProvider.google);
      return Right(user);
    } on SocialAuthCancelledException {
      return const Left(AuthCancelledFailure('user cancelled Google sign-in'));
    }
  }

  @override
  FutureResult<AuthUser> signInWithApple() async {
    try {
      final credential = await _apple.signIn();
      final user = await _completeSignIn(credential, AuthProvider.apple);
      return Right(user);
    } on AppleAuthCancelledException {
      return const Left(AuthCancelledFailure('user cancelled Apple sign-in'));
    }
  }

  /// Exchanges an already-collected provider credential for a real session.
  ///
  /// The client-side SDK call above (Google/Apple) already ran for real by
  /// the time this throws — only the backend half is missing.
  // TODO(auth-sync): call `supabase.auth.signInWithIdToken(provider: ...,
  // idToken: credential.idToken)` once Supabase is wired, then persist the
  // resulting session and emit it on `_controller`.
  Future<AuthUser> _completeSignIn(
    SocialCredential credential,
    AuthProvider provider,
  ) async {
    throw UnimplementedError(
      'AuthRepositoryImpl._completeSignIn: Supabase is not wired into this '
      'project yet, so a $provider credential cannot be exchanged for a real '
      'session. See docs/requirements/05-auth-sync.md.',
    );
  }

  @override
  FutureResult<MergeSummary> mergeLocalData() async {
    // The local half is real: this reads Drift, the actual source of truth,
    // for what already sits on this device.
    await _summaries.getSummary();
    // TODO(auth-sync): associate/upload these rows to the authenticated
    // account via PowerSync once wired (HU-04). Until then there is no
    // account to fold them into, so this throws instead of pretending the
    // merge happened.
    throw UnimplementedError(
      'AuthRepositoryImpl.mergeLocalData: Supabase/PowerSync wiring pending '
      '— local rows are counted for real but never uploaded yet.',
    );
  }

  @override
  FutureResult<Unit> signOut() async {
    // Signing out is entirely local (HU-06): it only stops sync going
    // forward and clears the cached provider session, it never touches data.
    unawaited(_google.signOutSilently());
    _current = const AuthSession.signedOut();
    _controller.add(_current);
    return const Right(unit);
  }

  @override
  FutureResult<Unit> deleteAccount() async {
    // TODO(auth-sync): call the Supabase Edge Function that deletes every row
    // owned by this user, synchronously (HU-07 ignores the tombstone cleanup
    // cron — see "Lápidas y sync rules" in the requirements doc). Pending
    // wiring, so this throws instead of a fake success.
    throw UnimplementedError(
      'AuthRepositoryImpl.deleteAccount: Supabase wiring pending — cannot '
      'delete the cloud account yet. See docs/requirements/05-auth-sync.md.',
    );
  }

  @override
  FutureResult<Unit> wipeLocalData() async {
    await _wipe.wipeAll();
    return const Right(unit);
  }
}
