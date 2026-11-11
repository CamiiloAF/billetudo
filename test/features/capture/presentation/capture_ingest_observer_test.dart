import 'dart:async';

import 'package:billetudo/core/crash/crash_reporter.dart';
import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/pending_capture.dart';
import 'package:billetudo/features/capture/presentation/capture_ingest_observer.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../capture_mocks.dart';

class MockCrashReporter extends Mock implements CrashReporter {}

/// The app-wide ingester: before it existed, a capture received with the app
/// already running stayed in the native buffer until a cold start or until the
/// user opened Avisos — no badge, nothing in the inbox. These cases pin both
/// triggers and the "never lose the last notification of a burst" rule.
void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late MockDrainAndIngestCaptures drainAndIngest;
  late MockWatchIncomingCaptures watchIncoming;
  late MockCrashReporter crash;
  late StreamController<void> doorbell;

  setUpAll(() {
    registerCaptureFallbacks();
    registerFallbackValue(const UnexpectedFailure('fallback'));
  });

  setUp(() {
    drainAndIngest = MockDrainAndIngestCaptures();
    watchIncoming = MockWatchIncomingCaptures();
    crash = MockCrashReporter();
    doorbell = StreamController<void>.broadcast();

    when(watchIncoming.call).thenAnswer((_) => doorbell.stream);
    when(drainAndIngest.call).thenAnswer(
      (_) async =>
          const Right<Failure, List<PendingCapture>>(<PendingCapture>[]),
    );
    when(() => crash.recordFailure(any(), context: any(named: 'context')))
        .thenAnswer((_) async {});
  });

  tearDown(() => doorbell.close());

  CaptureIngestObserver build() =>
      CaptureIngestObserver(drainAndIngest, watchIncoming, crash);

  test('starting does not drain: bootstrap owns the cold-start drain',
      () async {
    final CaptureIngestObserver observer = build();
    addTearDown(observer.stop);

    await observer.start();
    await pumpEventQueue();

    verifyNever(drainAndIngest.call);
  });

  test('a native capture doorbell drains immediately', () async {
    final CaptureIngestObserver observer = build();
    addTearDown(observer.stop);
    await observer.start();

    doorbell.add(null);
    await pumpEventQueue();

    verify(drainAndIngest.call).called(1);
  });

  test('returning to foreground drains as a safety net, other states do not',
      () async {
    final CaptureIngestObserver observer = build();
    addTearDown(observer.stop);
    await observer.start();

    observer.didChangeAppLifecycleState(AppLifecycleState.paused);
    await pumpEventQueue();
    verifyNever(drainAndIngest.call);

    observer.didChangeAppLifecycleState(AppLifecycleState.resumed);
    await pumpEventQueue();

    verify(drainAndIngest.call).called(1);
  });

  test('overlapping notifications coalesce, and a doorbell during a drain is '
      'not lost', () async {
    final Completer<void> firstDrain = Completer<void>();
    int calls = 0;
    when(drainAndIngest.call).thenAnswer((_) async {
      calls++;
      if (calls == 1) {
        await firstDrain.future;
      }
      return const Right<Failure, List<PendingCapture>>(<PendingCapture>[]);
    });

    final CaptureIngestObserver observer = build();
    addTearDown(observer.stop);
    await observer.start();

    doorbell.add(null);
    await pumpEventQueue();
    expect(calls, 1);

    // Two captures arrive while the first drain is still running.
    doorbell.add(null);
    doorbell.add(null);
    await pumpEventQueue();
    expect(calls, 1);

    firstDrain.complete();
    await pumpEventQueue();
    // One extra drain for the whole burst, not one per event.
    expect(calls, 2);
  });

  test('a failed drain is reported and swallowed', () async {
    when(drainAndIngest.call).thenAnswer(
      (_) async => const Left<Failure, List<PendingCapture>>(
        DatabaseFailure('write failed'),
      ),
    );

    final CaptureIngestObserver observer = build();
    addTearDown(observer.stop);
    await observer.start();

    doorbell.add(null);
    await pumpEventQueue();

    verify(
      () => crash.recordFailure(
        any(),
        context: 'drainAndIngestCaptures',
      ),
    ).called(1);
  });
}
