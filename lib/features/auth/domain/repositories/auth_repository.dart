import '../../../../core/error/result.dart';
import '../entities/auth_session.dart';
import '../entities/auth_user.dart';
import '../entities/merge_summary.dart';

/// Contract the Auth feature depends on.
///
/// Implemented in `data/` over the official Google/Apple SDKs for the
/// client-side half of sign-in, plus (pending PowerSync/Supabase wiring,
/// see `docs/requirements/05-auth-sync.md`) the server half that actually
/// creates/merges/deletes the cloud account. Until that wiring lands, the
/// methods that need a backend throw `UnimplementedError` — see
/// `AuthRepositoryImpl` for exactly which ones and why.
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
  /// separate, explicit choice (see [wipeLocalData]).
  FutureResult<Unit> deleteAccount();

  /// HU-07 paso 2, when the user picks "Borrar también los datos de este
  /// dispositivo": wipes every local row on this device.
  FutureResult<Unit> wipeLocalData();
}
