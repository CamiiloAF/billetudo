/// The social identity provider used to sign in. Auth is social-only, never
/// email/password (CLAUDE.md): Android only ever offers [google]; iOS offers
/// both (HU-02, HU-03).
enum AuthProvider { google, apple }
