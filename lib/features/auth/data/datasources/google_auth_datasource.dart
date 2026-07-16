import 'package:google_sign_in/google_sign_in.dart';
import 'package:injectable/injectable.dart';

import '../models/social_credential.dart';

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

  Future<void> _ensureInitialized() async {
    if (_initialized) {
      return;
    }
    // `serverClientId`/`clientId` come from the native `google-services.json`
    // / `GoogleService-Info.plist` once those are generated for this app
    // (pending `flutter create .` + Supabase project wiring, see
    // CLAUDE.md → "Estado del repo"). Passing none lets each platform fall
    // back to its native config file when present.
    await GoogleSignIn.instance.initialize();
    _initialized = true;
  }

  /// Runs the interactive Google sign-in flow and returns the signed-in
  /// identity. Throws [SocialAuthCancelledException] if the user backs out,
  /// or the underlying [GoogleSignInException] on any other failure.
  Future<SocialCredential> signIn() async {
    await _ensureInitialized();
    try {
      final account = await GoogleSignIn.instance.authenticate();
      return SocialCredential(
        providerUserId: account.id,
        displayName: account.displayName ?? account.email,
        email: account.email,
        avatarUrl: account.photoUrl,
        idToken: account.authentication.idToken,
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
