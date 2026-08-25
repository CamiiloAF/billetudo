import 'auth_user.dart';

/// Result of attempting `signInWithGoogle`/`signInWithApple`.
///
/// Sealed on purpose, same reasoning as `SignOutOutcome`: a plain
/// `Result<AuthUser>` cannot tell apart "signed in" from "blocked, pending a
/// decision the user has to make" — collapsing them into one `Right` would
/// force the caller to smuggle that distinction back out through a second,
/// separate flag.
sealed class SignInOutcome {
  const SignInOutcome();
}

/// The token exchange completed and no conflicting local data was found (or
/// this device had none to begin with): the session is signed in.
class SignedIn extends SignInOutcome {
  const SignedIn(this.user);

  final AuthUser user;
}

/// The token exchange with Supabase succeeded, but this device already holds
/// local data owned by a *different* account (the inverse of HU-04's
/// unowned-data merge). The sign-in is intentionally **not** completed yet —
/// `AuthSession` keeps reporting `signedOut` — until the user picks between
/// `AuthRepository.resolveAccountConflict` (wipe this device's data and
/// complete the sign-in) and `AuthRepository.cancelAccountConflict` (close
/// the just-exchanged session and keep this device's existing data intact).
class AccountConflictDetected extends SignInOutcome {
  const AccountConflictDetected();
}
