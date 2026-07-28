import '../../domain/entities/sync_operation.dart';

/// How long one operation has been failing against a backend that *answered*.
///
/// Infrastructure-only: nothing in `domain` or `presentation` reads it, so it
/// lives in `data/` as a single class carrying its own JSON mapping instead of
/// an entity plus a DTO (see `quarantined_operation_dto.dart` for the split
/// used when a type does cross the boundary).
///
/// Persisted next to the quarantine because an in-memory counter resets on
/// every app start — and an operation that blocks the FIFO queue survives
/// restarts, so its evidence has to as well.
class SyncRetryRecord {
  const SyncRetryRecord({
    required this.key,
    required this.attempts,
    required this.firstFailureAt,
    required this.lastFailureAt,
    this.lastErrorCode,
  });

  /// Identity of the write being retried: `table#rowId#type`. Two different
  /// writes to the same row (a `patch` and a `delete`) are counted apart, the
  /// same way the quarantine keys its records.
  static String keyOf(SyncOperation operation) =>
      '${operation.tableName}#${operation.rowId}#${operation.type.name}';

  final String key;

  /// Failures where the backend replied with something we could not classify.
  /// Pure connectivity failures are deliberately not counted here.
  final int attempts;

  final DateTime firstFailureAt;
  final DateTime lastFailureAt;

  /// Backend code of the most recent failure, when it exposed one.
  final String? lastErrorCode;

  SyncRetryRecord bump({required DateTime at, String? errorCode}) {
    return SyncRetryRecord(
      key: key,
      attempts: attempts + 1,
      firstFailureAt: firstFailureAt,
      lastFailureAt: at,
      lastErrorCode: errorCode ?? lastErrorCode,
    );
  }

  /// How long this operation has been failing without ever succeeding.
  Duration get stuckFor => lastFailureAt.difference(firstFailureAt);

  Map<String, dynamic> toJson() => <String, dynamic>{
        'key': key,
        'attempts': attempts,
        'first_failure_at': firstFailureAt.toUtc().toIso8601String(),
        'last_failure_at': lastFailureAt.toUtc().toIso8601String(),
        'last_error_code': lastErrorCode,
      };

  /// Returns `null` for a record an older build wrote or a truncated one: the
  /// ledger is diagnostics, losing a row is better than failing to read it.
  static SyncRetryRecord? fromJson(Map<String, dynamic> json) {
    final key = json['key'];
    final firstFailureAt = _parseDate(json['first_failure_at']);
    if (key is! String || firstFailureAt == null) {
      return null;
    }
    return SyncRetryRecord(
      key: key,
      attempts: json['attempts'] is int ? json['attempts'] as int : 1,
      firstFailureAt: firstFailureAt,
      lastFailureAt: _parseDate(json['last_failure_at']) ?? firstFailureAt,
      lastErrorCode: json['last_error_code'] is String
          ? json['last_error_code'] as String
          : null,
    );
  }

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
