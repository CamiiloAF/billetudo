import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'sync_storage_directory.dart';

/// A JSON array persisted to a single file, read once and rewritten on every
/// change. Shared by the quarantine and the local sync log.
///
/// Writes are serialized through [_pending]: both callers append from the
/// upload path, which can run concurrently with a manual retry, and two
/// interleaved rewrites of the same file would lose entries.
///
/// A corrupt or truncated file (a crash mid-write) degrades to an empty list
/// rather than throwing: diagnostics must never be the reason the app fails.
class JsonListFile {
  JsonListFile(this._directory, this._fileName);

  final SyncStorageDirectory _directory;
  final String _fileName;

  Future<void> _pending = Future<void>.value();

  Future<File> _file() async {
    final dir = await _directory.resolve();
    return File('${dir.path}/$_fileName');
  }

  /// Reads the stored array. Returns an empty list when the file is missing
  /// or unreadable.
  Future<List<Map<String, dynamic>>> read() async {
    try {
      final file = await _file();
      if (!file.existsSync()) {
        return <Map<String, dynamic>>[];
      }
      final raw = await file.readAsString();
      if (raw.trim().isEmpty) {
        return <Map<String, dynamic>>[];
      }
      final decoded = jsonDecode(raw);
      if (decoded is! List) {
        return <Map<String, dynamic>>[];
      }
      return decoded.whereType<Map<String, dynamic>>().toList();
    } catch (_) {
      return <Map<String, dynamic>>[];
    }
  }

  /// Overwrites the file with [entries], serialized against other writes.
  Future<void> write(List<Map<String, dynamic>> entries) {
    final next = _pending.then((_) async {
      final file = await _file();
      await file.writeAsString(jsonEncode(entries), flush: true);
    });
    // Keep the chain alive even if this write failed, so a single I/O error
    // does not poison every later write.
    _pending = next.catchError((Object _) {});
    return next;
  }
}
