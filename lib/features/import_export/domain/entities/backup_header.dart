import 'package:equatable/equatable.dart';

/// Versioned cabecera of a `.billetudo.json` copy (HU-03/HU-04). Read first,
/// before touching a single row, so a copy from a newer app can be rejected
/// outright instead of restoring half of it.
class BackupHeader extends Equatable {
  const BackupHeader({
    required this.formatVersion,
    required this.schemaVersion,
    required this.appVersion,
    required this.createdAt,
    required this.rowCountsByTable,
  });

  /// Version of this copy's own JSON shape (bumped only when the shape
  /// itself changes, independent of [schemaVersion]). `RestoreBackup` rejects
  /// a copy whose [formatVersion] is newer than what this build understands.
  final int formatVersion;

  /// `AppDatabase.schemaVersion` at the time the copy was written — informs
  /// `RestoreBackup` which migrations, if any, its content needs.
  final int schemaVersion;

  /// The app's own version string (`pubspec.yaml`), for the summary shown
  /// before restoring.
  final String appVersion;

  final DateTime createdAt;

  /// How many rows the copy carries per table (`'transactions': 512, ...`),
  /// so the pre-restore summary can say "cuántas filas trae por tipo"
  /// (HU-04) without reading the whole file first.
  final Map<String, int> rowCountsByTable;

  @override
  List<Object?> get props => [
        formatVersion,
        schemaVersion,
        appVersion,
        createdAt,
        rowCountsByTable,
      ];
}
