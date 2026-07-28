import 'dart:async';

import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:billetudo/core/sync/presentation/models/pending_sync_change.dart';
import 'package:billetudo/core/sync/presentation/pages/sync_status_page.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_pending_row.dart';
import 'package:billetudo/core/sync/presentation/widgets/sync_skeleton_row.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../pump_sync.dart';

class MockSyncStatusCubit extends MockCubit<SyncStatusState>
    implements SyncStatusCubit {}

/// "Estado de sincronización" (HU-08): la pantalla que existe para que
/// "sincronizando" y "sincronizando desde hace tres días" no puedan volver a
/// verse igual.
void main() {
  final now = DateTime.now();

  PendingSyncChange change(int index) => PendingSyncChange.fromOperation(
        QuarantinedOperation(
          id: 'q-$index',
          operation: SyncOperation(
            tableName: 'transactions',
            rowId: 'row-$index',
            type: SyncOperationType.put,
            payload: {'note': 'Cambio $index'},
          ),
          kind: SyncFailureKind.brokenSchema,
          errorCode: 'PGRST204',
          errorMessage: 'column transactions.foo does not exist',
          quarantinedAt: now.subtract(Duration(days: 3, minutes: index)),
          updatedAt: now,
          attempts: 4,
        ),
      );

  SyncStatusState state({
    SyncStatusStatus status = SyncStatusStatus.ready,
    SyncState syncState = SyncState.synced,
    Duration? syncedAgo = const Duration(minutes: 5),
    bool hasSyncedEver = true,
    int pending = 0,
    bool isRetrying = false,
  }) =>
      SyncStatusState(
        status: status,
        snapshot: SyncStatusSnapshot(
          state: syncState,
          quarantinedCount: pending,
          lastSyncedAt: syncedAgo == null ? null : now.subtract(syncedAgo),
          hasSyncedEver: hasSyncedEver,
        ),
        pending: [for (var i = 0; i < pending; i++) change(i)],
        isRetrying: isRetrying,
      );

  late MockSyncStatusCubit cubit;

  setUp(() {
    cubit = MockSyncStatusCubit();
    when(cubit.retryAll).thenAnswer((_) async {});
    when(cubit.acknowledgeRetryOutcome).thenReturn(null);
  });

  /// A tall viewport so the whole page (hero + copy row + list + diagnostics)
  /// is laid out: a `ListView` does not build what falls outside its cache.
  Future<void> pumpPage(
    WidgetTester tester, {
    required SyncStatusState initial,
    bool isSignedIn = true,
    Stream<SyncStatusState>? stream,
    VoidCallback? onSaveCopy,
    VoidCallback? onSignIn,
    VoidCallback? onSeeAllPending,
  }) async {
    whenListen(
      cubit,
      stream ?? const Stream<SyncStatusState>.empty(),
      initialState: initial,
    );
    tester.view.physicalSize = const Size(390, 1600) * 3;
    tester.view.devicePixelRatio = 3;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });
    await tester.pumpSyncWidget(
      BlocProvider<SyncStatusCubit>.value(
        value: cubit,
        child: SyncStatusPage(
          isSignedIn: isSignedIn,
          onSaveCopy: onSaveCopy ?? () {},
          onSignIn: onSignIn ?? () {},
          onSeeAllPending: onSeeAllPending ?? () {},
          onOpenComingSoon: (_) {},
        ),
      ),
      wrapInScaffold: false,
    );
  }

  group('carga', () {
    testWidgets('muestra el esqueleto, no un hero a medias', (tester) async {
      await pumpPage(
        tester,
        initial: state(status: SyncStatusStatus.loading),
      );

      expect(find.byType(SyncSkeletonRow), findsNWidgets(3));
      expect(find.text('Todo está sincronizado'), findsNothing);
      expect(find.text('Sincronizar ahora'), findsNothing);
    });
  });

  group('los cinco estados', () {
    testWidgets(
        'atención: el hero cuenta cuántos cambios y el CTA dice '
        '"Reintentar ahora"', (tester) async {
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 2),
      );

      expect(
          find.text('2 cambios están solo en este teléfono'), findsOneWidget);
      expect(find.text('Reintentar ahora'), findsOneWidget);
      expect(find.text('Sincronizar ahora'), findsNothing);
      expect(find.byType(SyncPendingRow), findsNWidgets(2));
      expect(find.text('Guardar una copia'), findsOneWidget);
    });

    testWidgets(
        'todo bien: el CTA dice "Sincronizar ahora", nunca '
        '"Reintentar ahora"', (tester) async {
      await pumpPage(tester, initial: state());

      expect(find.text('Todo está sincronizado'), findsOneWidget);
      expect(find.text('Sincronizar ahora'), findsOneWidget);
      expect(find.text('Reintentar ahora'), findsNothing);
      expect(find.byType(SyncPendingRow), findsNothing);
    });

    testWidgets('nunca sincronizó: informativo, sin nada de ámbar en el texto',
        (tester) async {
      await pumpPage(
        tester,
        initial: state(syncedAgo: null, hasSyncedEver: false),
      );

      expect(find.text('Aún no se ha sincronizado'), findsWidgets);
      expect(find.text('Acabas de iniciar sesión'), findsOneWidget);
    });

    testWidgets('sin conexión: copy local-first y CTA inerte', (tester) async {
      await pumpPage(tester, initial: state(syncState: SyncState.offline));

      expect(find.text('Sin conexión'), findsOneWidget);
      expect(
        find.text('Se reintentará solo en cuanto haya conexión.'),
        findsOneWidget,
      );

      await tester.tap(find.text('Sincronizar ahora'));
      await tester.pump();
      verifyNever(cubit.retryAll);
    });

    testWidgets('sin sesión: invita a iniciar sesión y ofrece la copia local',
        (tester) async {
      var signIn = 0;
      await pumpPage(
        tester,
        initial: state(),
        isSignedIn: false,
        onSignIn: () => signIn++,
      );

      expect(find.text('No hay sesión iniciada'), findsOneWidget);
      expect(find.text('Mientras tanto'), findsOneWidget);
      expect(find.text('Guardar una copia'), findsOneWidget);

      await tester.tap(find.text('Iniciar sesión'));
      expect(signIn, 1);
    });
  });

  group('la fila de tiempo se muestra siempre (la lección del incidente)', () {
    testWidgets(
        'todo bien también la muestra: sin ella no hay con qué '
        'comparar', (tester) async {
      await pumpPage(tester, initial: state());

      expect(
        find.text('Última sincronización: hace 5 minutos'),
        findsOneWidget,
      );
    });

    testWidgets('atención: la muestra en fraseo relativo, no una fecha',
        (tester) async {
      await pumpPage(
        tester,
        initial: state(
          syncState: SyncState.stalled,
          pending: 2,
          syncedAgo: const Duration(days: 3),
        ),
      );

      expect(find.text('Última sincronización: hace 3 días'), findsWidgets);
      expect(find.textContaining('2026-'), findsNothing);
    });

    testWidgets('sin sesión: dice que no hay sincronización activa',
        (tester) async {
      await pumpPage(tester, initial: state(), isSignedIn: false);

      expect(find.text('Sin sincronización activa'), findsOneWidget);
    });
  });

  group('NADA se repinta optimistamente al reintentar (incidente #22)', () {
    testWidgets(
        'con el reintento en curso el hero sigue diciendo que los '
        'cambios están en el teléfono y la lista sigue completa',
        (tester) async {
      final controller = StreamController<SyncStatusState>();
      addTearDown(controller.close);
      final attention = state(syncState: SyncState.stalled, pending: 3);
      await pumpPage(tester, initial: attention, stream: controller.stream);

      controller.add(
        state(syncState: SyncState.stalled, pending: 3, isRetrying: true),
      );
      await tester.pump();

      expect(
          find.text('3 cambios están solo en este teléfono'), findsOneWidget);
      expect(find.byType(SyncPendingRow), findsNWidgets(3));
      expect(find.text('Todo está sincronizado'), findsNothing);
    });

    testWidgets(
        'el CTA en curso cambia rótulo (dos señales, ninguna '
        'cromática) y queda inerte', (tester) async {
      await pumpPage(
        tester,
        initial: state(
          syncState: SyncState.stalled,
          pending: 3,
          isRetrying: true,
        ),
      );

      expect(find.text('Sincronizando…'), findsOneWidget);
      expect(find.text('Reintentar ahora'), findsNothing);

      await tester.tap(find.text('Sincronizando…'));
      await tester.pump();
      verifyNever(cubit.retryAll);
    });

    testWidgets('el CTA en curso no se oculta: el layout no se mueve',
        (tester) async {
      final controller = StreamController<SyncStatusState>();
      addTearDown(controller.close);
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 3),
        stream: controller.stream,
      );
      final restingBottom =
          tester.getRect(find.text('Reintentar ahora')).bottom;

      controller.add(
        state(syncState: SyncState.stalled, pending: 3, isRetrying: true),
      );
      await tester.pump();

      expect(
        tester.getRect(find.text('Sincronizando…')).bottom,
        closeTo(restingBottom, 1),
      );
    });

    testWidgets('tocar el CTA en reposo pide el reintento al cubit',
        (tester) async {
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 2),
      );

      await tester.tap(find.text('Reintentar ahora'));
      await tester.pump();

      verify(cubit.retryAll).called(1);
    });
  });

  group(
      'resultado del reintento: se cuenta con snackbar, no cambiando el '
      'hero', () {
    testWidgets('todo al día levanta el snackbar con el conteo real',
        (tester) async {
      final controller = StreamController<SyncStatusState>();
      addTearDown(controller.close);
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 2),
        stream: controller.stream,
      );

      controller.add(
        SyncStatusState(
          status: SyncStatusStatus.ready,
          snapshot: const SyncStatusSnapshot(
            state: SyncState.stalled,
            quarantinedCount: 2,
          ),
          pending: [change(0), change(1)],
          retryOutcome: SyncRetryOutcome.allUploaded,
          retriedCount: 2,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(find.text('Todo al día · 2 cambios subidos'), findsOneWidget);
      verify(cubit.acknowledgeRetryOutcome).called(1);
    });

    testWidgets('parcial: nunca se dice que se perdió nada', (tester) async {
      final controller = StreamController<SyncStatusState>();
      addTearDown(controller.close);
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 2),
        stream: controller.stream,
      );

      controller.add(
        SyncStatusState(
          status: SyncStatusStatus.ready,
          snapshot: const SyncStatusSnapshot(
            state: SyncState.stalled,
            quarantinedCount: 2,
          ),
          pending: [change(0), change(1)],
          retryOutcome: SyncRetryOutcome.partial,
        ),
      );
      await tester.pump();
      await tester.pump();

      expect(
        find.text('No se pudo subir todo. Sigue guardado en este teléfono.'),
        findsOneWidget,
      );
      expect(find.text('Ver detalle'), findsOneWidget);
    });
  });

  group('la lista es una muestra: 3 filas y un enlace contado', () {
    testWidgets('con 89 pendientes muestra 3 filas y "Ver los 89"',
        (tester) async {
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 89),
      );

      expect(find.byType(SyncPendingRow), findsNWidgets(3));
      expect(find.text('Ver los 89'), findsOneWidget);
      expect(
          find.text('89 cambios están solo en este teléfono'), findsOneWidget);
    });

    testWidgets('el enlace navega a la lista completa', (tester) async {
      var seeAll = 0;
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 89),
        onSeeAllPending: () => seeAll++,
      );

      await tester.tap(find.text('Ver los 89'));
      expect(seeAll, 1);
    });
  });

  group(
      '"Guardar una copia" es la única protección real mientras falla la '
      'nube', () {
    testWidgets('en atención está por encima de la lista', (tester) async {
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 89),
      );

      expect(
        tester.getRect(find.text('Guardar una copia')).top,
        lessThan(tester.getRect(find.byType(SyncPendingRow).first).top),
      );
    });

    testWidgets('navega a Importar y exportar, no abre hoja propia',
        (tester) async {
      var saveCopy = 0;
      await pumpPage(
        tester,
        initial: state(syncState: SyncState.stalled, pending: 2),
        onSaveCopy: () => saveCopy++,
      );

      await tester.tap(find.text('Guardar una copia'));
      await tester.pump();

      expect(saveCopy, 1);
      expect(find.byType(BottomSheet), findsNothing);
    });
  });

  group('no existe "Descartar" en ninguna superficie', () {
    for (final (name, value) in [
      ('atención', () => state(syncState: SyncState.stalled, pending: 3)),
      ('todo bien', state),
      ('sin conexión', () => state(syncState: SyncState.offline)),
      (
        'nunca sincronizó',
        () => state(syncedAgo: null, hasSyncedEver: false),
      ),
    ]) {
      testWidgets('$name: ni descartar, ni eliminar, ni borrar',
          (tester) async {
        await pumpPage(tester, initial: value());

        expect(find.textContaining('Descartar'), findsNothing);
        expect(find.textContaining('Eliminar'), findsNothing);
        expect(find.textContaining('Borrar'), findsNothing);
      });
    }

    testWidgets('sin sesión: tampoco', (tester) async {
      await pumpPage(tester, initial: state(), isSignedIn: false);

      expect(find.textContaining('Descartar'), findsNothing);
      expect(find.textContaining('Eliminar'), findsNothing);
    });
  });
}
