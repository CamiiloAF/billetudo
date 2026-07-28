import 'dart:io';

import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/data/datasources/json_sync_quarantine_store.dart';
import 'package:billetudo/core/sync/data/datasources/sync_operation_uploader.dart';
import 'package:billetudo/core/sync/data/datasources/sync_quarantine_store.dart';
import 'package:billetudo/core/sync/data/repositories/sync_quarantine_repository_impl.dart';
import 'package:billetudo/core/sync/domain/entities/quarantined_operation.dart';
import 'package:billetudo/core/sync/domain/entities/sync_failure_kind.dart';
import 'package:billetudo/core/sync/domain/entities/sync_log_entry.dart';
import 'package:billetudo/core/sync/domain/entities/sync_operation.dart';
import 'package:billetudo/core/sync/domain/repositories/sync_log_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../support/temp_sync_storage_directory.dart';

class MockSyncOperationUploader extends Mock implements SyncOperationUploader {}

class MockSyncLogRepository extends Mock implements SyncLogRepository {}

class MockCrashReporter extends Mock implements CrashReporter {}

class MockSyncQuarantineStore extends Mock implements SyncQuarantineStore {}

class FakeSyncOperation extends Fake implements SyncOperation {}

class FakeQuarantinedOperation extends Fake implements QuarantinedOperation {}

