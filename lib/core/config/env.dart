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

  // --- Placeholders for the sync phase (not wired up yet) ---
  static const String supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const String supabaseAnonKey =
      String.fromEnvironment('SUPABASE_ANON_KEY');
}
