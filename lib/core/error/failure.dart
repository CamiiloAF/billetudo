import 'package:equatable/equatable.dart';

/// Base class for every domain error in the app.
///
/// Use cases return `Either<Failure, T>` (see `result.dart`): the error is
/// explicit in the signature, never an implicit exception. The `data` layer
/// translates infrastructure exceptions (Drift, secure storage) into one of
/// these subclasses; the `presentation` layer maps `message`/type to a
/// localized string (see `core/l10n`).
sealed class Failure extends Equatable {
  const Failure(this.message, {this.cause, this.stackTrace});

  /// Technical message for logs/crash reporting. **Not** shown to the user as
  /// is: the UI picks a localized string based on the failure type.
  final String message;

  /// Original exception that caused the failure, when applicable.
  final Object? cause;

  /// Original stack trace, to attach to the crash reporter.
  final StackTrace? stackTrace;

  @override
  List<Object?> get props => [runtimeType, message, cause];

  @override
  String toString() => '$runtimeType($message)';
}

/// A business validation was not met (invalid input, rule violated). Not a
/// crash: this is an expected flow. [field] identifies the form field when
/// applicable, so the UI can highlight it.
final class ValidationFailure extends Failure {
  const ValidationFailure(super.message, {this.field, super.cause});

  final String? field;

  @override
  List<Object?> get props => [...super.props, field];
}

/// The requested entity was not found (unknown id, or already deleted).
final class NotFoundFailure extends Failure {
  const NotFoundFailure(super.message, {super.cause});
}

/// Local database failure (Drift/SQLite).
final class DatabaseFailure extends Failure {
  const DatabaseFailure(super.message, {super.cause, super.stackTrace});
}

/// Device secure storage failure (Keychain/Keystore).
final class SecureStorageFailure extends Failure {
  const SecureStorageFailure(super.message, {super.cause, super.stackTrace});
}

/// Network/backend failure (Supabase/PowerSync). Reserved for the sync phase.
final class NetworkFailure extends Failure {
  const NetworkFailure(super.message, {super.cause, super.stackTrace});
}

/// The user backed out of a social sign-in flow (closed the Google/Apple
/// sheet). Not an error to surface as a failure banner — the UI simply
/// returns to its normal state.
final class AuthCancelledFailure extends Failure {
  const AuthCancelledFailure(super.message, {super.cause});
}

/// Unanticipated error. Must always be sent to the crash reporter.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});
}

/// A file the user picked, or a file the app tried to write, could not be
/// read/written (HU-09 of `docs/requirements/fase-1/11-import-export.md`): not CSV,
/// unreadable encoding, no rows, no disk space, permission denied. Not a
/// crash — the tone is "the file has a problem", never "you did something
/// wrong" (`CLAUDE.md`).
final class IoFailure extends Failure {
  const IoFailure(super.message, {this.reason, super.cause, super.stackTrace});

  /// Machine-readable cause, so presentation can pick the right copy/icon
  /// without parsing [message].
  final IoFailureReason? reason;

  @override
  List<Object?> get props => [...super.props, reason];
}

/// Why an [IoFailure] happened.
enum IoFailureReason {
  unreadableFile,
  emptyFile,
  noSpace,
  permissionDenied,
  cancelled,
}

/// A typed error from the `ai-chat` broker.
///
/// Every other backend error in the app collapses into [NetworkFailure]
/// because the UI does the same thing with all of them ("no pudimos
/// conectarnos, reintentá"). The assistant is the one place where that would
/// delete behaviour, not just nuance: the function answers with
/// `{"error": {"code", "message", "retryAfterSeconds"?}}` and at least four of
/// those codes change what the app must *do* —
/// [AiFailureCode.payloadTooLarge] has to prune the local transcript and
/// resend, [AiFailureCode.unsupportedProtocol] has to send the user to the
/// store, [AiFailureCode.providerRateLimited] has to wait [retryAfterSeconds],
/// and [AiFailureCode.aiNotEnabled] has to hide the entry point instead of
/// offering a retry that will never succeed.
///
/// [AiFailureCode] is named by the server as the Dart half of that contract
/// (`supabase/functions/_shared/errors.ts`); renaming a wire string on either
/// side silently changes what the app shows.
///
/// [message] is deliberately built from the code and HTTP status only, never
/// from the server's prose: this failure is reported to Sentry, and nothing
/// that could carry a fragment of a conversation is allowed to travel there
/// (privacy policy §17.5 — the transcript exists on no server).
final class AiFailure extends Failure {
  const AiFailure(
    super.message, {
    required this.code,
    this.retryAfterSeconds,
    super.cause,
    super.stackTrace,
  });

  final AiFailureCode code;

  /// Only ever set for [AiFailureCode.providerRateLimited]. `null` means the
  /// server did not say — retry at the app's own discretion.
  final int? retryAfterSeconds;

  @override
  List<Object?> get props => [...super.props, code, retryAfterSeconds];
}

/// The `code` values of the `ai-chat` error envelope.
///
/// Kept in sync by hand with `AiErrorCode` in
/// `supabase/functions/_shared/errors.ts`. [unknown] is what a code added
/// server-side after this build maps to: an app that cannot name an error must
/// still be able to show one.
enum AiFailureCode {
  invalidRequest,
  unauthenticated,
  aiNotEnabled,
  payloadTooLarge,
  unsupportedProtocol,
  quotaExceeded,
  providerRateLimited,
  providerUnavailable,
  providerTimeout,
  internal,
  unknown,
}
