import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../entities/backup_header.dart';
import '../repositories/backup_repository.dart';

/// HU-04's first, cheap step: reads a copy's cabecera and rejects it outright
/// when it is newer than what this build understands — before touching a
/// single row.
///
/// Only [BackupHeader.formatVersion] (this feature's own JSON-shape version)
/// is checked here: it is domain-owned versioning, unlike
/// `AppDatabase.schemaVersion`, which `data/`'s `BackupRepositoryImpl`
/// compares against its own live instance instead — this domain layer never
/// imports Drift, so it cannot know the running app's schema version itself.
@injectable
class ParseBackupHeader {
  const ParseBackupHeader(this._repository);

  static const int currentFormatVersion = 1;

  final BackupRepository _repository;

  FutureResult<BackupHeader> call(String inputPath) async {
    final result = await _repository.parseBackupHeader(inputPath);
    return result.fold(Left.new, (header) {
      if (header.formatVersion > currentFormatVersion) {
        return Left(
          ValidationFailure(
            'backup format ${header.formatVersion} is newer than this app '
            'understands (max $currentFormatVersion)',
            field: 'formatVersion',
          ),
        );
      }
      return Right(header);
    });
  }
}
