import 'dart:io';

import 'package:csv/csv.dart' show ListToCsvConverter;
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';

/// An open CSV file being written row by row (HU-01/02/03: "se escribe por
/// streaming... nunca materializando todo en memoria", and cancelable —
/// [abort] deletes the partial file instead of leaving a truncated one that
/// looks complete).
class CsvRowSink {
  CsvRowSink._(this._sink, this._path);

  final IOSink _sink;
  final String _path;
  // RFC 4180 defaults (comma field delimiter, `\r\n` eol) match the
  // package's own, so nothing is overridden here.
  static const ListToCsvConverter _converter = ListToCsvConverter();
  int _rowCount = 0;

  /// [ListToCsvConverter.convert] only inserts `eol` *between* the rows of
  /// the list it's given, so converting a single-row list (one call per
  /// `writeRow`) never emits one. Writing the separator ourselves, before
  /// every row but the first, guarantees every row gets terminated once
  /// [close] adds the final one back (see there) — the only file that ends
  /// up with no trailing `\r\n` at all is a file with exactly one row,
  /// which RFC 4180 explicitly allows ("the last record... may or may not
  /// have an ending line break").
  void writeRow(List<String> row) {
    if (_rowCount > 0) {
      _sink.write('\r\n');
    }
    _sink.write(_converter.convert([row]));
    _rowCount++;
  }

  Future<void> close() async {
    // Re-adds the row separator [writeRow] intentionally withholds for the
    // last row, so that every row of a multi-row file — including the last
    // — ends with `\r\n`, matching this dialect's own header line and every
    // other tool's CSV output. A file with a single row keeps no trailing
    // break, per RFC 4180's own leniency for the last record.
    if (_rowCount > 1) {
      _sink.write('\r\n');
    }
    await _sink.flush();
    await _sink.close();
  }

  /// HU-09: "cancelar borra el archivo parcial en vez de dejar un CSV
  /// truncado que parezca completo".
  Future<void> abort() async {
    await _sink.close();
    final file = File(_path);
    if (file.existsSync()) {
      await file.delete();
    }
  }
}

/// Opens a fresh RFC 4180 CSV file for streaming writes: UTF-8 with a leading
/// BOM (so Excel on Windows/es-CO renders tildes correctly on double-click)
/// and `\r\n` line endings.
@lazySingleton
class CsvWriterDatasource {
  const CsvWriterDatasource();

  FutureResult<CsvRowSink> open(String outputPath) async {
    try {
      final file = File(outputPath);
      await file.parent.create(recursive: true);
      // Ownership transfers to the returned `CsvRowSink`, whose
      // `close`/`abort` close it; the lint cannot see across that handoff.
      final sink = file.openWrite(); // ignore: close_sinks
      // UTF-8 BOM (EF BB BF), written as raw bytes to avoid any ambiguity
      // about the literal character in this source file.
      sink.add(const [0xEF, 0xBB, 0xBF]);
      return Right(CsvRowSink._(sink, outputPath));
    } on FileSystemException catch (e, st) {
      return Left(
        IoFailure(
          'could not open csv file for writing',
          reason: _reasonOf(e),
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }

  IoFailureReason _reasonOf(FileSystemException e) => switch (e.osError?.errorCode) {
        13 => IoFailureReason.permissionDenied,
        28 => IoFailureReason.noSpace,
        _ => IoFailureReason.unreadableFile,
      };
}
