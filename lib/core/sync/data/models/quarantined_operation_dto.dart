import '../../domain/entities/quarantined_operation.dart';
import '../../domain/entities/sync_failure_kind.dart';
import '../../domain/entities/sync_operation.dart';

/// JSON representation of a [QuarantinedOperation], persisted to disk.
///
/// Enums travel as their `name` (never their index) so reordering the enum
/// cannot silently reinterpret already-stored records — the same rule the
/// Drift schema follows for parity with Postgres.
abstract final class QuarantinedOperationDto {
  const QuarantinedOperationDto._();

  static Map<String, dynamic> toJson(QuarantinedOperation entity) {
    return <String, dynamic>{
      'id': entity.id,
      'table': entity.operation.tableName,
      'row_id': entity.operation.rowId,
      'op': entity.operation.type.name,
      'payload': entity.operation.payload,
      'kind': entity.kind.name,
      'error_code': entity.errorCode,
      'error_message': entity.errorMessage,
      'quarantined_at': entity.quarantinedAt.toUtc().toIso8601String(),
      'updated_at': entity.updatedAt.toUtc().toIso8601String(),
      'attempts': entity.attempts,
    };
  }

  /// Returns `null` when the record cannot be understood (written by an older
  /// build, or truncated). A dropped diagnostics record is better than a
  /// crash while reading them.
  static QuarantinedOperation? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final tableName = json['table'];
    final rowId = json['row_id'];
    if (id is! String || tableName is! String || rowId is! String) {
      return null;
    }
    final type = _parseType(json['op']);
    final quarantinedAt = _parseDate(json['quarantined_at']);
    if (type == null || quarantinedAt == null) {
      return null;
    }
    final payload = json['payload'];
    return QuarantinedOperation(
      id: id,
      operation: SyncOperation(
        tableName: tableName,
        rowId: rowId,
        type: type,
        payload: payload is Map<String, dynamic> ? payload : null,
      ),
      kind: _parseKind(json['kind']),
      errorCode:
          json['error_code'] is String ? json['error_code'] as String : null,
      errorMessage: json['error_message'] is String
          ? json['error_message'] as String
          : '',
      quarantinedAt: quarantinedAt,
      updatedAt: _parseDate(json['updated_at']) ?? quarantinedAt,
      attempts: json['attempts'] is int ? json['attempts'] as int : 1,
    );
  }

  static SyncOperationType? _parseType(Object? raw) {
    for (final value in SyncOperationType.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  static SyncFailureKind _parseKind(Object? raw) {
    for (final value in SyncFailureKind.values) {
      if (value.name == raw) return value;
    }
    return SyncFailureKind.invalidData;
  }

  static DateTime? _parseDate(Object? raw) =>
      raw is String ? DateTime.tryParse(raw) : null;
}
