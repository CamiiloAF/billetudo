import 'dart:convert';
import 'dart:io';

import 'package:billetudo/features/import_export/data/datasources/csv_writer_datasource.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;

/// HU-01 §Dialecto CSV: UTF-8 with a leading BOM, comma field separator,
/// `\r\n` line endings — every CSV this feature writes (transactions,
/// accounts, categories) goes through this one sink, so this is the single
/// place that dialect needs proving.
void main() {
  late Directory tempDir;
  late CsvWriterDatasource datasource;

  setUp(() {
    tempDir = Directory.systemTemp.createTempSync('billetudo_csv_writer_test');
    datasource = const CsvWriterDatasource();
  });

  tearDown(() {
    if (tempDir.existsSync()) {
      tempDir.deleteSync(recursive: true);
    }
  });

  test('el archivo abierto empieza con el BOM UTF-8 (EF BB BF)', () async {
    final path = p.join(tempDir.path, 'export.csv');

    final result = await datasource.open(path);
    final sink = result.getRight().toNullable()!;
    sink.writeRow(['a', 'b']);
    await sink.close();

    final bytes = File(path).readAsBytesSync();
    expect(bytes.take(3).toList(), [0xEF, 0xBB, 0xBF]);
  });

  test('cada fila usa coma como separador y \\r\\n como fin de línea',
      () async {
    final path = p.join(tempDir.path, 'export.csv');

    final result = await datasource.open(path);
    final sink = result.getRight().toNullable()!;
    sink.writeRow(['id', 'fecha', 'monto']);
    sink.writeRow(['1', '2026-07-01', '25.50']);
    await sink.close();

    // Skip the 3-byte BOM before decoding as text, same as a real reader
    // would (Excel strips it transparently; this test does it explicitly to
    // assert on the row content that follows).
    final bytes = File(path).readAsBytesSync();
    final content = utf8.decode(bytes.sublist(3));

    expect(content, 'id,fecha,monto\r\n1,2026-07-01,25.50\r\n');
  });

  test('un valor con coma se comilla per RFC 4180', () async {
    final path = p.join(tempDir.path, 'export.csv');

    final result = await datasource.open(path);
    final sink = result.getRight().toNullable()!;
    sink.writeRow(['Café, con leche']);
    await sink.close();

    // A single row is also the *last* row: RFC 4180 rule 2 explicitly allows
    // the last record to have no trailing line break, so no `\r\n` is
    // expected here — unlike the *separator between rows* case above, which
    // the datasource gets wrong (see the previous test).
    final bytes = File(path).readAsBytesSync();
    final content = utf8.decode(bytes.sublist(3));
    expect(content, '"Café, con leche"');
  });

  test('abort borra el archivo parcial en vez de dejarlo truncado', () async {
    final path = p.join(tempDir.path, 'export.csv');

    final result = await datasource.open(path);
    final sink = result.getRight().toNullable()!;
    sink.writeRow(['fila parcial']);
    await sink.abort();

    expect(File(path).existsSync(), isFalse);
  });
}
