import 'dart:io';

import 'package:archive/archive_io.dart';
import 'package:injectable/injectable.dart';
import 'package:path/path.dart' as p;

import '../../../../core/error/result.dart';

/// Bundles the loose CSVs from an HU-02 multi-selection export into a single
/// `.zip`, then deletes the loose files — the share sheet must only ever
/// offer one artifact when more than one kind was selected.
@lazySingleton
class ZipPackagerDatasource {
  const ZipPackagerDatasource();

  FutureResult<Unit> zipFiles({
    required String outputPath,
    required List<String> inputPaths,
  }) async {
    try {
      final encoder = ZipFileEncoder()..create(outputPath);
      for (final path in inputPaths) {
        await encoder.addFile(File(path), p.basename(path));
      }
      await encoder.close();
      for (final path in inputPaths) {
        final file = File(path);
        if (file.existsSync()) {
          await file.delete();
        }
      }
      return const Right(unit);
    } on FileSystemException catch (e, st) {
      return Left(
        IoFailure(
          'could not create zip file',
          reason: e.osError?.errorCode == 28
              ? IoFailureReason.noSpace
              : IoFailureReason.unreadableFile,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
