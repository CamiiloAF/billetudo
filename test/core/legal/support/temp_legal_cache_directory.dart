import 'dart:io';

import 'package:billetudo/core/legal/data/datasources/legal_documents_cache_datasource.dart';

/// [LegalCacheDirectory] pointing at a throwaway temp directory, same
/// convention as `TempSyncStorageDirectory`: `path_provider` has no platform
/// channel under `flutter test`.
class TempLegalCacheDirectory implements LegalCacheDirectory {
  TempLegalCacheDirectory(this.directory);

  factory TempLegalCacheDirectory.create([String prefix = 'billetudo_legal']) =>
      TempLegalCacheDirectory(Directory.systemTemp.createTempSync(prefix));

  final Directory directory;

  void dispose() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  }

  @override
  Future<Directory> resolve() async => directory;
}
