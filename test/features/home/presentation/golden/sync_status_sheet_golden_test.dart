import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/sync_status_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../support/golden_helpers.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  /// [syncedAgo] y [quarantined] son el detalle que la hoja necesita: la fila
  /// de "última sincronización" se muestra en los cinco estados, y el estado
  /// de atención cambia de copy según su causa (registros trabados vs. una
  /// sincronización que lleva demasiado).
  HomeState stateWith(
    HomeSyncStatus status, {
    Duration syncedAgo = const Duration(minutes: 5),
    int quarantined = 0,
    SyncState snapshotState = SyncState.synced,
  }) =>
      HomeState(
        status: HomeStatus.ready,
        syncStatus: status,
        syncSnapshot: SyncStatusSnapshot(
          state: snapshotState,
          quarantinedCount: quarantined,
          lastSyncedAt: DateTime.now().subtract(syncedAgo),
          hasSyncedEver: true,
        ),
      );

  /// Opens the reactive [SyncStatusSheet] through a real trigger (scrim, drag
  /// handle and `BottomSheetBase` chrome included) with the cubit pinned to
  /// [status], then captures the whole screen — the same choreography as the
  /// other sheet goldens (bugfix item 6).
  Future<void> golden(
    WidgetTester tester,
    HomeState state,
    String name, {
    required Brightness brightness,
    bool withDetails = false,
  }) async {
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      const Stream<HomeState>.empty(),
      initialState: state,
    );

    setGoldenViewport(tester);
    await tester.pumpWidget(
      wrapForGolden(
        Builder(
          builder: (context) => ElevatedButton(
            onPressed: () => SyncStatusSheet.show(
              context,
              cubit,
              // Los estados de atención son los únicos que ofrecen la salida a
              // "Estado de sincronización": sin este callback la hoja se
              // dibujaría con un solo botón y el golden no sería el frame.
              onOpenDetails: withDetails ? () {} : null,
            ),
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
      matchesGoldenFile('goldens/sync_status_sheet_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('sync status sheet — synced ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(HomeSyncStatus.synced),
        'synced_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status sheet — syncing ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(HomeSyncStatus.syncing),
        'syncing_$suffix',
        brightness: brightness,
      );
    });

    testWidgets('sync status sheet — offline ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(HomeSyncStatus.offline),
        'offline_$suffix',
        brightness: brightness,
      );
    });

    // `MEcVH`/`ISnfN`: registros trabados — la causa accionable, ítem a ítem.
    testWidgets('sync status sheet — stalled ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(HomeSyncStatus.attention, quarantined: 2),
        'stalled_$suffix',
        brightness: brightness,
        withDetails: true,
      );
    });

    // `W4oGp`/`G6yA34`: sincronizando hace demasiado — reintento activo que
    // lleva más de 24 h sin éxito, el caso literal del incidente. Requiere
    // `state: syncing` explícito: es la única combinación de la que esta
    // copy es verdad (dice "llevamos X intentando subir tus cambios").
    testWidgets('sync status sheet — too long ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(
          HomeSyncStatus.attention,
          syncedAgo: const Duration(days: 3),
          snapshotState: SyncState.syncing,
        ),
        'too_long_$suffix',
        brightness: brightness,
        withDetails: true,
      );
    });

    // Sin frame propio todavía en `billetudo.pen` (gap conocido, ver
    // `design-system/billetudo/pages/sincronizacion.md`): atención sin nada
    // en cuarentena y sin reintento activo — solo silencio. Antes de este fix
    // caía en la copy de "too long" ("Llevamos 3 días intentando subir tus
    // cambios"), falsa cuando no hay ningún cambio pendiente.
    testWidgets('sync status sheet — stale ($suffix)', (tester) async {
      await golden(
        tester,
        stateWith(
          HomeSyncStatus.attention,
          syncedAgo: const Duration(days: 3),
        ),
        'stale_$suffix',
        brightness: brightness,
        withDetails: true,
      );
    });
  }
}
