import 'dart:async';

import 'package:injectable/injectable.dart';
import 'package:powersync/powersync.dart' show PowerSyncDatabase;
import 'package:supabase_flutter/supabase_flutter.dart' hide AuthUser;

import '../../../../core/error/result.dart';
import '../../domain/entities/auth_provider.dart';
import '../../domain/entities/auth_session.dart';
import '../../domain/entities/auth_user.dart';
import '../../domain/entities/merge_summary.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/apple_auth_datasource.dart';
import '../datasources/google_auth_datasource.dart';
import '../datasources/local_data_ownership_datasource.dart';
import '../datasources/local_data_summary_datasource.dart';
import '../datasources/local_data_wipe_datasource.dart';
import '../datasources/powersync_connector.dart';
import '../models/social_credential.dart';

/// Real Google/Apple SDK integration, HU-02's Supabase session exchange, the
/// PowerSync connect/disconnect lifecycle (HU-04/HU-05/HU-06), the
/// local-only half of HU-07 (wiping local rows on request), and — via the
/// `delete-account` Edge Function — the cloud half of HU-07 (deleting every
/// row owned by the user and the `auth.users` entry itself).
@LazySingleton(as: AuthRepository)
class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl(
    this._google,
    this._apple,
    this._summaries,
    this._wipe,
    this._ownership,
    this._supabase,
    this._powerSync,
    this._connector,
  ) {
    _restoreSession();
    _authStateSubscription = _supabase.auth.onAuthStateChange.listen(
      _onAuthStateChange,
      // Supabase reports a failed token refresh as an *error* on this stream,
      // not as an event. Swallowing it is deliberate: the app is local-first,
      // so a refresh that fails (typically just being offline) must neither
      // tear down the session nor escape as an uncaught async error. If the
      // token is really gone, Supabase follows up with a signed-out event and
      // [_onAuthStateChange] handles it there.
      onError: (Object _, StackTrace __) {},
    );
  }

  /// Releases the Supabase auth listener and the session stream. In a normal
  /// run this singleton lives as long as the app does and nothing calls this;
  /// it exists so tests can tear an instance down without leaking a listener
  /// into the next one.
  Future<void> dispose() async {
    await _authStateSubscription.cancel();
    await _controller.close();
  }

  final GoogleAuthDatasource _google;
  final AppleAuthDatasource _apple;
  final LocalDataSummaryDatasource _summaries;
  final LocalDataWipeDatasource _wipe;
  final LocalDataOwnershipDatasource _ownership;
  final SupabaseClient _supabase;
  final PowerSyncDatabase _powerSync;
  final PowerSyncConnector _connector;

  AuthSession _current = const AuthSession.signedOut();
  final _controller = StreamController<AuthSession>.broadcast();
  late final StreamSubscription<AuthState> _authStateSubscription;

  @override
  AuthSession get currentSession => _current;

  /// Rebuilds the session from the one `supabase_flutter` already restored
  /// from disk (it persists and auto-refreshes it on its own). Without this
  /// every relaunch started as [AuthSession.signedOut] even with a live
  /// token, so the UI asked the user to sign in again and — worse —
  /// [_connectPowerSync] never ran, leaving sync off for the whole session.
  ///
  /// Safe to call from the constructor: `Supabase.initialize()` is awaited in
  /// `bootstrap.dart` before the DI graph is built, so the session is already
  /// loaded and `currentSession` is a synchronous read.
  void _restoreSession() {
    final user = _supabase.auth.currentSession?.user;
    if (user == null) {
      return;
    }
    _current = AuthSession.signedIn(_toAuthUser(user));
    _connectPowerSync();
  }

  /// Keeps the session in step with Supabase's own lifecycle: a token refresh
  /// that fails, a sign-out from another part of the app, or the initial
  /// restore landing after this was constructed.
  void _onAuthStateChange(AuthState state) {
    final user = state.session?.user;

    if (user == null) {
      if (!_current.isSignedIn) {
        return;
      }
      _current = const AuthSession.signedOut();
      _controller.add(_current);
      return;
    }

    // Already tracking this account: don't rebuild it. `_completeSignIn` has
    // richer identity data (the provider credential's own name/avatar, which
    // Apple only ever returns on the *first* authorization) than anything
    // recoverable from the Supabase user alone.
    if (_current.user?.id == user.id) {
      _connectPowerSync();
      return;
    }

    _current = AuthSession.signedIn(_toAuthUser(user));
    _controller.add(_current);
    _connectPowerSync();
  }

  /// Best-effort identity from a Supabase user alone (no provider credential
  /// at hand). [AuthUser.displayName] is non-nullable, so it falls back to the
  /// email and then to empty rather than dropping the session entirely.
  AuthUser _toAuthUser(User user) {
    final metadata = user.userMetadata ?? const {};
    return AuthUser(
      id: user.id,
      displayName: (metadata['full_name'] as String?) ??
          (metadata['name'] as String?) ??
          user.email ??
          '',
      provider: user.appMetadata['provider'] == 'apple'
          ? AuthProvider.apple
          : AuthProvider.google,
      email: user.email,
      avatarUrl: metadata['avatar_url'] as String?,
    );
  }

  @override
  Stream<AuthSession> watchSession() async* {
    yield _current;
    yield* _controller.stream;
  }

  @override
  FutureResult<AuthUser> signInWithGoogle() async {
    try {
      final credential = await _google.signIn();
      return _completeSignIn(credential, AuthProvider.google);
    } on SocialAuthCancelledException {
      return const Left(AuthCancelledFailure('user cancelled Google sign-in'));
    }
  }

  @override
  FutureResult<AuthUser> signInWithApple() async {
    try {
      final credential = await _apple.signIn();
      return _completeSignIn(credential, AuthProvider.apple);
    } on AppleAuthCancelledException {
      return const Left(AuthCancelledFailure('user cancelled Apple sign-in'));
    }
  }

  /// Exchanges an already-collected provider credential for a real Supabase
  /// session (HU-02). The client-side SDK call above (Google/Apple) already
  /// ran for real by the time this is called.
  FutureResult<AuthUser> _completeSignIn(
    SocialCredential credential,
    AuthProvider provider,
  ) async {
    final idToken = credential.idToken;
    if (idToken == null) {
      return Left(
        UnexpectedFailure(
          '$provider sign-in did not return an idToken — cannot exchange it '
          'for a Supabase session.',
        ),
      );
    }

    try {
      final response = await _supabase.auth.signInWithIdToken(
        provider: provider == AuthProvider.google
            ? OAuthProvider.google
            : OAuthProvider.apple,
        idToken: idToken,
        // On iOS the Google idToken carries a `nonce` claim, so the raw nonce
        // must accompany it here or Supabase rejects the exchange with 400
        // "Passed nonce and nonce in id_token should either both exist or
        // not". Null (Android Google today, Apple) means no nonce was bound,
        // and passing null keeps the "neither exists" branch valid.
        nonce: credential.rawNonce,
      );
      final supabaseUser = response.user;
      if (supabaseUser == null) {
        return const Left(
          UnexpectedFailure(
            'Supabase returned no user after signInWithIdToken.',
          ),
        );
      }

      final metadata = supabaseUser.userMetadata ?? const {};
      final user = AuthUser(
        id: supabaseUser.id,
        displayName: (metadata['full_name'] as String?) ??
            (metadata['name'] as String?) ??
            credential.displayName,
        provider: provider,
        email: supabaseUser.email ?? credential.email,
        avatarUrl: (metadata['avatar_url'] as String?) ?? credential.avatarUrl,
      );
      _current = AuthSession.signedIn(user);
      _controller.add(_current);
      _connectPowerSync();
      return Right(user);
    } on AuthException catch (e, stackTrace) {
      return Left(NetworkFailure(e.message, cause: e, stackTrace: stackTrace));
    }
  }

  /// Starts the PowerSync sync stream if it is not already connected
  /// (HU-05). Idempotent: called both right after sign-in and again from
  /// [mergeLocalData], which may run after the same session in the merge
  /// screen's own flow.
  void _connectPowerSync() {
    if (_powerSync.connected) {
      return;
    }
    unawaited(_powerSync.connect(connector: _connector));
  }

  @override
  FutureResult<MergeSummary> mergeLocalData() async {
    // The local half: this reads Drift, the actual source of truth, for what
    // already sits on this device (HU-04's "Tus datos están a salvo" counts).
    final summary = await _summaries.getSummary();

    final user = _current.user;
    if (user == null) {
      return const Left(
        UnexpectedFailure(
          'AuthRepositoryImpl.mergeLocalData called without a signed-in '
          'session — nothing to associate the local rows with.',
        ),
      );
    }

    // Claims every row with no owner yet for this account. PowerSync's write
    // interception (decision #6, docs/requirements/05-auth-sync.md) then
    // queues each claimed row for upload on its own — there is no separate
    // upload step to trigger. Can fail with a `NetworkFailure` (decision
    // #12): claiming `seed-*` categories needs a live Postgres check for
    // which ones the account already owns, to avoid duplicating them.
    final claimResult = await _ownership.claimUnownedRows(user.id);
    if (claimResult case Left(value: final failure)) {
      return Left(failure);
    }
    _connectPowerSync();

    return Right(summary);
  }

  @override
  FutureResult<Unit> signOut() {
    // Signing out is entirely local (HU-06): it only stops sync going
    // forward and clears the cached provider/Supabase session, it never
    // touches data. It is awaited end to end so the caller can sequence a
    // local wipe *after* the session is really gone and PowerSync is really
    // disconnected — see [SignOutWithLocalDataChoice].
    return _clearLocalSession(force: false);
  }

  /// Drops the local half of the session: Google's cached credential,
  /// Supabase's own session, and the PowerSync connection. Shared by
  /// [signOut] (HU-06) and [deleteAccount] (HU-07) — once the cloud account
  /// is gone there is nothing left to keep a local session alive for either.
  ///
  /// Every step is awaited, so a `Right` means the session really is closed
  /// and the sync stream really is down. That is what lets HU-06 wipe this
  /// device afterwards without racing a download that repopulates it.
  ///
  /// Google's `signOutSilently` is awaited but can never fail the flow: the
  /// datasource swallows its own errors on purpose, since a stale cached
  /// Google credential does not keep the app's session alive — only Supabase's
  /// does. It is awaited anyway to keep the sequence deterministic.
  ///
  /// On failure the local state is left **as it was**: `_current` stays
  /// signed-in and nothing is emitted. Telling the UI it is signed out while
  /// the Supabase session survives on disk creates a state that silently
  /// reverts on the next launch (`_restoreSession` finds the token, reconnects
  /// PowerSync). Better to keep showing the truth and let the user retry.
  ///
  /// [force] is [deleteAccount]'s path (HU-07): the cloud account is already
  /// gone, so the local session points at nothing and cleanup failing must not
  /// block anything — the signed-out state is emitted regardless.
  FutureResult<Unit> _clearLocalSession({required bool force}) async {
    await _google.signOutSilently();

    final failure = await _runQuietly(
      _supabase.auth.signOut,
      'Supabase sign-out failed — the session may still be on disk.',
    );
    if (failure != null && !force) {
      return Left(failure);
    }

    final disconnectFailure = await _runQuietly(
      _powerSync.disconnect,
      'PowerSync disconnect failed after signing out.',
    );

    _current = const AuthSession.signedOut();
    _controller.add(_current);

    // The Supabase session is gone by now, so the signed-out state above is
    // accurate; but sync may still be streaming, and a wipe running against a
    // live stream is exactly the race this method exists to prevent. Report it
    // so the caller skips the wipe instead of confirming a delete that sync
    // could undo.
    if (disconnectFailure != null && !force) {
      return Left(disconnectFailure);
    }
    return const Right(unit);
  }

  /// Runs a cleanup step and turns whatever it throws into a [NetworkFailure]
  /// instead of letting it escape as an async error, so [_clearLocalSession]
  /// can decide what each step's failure means rather than aborting on the
  /// first one.
  Future<Failure?> _runQuietly(
    Future<void> Function() step,
    String message,
  ) async {
    try {
      await step();
      return null;
    } on Object catch (e, stackTrace) {
      return NetworkFailure('$message ($e)', cause: e, stackTrace: stackTrace);
    }
  }

  @override
  FutureResult<Unit> deleteAccount() async {
    // Cloud half of HU-07: the `delete-account` Edge Function deletes every
    // row owned by this user (via the `delete_account_data` RPC, inside a
    // transaction) and then `auth.users` itself. `supabase.functions.invoke`
    // attaches the current session's JWT as the `Authorization` header on
    // its own (via `SupabaseClient`'s internal `AuthHttpClient`), so there is
    // nothing to build by hand here.
    try {
      final response = await _supabase.functions.invoke('delete-account');
      final data = response.data;
      final succeeded = data is Map && data['success'] == true;
      if (!succeeded) {
        return Left(_deleteAccountFailure(data));
      }
      // The cloud account no longer exists — clear the local session so it
      // doesn't linger pointing at a dead account. `force: true`: there is no
      // session left to protect, so a failing cleanup step must not turn a
      // completed deletion into an error the user could read as "nothing
      // happened".
      await _clearLocalSession(force: true);
      return const Right(unit);
    } on FunctionException catch (e, stackTrace) {
      return Left(
        _deleteAccountFailure(e.details, stackTrace: stackTrace),
      );
    }
  }

  /// Maps a `delete-account` Edge Function error payload (`{error: string}`,
  /// optionally `{dataDeleted: true}` when the rows were wiped but
  /// `auth.admin.deleteUser` itself failed) to a [NetworkFailure]. Whether
  /// `dataDeleted` came back true is folded into the message instead of
  /// dropped, since it changes what the user should be told (their data is
  /// already gone even though the call "failed").
  NetworkFailure _deleteAccountFailure(
    Object? details, {
    StackTrace? stackTrace,
  }) {
    final errorMessage = details is Map && details['error'] is String
        ? details['error'] as String
        : 'delete-account Edge Function failed without a usable error body: '
            '$details';
    final dataDeleted = details is Map && details['dataDeleted'] == true;
    final message = dataDeleted
        ? '$errorMessage (dataDeleted: the user rows were already wiped '
            'before this failure)'
        : errorMessage;
    return NetworkFailure(message, cause: details, stackTrace: stackTrace);
  }

  @override
  FutureResult<Unit> wipeLocalData() async {
    await _wipe.wipeAll();
    return const Right(unit);
  }
}
