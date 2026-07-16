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
  });

  final String providerUserId;
  final String displayName;
  final String? email;
  final String? avatarUrl;

  /// The OpenID Connect ID token, needed to exchange this credential for a
  /// Supabase session (`supabase.auth.signInWithIdToken`) once that wiring
  /// exists.
  final String? idToken;
}
