import 'dart:io';

import 'package:billetudo/core/sync/data/datasources/sync_storage_directory.dart';

/// [SyncStorageDirectory] pointing at a throwaway temp directory.
///
/// The production implementation goes through `path_provider`, which has no
/// platform channel under `flutter test` — that is precisely why the interface
/// exists. Several store instances can share one of these to exercise the
/// "restart the app and read the file again" path.
class TempSyncStorageDirectory implements SyncStorageDirectory {
  TempSyncStorageDirectory(this.directory);

  /// Creates a fresh temp directory. Delete it with [dispose].
  factory TempSyncStorageDirectory.create([String prefix = 'billetudo_sync']) =>
      TempSyncStorageDirectory(Directory.systemTemp.createTempSync(prefix));

  final Directory directory;

  /// Writes [contents] verbatim into `<dir>/<fileName>`, to set up a store
  /// with pre-existing (or deliberately corrupt) data.
  void writeRaw(String fileName, String contents) {
    File('${directory.path}/$fileName').writeAsStringSync(contents);
  }

  /// Reads `<dir>/<fileName>` verbatim, or `null` when it does not exist.
  String? readRaw(String fileName) {
    final file = File('${directory.path}/$fileName');
    return file.existsSync() ? file.readAsStringSync() : null;
  }

  void dispose() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  @override
  Future<Directory> resolve() async => directory;
}
