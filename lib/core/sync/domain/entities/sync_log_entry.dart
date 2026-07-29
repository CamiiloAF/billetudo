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

  /// Console-shaped single line — short timestamp, context, detail — used both
  /// by the plain-text export and by the log block of "Registro técnico".
  ///
  /// The density is the point (`T7Iw0C` shows six entries, one line each): the
  /// ISO timestamp with milliseconds plus the `[LEVEL] … — ` scaffolding wrapped
  /// most entries over two or three lines, so a block sized for eight showed
  /// four and cut the last one in half. `info` carries no marker, because the
  /// severity worth spending characters on is the one that is not routine.
  String toLogLine() {
    final context = level == SyncLogLevel.info
        ? _snakeCase(event.name)
        : '${level.name}/${_snakeCase(event.name)}';
    final detail = <String>[
      if (tableName != null) tableName!,
      if (code != null) code!,
      message,
    ].join(' ');
    return '$_utcTimestamp  $context  $detail';
  }

  /// `2026-07-15 09:14:02`, always UTC: a log read on one device may well be
  /// pasted next to one read on another.
  String get _utcTimestamp {
    final at = timestamp.toUtc();
    return '${at.year}-${_pad(at.month)}-${_pad(at.day)} '
        '${_pad(at.hour)}:${_pad(at.minute)}:${_pad(at.second)}';
  }

  static String _pad(int value) => value.toString().padLeft(2, '0');

  static String _snakeCase(String name) => name.replaceAllMapped(
        RegExp('[A-Z]'),
        (match) => '_${match[0]!.toLowerCase()}',
      );

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
