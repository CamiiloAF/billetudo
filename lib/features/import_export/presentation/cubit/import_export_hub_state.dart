import 'package:equatable/equatable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/import_batch.dart';

enum ImportExportHubStatus { loading, ready, failure }

/// The Hub screen (`oSWz9`/`qDCvi`/`Am9cg`): Variant B "Copia protagonista".
/// `hasAnyTransactions == false` renders the third state (`Am9cg`,
/// brand-new user) — this feature has no way to know the transaction count
/// itself, so the caller (the page, wired from the router) tells the cubit
/// via `ImportExportHubCubit.start`.
class ImportExportHubState extends Equatable {
  const ImportExportHubState({
    this.status = ImportExportHubStatus.loading,
    this.lastBackupSavedAt,
    this.latestBatch,
    this.hasAnyTransactions = true,
    this.failure,
  });

  final ImportExportHubStatus status;

  /// `null` renders "Aún no has guardado una copia" (`qDCvi`) — content, not
  /// an error.
  final DateTime? lastBackupSavedAt;

  /// Most recent import batch, for the "Importaciones recientes" preview row.
  /// `null` when none exists yet.
  final ImportBatch? latestBatch;

  /// `false` renders the empty state (`Am9cg`) — no transactions to export
  /// yet, the hero flips to "traer historial".
  final bool hasAnyTransactions;

  final Failure? failure;

  bool get isLoading => status == ImportExportHubStatus.loading;
  bool get hasCopy => lastBackupSavedAt != null;

  ImportExportHubState copyWith({
    ImportExportHubStatus? status,
    DateTime? lastBackupSavedAt,
    bool clearLastBackupSavedAt = false,
    ImportBatch? latestBatch,
    bool clearLatestBatch = false,
    bool? hasAnyTransactions,
    Failure? failure,
  }) =>
      ImportExportHubState(
        status: status ?? this.status,
        lastBackupSavedAt: clearLastBackupSavedAt
            ? null
            : (lastBackupSavedAt ?? this.lastBackupSavedAt),
        latestBatch: clearLatestBatch ? null : (latestBatch ?? this.latestBatch),
        hasAnyTransactions: hasAnyTransactions ?? this.hasAnyTransactions,
        failure: failure,
      );

  @override
  List<Object?> get props => [
        status,
        lastBackupSavedAt,
        latestBatch,
        hasAnyTransactions,
        failure,
      ];
}
