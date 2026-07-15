import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Opens the local SQLite database — the app's **offline-first source of
/// truth**. The actual open (path_provider I/O) is deferred with
/// [LazyDatabase] so it does not block startup.
///
/// Once PowerSync is integrated, this function is replaced by opening Drift on
/// top of the PowerSync-managed database (see the note in `app_database.dart`).
LazyDatabase openLocalDatabase() {
  return LazyDatabase(() async {
    final dir = await getApplicationDocumentsDirectory();
    final file = File(p.join(dir.path, 'billetudo.sqlite'));
    return NativeDatabase.createInBackground(file);
  });
}
