import '../error/failure.dart';

/// Error/crash reporting abstraction. The app depends on this interface, never
/// on Sentry directly — that way the rest of the code knows nothing about the
/// vendor and tests can inject a double with no network access.
///
/// Implementations:
///  - `SentryCrashReporter` when `SENTRY_DSN` is set (see `core/config/env.dart`).
///  - `NoopCrashReporter` when it is not (dev without a Sentry project).
///
/// Dependency injection in `core/di` picks the implementation.
abstract interface class CrashReporter {
  /// Initializes the reporting backend. Must be called during bootstrap,
  /// before running the app. No-op when there is no DSN.
  Future<void> init();

  /// Reports an unhandled error (or a handled but relevant one). [fatal] marks
  /// crashes that prevented the app from continuing; the rest are "handled".
  Future<void> recordError(
    Object error,
    StackTrace? stackTrace, {
    String? context,
    bool fatal = false,
  });

  /// Reports an unexpected domain [Failure]. Expected validations
  /// (`ValidationFailure`) are normally NOT reported.
  Future<void> recordFailure(Failure failure, {String? context});

  /// Leaves a breadcrumb / log to give context to the next error.
  void log(String message, {String? category});

  /// Ties reports to a user (after login). Anonymous before auth.
  Future<void> setUser(String id);

  /// Clears the user identity (logout / account deletion).
  Future<void> clearUser();
}
