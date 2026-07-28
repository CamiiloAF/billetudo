import 'package:equatable/equatable.dart';

/// Severity of a [SyncLogEntry].
enum SyncLogLevel { info, warning, error }

/// What happened, in the few categories the sync path can produce.
enum SyncLogEvent {
  /// Credentials were handed to the sync engine, or there was no session.
  connection,

  /// A batch of local writes started uploading.
  uploadStarted,

  /// A batch finished (fully or with quarantined operations).
  uploadFinished,

  /// A write failed and will be retried.
  uploadRetry,

  /// A write failed permanently and went to the quarantine.
  quarantined,

  /// The retry watchdog pulled a write out of the queue: it was not classified
  /// as permanent, it just kept being rejected long enough to be blocking
  /// everything behind it.
  watchdogQuarantined,

  /// A quarantined write was replayed manually.
  quarantineRetry,

  /// A quarantined write was discarded by the user.
  quarantineDiscarded,
}

/// One line of the local, on-device sync log.
///
/// Sync problems used to exist only in Sentry, which is unreadable from the
/// device and absent when there is no DSN — so a queue could stay blocked for
/// days with no symptom anywhere the user or a developer could see. This is
/// that missing evidence trail, kept as a bounded ring buffer.
class SyncLogEntry extends Equatable {
  const SyncLogEntry({
    required this.id,
    required this.timestamp,
    required this.level,
    required this.event,
    required this.message,
    this.code,
    this.tableName,
  });

  final String id;
  final DateTime timestamp;
  final SyncLogLevel level;
  final SyncLogEvent event;

  /// Technical description, in English: this is a diagnostics log, not UI
  /// copy. Any screen that shows it renders the [event] with a localized
  /// label and treats this as detail.
  final String message;

  /// Backend error code, when the entry describes a failure.
  final String? code;

  /// Table involved, when applicable.
  final String? tableName;

  /// Single-line rendering used by the plain-text export.
  String toLogLine() {
    final buffer = StringBuffer()
      ..write(timestamp.toUtc().toIso8601String())
      ..write(' [${level.name.toUpperCase()}] ')
      ..write(event.name);
    if (tableName != null) {
      buffer.write(' table=$tableName');
    }
    if (code != null) {
      buffer.write(' code=$code');
    }
    buffer.write(' — $message');
    return buffer.toString();
  }

  @override
  List<Object?> get props => [
        id,
        timestamp,
        level,
        event,
        message,
        code,
        tableName,
      ];
}
