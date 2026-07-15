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

/// Unanticipated error. Must always be sent to the crash reporter.
final class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});
}
