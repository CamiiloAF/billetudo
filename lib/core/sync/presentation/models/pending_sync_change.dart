import 'package:equatable/equatable.dart';

import '../../domain/entities/quarantined_operation.dart';
import 'sync_change_kind.dart';

/// A held-back write, described the way the screen needs to say it.
///
/// It reads the operation's payload (the very columns that were going to be
/// uploaded) to recover a human name for the row — that is the only source
/// available: the row itself may already have changed, and the quarantine is
/// deliberately transport-shaped. Everything technical the payload also
/// carries (codes, table names) stops here and never reaches a label.
class PendingSyncChange extends Equatable {
  const PendingSyncChange({
    required this.id,
    required this.kind,
    required this.pendingSince,
    required this.attempts,
    this.label,
    this.amountMinor,
    this.currencyCode,
    this.occurredAt,
  });

  factory PendingSyncChange.fromOperation(QuarantinedOperation operation) {
    final payload = operation.operation.payload ?? const <String, dynamic>{};
    return PendingSyncChange(
      id: operation.id,
      kind: SyncChangeKind.fromTableName(operation.operation.tableName),
      pendingSince: operation.quarantinedAt,
      attempts: operation.attempts,
      label: _firstText(payload, const ['name', 'note', 'counterparty']),
      amountMinor: _asInt(payload['amount_minor']),
      currencyCode: _firstText(payload, const ['currency']),
      occurredAt: _asDate(payload['date'] ?? payload['entry_date']),
    );
  }

  /// The quarantine record's id — what a retry is addressed to.
  final String id;

  final SyncChangeKind kind;

  /// The user-facing name of the affected row, when the payload carried one.
  /// `null` renders the kind alone ("Movimiento"), never a table name.
  final String? label;

  /// Amount in minor units, when the row has one.
  final int? amountMinor;
  final String? currencyCode;

  /// The date the *entity* carries (a movement's date), not when it was
  /// quarantined.
  final DateTime? occurredAt;

  final DateTime pendingSince;
  final int attempts;

  static String? _firstText(Map<String, dynamic> payload, List<String> keys) {
    for (final key in keys) {
      final value = payload[key];
      if (value is String && value.trim().isNotEmpty) {
        return value.trim();
      }
    }
    return null;
  }

  static int? _asInt(Object? value) => switch (value) {
        final int value => value,
        final num value => value.toInt(),
        final String value => int.tryParse(value),
        _ => null,
      };

  /// Dates travel to Postgres as unix **seconds** (decision #15 of
  /// `05-auth-sync.md`), which is also how they sit in the upload payload.
  ///
  /// Read back as UTC on purpose: these are calendar days pinned to UTC
  /// midnight, so converting them to the phone's zone would shift a movement
  /// made "el 12" to "el 11" anywhere west of Greenwich.
  static DateTime? _asDate(Object? value) {
    final seconds = _asInt(value);
    if (seconds == null) {
      return null;
    }
    return DateTime.fromMillisecondsSinceEpoch(seconds * 1000, isUtc: true);
  }

  @override
  List<Object?> get props => [
        id,
        kind,
        label,
        amountMinor,
        currencyCode,
        occurredAt,
        pendingSince,
        attempts,
      ];
}
