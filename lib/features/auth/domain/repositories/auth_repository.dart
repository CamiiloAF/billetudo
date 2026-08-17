import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';
import '../entities/merge_summary.dart';

/// Contract the Auth feature depends on.
///
/// Implemented in `data/` over the official Google/Apple SDKs for the
/// client-side half of sign-in, Supabase for the session/account, and
/// PowerSync for sync (see `docs/requirements/05-auth-sync.md`). [deleteAccount]
/// calls a Supabase Edge Function (`delete-account`); see `AuthRepositoryImpl`.
///
/// Signing in is always optional (HU-01): nothing in this contract may be
/// called to gate access to a Nivel 0 feature.
abstract class AuthRepository {
  /// Emits every time the session changes (sign in/out). Replays the current
  /// value to new listeners.
  Stream<AuthSession> watchSession();

  /// The session as of right now, without waiting on the stream.
  AuthSession get currentSession;

  /// HU-02: Google sign-in, available on Android and iOS.
  FutureResult<AuthUser> signInWithGoogle();

  /// HU-03: Sign in with Apple, iOS only.
  FutureResult<AuthUser> signInWithApple();

  /// HU-04: folds this device's local data into the just-authenticated
  /// account and reports what was folded in.
  FutureResult<MergeSummary> mergeLocalData();

  /// HU-06: stops sync on this device. Local data is untouched.
  FutureResult<Unit> signOut();

  /// HU-07: deletes the user's account and all of their data in Supabase,
  /// synchronously and irreversibly. Does not touch local data — that is a
  /// separate, explicit choice (see [wipeLocalData]). Without an active
  /// session (the user never signed in, or already signed out) there is no
  /// session to call the server with, so this returns success without
  /// calling it, and the caller still proceeds to [wipeLocalData]'s choice —
  /// even if a real cloud account still exists (see [hasEverSignedIn], and
  /// `GetDeleteAccountScope` in `domain/usecases`, which is what decides
  /// whether the UI needs to warn about that before this is even called).
  FutureResult<Unit> deleteAccount();

  /// HU-07 paso 2, when the user picks "Borrar también los datos de este
  /// dispositivo": wipes every local row on this device.
  FutureResult<Unit> wipeLocalData();

  /// Whether this device has ever completed a successful sign-in, even if it
  /// later called [signOut]. Unlike [currentSession], this survives signing
  /// out — it only clears once [deleteAccount] really deletes the cloud
  /// account. Lets HU-07 tell apart a device that never had a cloud account
  /// from one that signed out of a real one, so "Eliminar cuenta" never
  /// implies the cloud account is gone when it was only skipped.
  Future<bool> hasEverSignedIn();

  /// Bug corregido (2026-08-17, docs/requirements/05-auth-sync.md): if this
  /// device has a restorable Supabase session, connects PowerSync (if it is
  /// not connected yet) and waits, bounded by [timeout], for its first full
  /// sync to land — so a caller writing local defaults right after this
  /// (e.g. `bootstrap.dart` seeding `AppSettings`/default categories) never
  /// races the download of the user's real server values.
  ///
  /// A no-op `Right` when there is no restorable session — the local-first,
  /// no-account path (HU-01) has nothing on a server to race against.
  ///
  /// Returns a `NetworkFailure` (not thrown) if [timeout] elapses before the
  /// first sync completes, e.g. no network at this exact launch — the
  /// caller decides what "proceed anyway" means for it, same posture as
  /// `SeedDefaultCategories`'s own `NetworkFailure` handling in
  /// `bootstrap.dart`.
  FutureResult<Unit> waitForFirstSync({Duration timeout});
}
