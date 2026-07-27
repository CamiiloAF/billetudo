/// Environment configuration read at compile time via `--dart-define` (or
/// `--dart-define-from-file`). Never hardcode secrets in the repo.
///
/// Example:
///   flutter run --dart-define=SENTRY_DSN=https://... --dart-define=ENVIRONMENT=dev
///
/// Without `SENTRY_DSN`, crash reporting is a no-op (see `CrashReporter`).
abstract final class Env {
  const Env._();

  /// `dev` | `staging` | `prod`. Defaults to `dev`.
  static const String environment =
      String.fromEnvironment('ENVIRONMENT', defaultValue: 'dev');

  static bool get isProduction => environment == 'prod';
  static bool get isDev => environment == 'dev';

  /// Sentry DSN. Empty ⇒ crash reporting disabled (no-op).
  static const String sentryDsn = String.fromEnvironment('SENTRY_DSN');

  static bool get hasSentryDsn => sentryDsn.isNotEmpty;

  // --- Supabase (sync/auth backend) ---
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');

  /// Google Cloud "Web application" OAuth client id. Not a secret: Supabase
  /// uses it server-side to validate the `idToken` collected by the native
  /// Android/iOS Google sign-in flow (HU-02).
  static const String googleServerClientId =
      String.fromEnvironment('GOOGLE_SERVER_CLIENT_ID');

  /// PowerSync instance URL for this environment (HU-04/HU-05 sync).
  static const String powerSyncUrl = String.fromEnvironment('POWERSYNC_URL');
}
