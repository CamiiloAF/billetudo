import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/config/env.dart';
import '../models/social_credential.dart';
import 'auth_nonce.dart';

/// Thrown when the user dismisses the Google sign-in sheet — not a failure,
/// just no-op from the caller's point of view.
class SocialAuthCancelledException implements Exception {
  const SocialAuthCancelledException();
}

/// Real Google Identity Services integration (HU-02), following the
/// `google_sign_in` v7 API: [GoogleSignIn.instance] is initialized once and
/// [GoogleSignIn.authenticate] drives the interactive flow. Only collects the
/// identity claims — exchanging them for a Supabase session is
/// `AuthRepositoryImpl`'s job, and is not implemented yet.
@lazySingleton
class GoogleAuthDatasource {
  bool _initialized = false;

  /// Initializes (or re-initializes) the Google SDK.
  ///
  /// `serverClientId` is the Google Cloud "Web application" OAuth client id
  /// (see `Env.googleServerClientId`): Supabase needs it server-side to
  /// validate the `idToken` collected below. The native `clientId` still
  /// comes from `google-services.json` / `GoogleService-Info.plist` per
  /// platform, which each SDK reads on its own.
  ///
  /// [nonce] (the SHA-256 hash of [signIn]'s per-attempt raw nonce) can only
  /// be supplied through `initialize` in `google_sign_in` v7 — `authenticate`
  /// takes no nonce — so binding a *fresh* nonce per sign-in attempt (replay
  /// protection, and what Supabase's `signInWithIdToken` requires on iOS)
  /// means re-initializing right before each interactive call. The package
  /// warns this is "undefined behavior", but in v7.2.0 `initialize` only
  /// re-runs the platform `init`; the auth-event stream it also subscribes to
  /// is never consumed here (we await `authenticate()` directly), so re-init
  /// is safe for this usage.
  Future<void> _initialize({String? nonce}) async {
    await GoogleSignIn.instance.initialize(
      serverClientId: Env.googleServerClientId,
      nonce: nonce,
    );
    _initialized = true;
  }

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    await _initialize();
  }

  /// Runs the interactive Google sign-in flow and returns the signed-in
  /// identity. Throws [SocialAuthCancelledException] if the user backs out,
  /// or the underlying [GoogleSignInException] on any other failure.
  Future<SocialCredential> signIn() async {
    // A fresh nonce per attempt: the SHA-256 hash goes to Google (embedded in
    // the returned `idToken`'s `nonce` claim), while the raw value travels to
    // Supabase in `SocialCredential.rawNonce` so it can re-hash and compare.
    final nonce = AuthNonce.generate();
    await _initialize(nonce: nonce.hashed);
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return SocialCredential(
        providerUserId: account.id,
        displayName: account.displayName ?? account.email,
        email: account.email,
        avatarUrl: account.photoUrl,
        idToken: account.authentication.idToken,
        rawNonce: nonce.raw,
      );
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw const SocialAuthCancelledException();
      }
      rethrow;
    }
  }

  /// Clears the cached Google session on this device (HU-06). Best-effort:
  /// signing out locally must never fail the app's own sign-out flow, so
  /// errors are swallowed here.
  Future<void> signOutSilently() async {
    try {
      await _ensureInitialized();
      await GoogleSignIn.instance.signOut();
    } catch (_) {
      // Local-only cleanup; the app's sign-out already succeeded regardless.
    }
  }
}
