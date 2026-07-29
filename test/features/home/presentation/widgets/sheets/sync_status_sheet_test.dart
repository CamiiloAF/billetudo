import 'dart:async';

import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_time_row.dart';
import 'package:billetudo/core/theme/app_colors.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/home/presentation/cubit/home_cubit.dart';
import 'package:billetudo/features/home/presentation/cubit/home_state.dart';
import 'package:billetudo/features/home/presentation/widgets/sheets/sync_status_sheet.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class MockHomeCubit extends MockCubit<HomeState> implements HomeCubit {}

void main() {
  final month = DateTime(2026, 7);

  HomeState stateWith(HomeSyncStatus status) => HomeState(
        month: month,
        currentMonth: month,
        status: HomeStatus.ready,
        syncStatus: status,
      );

  Future<void> pumpSheet(
    WidgetTester tester,
    MockHomeCubit cubit,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(
          body: BlocProvider<HomeCubit>.value(
            value: cubit,
            child: const SyncStatusSheet(),
          ),
        ),
      ),
    );
  }

  /// Los cinco rostros de la hoja (`DUSmQ`/`uYVmf`/`n1qFs`/`MEcVH`/`W4oGp`),
  /// con el detalle que necesitan: cuándo fue la última sincronización y
  /// cuántos cambios están retenidos.
  HomeState sheetState(
    HomeSyncStatus status, {
    Duration? syncedAgo = const Duration(minutes: 5),
    int quarantined = 0,
    SyncState snapshotState = SyncState.synced,
  }) =>
      HomeState(
        month: month,
        currentMonth: month,
        status: HomeStatus.ready,
        syncStatus: status,
        syncSnapshot: SyncStatusSnapshot(
          state: snapshotState,
          quarantinedCount: quarantined,
          lastSyncedAt:
              syncedAgo == null ? null : DateTime.now().subtract(syncedAgo),
          hasSyncedEver: syncedAgo != null,
        ),
      );

  Future<void> pumpState(WidgetTester tester, HomeState state) async {
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      const Stream<HomeState>.empty(),
      initialState: state,
    );
    await pumpSheet(tester, cubit);
  }

  /// **La fila de "última sincronización" se muestra en los cinco estados.**
  /// Si solo apareciera al fallar, el usuario no tendría con qué comparar —
  /// es la lección literal del incidente que produjo esta feature.
  group('la fila de tiempo aparece en los CINCO estados', () {
    for (final (name, state) in [
      ('sincronizado', () => sheetState(HomeSyncStatus.synced)),
      ('sincronizando', () => sheetState(HomeSyncStatus.syncing)),
      ('sin conexión', () => sheetState(HomeSyncStatus.offline)),
      (
        'registros trabados',
        () => sheetState(HomeSyncStatus.attention, quarantined: 2),
      ),
      (
        'silencio prolongado (stale, sin reintento activo)',
        () => sheetState(
              HomeSyncStatus.attention,
              syncedAgo: const Duration(days: 3),
            ),
      ),
      (
        'sincronizando hace demasiado (reintento activo)',
        () => sheetState(
              HomeSyncStatus.attention,
              syncedAgo: const Duration(days: 3),
              snapshotState: SyncState.syncing,
            ),
      ),
    ]) {
      testWidgets('$name: muestra la última sincronización en relativo',
          (tester) async {
        await pumpState(tester, state());

        expect(find.byType(SyncTimeRow), findsOneWidget);
        expect(find.textContaining('hace '), findsWidgets);
        // Jamás una fecha absoluta.
        expect(find.textContaining('/'), findsNothing);
      });
    }

    testWidgets(
        'sin haber sincronizado nunca, la fila lo dice en vez de '
        'desaparecer', (tester) async {
      await pumpState(
          tester, sheetState(HomeSyncStatus.synced, syncedAgo: null));

      expect(find.byType(SyncTimeRow), findsOneWidget);
      expect(find.text('Aún no se ha sincronizado'), findsOneWidget);
    });
  });

  group('atención: dos causas, dos copys distintos', () {
    testWidgets('registros trabados: cuenta los cambios retenidos',
        (tester) async {
      await pumpState(
        tester,
        sheetState(HomeSyncStatus.attention, quarantined: 2),
      );

      expect(
          find.text('2 cambios están solo en este teléfono'), findsOneWidget);
      expect(find.byIcon(LucideIcons.cloudAlert), findsOneWidget);
    });

    testWidgets('sincronizando hace demasiado: NO se ve como sincronizando',
        (tester) async {
      // Only truthful with an active retry in flight (`state: syncing`):
      // this copy claims "llevamos X días intentando subir tus cambios",
      // which would be a lie with nothing pending and nothing retrying.
      await pumpState(
        tester,
        sheetState(
          HomeSyncStatus.attention,
          syncedAgo: const Duration(days: 3),
          snapshotState: SyncState.syncing,
        ),
      );

      expect(find.text('La sincronización está tardando'), findsOneWidget);
      expect(find.text('Sincronizando…'), findsNothing);
      expect(
        find.textContaining('Llevamos 3 días intentando subir tus cambios'),
        findsOneWidget,
      );
    });

    testWidgets(
        'silencio prolongado sin nada pendiente: no reclama un reintento '
        'activo', (tester) async {
      // Regression: before splitting the branch, this exact fixture (nothing
      // quarantined, just >24h since the last success, no active retry) fell
      // into the "too long" copy above and showed "Llevamos 3 días
      // intentando subir tus cambios" — false, because nothing was even
      // trying. Same class of bug as "Esos 0 cambios viven solo aquí" on the
      // full screen.
      await pumpState(
        tester,
        sheetState(
          HomeSyncStatus.attention,
          syncedAgo: const Duration(days: 3),
        ),
      );

      expect(find.text('Sin contacto con la nube'), findsOneWidget);
      expect(find.text('La sincronización está tardando'), findsNothing);
      expect(
        find.textContaining('Llevamos'),
        findsNothing,
      );
      expect(find.byIcon(LucideIcons.cloudOff), findsOneWidget);
    });

    testWidgets('la fila de tiempo pasa a ámbar pasadas las 24 h',
        (tester) async {
      await pumpState(
        tester,
        sheetState(
          HomeSyncStatus.attention,
          syncedAgo: const Duration(days: 3),
        ),
      );

      final context = tester.element(find.byType(SyncTimeRow));
      final colors = Theme.of(context).extension<AppColors>()!;
      final row = tester.widget<SyncTimeRow>(find.byType(SyncTimeRow));

      expect(row.color, colors.amberText);
      expect(row.color, isNot(colors.expense));
    });

    testWidgets('con todo al día la fila NO va en ámbar', (tester) async {
      await pumpState(tester, sheetState(HomeSyncStatus.synced));

      final context = tester.element(find.byType(SyncTimeRow));
      final colors = Theme.of(context).extension<AppColors>()!;
      final row = tester.widget<SyncTimeRow>(find.byType(SyncTimeRow));

      expect(row.color, colors.textPrimary);
    });

    testWidgets(
        'ofrece "Ver detalles" solo en atención y solo si hay a dónde '
        'ir', (tester) async {
      final cubit = MockHomeCubit();
      whenListen(
        cubit,
        const Stream<HomeState>.empty(),
        initialState: sheetState(HomeSyncStatus.attention, quarantined: 2),
      );
      var opened = 0;
      await tester.pumpWidget(
        MaterialApp(
          theme: AppTheme.light(),
          locale: const Locale('es'),
          localizationsDelegates: AppLocalizations.localizationsDelegates,
          supportedLocales: AppLocalizations.supportedLocales,
          home: Scaffold(
            body: BlocProvider<HomeCubit>.value(
              value: cubit,
              child: SyncStatusSheet(onOpenDetails: () => opened++),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Ver detalles'));
      await tester.pumpAndSettle();
      expect(opened, 1);
    });

    testWidgets('sincronizado: no ofrece "Ver detalles"', (tester) async {
      await pumpState(tester, sheetState(HomeSyncStatus.synced));

      expect(find.text('Ver detalles'), findsNothing);
    });
  });

  testWidgets('ninguna variante ofrece "Descartar" los cambios',
      (tester) async {
    await pumpState(
      tester,
      sheetState(HomeSyncStatus.attention, quarantined: 2),
    );

    expect(find.textContaining('Descartar'), findsNothing);
    expect(find.textContaining('Eliminar'), findsNothing);
  });

  testWidgets(
      'reactivo: pasa de "Sincronizando…" a "Todo a salvo" en sitio '
      'cuando la sync termina, sin cerrarse (bugfix item 6)', (tester) async {
    final controller = StreamController<HomeState>();
    addTearDown(controller.close);
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      controller.stream,
      initialState: stateWith(HomeSyncStatus.syncing),
    );

    await pumpSheet(tester, cubit);

    expect(find.text('Sincronizando…'), findsOneWidget);
    expect(
      find.text(
        'Estamos guardando tus cambios en la nube. '
        'Puedes seguir usando la app.',
      ),
      findsOneWidget,
    );
    expect(find.text('Todo a salvo'), findsNothing);

    controller.add(stateWith(HomeSyncStatus.synced));
    await tester.pump();

    // Same sheet instance, content swapped in place.
    expect(find.byType(SyncStatusSheet), findsOneWidget);
    expect(find.text('Todo a salvo'), findsOneWidget);
    expect(find.text('Tu información está a salvo y sincronizada.'),
        findsOneWidget);
    expect(find.text('Sincronizando…'), findsNothing);
  });

  testWidgets('sin conexión: copy local-first, no de error', (tester) async {
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      const Stream<HomeState>.empty(),
      initialState: stateWith(HomeSyncStatus.offline),
    );

    await pumpSheet(tester, cubit);

    expect(find.text('Sin conexión'), findsOneWidget);
    expect(
      find.text(
        'Tus datos están guardados en este teléfono. '
        'Se sincronizarán en cuanto vuelva la conexión.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('el botón "Entendido" cierra el sheet', (tester) async {
    final cubit = MockHomeCubit();
    whenListen(
      cubit,
      const Stream<HomeState>.empty(),
      initialState: stateWith(HomeSyncStatus.synced),
    );

    await tester.pumpWidget(
      MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (context) => Scaffold(
            body: Center(
              child: ElevatedButton(
                onPressed: () => SyncStatusSheet.show(context, cubit),
                child: const Text('abrir'),
              ),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('abrir'));
    await tester.pumpAndSettle();
    expect(find.text('Todo a salvo'), findsOneWidget);

    await tester.tap(find.text('Entendido'));
    await tester.pumpAndSettle();
    expect(find.text('Todo a salvo'), findsNothing);
  });
}
