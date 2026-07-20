/// The identity claims collected from a provider's SDK, before they are
/// handed to Supabase Auth. Data-layer type: never leaves `data/` — the
/// mapped `AuthUser` is what the rest of the app sees.
class SocialCredential {
  const SocialCredential({
    required this.providerUserId,
    required this.displayName,
    this.email,
    this.avatarUrl,
    this.idToken,
    this.rawNonce,
  });

  final String providerUserId;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  /// The OpenID Connect ID token, needed to exchange this credential for a
  /// Supabase session (`supabase.auth.signInWithIdToken`).
  final String? idToken;

  /// The un-hashed nonce that was bound to this sign-in attempt. The provider
  /// received its SHA-256 hash (embedded in [idToken]'s `nonce` claim), while
  /// Supabase needs this raw value to re-hash and compare — passing one
  /// without the other makes `signInWithIdToken` fail with "Passed nonce and
  /// nonce in id_token should either both exist or not". Null when the
  /// provider flow did not bind a nonce.
  final String? rawNonce;
}
