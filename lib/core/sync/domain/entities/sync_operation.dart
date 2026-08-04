import 'package:equatable/equatable.dart';

/// The kind of write the sync engine queued for a single row.
///
/// Mirrors PowerSync's `UpdateType`, redeclared here so `domain` (and the
/// quarantine, which persists it) never depends on the package.
enum SyncOperationType {
  /// Insert or replace the whole row.
  put,

  /// Partial update of the columns in `payload`.
  patch,

  /// Remove the row.
  delete,
}

/// One pending write against the cloud database, described in plain data.
///
/// Deliberately transport-agnostic: it is what the upload path replays, what
/// the quarantine stores when a replay fails permanently, and what a manual
/// retry re-injects later.
class SyncOperation extends Equatable {
  const SyncOperation({
    required this.tableName,
    required this.rowId,
    required this.type,
    this.payload,
  });

  /// Remote table this write targets (`transactions`, `debts`...).
  final String tableName;

  /// UUID of the affected row.
  final String rowId;

  final SyncOperationType type;

  /// Column values to write. `null` for [SyncOperationType.delete].
  final Map<String, dynamic>? payload;

  @override
  List<Object?> get props => [tableName, rowId, type, payload];
}
