import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/sync/domain/entities/sync_log_entry.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_log_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_log_state.dart';
import 'package:billetudo/core/sync/presentation/widgets/sheets/sync_log_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/golden_helpers.dart';

class MockSyncLogCubit extends MockCubit<SyncLogState>
    implements SyncLogCubit {}

/// "Registro técnico" (`T7Iw0C`/`ShmG5`): la única superficie del producto
/// donde se permite jerga de sync — códigos, nombres de tabla y timestamps
/// ISO.
///
/// La hoja se abre por su propio `show()`, que resuelve `SyncLogCubit` desde
/// `getIt`: el golden registra el cubit mockeado en el contenedor en vez de
/// puentear el punto de entrada real, para capturar exactamente la hoja que
/// se muestra en la app (scrim, handle y chrome de `BottomSheetBase`
/// incluidos).
///
/// Timestamps fijos en UTC a propósito: `toLogLine()` los escribe en ISO, así
/// que un `DateTime.now()` haría el golden no determinista.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  tearDown(getIt.reset);

  SyncLogEntry entry(
    int index, {
    required SyncLogLevel level,
    required SyncLogEvent event,
    String? code,
    String? tableName,
    required String message,
  }) =>
      SyncLogEntry(
        id: 'log-$index',
        timestamp: DateTime.utc(2026, 7, 25, 9, 14).add(
          Duration(minutes: index * 7),
        ),
        level: level,
        event: event,
        message: message,
        code: code,
        tableName: tableName,
      );

  /// Un registro realista del incidente que originó la feature: la subida
  /// arranca, una escritura se rechaza, se reintenta, el watchdog la saca de
  /// la cola y la subida termina con operaciones en cuarentena.
  final entries = <SyncLogEntry>[
    // Telegraphic on purpose, matching the density every real call site now
    // uses (`toLogLine()`, `powersync_connector.dart`): the block is sized
    // for eight one-line entries (`T7Iw0C`), not eight paragraphs.
    entry(
      0,
      level: SyncLogLevel.info,
      event: SyncLogEvent.connection,
      message: 'credentials issued',
    ),
    entry(
      1,
      level: SyncLogLevel.info,
      event: SyncLogEvent.uploadStarted,
      message: 'push 12 ops',
    ),
    entry(
      2,
      level: SyncLogLevel.warning,
      event: SyncLogEvent.uploadRetry,
      code: 'PGRST204',
      tableName: 'transactions',
      message: 'retry #1',
    ),
    entry(
      3,
      level: SyncLogLevel.error,
      event: SyncLogEvent.quarantined,
      code: 'PGRST204',
      tableName: 'transactions',
      message: 'quarantined (brokenSchema)',
    ),
    entry(
      4,
      level: SyncLogLevel.error,
      event: SyncLogEvent.watchdogQuarantined,
      code: '503',
      tableName: 'debts',
      message: 'stalled 20x/72h',
    ),
    entry(
      5,
      level: SyncLogLevel.info,
      event: SyncLogEvent.uploadFinished,
      message: '10 uploaded, 2 quarantined',
    ),
    entry(
      6,
      level: SyncLogLevel.info,
      event: SyncLogEvent.quarantineRetry,
      tableName: 'transactions',
      message: 'retry ok',
    ),
    entry(
      7,
      level: SyncLogLevel.info,
      event: SyncLogEvent.uploadFinished,
      message: '1 uploaded, 0 quarantined',
    ),
  ];

  Future<void> golden(
    WidgetTester tester,
    SyncLogState initial,
    String name, {
    required Brightness brightness,
  }) async {
    final cubit = MockSyncLogCubit();
    when(cubit.start).thenAnswer((_) async {});
    whenListen(
      cubit,
      const Stream<SyncLogState>.empty(),
      initialState: initial,
    );
    getIt.registerFactory<SyncLogCubit>(() => cubit);

    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SyncLogSheet.show(context),
            child: const Text('open'),
          ),
        ),
        brightness: brightness,
      ),
    );
    await tester.tap(find.byType(ElevatedButton));
    await tester.pumpAndSettle();

    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/sync_log_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    // El caso normal: la consola llena hasta su tope de 220px, con los dos
    // botones del pie ("Copiar" y "Compartir").
    testWidgets('registro técnico — con líneas ($suffix)', (tester) async {
      await golden(
        tester,
        SyncLogState(entries: entries, isLoading: false),
        'with_entries_$suffix',
        brightness: brightness,
      );
    });

    // Una sola línea: el subtítulo cambia de forma plural ("Última línea").
    testWidgets('registro técnico — una sola línea ($suffix)', (tester) async {
      await golden(
        tester,
        SyncLogState(entries: [entries.first], isLoading: false),
        'single_entry_$suffix',
        brightness: brightness,
      );
    });

    // Vacío: el bloque no colapsa, dice que todavía no hay nada registrado.
    testWidgets('registro técnico — vacío ($suffix)', (tester) async {
      await golden(
        tester,
        const SyncLogState(entries: [], isLoading: false),
        'empty_$suffix',
        brightness: brightness,
      );
    });
  }
}
