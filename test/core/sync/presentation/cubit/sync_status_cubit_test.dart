import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_state.dart';
import 'package:billetudo/core/sync/domain/entities/sync_status_snapshot.dart';
import 'package:billetudo/core/sync/domain/usecases/retry_all_quarantined_operations.dart';
import 'package:billetudo/core/sync/domain/usecases/retry_quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_quarantined_operations.dart';
import 'package:billetudo/core/sync/domain/usecases/watch_sync_status_details.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_cubit.dart';
import 'package:billetudo/core/sync/presentation/cubit/sync_status_state.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockWatchSyncStatusDetails extends Mock
    implements WatchSyncStatusDetails {}

class MockWatchQuarantinedOperations extends Mock
    implements WatchQuarantinedOperations {}

class MockRetryAll extends Mock implements RetryAllQuarantinedOperations {}

class MockRetryOne extends Mock implements RetryQuarantinedOperation {}

/// HU-08. Lo que este cubit no puede hacer nunca, porque es el modo de falla
/// exacto del incidente #22: **repintar optimistamente**. Un reintento solo
/// mueve `isRetrying`; el hero y la lista solo cambian cuando el stream (o
/// sea, el repositorio) lo confirma.
void main() {
  late MockWatchSyncStatusDetails watchStatus;
  late MockWatchQuarantinedOperations watchQuarantine;
  late MockRetryAll retryAll;
  late MockRetryOne retryOne;
  late StreamController<SyncStatusSnapshot> statusController;
  late StreamController<List<QuarantinedOperation>> quarantineController;

  final quarantinedAt = DateTime(2026, 7, 25, 9);

  QuarantinedOperation operation(String id, {DateTime? at, String? name}) =>
      QuarantinedOperation(
        id: id,
        operation: SyncOperation(
          tableName: 'transactions',
          rowId: 'row-$id',
          type: SyncOperationType.put,
          payload: name == null ? null : {'name': name},
        ),
        kind: SyncFailureKind.brokenSchema,
        errorCode: 'PGRST204',
        errorMessage: 'column does not exist',
        quarantinedAt: at ?? quarantinedAt,
        updatedAt: at ?? quarantinedAt,
        attempts: 2,
      );

  const stalledSnapshot = SyncStatusSnapshot(
    state: SyncState.stalled,
    quarantinedCount: 2,
  );

  SyncStatusCubit build() => SyncStatusCubit(
        watchStatus,
        watchQuarantine,
        retryAll,
        retryOne,
      );

  /// Arranca el cubit y deja que las dos suscripciones queden montadas.
  Future<SyncStatusCubit> started() async {
    final cubit = build();
    await cubit.start();
    addTearDown(cubit.close);
    return cubit;
  }

  Future<void> settle() => Future<void>.delayed(Duration.zero);

  setUp(() {
    watchStatus = MockWatchSyncStatusDetails();
    watchQuarantine = MockWatchQuarantinedOperations();
    retryAll = MockRetryAll();
    retryOne = MockRetryOne();
    statusController = StreamController<SyncStatusSnapshot>.broadcast();
    quarantineController =
        StreamController<List<QuarantinedOperation>>.broadcast();
    when(watchStatus.call).thenAnswer((_) => statusController.stream);
    when(watchQuarantine.call).thenAnswer((_) => quarantineController.stream);
    addTearDown(statusController.close);
    addTearDown(quarantineController.close);
  });

  group('carga: el esqueleto solo cubre la latencia de SQLite', () {
    test('el estado inicial es loading', () async {
      final cubit = build();
      addTearDown(cubit.close);

      expect(cubit.state.status, SyncStatusStatus.loading);
      expect(cubit.state.isLoading, isTrue);
    });

    test('con una sola de las dos lecturas respondida sigue en loading',
        () async {
      final cubit = await started();

      statusController.add(stalledSnapshot);
      await settle();

      expect(cubit.state.isLoading, isTrue);
      expect(cubit.state.snapshot, stalledSnapshot);
    });

    test('pasa a ready cuando ambas lecturas respondieron', () async {
      final cubit = await started();

      statusController.add(stalledSnapshot);
      quarantineController.add([operation('q-1')]);
      await settle();

      expect(cubit.state.status, SyncStatusStatus.ready);
    });

    test(
        'una cuarentena ilegible no deja la pantalla en el esqueleto '
        'para siempre', () async {
      final cubit = await started();

      statusController.add(stalledSnapshot);
      quarantineController.addError(const DatabaseFailure('unreadable'));
      await settle();

      expect(cubit.state.status, SyncStatusStatus.ready);
      // El resto del estado sigue siendo verdad y vale la pena mostrarlo.
      expect(cubit.state.snapshot, stalledSnapshot);
      expect(cubit.state.pending, isEmpty);
    });

    test('una cuarentena vacía también resuelve la carga', () async {
      final cubit = await started();

      statusController.add(
        const SyncStatusSnapshot(state: SyncState.synced, quarantinedCount: 0),
      );
      quarantineController.add(const []);
      await settle();

      expect(cubit.state.status, SyncStatusStatus.ready);
      expect(cubit.state.hasPending, isFalse);
    });
  });

  group('la lista es una muestra ordenada: la más vieja primero', () {
    test(
        'ordena por fecha de cuarentena ascendente, no por el orden de la '
        'fuente', () async {
      final cubit = await started();

      quarantineController.add([
        operation('nuevo', at: DateTime(2026, 7, 27)),
        operation('viejo', at: DateTime(2026, 7, 20)),
        operation('medio', at: DateTime(2026, 7, 25)),
      ]);
      await settle();

      expect(
        cubit.state.pending.map((change) => change.id).toList(),
        ['viejo', 'medio', 'nuevo'],
      );
    });

    test('89 cambios entran completos al estado: recortar es cosa de la UI',
        () async {
      final cubit = await started();

      quarantineController.add([
        for (var i = 0; i < 89; i++)
          operation('q-$i', at: DateTime(2026, 7, 20).add(Duration(hours: i))),
      ]);
      await settle();

      expect(cubit.state.pendingCount, 89);
      expect(cubit.state.hasPending, isTrue);
      expect(cubit.state.pending.first.id, 'q-0');
    });
  });

  group('NADA se repinta optimistamente (incidente #22)', () {
    test(
        'mientras el reintento corre, el hero y la lista siguen diciendo que '
        'los cambios están en el teléfono', () async {
      final cubit = await started();
      statusController.add(stalledSnapshot);
      quarantineController.add([operation('q-1'), operation('q-2')]);
      await settle();

      final completer = Completer<Result<int>>();
      when(retryAll.call).thenAnswer((_) => completer.future);

      final pendingRetry = cubit.retryAll();
      await settle();

      expect(cubit.state.isRetrying, isTrue);
      // Lo único que cambió es el CTA. La evidencia sigue intacta.
      expect(cubit.state.pendingCount, 2);
      expect(cubit.state.snapshot, stalledSnapshot);
      expect(cubit.state.retryOutcome, SyncRetryOutcome.none);

      completer.complete(const Right(2));
      await pendingRetry;
    });

    test('un reintento exitoso NO vacía la lista: solo el stream puede',
        () async {
      final cubit = await started();
      statusController.add(stalledSnapshot);
      quarantineController.add([operation('q-1'), operation('q-2')]);
      await settle();
      when(retryAll.call).thenAnswer((_) async => const Right(2));

      await cubit.retryAll();

      expect(cubit.state.retryOutcome, SyncRetryOutcome.allUploaded);
      // El repositorio dijo "subí 2", pero la lista solo se vacía cuando la
      // cuarentena lo confirma con una emisión.
      expect(cubit.state.pendingCount, 2);

      quarantineController.add(const []);
      await settle();
      expect(cubit.state.pendingCount, 0);
    });

    test('las filas desaparecen una a una, según confirma el stream', () async {
      final cubit = await started();
      quarantineController.add([operation('q-1'), operation('q-2')]);
      await settle();

      quarantineController.add([operation('q-2')]);
      await settle();
      expect(cubit.state.pending.map((c) => c.id), ['q-2']);

      quarantineController.add(const []);
      await settle();
      expect(cubit.state.pending, isEmpty);
    });

    test('el snapshot del hero solo cambia cuando el motor lo emite', () async {
      final cubit = await started();
      statusController.add(stalledSnapshot);
      quarantineController.add([operation('q-1')]);
      await settle();
      when(retryAll.call).thenAnswer((_) async => const Right(1));

      await cubit.retryAll();
      expect(cubit.state.snapshot.state, SyncState.stalled);

      statusController.add(
        const SyncStatusSnapshot(state: SyncState.synced, quarantinedCount: 0),
      );
      await settle();
      expect(cubit.state.snapshot.state, SyncState.synced);
    });
  });

  group('retryAll: el resultado se reporta, no se pinta', () {
    test('todo subido: allUploaded con el conteo real', () async {
      final cubit = await started();
      quarantineController.add([operation('q-1'), operation('q-2')]);
      await settle();
      when(retryAll.call).thenAnswer((_) async => const Right(2));

      await cubit.retryAll();

      expect(cubit.state.isRetrying, isFalse);
      expect(cubit.state.retryOutcome, SyncRetryOutcome.allUploaded);
      expect(cubit.state.retriedCount, 2);
    });

    test('subió menos de los esperados: partial (noticia honesta)', () async {
      final cubit = await started();
      quarantineController.add([operation('q-1'), operation('q-2')]);
      await settle();
      when(retryAll.call).thenAnswer((_) async => const Right(1));

      await cubit.retryAll();

      expect(cubit.state.retryOutcome, SyncRetryOutcome.partial);
      expect(cubit.state.retriedCount, 1);
    });

    test('un fallo del repositorio es partial, nunca "todo al día"', () async {
      final cubit = await started();
      quarantineController.add([operation('q-1')]);
      await settle();
      when(retryAll.call)
          .thenAnswer((_) async => const Left(NetworkFailure('sin red')));

      await cubit.retryAll();

      expect(cubit.state.retryOutcome, SyncRetryOutcome.partial);
      expect(cubit.state.retriedCount, 0);
      expect(cubit.state.isRetrying, isFalse);
    });

    test('un segundo toque mientras corre el primero se ignora', () async {
      final cubit = await started();
      quarantineController.add([operation('q-1')]);
      await settle();
      final completer = Completer<Result<int>>();
      when(retryAll.call).thenAnswer((_) => completer.future);

      final first = cubit.retryAll();
      await settle();
      await cubit.retryAll();

      verify(retryAll.call).called(1);
      completer.complete(const Right(1));
      await first;
    });

    test('un reintento nuevo limpia el resultado del anterior antes de correr',
        () async {
      final cubit = await started();
      quarantineController.add([operation('q-1')]);
      await settle();
      when(retryAll.call).thenAnswer((_) async => const Right(1));
      await cubit.retryAll();
      expect(cubit.state.retryOutcome, SyncRetryOutcome.allUploaded);

      final completer = Completer<Result<int>>();
      when(retryAll.call).thenAnswer((_) => completer.future);
      final second = cubit.retryAll();
      await settle();

      expect(cubit.state.retryOutcome, SyncRetryOutcome.none);
      expect(cubit.state.retriedCount, 0);
      completer.complete(const Right(1));
      await second;
    });
  });

  group('retryOne: el reintento de una sola fila', () {
    setUp(() {
      when(() => retryOne(any()))
          .thenAnswer((_) async => const Right<Failure, Unit>(unit));
    });

    test('éxito: allUploaded con 1, dirigido al id del registro de cuarentena',
        () async {
      final cubit = await started();
      quarantineController.add([operation('q-7')]);
      await settle();

      await cubit.retryOne('q-7');

      verify(() => retryOne('q-7')).called(1);
      expect(cubit.state.retryOutcome, SyncRetryOutcome.allUploaded);
      expect(cubit.state.retriedCount, 1);
      expect(cubit.state.isRetrying, isFalse);
    });

    test('fallo: partial y la fila sigue en la lista', () async {
      final cubit = await started();
      quarantineController.add([operation('q-7')]);
      await settle();
      when(() => retryOne(any()))
          .thenAnswer((_) async => const Left(NetworkFailure('sin red')));

      await cubit.retryOne('q-7');

      expect(cubit.state.retryOutcome, SyncRetryOutcome.partial);
      expect(cubit.state.retriedCount, 0);
      expect(cubit.state.pendingCount, 1);
    });

    test('no arranca si ya hay un reintento en curso', () async {
      final cubit = await started();
      final completer = Completer<Result<int>>();
      when(retryAll.call).thenAnswer((_) => completer.future);

      final all = cubit.retryAll();
      await settle();
      await cubit.retryOne('q-7');

      verifyNever(() => retryOne(any()));
      completer.complete(const Right(0));
      await all;
    });
  });

  group('acknowledgeRetryOutcome', () {
    test('limpia el resultado para que el snackbar se muestre una sola vez',
        () async {
      final cubit = await started();
      quarantineController.add([operation('q-1')]);
      await settle();
      when(retryAll.call).thenAnswer((_) async => const Right(1));
      await cubit.retryAll();

      cubit.acknowledgeRetryOutcome();

      expect(cubit.state.retryOutcome, SyncRetryOutcome.none);
    });

    test('sin resultado pendiente no emite un estado nuevo', () async {
      final cubit = await started();
      quarantineController.add(const []);
      await settle();
      final before = cubit.state;

      cubit.acknowledgeRetryOutcome();

      expect(cubit.state, same(before));
    });
  });

  group('ciclo de vida', () {
    test('cerrar el cubit corta las dos suscripciones', () async {
      final cubit = build();
      await cubit.start();
      await cubit.close();

      // Emitir después de cerrar no debe lanzar ni cambiar nada.
      statusController.add(stalledSnapshot);
      quarantineController.add([operation('q-1')]);
      await settle();

      expect(cubit.state.status, SyncStatusStatus.loading);
      expect(cubit.state.pending, isEmpty);
    });

    test('llamar start() dos veces no duplica las suscripciones', () async {
      final cubit = await started();
      await cubit.start();

      quarantineController.add([operation('q-1'), operation('q-2')]);
      await settle();

      expect(cubit.state.pendingCount, 2);
    });
  });
}
