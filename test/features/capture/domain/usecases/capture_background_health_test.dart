import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/capture_background_health.dart';
import 'package:billetudo/features/capture/domain/entities/capture_diagnostics.dart';
import 'package:billetudo/features/capture/domain/usecases/get_capture_background_health.dart';
import 'package:billetudo/features/capture/domain/usecases/mark_capture_configured.dart';
import 'package:billetudo/features/capture/domain/usecases/open_capture_autostart_settings.dart';
import 'package:billetudo/features/capture/domain/usecases/request_battery_optimization_exemption.dart';
import 'package:billetudo/features/capture/domain/usecases/snooze_capture_background_alert.dart';
import 'package:clock/clock.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

/// One row of the degraded table: everything the formula reads, and whether it
/// should come out degraded.
typedef _HealthCase = ({
  String name,
  bool permission,
  Set<String> issuers,
  DateTime? configuredAt,
  int? lastCaptureAtEpochMs,
  bool degraded,
});

/// One row of the listener-heartbeat table: the two direct signals plus the
/// heuristic inputs they must be distinguished from.
typedef _HeartbeatCase = ({
  String name,
  bool permission,
  Set<String> issuers,
  DateTime configuredAt,
  DateTime? lastListenerConnectedAt,
  bool listenerConnectedNow,
  int? lastCaptureAtEpochMs,
  bool degraded,
});

