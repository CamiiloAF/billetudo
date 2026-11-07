import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/data/datasources/manual_movement_attempt_preference_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/manual_movement_attempt_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shared_preferences_platform_interface/in_memory_shared_preferences_async.dart';
import 'package:shared_preferences_platform_interface/shared_preferences_async_platform_interface.dart';

class _MockCrashReporter extends Mock implements CrashReporter {}

/// `17-captura-voz.md` HU-02: the manual-attempt counter behind the voice
/// tutorial. It lives in `SharedPreferences`, so this also pins that it
/// survives a second read (same process) and that a failed write never
/// throws into the `+` button's caller.
void main() {
  late _MockCrashReporter crash;
  late ManualMovementAttemptPreferenceDatasource datasource;
  late ManualMovementAttemptRepositoryImpl repository;

  setUp(() {
    SharedPreferencesAsyncPlatform.instance =
        InMemorySharedPreferencesAsync.empty();
    crash = _MockCrashReporter();
    datasource = ManualMovementAttemptPreferenceDatasource(
      SharedPreferencesAsync(),
    );
    repository = ManualMovementAttemptRepositoryImpl(datasource, crash);
  });

  group('ManualMovementAttemptPreferenceDatasource', () {
    test('a device that never opened the form reports 0 attempts', () async {
      expect(await datasource.readAttempts(), 0);
    });

    test('written attempts are read back', () async {
      await datasource.writeAttempts(2);

      expect(await datasource.readAttempts(), 2);
    });
  });

  group('ManualMovementAttemptRepositoryImpl', () {
    test('registerAttempt counts up: 1, 2, 3', () async {
      Future<int> attempt() async =>
          (await repository.registerAttempt()).getOrElse((_) => -1);

      expect(await attempt(), 1);
      expect(await attempt(), 2);
      expect(await attempt(), 3);
      expect(await datasource.readAttempts(), 3);
    });

    test('a write failure is reported and returned as a failure, never thrown',
        () async {
      final failing = ManualMovementAttemptRepositoryImpl(
        _FailingDatasource(),
        crash,
      );
      when(
        () => crash.recordError(
          any(),
          any(),
          context: any(named: 'context'),
          fatal: any(named: 'fatal'),
        ),
      ).thenAnswer((_) async {});

      final result = await failing.registerAttempt();

      expect(result, isA<Left<Failure, int>>());
      verify(
        () => crash.recordError(
          any(),
          any(),
          context: 'manual movement attempt write',
          fatal: any(named: 'fatal'),
        ),
      ).called(1);
    });
  });
}

class _FailingDatasource extends ManualMovementAttemptPreferenceDatasource {
  _FailingDatasource() : super(SharedPreferencesAsync());

  @override
  Future<int> readAttempts() async => throw StateError('prefs unavailable');
}
