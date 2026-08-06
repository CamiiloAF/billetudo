// Patrol e2e for Import/Export (HU-05/06/07/08): the real app, real
// on-device Drift database, real go_router navigation, nothing mocked
// *except* the OS's own native file picker — see the note above
// `_mockFilePicker` for why that one plugin boundary is stubbed instead of
// driven for real.
//
// Covers the most critical multi-screen path: pick a CSV file → mapping
// (autodetected, own vocabulary) → resolve destinations → preview → confirm
// → summary, then undo that same import from the "Importaciones" history.
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
    'id', 'fecha', 'tipo', 'monto', 'moneda', 'cuenta', 'cuenta_destino',
    'categoria', 'subcategoria', 'nota', 'etiquetas', 'presupuestable',
    'origen',
  ];
  final rowColumns = [
    '', '2026-07-10', 'gasto', '25.50', 'COP', 'Cuenta E2E', '',
    'Mercado E2E', '', '', '', 'sí', 'manual',
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
      await _mockFilePicker(csvPath, _fileName);

      await _openImportExportHub($);

      // Hub → "Importar desde un CSV" (HU-05 entry point).
      await $.tester.tap(find.text('Importar desde un CSV'));
      await $.tester.pumpAndSettle();

      // File-select step → triggers the (mocked) native picker.
      expect(find.text('Elegir archivo'), findsOneWidget);
      await $.tester.tap(find.text('Elegir archivo'));
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

      // Summary: the write committed inside ConfirmImport's single
      // transaction. "Listo" pops back to the hub (`onDone: context.pop()`).
      expect(find.text('Importación completa'), findsOneWidget);
      await $.tester.tap(find.text('Listo'));
      await $.tester.pumpAndSettle();
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
}
