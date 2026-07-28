import '../../domain/entities/sync_log_entry.dart';

/// JSON representation of a [SyncLogEntry], persisted to disk.
abstract final class SyncLogEntryDto {
  const SyncLogEntryDto._();

  static Map<String, dynamic> toJson(SyncLogEntry entity) {
    return <String, dynamic>{
      'id': entity.id,
      'at': entity.timestamp.toUtc().toIso8601String(),
      'level': entity.level.name,
      'event': entity.event.name,
      'message': entity.message,
      'code': entity.code,
      'table': entity.tableName,
    };
  }

  /// `null` when the record is unreadable (written by an older build, or
  /// truncated by a crash mid-write). A dropped diagnostics record is better
  /// than a crash while reading them.
  static SyncLogEntry? fromJson(Map<String, dynamic> json) {
    final id = json['id'];
    final timestamp =
        json['at'] is String ? DateTime.tryParse(json['at'] as String) : null;
    final event = _parseEvent(json['event']);
    if (id is! String || timestamp == null || event == null) {
      return null;
    }
    return SyncLogEntry(
      id: id,
      timestamp: timestamp,
      level: _parseLevel(json['level']),
      event: event,
      message: json['message'] is String ? json['message'] as String : '',
      code: json['code'] is String ? json['code'] as String : null,
      tableName: json['table'] is String ? json['table'] as String : null,
    );
  }

  static SyncLogEvent? _parseEvent(Object? raw) {
    for (final value in SyncLogEvent.values) {
      if (value.name == raw) return value;
    }
    return null;
  }

  static SyncLogLevel _parseLevel(Object? raw) {
    for (final value in SyncLogLevel.values) {
      if (value.name == raw) return value;
    }
    return SyncLogLevel.info;
  }
}