/// Driven against the real JSON store on a temp directory (the store is a
/// file, not a service — mocking it would only test the mock). The uploader is
/// mocked because it is the network edge.
void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(FakeSyncOperation());
    registerFallbackValue(FakeQuarantinedOperation());
    registerFallbackValue(SyncLogEvent.quarantined);
    registerFallbackValue(SyncLogLevel.info);
  });

  late TempSyncStorageDirectory storage;
  late JsonSyncQuarantineStore store;
  late MockSyncOperationUploader uploader;
  late MockSyncLogRepository log;
  late MockCrashReporter crash;
  late SyncQuarantineRepositoryImpl repository;

  setUp(() {
    storage = TempSyncStorageDirectory.create('quarantine_repo');
    store = JsonSyncQuarantineStore(storage);
    uploader = MockSyncOperationUploader();
    log = MockSyncLogRepository();
    crash = MockCrashReporter();
    repository = SyncQuarantineRepositoryImpl(store, uploader, log, crash);

    when(() => uploader.upload(any())).thenAnswer((_) async {});
    when(
      () => log.record(
        event: any(named: 'event'),
        message: any(named: 'message'),
        level: any(named: 'level'),
        code: any(named: 'code'),
        tableName: any(named: 'tableName'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => crash.recordError(
        any(),
        any(),
        context: any(named: 'context'),
        fatal: any(named: 'fatal'),
      ),
    ).thenAnswer((_) async {});
  });

  tearDown(() => storage.dispose());

  SyncOperation operation({
    String tableName = 'debts',
    String rowId = 'd-1',
    SyncOperationType type = SyncOperationType.put,
    Map<String, dynamic>? payload,
  }) {
    return SyncOperation(
      tableName: tableName,
      rowId: rowId,
      type: type,
      payload: payload ?? <String, dynamic>{'amount_minor': 1234},
    );
  }

  Future<void> record(
    SyncOperation op, {
    SyncFailureKind kind = SyncFailureKind.brokenSchema,
    String? errorCode = 'PGRST204',
    String errorMessage = 'boom',
  }) =>
      repository.record(
        operation: op,
        kind: kind,
        errorMessage: errorMessage,
        errorCode: errorCode,
      );

  group('record', () {
    test('guarda la op con id UUID, attempts en 1 y sus marcas de tiempo',
        () async {
      final before = DateTime.now();

      await record(operation());

      final stored = (await store.readAll()).single;
      expect(
        stored.id,
        matches(
          RegExp(
            r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-'
            r'[0-9a-f]{12}$',
          ),
        ),
      );
      expect(stored.attempts, 1);
      expect(stored.kind, SyncFailureKind.brokenSchema);
      expect(stored.errorCode, 'PGRST204');
      expect(stored.errorMessage, 'boom');
      expect(stored.quarantinedAt.isBefore(before), isFalse);
      expect(stored.updatedAt, stored.quarantinedAt);
      // Dinero en centavos, entero.
      expect(stored.operation.payload!['amount_minor'], 1234);
      expect(stored.operation.payload!['amount_minor'], isA<int>());
    });

    test(
        'DEDUPE: la misma tabla+fila+tipo no hace crecer la cuarentena, solo '
        'sube attempts y actualiza updatedAt', () async {
      await record(operation());
      final first = (await store.readAll()).single;
      await Future<void>.delayed(const Duration(milliseconds: 5));

      await record(
        operation(payload: <String, dynamic>{'amount_minor': 999}),
        kind: SyncFailureKind.invalidData,
        errorCode: '23503',
        errorMessage: 'fk',
      );
      await record(operation());

      final stored = await store.readAll();
      expect(stored, hasLength(1));
      expect(stored.single.attempts, 3);
      // El id y la fecha original se conservan: es el mismo problema.
      expect(stored.single.id, first.id);
      expect(stored.single.quarantinedAt, first.quarantinedAt);
      expect(stored.single.updatedAt.isAfter(first.updatedAt), isTrue);
      // Y se conserva el último error y el último payload.
      expect(stored.single.operation.payload!['amount_minor'], 1234);
      expect(stored.single.errorCode, 'PGRST204');
    });

    test('la misma fila con otro tipo de escritura sí es otro registro',
        () async {
      await record(operation());
      await record(operation(type: SyncOperationType.patch));
      await record(operation(type: SyncOperationType.delete));

      expect(await store.readAll(), hasLength(3));
    });

    test('la misma fila en otra tabla es otro registro', () async {
      await record(operation());
      await record(operation(tableName: 'transactions'));

      expect(await store.readAll(), hasLength(2));
    });

    test('otra fila de la misma tabla es otro registro', () async {
      await record(operation());
      await record(operation(rowId: 'd-2'));

      expect(await store.readAll(), hasLength(2));
    });

    test(
        'si el almacenamiento falla NO relanza (relanzar volvería a bloquear '
        'la cola) y lo reporta como fatal', () async {
      final broken = MockSyncQuarantineStore();
      when(broken.readAll).thenThrow(const FileSystemException('nope'));
      final resilient =
          SyncQuarantineRepositoryImpl(broken, uploader, log, crash);

      await expectLater(
        resilient.record(
          operation: operation(),
          kind: SyncFailureKind.brokenSchema,
          errorMessage: 'boom',
          errorCode: 'PGRST204',
        ),
        completes,
      );

      verify(
        () => crash.recordError(
          any(that: isA<FileSystemException>()),
          any(),
          context: any(named: 'context', that: contains('quarantine')),
          fatal: true,
        ),
      ).called(1);
    });
  });

  group('retry', () {
    test('si tiene éxito, la op sale de la cuarentena y queda registrada',
        () async {
      await record(operation());
      final target = (await store.readAll()).single;

      final result = await repository.retry(target.id);

      expect(result.isRight(), isTrue);
      expect(await store.readAll(), isEmpty);
      final replayed = verify(() => uploader.upload(captureAny()))
          .captured
          .single as SyncOperation;
      expect(replayed.tableName, 'debts');
      expect(replayed.rowId, 'd-1');
      expect(replayed.payload!['amount_minor'], 1234);
      verify(
        () => log.record(
          event: SyncLogEvent.quarantineRetry,
          message: any(named: 'message'),
          tableName: 'debts',
        ),
      ).called(1);
    });

    test(
        'si vuelve a fallar, incrementa attempts, actualiza el error y SIGUE '
        'en cuarentena', () async {
      await record(operation());
      final target = (await store.readAll()).single;
      when(() => uploader.upload(any())).thenThrow(
        const PostgrestException(message: 'still missing', code: 'PGRST204'),
      );

      final result = await repository.retry(target.id);

      expect(result.isLeft(), isTrue);
      final stored = (await store.readAll()).single;
      expect(stored.id, target.id);
      expect(stored.attempts, 2);
      expect(stored.errorCode, 'PGRST204');
      expect(stored.errorMessage, contains('still missing'));
      expect(stored.updatedAt.isBefore(target.updatedAt), isFalse);
      expect(stored.quarantinedAt, target.quarantinedAt);
    });

    test(
        'un reintento que falla por red NO reescribe el veredicto permanente '
        'original', () async {
      await record(operation());
      final target = (await store.readAll()).single;
      when(() => uploader.upload(any()))
          .thenThrow(const SocketException('offline'));

      await repository.retry(target.id);

      final stored = (await store.readAll()).single;
      expect(stored.kind, SyncFailureKind.brokenSchema);
      expect(stored.attempts, 2);
    });

    test(
        'un reintento manual de una op cuarentenada por el watchdog conserva '
        'stuck si vuelve a fallar por red', () async {
      // `stuck` no es un veredicto sobre la escritura: dice "nadie clasificó
      // este fallo y estaba bloqueando la cola". Si el reintento falla porque
      // el usuario está sin red, esa evidencia no puede degradarse a
      // "transitorio" — se perdería la única pista de que hubo un atasco.
      await record(operation(),
          kind: SyncFailureKind.stuck, errorCode: 'WEIRD-CODE');
      final target = (await store.readAll()).single;
      when(() => uploader.upload(any()))
          .thenThrow(const SocketException('offline'));

      await repository.retry(target.id);

      final stored = (await store.readAll()).single;
      expect(stored.kind, SyncFailureKind.stuck);
      expect(stored.attempts, 2);
    });

    test(
        'un reintento de una op stuck que ahora falla con un código conocido '
        'sí se reclasifica', () async {
      await record(operation(),
          kind: SyncFailureKind.stuck, errorCode: 'WEIRD');
      final target = (await store.readAll()).single;
      when(() => uploader.upload(any())).thenThrow(
        const PostgrestException(message: 'no column', code: 'PGRST204'),
      );

      await repository.retry(target.id);

      final stored = (await store.readAll()).single;
      expect(stored.kind, SyncFailureKind.brokenSchema);
      expect(stored.errorCode, 'PGRST204');
    });

    test(
        'un reintento de una op stuck que ahora funciona la saca de la '
        'cuarentena', () async {
      await record(operation(),
          kind: SyncFailureKind.stuck, errorCode: 'WEIRD');
      final target = (await store.readAll()).single;

      final result = await repository.retry(target.id);

      expect(result.isRight(), isTrue);
      expect(await store.readAll(), isEmpty);
    });

    test('un reintento que falla con otro código permanente cambia el kind',
        () async {
      await record(operation());
      final target = (await store.readAll()).single;
      when(() => uploader.upload(any()))
          .thenThrow(const PostgrestException(message: 'fk', code: '23503'));

      await repository.retry(target.id);

      final stored = (await store.readAll()).single;
      expect(stored.kind, SyncFailureKind.invalidData);
      expect(stored.errorCode, '23503');
    });

    test('un id inexistente devuelve NotFoundFailure sin tocar la red',
        () async {
      final result = await repository.retry('no-existe');

      expect(result.isLeft(), isTrue);
      result.fold(
        (failure) => expect(failure, isA<NotFoundFailure>()),
        (_) => fail('se esperaba un Left'),
      );
      verifyNever(() => uploader.upload(any()));
    });
  });

  group('retryAll', () {
    test('devuelve cuántas se recuperaron y deja las que siguen fallando',
        () async {
      await record(operation(rowId: 'd-1'));
      await record(operation(tableName: 'transactions', rowId: 'tx-1'));
      when(() => uploader.upload(any())).thenAnswer((invocation) async {
        final op = invocation.positionalArguments.single as SyncOperation;
        if (op.tableName == 'debts') {
          throw const PostgrestException(message: 'boom', code: 'PGRST204');
        }
      });

      final result = await repository.retryAll();

      expect(result.getOrElse((_) => -1), 1);
      final stored = await store.readAll();
      expect(stored, hasLength(1));
      expect(stored.single.operation.tableName, 'debts');
      expect(stored.single.attempts, 2);
    });

    test('con la cuarentena vacía devuelve 0 sin tocar la red', () async {
      final result = await repository.retryAll();

      expect(result.getOrElse((_) => -1), 0);
      verifyNever(() => uploader.upload(any()));
    });
  });

  group('clear', () {
    test('descarta una sola op y lo deja en el log', () async {
      await record(operation());
      await record(operation(rowId: 'd-2'));
      final target = (await store.readAll()).first;

      final result = await repository.clear(target.id);

      expect(result.isRight(), isTrue);
      expect((await store.readAll()).single.operation.rowId, 'd-2');
      verify(
        () => log.record(
          event: SyncLogEvent.quarantineDiscarded,
          message: any(named: 'message'),
          level: SyncLogLevel.warning,
        ),
      ).called(1);
      // Descartar es una decisión explícita del usuario: nunca reintenta.
      verifyNever(() => uploader.upload(any()));
    });

    test('clearAll vacía la cuarentena entera', () async {
      await record(operation());
      await record(operation(rowId: 'd-2'));

      final result = await repository.clearAll();

      expect(result.isRight(), isTrue);
      expect(await store.readAll(), isEmpty);
    });
  });

  group('lectura', () {
    test('getFailures devuelve lo guardado', () async {
      await record(operation());

      final result = await repository.getFailures();

      expect(result.getOrElse((_) => const []), hasLength(1));
    });

    test('getFailures traduce un fallo de almacenamiento a DatabaseFailure',
        () async {
      final broken = MockSyncQuarantineStore();
      when(broken.readAll).thenThrow(const FileSystemException('nope'));
      final resilient =
          SyncQuarantineRepositoryImpl(broken, uploader, log, crash);

      final result = await resilient.getFailures();

      result.fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('se esperaba un Left'),
      );
    });

    test('watchFailures emite el estado actual y luego cada cambio', () async {
      final emissions = <List<QuarantinedOperation>>[];
      final subscription = repository.watchFailures().listen(emissions.add);
      await Future<void>.delayed(Duration.zero);

      await record(operation());
      await record(operation(rowId: 'd-2'));
      await Future<void>.delayed(Duration.zero);
      await subscription.cancel();

      expect(emissions.map((each) => each.length), <int>[0, 1, 2]);
    });
  });
}
