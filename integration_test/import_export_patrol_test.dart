// Patrol e2e for Import/Export (HU-03/04/05/06/07/08): the real app, real
// on-device Drift database, real go_router navigation, nothing mocked
// *except* two OS-owned plugin boundaries — see the notes above
// `_mockFilePicker`/`_mockShareChannel` for why those are stubbed instead of
// driven for real.
//
// Covers:
//  - HU-05/06/07/08: pick a CSV file → mapping (autodetected, own
//    vocabulary) → resolve destinations → preview → confirm → summary, then
//    undo that same import from the "Importaciones" history.
//  - HU-03: export the transactions CSV from the hub.
//  - HU-03/04 setup: "Guardar una copia" writes a real `.billetudo.json`.
//  - HU-04: restore that copy (Fusionar) and recreate data lost since it was
//    taken.
import 'dart:convert';
import 'dart:io';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

const _fileName = 'billetudo-transacciones-e2e.csv';

/// `file_picker`'s native method channel (`miguelruivo.flutter.plugins.filepicker`,
/// see `file_picker_method_channel.dart`). The OS's own file chooser is
/// system UI, not app UI — `design-system/billetudo/pages/import-export.md`
/// explicitly says it "no se diseña (es del sistema operativo)" — and
/// driving it for real would make this scenario depend on the emulator's
/// Files app/document-provider layout, which varies by Android version and
/// is exactly the kind of native-automation flakiness `CLAUDE.md`'s QA
/// playbook warns about (`docs/dev-runs/bug-fixes-pixel-audit.md`,
/// `adb input tap`). Stubbing the plugin boundary at the method channel
/// (same technique as `test/core/security/secure_clipboard_test.dart`) keeps
/// the scenario deterministic while still exercising every screen that is
/// actually part of this feature's own UI.
///
/// Reused for both CSV import (HU-05) and restore (HU-04) — `RestoreCubit`
/// and `ImportFlowCubit` both call `FilePicker.pickFiles` on this same
/// channel, only `allowedExtensions` differs, and this mock ignores that
/// filter entirely (it always returns the one file it was told to).
Future<void> _mockFilePicker(String path, String name) async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('miguelruivo.flutter.plugins.filepicker'),
    (call) async {
      if (call.method == 'clear') {
        return true;
      }
      final size = File(path).lengthSync();
      return <Map<String, dynamic>>[
        {'path': path, 'name': name, 'size': size},
      ];
    },
  );
}

/// `share_plus`'s native method channel
/// (`dev.fluttercommunity.plus/share`, see
/// `share_plus_platform_interface`'s `MethodChannelShare`). Export (HU-01),
/// "Guardar una copia" (HU-03) and every write this suite exercises all
/// funnel their result straight into `SharePlus.instance.share` the instant
/// they finish — `ExportRunSheetBody`/`SaveCopySheetBody`'s listeners call it
/// automatically, not from a tap this suite drives. The OS share sheet is
/// system UI, same reasoning as `_mockFilePicker`: stub the plugin boundary
/// so the scenario doesn't depend on the emulator's installed share targets.
Future<void> _mockShareChannel() async {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(
    const MethodChannel('dev.fluttercommunity.plus/share'),
    (call) async {
      if (call.method == 'share') {
        return 'dev.fluttercommunity.plus/share/success';
      }
      return null;
    },
  );
}

/// Writes a one-row CSV in billetudo's own export vocabulary (es) so the
/// mapping step's autodetection (HU-05 "autodetección del formato propio")
/// resolves the mapping in full — no manual column picking needed, matching
/// what a real "reimport my own export" migration looks like.
Future<String> _writeOwnFormatCsv() async {
  final dir = await getTemporaryDirectory();
  final path = p.join(dir.path, _fileName);
  // Built from an explicit field list (13 columns, HU-01's exact order) and
  // joined programmatically rather than hand-typed with literal commas — a
  // hand-typed row is an easy off-by-one on the number of empty fields, and
  // a wrong field count makes `PreviewImport` reject the row as invalid.
  const headerColumns = [
    'id',
    'fecha',
    'tipo',
    'monto',
    'moneda',
    'cuenta',
    'cuenta_destino',
    'categoria',
    'subcategoria',
    'nota',
    'etiquetas',
    'presupuestable',
    'origen',
  ];
  final rowColumns = [
    '',
    '2026-07-10',
    'gasto',
    '25.50',
    'COP',
    'Cuenta E2E',
    '',
    'Mercado E2E',
    '',
    '',
    '',
    'sí',
    'manual',
  ];
  assert(headerColumns.length == 13 && rowColumns.length == 13);
  await File(path).writeAsString(
    '${headerColumns.join(',')}\r\n${rowColumns.join(',')}\r\n',
  );
  return path;
}

