/// What "Eliminar cuenta" (HU-07) can actually delete on this run of the
/// flow, decided once when it starts (see `GetDeleteAccountScope`).
///
/// Both `localOnly*` variants end up calling the same local-only path
/// (`AuthRepository.deleteAccount` is a no-op without a session), but they
/// must not read the same way to the user: only [localOnlySignedOut] has a
/// live cloud account this device simply cannot reach right now.
enum DeleteAccountScope {
  /// Signed in: paso 1 really calls the cloud, paso 3 truthfully says the
  /// cloud account is gone.
  cloudAndLocal,

  /// This device has never completed a sign-in — there is no cloud account
  /// to mention anywhere in the flow.
  localOnlyNeverSignedIn,

  /// Signed out, but this device signed in before: a cloud account may still
  /// exist and this flow cannot reach it. Paso 1 must say so before letting
  /// the user continue with a local-only deletion; paso 3 must not claim the
  /// cloud account was deleted.
  localOnlySignedOut,
}