void main() {
  final DateTime now = DateTime(2026, 11, 10, 12);
  final DateTime configuredLongAgo = DateTime(2026, 10, 1, 9);

  late MockNotificationCaptureRepository capture;
  late MockCaptureBackgroundPreferencesRepository preferences;

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    capture = MockNotificationCaptureRepository();
    preferences = MockCaptureBackgroundPreferencesRepository();
  });

  void stub({
    bool granted = true,
    Set<String> issuers = const <String>{'nu'},
    DateTime? configuredAt,
    int? lastCaptureAtEpochMs,
    int? lastListenerConnectedAtEpochMs = defaultListenerConnectedAtEpochMs,
    bool listenerConnectedNow = true,
    DateTime? snoozedUntil,
  }) {
    when(capture.isPermissionGranted).thenAnswer((_) async => Right(granted));
    when(capture.getEnabledIssuers).thenAnswer((_) async => Right(issuers));
    when(capture.getDiagnostics).thenAnswer(
      (_) async => Right(
        buildCaptureDiagnostics(
          lastCaptureAtEpochMs: lastCaptureAtEpochMs,
          lastListenerConnectedAtEpochMs: lastListenerConnectedAtEpochMs,
          listenerConnectedNow: listenerConnectedNow,
          manufacturer: 'Xiaomi',
          batteryOptimizationExempt: true,
          autostartAvailable: true,
        ),
      ),
    );
    when(preferences.configuredAt).thenAnswer((_) async => Right(configuredAt));
    when(preferences.snoozedUntil).thenAnswer((_) async => Right(snoozedUntil));
  }

  Future<CaptureBackgroundHealth> healthAt(DateTime at) async {
    final Result<CaptureBackgroundHealth> result = await withClock(
      Clock.fixed(at),
      () => GetCaptureBackgroundHealth(capture, preferences)(),
    );
    return result.getOrElse((Failure f) => throw StateError(f.message));
  }

  group('GetCaptureBackgroundHealth', () {
    // The full table: four exclusive `false` preconditions, both grace-period
    // boundaries (3 days from configuration, 7 from the last capture), the
    // "still inside the window" case on each side, and recovery — a capture
    // from today clears the alarm even if the configuration is old.
    final List<_HealthCase> cases = <_HealthCase>[
      (
        name: 'no permission: the permission state takes precedence',
        permission: false,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: null,
        degraded: false,
      ),
      (
        name: 'no enabled issuer: nothing is being listened to',
        permission: true,
        issuers: const <String>{},
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: null,
        degraded: false,
      ),
      (
        name: 'never configured: an old install gets no alarm',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: null,
        lastCaptureAtEpochMs: null,
        degraded: false,
      ),
      (
        name: 'configured two days ago and nothing arrived yet: still patient',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: DateTime(2026, 11, 8, 12),
        lastCaptureAtEpochMs: null,
        degraded: false,
      ),
      (
        name: 'configured three days ago and nothing arrived: degraded',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: DateTime(2026, 11, 7, 12),
        lastCaptureAtEpochMs: null,
        degraded: true,
      ),
      (
        name: 'last capture six days ago: still inside the seven-day window',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: DateTime(2026, 11, 4, 12).millisecondsSinceEpoch,
        degraded: false,
      ),
      (
        name: 'last capture seven days ago: it used to work and stopped',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: DateTime(2026, 11, 3, 12).millisecondsSinceEpoch,
        degraded: true,
      ),
      (
        name: 'a capture from today clears the alarm',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs:
            DateTime(2026, 11, 10, 9, 19).millisecondsSinceEpoch,
        degraded: false,
      ),
    ];

    for (final _HealthCase row in cases) {
      test(row.name, () async {
        stub(
          granted: row.permission,
          issuers: row.issuers,
          configuredAt: row.configuredAt,
          lastCaptureAtEpochMs: row.lastCaptureAtEpochMs,
        );

        final CaptureBackgroundHealth health = await healthAt(now);

        expect(health.degraded, row.degraded);
      });
    }

    // The direct signal table: the listener heartbeat catches a rejected bind
    // in minutes, and must not override the legitimately calm states.
    final List<_HeartbeatCase> heartbeatCases = <_HeartbeatCase>[
      (
        name: 'never connected and configured four minutes ago: still inside '
            'the grace period',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: now.subtract(const Duration(minutes: 4)),
        lastListenerConnectedAt: null,
        listenerConnectedNow: false,
        lastCaptureAtEpochMs: null,
        degraded: false,
      ),
      (
        name: 'never connected five minutes after configuring: degraded',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: now.subtract(const Duration(minutes: 5)),
        lastListenerConnectedAt: null,
        listenerConnectedNow: false,
        lastCaptureAtEpochMs: null,
        degraded: true,
      ),
      (
        name: 'never connected six minutes after configuring: degraded',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: now.subtract(const Duration(minutes: 6)),
        lastListenerConnectedAt: null,
        listenerConnectedNow: false,
        lastCaptureAtEpochMs: null,
        degraded: true,
      ),
      (
        name: 'disconnected now after connecting seven hours ago: degraded',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastListenerConnectedAt: now.subtract(const Duration(hours: 7)),
        listenerConnectedNow: false,
        lastCaptureAtEpochMs:
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        degraded: true,
      ),
      (
        name: 'disconnected now but it connected one hour ago: still patient',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastListenerConnectedAt: now.subtract(const Duration(hours: 1)),
        listenerConnectedNow: false,
        lastCaptureAtEpochMs:
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        degraded: false,
      ),
      (
        name: 'connected now after seven hours offline with a recent capture: '
            'the heuristic decides',
        permission: true,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastListenerConnectedAt: now.subtract(const Duration(hours: 7)),
        listenerConnectedNow: true,
        lastCaptureAtEpochMs:
            now.subtract(const Duration(hours: 1)).millisecondsSinceEpoch,
        degraded: false,
      ),
      (
        name: 'no permission: wins over a listener that never connected',
        permission: false,
        issuers: const <String>{'nu'},
        configuredAt: configuredLongAgo,
        lastListenerConnectedAt: null,
        listenerConnectedNow: false,
        lastCaptureAtEpochMs: null,
        degraded: false,
      ),
      (
        name: 'no enabled issuer: wins over a listener that never connected',
        permission: true,
        issuers: const <String>{},
        configuredAt: configuredLongAgo,
        lastListenerConnectedAt: null,
        listenerConnectedNow: false,
        lastCaptureAtEpochMs: null,
        degraded: false,
      ),
    ];

    for (final _HeartbeatCase row in heartbeatCases) {
      test(row.name, () async {
        stub(
          granted: row.permission,
          issuers: row.issuers,
          configuredAt: row.configuredAt,
          lastCaptureAtEpochMs: row.lastCaptureAtEpochMs,
          lastListenerConnectedAtEpochMs:
              row.lastListenerConnectedAt?.millisecondsSinceEpoch,
          listenerConnectedNow: row.listenerConnectedNow,
        );

        final CaptureBackgroundHealth health = await healthAt(now);

        expect(health.degraded, row.degraded);
      });
    }

    test('attention follows degraded when nothing was snoozed', () async {
      stub(
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: DateTime(2026, 11, 3, 12).millisecondsSinceEpoch,
      );

      final CaptureBackgroundHealth health = await healthAt(now);

      expect(health.degraded, isTrue);
      expect(health.showsAttention, isTrue);
    });

    test('a future snooze hides the card but not the truth', () async {
      stub(
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: DateTime(2026, 11, 3, 12).millisecondsSinceEpoch,
        snoozedUntil: now.add(const Duration(days: 1)),
      );

      final CaptureBackgroundHealth health = await healthAt(now);

      expect(health.degraded, isTrue);
      expect(health.showsAttention, isFalse);
      expect(health.snoozedUntil, isNotNull);
    });

    test('an expired snooze lets the card come back', () async {
      stub(
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: DateTime(2026, 11, 3, 12).millisecondsSinceEpoch,
        snoozedUntil: now.subtract(const Duration(days: 1)),
      );

      final CaptureBackgroundHealth health = await healthAt(now);

      expect(health.showsAttention, isTrue);
    });

    test('carries the real device diagnostics with the decision', () async {
      stub(
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: DateTime(2026, 11, 3, 12).millisecondsSinceEpoch,
      );

      final CaptureBackgroundHealth health = await healthAt(now);

      expect(health.diagnostics.manufacturer, 'Xiaomi');
      expect(health.diagnostics.batteryOptimizationExempt, isTrue);
      expect(health.diagnostics.autostartAvailable, isTrue);
      expect(health.diagnostics.listenerConnectedNow, isTrue);
      expect(
        health.diagnostics.lastListenerConnectedAt,
        DateTime.fromMillisecondsSinceEpoch(defaultListenerConnectedAtEpochMs),
      );
    });

    test('fails closed when the device diagnostics cannot be read', () async {
      stub(configuredAt: configuredLongAgo);
      when(capture.getDiagnostics)
          .thenAnswer((_) async => const Left(UnexpectedFailure('channel')));

      final CaptureBackgroundHealth health = await healthAt(now);

      expect(health.degraded, isFalse);
      expect(health.showsAttention, isFalse);
    });

    test('fails closed when the snooze cannot be read', () async {
      stub(
        configuredAt: configuredLongAgo,
        lastCaptureAtEpochMs: DateTime(2026, 11, 3, 12).millisecondsSinceEpoch,
      );
      when(preferences.snoozedUntil)
          .thenAnswer((_) async => const Left(UnexpectedFailure('store')));

      final CaptureBackgroundHealth health = await healthAt(now);

      expect(health.degraded, isFalse);
      expect(health.showsAttention, isFalse);
    });

    test('a permission read failure is not an alarm', () async {
      when(capture.isPermissionGranted)
          .thenAnswer((_) async => const Left(UnexpectedFailure('channel')));

      final CaptureBackgroundHealth health = await healthAt(now);

      expect(health.degraded, isFalse);
      verifyNever(preferences.configuredAt);
    });
  });

  group('SnoozeCaptureBackgroundAlert', () {
    test('stores fourteen days from now and touches nothing else', () async {
      when(() => preferences.snoozeUntil(any()))
          .thenAnswer((_) async => const Right(unit));

      final Result<Unit> result = await withClock(
        Clock.fixed(now),
        () => SnoozeCaptureBackgroundAlert(preferences)(),
      );

      expect(result.isRight(), isTrue);
      verify(
        () => preferences.snoozeUntil(now.add(const Duration(days: 14))),
      ).called(1);
      verifyNever(() => preferences.markConfigured(any()));
      verifyNever(() => capture.setEnabledIssuers(any()));
    });

    test('a failed write surfaces instead of pretending it was snoozed',
        () async {
      when(() => preferences.snoozeUntil(any()))
          .thenAnswer((_) async => const Left(UnexpectedFailure('disk')));

      final Result<Unit> result = await withClock(
        Clock.fixed(now),
        () => SnoozeCaptureBackgroundAlert(preferences)(),
      );

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });

  group('MarkCaptureConfigured', () {
    Future<Result<Unit>> mark() => withClock(
          Clock.fixed(now),
          () => MarkCaptureConfigured(capture, preferences)(),
        );

    test('latches the date only when permission and issuers are in place',
        () async {
      stub(configuredAt: null);
      when(() => preferences.markConfigured(any()))
          .thenAnswer((_) async => const Right(unit));

      final Result<Unit> result = await mark();

      expect(result.isRight(), isTrue);
      verify(() => preferences.markConfigured(now)).called(1);
    });

    test('is idempotent: an existing mark is never overwritten', () async {
      stub(configuredAt: DateTime(2026, 9, 1, 10));

      final Result<Unit> result = await mark();

      expect(result.isRight(), isTrue);
      verifyNever(() => preferences.markConfigured(any()));
      // The mark exists, so the expensive checks are skipped too.
      verifyNever(capture.isPermissionGranted);
    });

    test('does not mark without the notification permission', () async {
      stub(granted: false, configuredAt: null);

      final Result<Unit> result = await mark();

      expect(result.isRight(), isTrue);
      verifyNever(() => preferences.markConfigured(any()));
    });

    test('does not mark with every issuer off', () async {
      stub(configuredAt: null, issuers: const <String>{});

      final Result<Unit> result = await mark();

      expect(result.isRight(), isTrue);
      verifyNever(() => preferences.markConfigured(any()));
    });

    test('does not mark when the existing date cannot be read', () async {
      when(preferences.configuredAt)
          .thenAnswer((_) async => const Left(UnexpectedFailure('store')));

      final Result<Unit> result = await mark();

      expect(result.isRight(), isTrue);
      verifyNever(() => preferences.markConfigured(any()));
    });

    test('surfaces a failed write so the caller knows nothing was latched',
        () async {
      stub(configuredAt: null);
      when(() => preferences.markConfigured(any()))
          .thenAnswer((_) async => const Left(UnexpectedFailure('disk')));

      final Result<Unit> result = await mark();

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });

  group('system actions', () {
    test('battery exemption delegates to the channel', () async {
      when(capture.requestIgnoreBatteryOptimizations)
          .thenAnswer((_) async => const Right(unit));

      final Result<Unit> result =
          await RequestBatteryOptimizationExemption(capture)();

      expect(result.isRight(), isTrue);
      verify(capture.requestIgnoreBatteryOptimizations).called(1);
    });

    test('battery exemption surfaces a channel failure', () async {
      when(capture.requestIgnoreBatteryOptimizations).thenAnswer(
        (_) async => const Left(UnexpectedFailure('no activity')),
      );

      final Result<Unit> result =
          await RequestBatteryOptimizationExemption(capture)();

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });

    test('autostart delegates to the channel', () async {
      when(capture.openAutostartSettings)
          .thenAnswer((_) async => const Right(unit));

      final Result<Unit> result = await OpenCaptureAutostartSettings(capture)();

      expect(result.isRight(), isTrue);
      verify(capture.openAutostartSettings).called(1);
    });

    test('autostart surfaces a channel failure', () async {
      when(capture.openAutostartSettings).thenAnswer(
        (_) async => const Left(UnexpectedFailure('no activity')),
      );

      final Result<Unit> result = await OpenCaptureAutostartSettings(capture)();

      expect(result.getLeft().toNullable(), isA<UnexpectedFailure>());
    });
  });

  // Keeps the `CaptureDiagnostics` import meaningful and pins the "no history"
  // reading the copy depends on.
  test('empty diagnostics have no capture history', () {
    expect(const CaptureDiagnostics.empty().hasCaptureHistory, isFalse);
    expect(const CaptureDiagnostics.empty().lastCaptureAt, isNull);
    expect(const CaptureDiagnostics.empty().lastListenerConnectedAt, isNull);
    expect(const CaptureDiagnostics.empty().listenerConnectedNow, isFalse);
  });
}