Future<void> _openImportExportHub(PatrolIntegrationTester $) async {
  await $.tester.tap(find.text('Más'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Importar y exportar'));
  await $.tester.pumpAndSettle();
}

/// Runs HU-05 end to end from the hub: mocks the native picker with
/// [csvPath]/[csvName], taps the import CTA (which — since
/// `ImportPickSheet` (2026-08-07) fires the native picker *before* pushing
/// any route — jumps straight to the mapping step, no intermediate
/// "Elegir archivo" screen anymore), confirms the fully-autodetected
/// mapping, accepts the default "crear nueva" destinations, and commits the
/// single previewed row. Leaves the app back on the hub, same as tapping
/// "Listo" would.
///
/// Every call site starts from a Drift database with no transactions yet
/// (`startApp` always boots a fresh in-memory-equivalent DB, and this is the
/// *first* import each scenario runs), so the hub is always rendering
/// `ImportExportEmptyHub` at this point, never `ImportExportHubContent` —
/// same `onImportCsv` callback underneath, but the empty state's CTA label
/// is "Importar un CSV" (`importExportEmptyImportCta`), not "Importar desde
/// un CSV" (`importExportImportCsvTitle`, the data-state row's label).
Future<void> _importOwnFormatCsv(
  PatrolIntegrationTester $,
  String csvPath,
  String csvName,
) async {
  await _mockFilePicker(csvPath, csvName);
  await _openImportExportHub($);

  // Hub (empty state) → "Importar un CSV" (HU-05 entry point) triggers the
  // (mocked) native picker directly — no "Elegir archivo" sheet in between
  // anymore.
  await $.tester.tap(find.text('Importar un CSV'));
  await $.tester.pumpAndSettle();

  // Mapping step: own vocabulary fully autodetected — defaults to the
  // "Automático" toggle, whose CTA reads "Confirmar mapeo" (not
  // "Continuar", that label is Manual mode's) — just confirm.
  expect(find.text('Mapeo de columnas'), findsOneWidget);
  expect(find.text('Automático'), findsOneWidget);
  await $.tester.tap(find.text('Confirmar mapeo'));
  await $.tester.pumpAndSettle();

  // Destinations step: "Cuenta E2E" and "Mercado E2E" are both new,
  // "crear nueva" is the default — no interaction needed, just advance.
  expect(find.text('Resolver destinos'), findsOneWidget);
  await $.tester.tap(find.text('Continuar'));
  await $.tester.pumpAndSettle();

  // Final preview: one valid, non-duplicate row, checked by default.
  // `ImportPreviewStep`'s CTA is `importExportImportRowsCta(count)`
  // ("Importar {count} movimientos"), not a fixed "Confirmar
  // importación" label — this scenario always has exactly one row.
  expect(find.text('Vista previa'), findsOneWidget);
  await $.tester.tap(find.text('Importar 1 movimientos'));
  await $.tester.pumpAndSettle();

  // Summary lives in `ImportRunSheet` (modal, corrected 2026-08-07) — the
  // write committed inside `ConfirmImport`'s single transaction.
  // "Listo" pops the sheet, handing back to the hub underneath.
  expect(find.text('Importación completa'), findsOneWidget);
  await $.tester.tap(find.text('Listo'));
  await $.tester.pumpAndSettle();
}

String _dateStamp(DateTime date) => '${date.year.toString().padLeft(4, '0')}-'
    '${date.month.toString().padLeft(2, '0')}-'
    '${date.day.toString().padLeft(2, '0')}';

/// Both `SaveCopyCubit.start` and `ExportCubit.confirm` write into
/// `getTemporaryDirectory()` with a filename stamped by today's date —
/// deterministic enough to predict from the test without needing a handle on
/// the cubit itself (nothing in the widget tree surfaces the exact path).
Future<String> _tempFilePath(String fileName) async {
  final dir = await getTemporaryDirectory();
  return p.join(dir.path, fileName);
}

/// Polls for a file to appear on disk. This suite runs as a real Patrol
/// integration test (a live `IntegrationTestWidgetsFlutterBinding`, not the
/// fake-async clock of a plain widget test), so a real bounded
/// `Future.delayed` poll is safe here the same way this file already reads
/// real `File`s directly elsewhere — `pumpAndSettle` alone only guarantees
/// the widget tree stopped scheduling frames, not that an unrelated disk
/// write already landed.
Future<void> _waitForFile(String path, {int maxAttempts = 50}) async {
  for (var i = 0; i < maxAttempts; i++) {
    if (File(path).existsSync()) {
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 100));
  }
  throw StateError('Expected file was never written: $path');
}

void main() {
  patrolTest(
    // No slash in the scenario name: AndroidTestOrchestrator turns each Dart
    // test name into an output filename, and a literal "/" is treated as a
    // path separator, crashing the whole native test run — same caveat as
    // `categories_patrol_test.dart`, verified against a real emulator run.
    'HU-05 06 07 08: importar un CSV propio de punta a punta y deshacer '
    'esa importación desde el historial',
    ($) async {
      await startApp($);

      final csvPath = await _writeOwnFormatCsv();
      await _importOwnFormatCsv($, csvPath, _fileName);

      // Same async-hop caveat as the undo step below: popping back to the
      // hub and the hub's `WatchImportBatches` Drift stream picking up the
      // batch just committed inside `ConfirmImport`'s transaction are
      // separate hops — give the stream's query a tick to emit before
      // asserting on its result.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Back on the hub: the new batch shows in "Importaciones recientes".
      // The row sits below the fold on a phone-sized viewport (hero card +
      // privacy note + the three action rows all come first) — `ListView`
      // lazily lays out only what's within its cache extent, so the row's
      // `Text` isn't in the tree at all until scrolled into view.
      await $.tester.scrollUntilVisible(
        find.text(_fileName),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await $.tester.pumpAndSettle();
      expect(find.text(_fileName), findsOneWidget);

      // The transaction itself landed for real against the on-device Drift
      // database, with source=imported and a non-null importBatchId (HU-05),
      // not just something the UI claims happened.
      final db = getIt<AppDatabase>();
      final imported = await (db.select(db.transactions)
            ..where((t) => t.amountMinor.equals(2550)))
          .getSingle();
      expect(imported.source, TxSource.imported);
      expect(imported.importBatchId, isNotNull);

      // HU-08: open the batch from the hub's recent-imports row and undo it.
      await $.tester.tap(find.text(_fileName));
      await $.tester.pumpAndSettle();

      expect(find.text('Importaciones'), findsOneWidget);
      await $.tester.tap(find.text(_fileName));
      await $.tester.pumpAndSettle();

      expect(find.text('¿Deshacer esta importación?'), findsOneWidget);
      await $.tester.tap(find.text('Deshacer importación'));
      await $.tester.pumpAndSettle();
      // Same async-hop caveat as categories_patrol_test.dart: undo, the
      // sheet pop and the Drift stream update are separate hops.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Reverted: the row now carries the "Revertida" badge and the
      // transaction it created is soft-deleted (deletedAt, HU-08 — not
      // tombstoned, still recoverable from the trash).
      expect(find.text('Revertida'), findsOneWidget);

      final revertedTransaction = await (db.select(db.transactions)
            ..where((t) => t.amountMinor.equals(2550)))
          .getSingle();
      expect(revertedTransaction.deletedAt, isNotNull);
      expect(revertedTransaction.tombstonedAt, isNull);
    },
  );

  patrolTest(
    'HU-03: exportar los movimientos a CSV desde el hub',
    ($) async {
      await startApp($);
      await _mockShareChannel();

      // Setup: a real transaction/account/category to export, via the same
      // CSV-import path the first scenario exercises end to end.
      final csvPath = await _writeOwnFormatCsv();
      await _importOwnFormatCsv($, csvPath, _fileName);

      // `_importOwnFormatCsv` already leaves the app on the hub (its own
      // "Listo" pop) — no second `_openImportExportHub` needed here.
      await $.tester.tap(find.text('Exportar a CSV'));
      await $.tester.pumpAndSettle();

      // Default scope already has "Transacciones" checked (the router seeds
      // `ExportCubit.start(hasAnyTransactions: true)`) — no toggle needed,
      // just confirm.
      expect(find.text('Exportar tus datos'), findsOneWidget);
      await $.tester.tap(find.text('Exportar'));
      await $.tester.pumpAndSettle();
      // `ExportRunSheet` opens over the form, runs, hands the file to the
      // (mocked) share sheet and closes itself back to the form — give the
      // async hops (write → share → state → pop) room to settle.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Back on the export form: no error sheet stuck on screen.
      expect(find.text('No pudimos guardar el archivo'), findsNothing);
      expect(find.text('Exportar tus datos'), findsOneWidget);

      // The write landed for real: a single CSV (only "Transacciones" was
      // selected, so no zip step) containing the row this scenario imported.
      final stamp = _dateStamp(DateTime.now());
      final exportedPath =
          await _tempFilePath('billetudo-transacciones-$stamp.csv');
      await _waitForFile(exportedPath);
      final content = File(exportedPath).readAsStringSync();
      expect(content, contains('Mercado E2E'));
      expect(content, contains('Cuenta E2E'));
    },
  );

  patrolTest(
    'HU-03 04: guardar una copia local completa desde el hub',
    ($) async {
      await startApp($);
      await _mockShareChannel();

      // Setup: real data to back up.
      final csvPath = await _writeOwnFormatCsv();
      await _importOwnFormatCsv($, csvPath, _fileName);

      // `_importOwnFormatCsv` already leaves the app on the hub (its own
      // "Listo" pop) — no second `_openImportExportHub` needed here.
      await $.tester.tap(find.text('Guardar una copia'));
      await $.tester.pumpAndSettle();
      // `SaveCopySheet` opens over the hub, runs, hands the file to the
      // (mocked) share sheet and closes itself — same async-hop caveat as
      // the export scenario above.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      // Back on the hub: no error sheet stuck on screen, and the hero card
      // now shows a "last saved" status instead of "never saved" (HU-03).
      expect(find.text('No pudimos guardar el archivo'), findsNothing);
      expect(
        find.text('Aún no has guardado una copia'),
        findsNothing,
      );

      // The write landed for real, as a valid `.billetudo.json` this same
      // scenario could hand to `RestoreCubit.pickFile` (exercised by the
      // restore scenario below, from its own independent setup).
      final stamp = _dateStamp(DateTime.now());
      final backupPath =
          await _tempFilePath('billetudo-copia-$stamp.billetudo.json');
      await _waitForFile(backupPath);
      final decoded = jsonDecode(File(backupPath).readAsStringSync())
          as Map<String, dynamic>;
      expect(decoded['formatVersion'], isNotNull);
      expect(decoded['tables'], isA<Map<String, dynamic>>());
    },
  );

  patrolTest(
    'HU-04: restaurar una copia con Fusionar recrea un movimiento perdido',
    ($) async {
      await startApp($);
      await _mockShareChannel();

      // Setup: create the data, then back it up for real (HU-03) — the
      // backup this scenario restores from is the app's own output, not a
      // hand-built fixture, so it stays honest about the on-disk format.
      final csvPath = await _writeOwnFormatCsv();
      await _importOwnFormatCsv($, csvPath, _fileName);

      final db = getIt<AppDatabase>();
      final imported = await (db.select(db.transactions)
            ..where((t) => t.amountMinor.equals(2550)))
          .getSingle();

      // `_importOwnFormatCsv` already leaves the app on the hub (its own
      // "Listo" pop) — no second `_openImportExportHub` needed here.
      await $.tester.tap(find.text('Guardar una copia'));
      await $.tester.pumpAndSettle();
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      final stamp = _dateStamp(DateTime.now());
      final backupPath =
          await _tempFilePath('billetudo-copia-$stamp.billetudo.json');
      await _waitForFile(backupPath);

      // Simulate data loss since that backup was taken: the transaction the
      // backup captured is now gone from the live database.
      await (db.delete(db.transactions)..where((t) => t.id.equals(imported.id)))
          .go();
      final goneCheck = await (db.select(db.transactions)
            ..where((t) => t.id.equals(imported.id)))
          .getSingleOrNull();
      expect(goneCheck, isNull);

      // Restore from that exact backup, Fusionar mode (the default) —
      // native picker mocked straight onto the file this same scenario just
      // wrote, same pattern as `_mockFilePicker`'s CSV use.
      await _mockFilePicker(backupPath, p.basename(backupPath));
      await $.tester.tap(find.text('Restaurar desde una copia'));
      await $.tester.pumpAndSettle();

      expect(find.text('Restaurar copia'), findsOneWidget);
      expect(find.text('Fusionar'), findsOneWidget);
      await $.tester.tap(find.text('Restaurar'));
      await $.tester.pumpAndSettle();
      // Same async-hop caveat as the rest of this suite: the restore
      // transaction, the sheet's state update and its `done` render are
      // separate hops.
      await $.tester.pump(const Duration(milliseconds: 500));
      await $.tester.pumpAndSettle();

      expect(find.text('Restauración completa'), findsOneWidget);
      await $.tester.tap(find.text('Listo'));
      await $.tester.pumpAndSettle();

      // The row the backup captured is back, with the exact id and amount
      // it had when the copy was taken — not just "some transaction exists".
      final restored = await (db.select(db.transactions)
            ..where((t) => t.id.equals(imported.id)))
          .getSingle();
      expect(restored.amountMinor, 2550);
      expect(restored.deletedAt, isNull);
    },
  );
}
