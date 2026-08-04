import 'dart:io';

import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/core/sync/data/datasources/json_sync_log_store.dart';
import 'package:billetudo/core/sync/data/datasources/sync_log_store.dart';
import 'package:billetudo/core/sync/data/repositories/sync_log_repository_impl.dart';
import 'package:billetudo/core/sync/domain/entities/sync_log_entry.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../../../support/temp_sync_storage_directory.dart';

class MockCrashReporter extends Mock implements CrashReporter {}

class MockSyncLogStore extends Mock implements SyncLogStore {}

class FakeSyncLogEntry extends Fake implements SyncLogEntry {}

void main() {
  setUpAll(() {
    registerFallbackValue(StackTrace.empty);
    registerFallbackValue(FakeSyncLogEntry());
  });

  late TempSyncStorageDirectory storage;
  late JsonSyncLogStore store;
  late MockCrashReporter crash;
  late SyncLogRepositoryImpl repository;

  setUp(() {
    storage = TempSyncStorageDirectory.create('sync_log_repo');
    store = JsonSyncLogStore(storage);
    crash = MockCrashReporter();
    repository = SyncLogRepositoryImpl(store, crash);
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

  test('record estampa un id UUID y la marca de tiempo', () async {
    await repository.record(
      event: SyncLogEvent.quarantined,
      message: 'operation quarantined',
      level: SyncLogLevel.error,
      code: 'PGRST204',
      tableName: 'debts',
    );

    final stored = (await store.readAll()).single;
    expect(
      stored.id,
      matches(
        RegExp(
          r'^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$',
        ),
      ),
    );
    expect(stored.event, SyncLogEvent.quarantined);
    expect(stored.level, SyncLogLevel.error);
    expect(stored.code, 'PGRST204');
    expect(stored.tableName, 'debts');
  });

  test('record usa nivel info por defecto', () async {
    await repository.record(
      event: SyncLogEvent.uploadStarted,
      message: 'uploading',
    );

    expect((await store.readAll()).single.level, SyncLogLevel.info);
  });

  test(
      'record NUNCA relanza: un fallo del log leído como fallo de subida '
      'devolvería la cola al bucle de reintento', () async {
    final broken = MockSyncLogStore();
    when(() => broken.append(any()))
        .thenThrow(const FileSystemException('disk full'));
    final resilient = SyncLogRepositoryImpl(broken, crash);

    await expectLater(
      resilient.record(
        event: SyncLogEvent.uploadStarted,
        message: 'uploading',
      ),
      completes,
    );

    verify(
      () => crash.recordError(
        any(that: isA<FileSystemException>()),
        any(),
        context: any(named: 'context', that: contains('sync log')),
      ),
    ).called(1);
  });

  test('getEntries devuelve las entradas más nuevas primero', () async {
    await repository.record(
      event: SyncLogEvent.uploadStarted,
      message: 'primera',
    );
    await repository.record(
      event: SyncLogEvent.uploadFinished,
      message: 'segunda',
    );

    final result = await repository.getEntries();

    expect(
      result.getOrElse((_) => const []).map((each) => each.message),
      <String>['segunda', 'primera'],
    );
  });

  test('watchEntries también emite las más nuevas primero', () async {
    await repository.record(
      event: SyncLogEvent.uploadStarted,
      message: 'primera',
    );

    final emissions = <List<SyncLogEntry>>[];
    final subscription = repository.watchEntries().listen(emissions.add);
    await Future<void>.delayed(Duration.zero);
    await repository.record(
      event: SyncLogEvent.uploadFinished,
      message: 'segunda',
    );
    await Future<void>.delayed(Duration.zero);
    await subscription.cancel();

    expect(emissions.last.first.message, 'segunda');
  });

  test('exportAsText arma el texto en orden cronológico, una línea por entrada',
      () async {
    await repository.record(
      event: SyncLogEvent.uploadStarted,
      message: 'primera',
    );
    await repository.record(
      event: SyncLogEvent.quarantined,
      message: 'segunda',
      level: SyncLogLevel.error,
      code: 'PGRST204',
      tableName: 'debts',
    );

    final text = (await repository.exportAsText()).getOrElse((_) => '');

    final lines = text.split('\n');
    expect(lines, hasLength(2));
    expect(lines.first, contains('upload_started'));
    expect(lines.first, contains('primera'));
    expect(lines.last, contains('error/quarantined'));
    expect(lines.last, contains('debts'));
    expect(lines.last, contains('PGRST204'));
  });

  test('exportAsText con el log vacío devuelve texto vacío', () async {
    expect((await repository.exportAsText()).getOrElse((_) => 'x'), '');
  });

  test('clear vacía el log', () async {
    await repository.record(
      event: SyncLogEvent.uploadStarted,
      message: 'primera',
    );

    final result = await repository.clear();

    expect(result.isRight(), isTrue);
    expect(await store.readAll(), isEmpty);
  });

  group('los fallos de lectura se traducen a DatabaseFailure', () {
    late SyncLogRepositoryImpl resilient;

    setUp(() {
      final broken = MockSyncLogStore();
      when(broken.readAll).thenThrow(const FileSystemException('unreadable'));
      when(broken.removeAll).thenThrow(const FileSystemException('unreadable'));
      resilient = SyncLogRepositoryImpl(broken, crash);
    });

    test('getEntries', () async {
      (await resilient.getEntries()).fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('se esperaba un Left'),
      );
    });

    test('exportAsText', () async {
      (await resilient.exportAsText()).fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('se esperaba un Left'),
      );
    });

    test('clear', () async {
      (await resilient.clear()).fold(
        (failure) => expect(failure, isA<DatabaseFailure>()),
        (_) => fail('se esperaba un Left'),
      );
    });
  });
}
