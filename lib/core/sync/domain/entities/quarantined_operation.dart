import 'package:equatable/equatable.dart';

import 'sync_failure_kind.dart';
import 'sync_operation.dart';

/// A write the cloud rejected permanently, held locally so it is never lost
/// and never blocks the upload queue.
///
/// The user (or a developer) can retry it once the cause is fixed, or discard
/// it explicitly. Nothing here is ever dropped silently.
class QuarantinedOperation extends Equatable {
  const QuarantinedOperation({
    required this.id,
    required this.operation,
    required this.kind,
    required this.errorMessage,
    required this.quarantinedAt,
    required this.updatedAt,
    required this.attempts,
    this.errorCode,
  });

  /// UUID of the quarantine record itself (not of the affected row).
  final String id;

  /// The write that failed, complete enough to be replayed as is.
  final SyncOperation operation;

  final SyncFailureKind kind;

  /// Backend error code (`PGRST204`, `23503`...). `null` when the backend did
  /// not provide one.
  final String? errorCode;

  /// Technical message from the backend. Never shown raw to the user.
  final String errorMessage;

  /// When the operation was first quarantined.
  final DateTime quarantinedAt;

  /// Last time this record changed (a retry that failed again bumps it).
  final DateTime updatedAt;

  /// How many times the upload of this operation has failed, including the
  /// original attempt.
  final int attempts;

  QuarantinedOperation copyWith({
    SyncFailureKind? kind,
    String? errorCode,
    String? errorMessage,
    DateTime? updatedAt,
    int? attempts,
  }) {
    return QuarantinedOperation(
      id: id,
      operation: operation,
      kind: kind ?? this.kind,
      errorCode: errorCode ?? this.errorCode,
      errorMessage: errorMessage ?? this.errorMessage,
      quarantinedAt: quarantinedAt,
      updatedAt: updatedAt ?? this.updatedAt,
      attempts: attempts ?? this.attempts,
    );
  }

  @override
  List<Object?> get props => [
        id,
        operation,
        kind,
        errorCode,
        errorMessage,
        quarantinedAt,
        updatedAt,
        attempts,
      ];
}
