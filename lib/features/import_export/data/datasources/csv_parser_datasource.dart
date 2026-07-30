import 'dart:convert';
import 'dart:io';

import 'package:csv/csv.dart' show CsvToListConverter;
import 'package:injectable/injectable.dart';

import '../../../../core/error/result.dart';
import '../../domain/entities/csv_dialect.dart';
import '../../domain/entities/parsed_csv_sample.dart';

/// How many data rows `readCsvSample` previews (HU-05's live mapping
/// preview).
const int csvSampleRowCount = 5;

/// Reads and detects the dialect of an import CSV file (HU-05).
///
/// UTF-8 with an optional BOM (Excel writes one; a file without one is still
/// accepted, since not every source respects the convention this app's own
/// export follows). Field separator is detected by counting commas,
/// semicolons and tabs in the header line — whichever appears most wins,
/// falling back to comma when the line has none of the three (a single-column
/// file, or one already using something else the user must correct by hand).
@lazySingleton
class CsvParserDatasource {
  const CsvParserDatasource();

  FutureResult<ParsedCsvSample> readCsvSample(String filePath) async {
    final linesResult = await _readLines(filePath);
    if (linesResult case Left(value: final failure)) {
      return Left(failure);
    }
    final lines = (linesResult as Right<Failure, List<String>>).value;
    if (lines.isEmpty) {
      return const Left(
        IoFailure('csv file has no rows', reason: IoFailureReason.emptyFile),
      );
    }

    final separator = detectFieldSeparator(lines.first);
    final rows = _parse(lines.join('\n'), separator);
    if (rows.isEmpty) {
      return const Left(
        IoFailure('csv file has no rows', reason: IoFailureReason.emptyFile),
      );
    }

    final headers = rows.first;
    final dataRows = rows.skip(1).toList();

    return Right(
      ParsedCsvSample(
        headers: headers,
        sampleRows: dataRows.take(csvSampleRowCount).toList(),
        dialect: CsvDialect(fieldSeparator: separator),
        totalDataRowCount: dataRows.length,
      ),
    );
  }

  FutureResult<List<List<String>>> readAllRows(
    String filePath, {
    required CsvDialect dialect,
  }) async {
    final linesResult = await _readLines(filePath);
    if (linesResult case Left(value: final failure)) {
      return Left(failure);
    }
    final lines = (linesResult as Right<Failure, List<String>>).value;
    if (lines.isEmpty) {
      return const Left(
        IoFailure('csv file has no rows', reason: IoFailureReason.emptyFile),
      );
    }
    final rows = _parse(lines.join('\n'), dialect.fieldSeparator);
    if (rows.isEmpty) {
      return const Right([]);
    }
    return Right(rows.skip(1).toList());
  }

  /// Exposed so `AutodetectColumnMapping`'s caller (a future presentation
  /// cubit) can let the user correct a wrong guess without re-reading the
  /// file — kept `static` since it is a pure function of the header line.
  static CsvFieldSeparator detectFieldSeparator(String headerLine) {
    final commas = ','.allMatches(headerLine).length;
    final semicolons = ';'.allMatches(headerLine).length;
    final tabs = '\t'.allMatches(headerLine).length;
    if (semicolons > commas && semicolons >= tabs) {
      return CsvFieldSeparator.semicolon;
    }
    if (tabs > commas && tabs > semicolons) {
      return CsvFieldSeparator.tab;
    }
    return CsvFieldSeparator.comma;
  }

  List<List<String>> _parse(String content, CsvFieldSeparator separator) {
    final fieldSeparator = switch (separator) {
      CsvFieldSeparator.comma => ',',
      CsvFieldSeparator.semicolon => ';',
      CsvFieldSeparator.tab => '\t',
    };
    final converter = CsvToListConverter(
      fieldDelimiter: fieldSeparator,
      shouldParseNumbers: false,
      eol: '\n',
    );
    final rows = converter.convert(content);
    return [
      for (final row in rows)
        if (row.any((cell) => cell.toString().trim().isNotEmpty))
          [for (final cell in row) cell?.toString() ?? ''],
    ];
  }

  FutureResult<List<String>> _readLines(String filePath) async {
    try {
      final file = File(filePath);
      if (!file.existsSync()) {
        return const Left(
          IoFailure(
            'csv file does not exist',
            reason: IoFailureReason.unreadableFile,
          ),
        );
      }
      final bytes = await file.readAsBytes();
      if (bytes.isEmpty) {
        return const Left(
          IoFailure('csv file is empty', reason: IoFailureReason.emptyFile),
        );
      }
      // Strip a UTF-8 BOM (EF BB BF) if present.
      final withoutBom = bytes.length >= 3 &&
              bytes[0] == 0xEF &&
              bytes[1] == 0xBB &&
              bytes[2] == 0xBF
          ? bytes.sublist(3)
          : bytes;
      final String content;
      try {
        content = utf8.decode(withoutBom);
      } on FormatException {
        return const Left(
          IoFailure(
            'csv file is not valid UTF-8',
            reason: IoFailureReason.unreadableFile,
          ),
        );
      }
      final lines = const LineSplitter()
          .convert(content)
          .where((line) => line.isNotEmpty)
          .toList();
      return Right(lines);
    } on FileSystemException catch (e, st) {
      return Left(
        IoFailure(
          'could not read csv file',
          reason: e.osError?.errorCode == 13
              ? IoFailureReason.permissionDenied
              : IoFailureReason.unreadableFile,
          cause: e,
          stackTrace: st,
        ),
      );
    }
  }
}
