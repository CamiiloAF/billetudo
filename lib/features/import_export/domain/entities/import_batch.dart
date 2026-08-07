import 'package:equatable/equatable.dart';

/// One completed import (HU-08). Mirrors the `ImportBatches` table; never
/// deleted, only ever marked [revertedAt] once undone.
class ImportBatch extends Equatable {
  const ImportBatch({
    required this.id,
    required this.fileName,
    required this.importedAt,
    required this.rowsImported,
    required this.rowsSkipped,
    required this.createdAt,
    required this.updatedAt,
    this.templateName,
    this.revertedAt,
  });

  final String id;
  final String fileName;
  final String? templateName;
  final DateTime importedAt;
  final int rowsImported;
  final int rowsSkipped;
  final DateTime? revertedAt;
  final DateTime createdAt;

  /// Epoch millis, not a `DateTime` — see `_SyncColumns.updatedAt`.
  final int updatedAt;

  bool get isReverted => revertedAt != null;

  @override
  List<Object?> get props => [
        id,
        fileName,
        templateName,
        importedAt,
        rowsImported,
        rowsSkipped,
        revertedAt,
        createdAt,
        updatedAt,
      ];
}
