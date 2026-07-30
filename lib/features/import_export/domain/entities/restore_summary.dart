import 'package:equatable/equatable.dart';

import 'restore_mode.dart';

/// What `RestoreBackup` actually did (HU-04): per-table counts of created,
/// updated and omitted rows, shown in the closing summary.
class RestoreSummary extends Equatable {
  const RestoreSummary({
    required this.mode,
    required this.createdByTable,
    required this.updatedByTable,
    required this.skippedByTable,
  });

  final RestoreMode mode;
  final Map<String, int> createdByTable;
  final Map<String, int> updatedByTable;
  final Map<String, int> skippedByTable;

  int get totalCreated => createdByTable.values.fold(0, (a, b) => a + b);
  int get totalUpdated => updatedByTable.values.fold(0, (a, b) => a + b);
  int get totalSkipped => skippedByTable.values.fold(0, (a, b) => a + b);

  @override
  List<Object?> get props => [mode, createdByTable, updatedByTable, skippedByTable];
}
