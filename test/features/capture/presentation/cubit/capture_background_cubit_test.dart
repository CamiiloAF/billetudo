import 'dart:async';

import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/domain/entities/capture_background_health.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_app.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_cubit.dart';
import 'package:billetudo/features/capture/presentation/cubit/capture_background_state.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../capture_mocks.dart';

/// HU-09's orchestrator: it re-reads the real permission, the native issuer
/// list and the health snapshot on every start/refresh, and never lets the
/// surfaces show attention when a precondition is missing or a probe failed.
///
/// The rule itself lives in `GetCaptureBackgroundHealth` and is covered by its
/// own domain test. These cases are about the cubit's contract with the three
/// surfaces: what it asks, what it emits, and what it refuses to claim.
void main() {
  late MockGetCaptureBackgroundHealth health;
  late MockIsNotificationCaptureSupported supported;
  late MockIsNotificationAccessGranted granted;
  late MockGetIssuerApps issuerApps;
  late MockSnoozeCaptureBackgroundAlert snooze;
  late MockRequestBatteryOptimizationExemption requestBattery;
  late MockOpenCaptureAutostartSettings openAutostart;
  late MockMarkCaptureConfigured markConfigured;
  late MockWatchIncomingCaptures watchIncoming;

  setUpAll(registerCaptureFallbacks);

  setUp(() {
    health = MockGetCaptureBackgroundHealth();
    supported = MockIsNotificationCaptureSupported();
    granted = MockIsNotificationAccessGranted();
    issuerApps = MockGetIssuerApps();
    snooze = MockSnoozeCaptureBackgroundAlert();
    requestBattery = MockRequestBatteryOptimizationExemption();
    openAutostart = MockOpenCaptureAutostartSettings();
    markConfigured = MockMarkCaptureConfigured();
    watchIncoming = MockWatchIncomingCaptures();

    when(markConfigured.call).thenAnswer((_) async => const Right(unit));
    when(watchIncoming.call).thenAnswer((_) => const Stream<void>.empty());

    when(supported.call).thenReturn(true);
    when(granted.call).thenAnswer((_) async => const Right(true));
    when(issuerApps.call).thenAnswer(
      (_) async => Right(<IssuerApp>[_issuer('nu', enabled: true)]),
    );
    when(health.call)
        .thenAnswer((_) async => const Right(CaptureBackgroundHealth.calm()));
    when(snooze.call).thenAnswer((_) async => const Right(unit));
    when(requestBattery.call).thenAnswer((_) async => const Right(unit));
    when(openAutostart.call).thenAnswer((_) async => const Right(unit));
  });

  CaptureBackgroundCubit build() => CaptureBackgroundCubit(
        health,
        supported,
        granted,
        issuerApps,
        snooze,
        requestBattery,
        openAutostart,
        markConfigured,
        watchIncoming,
      );

  void stubHealth({
    bool degraded = false,
    bool showsAttention = false,
    DateTime? snoozedUntil,
    bool batteryOptimizationExempt = false,
    bool autostartAvailable = false,
    int? lastCaptureAtEpochMs,
  }) {
    when(health.call).thenAnswer(
      (_) async => Right(
        buildCaptureBackgroundHealth(
          diagnostics: buildCaptureDiagnostics(
            batteryOptimizationExempt: batteryOptimizationExempt,
            autostartAvailable: autostartAvailable,
            manufacturer: 'Xiaomi',
            lastCaptureAtEpochMs: lastCaptureAtEpochMs,
          ),
          degraded: degraded,
          snoozedUntil: snoozedUntil,
          showsAttention: showsAttention,
        ),
      ),
    );
  }

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'start reads the real permission, the native issuers and the health, and '
    'surfaces attention when the health says so',
    setUp: () {
      stubHealth(
        degraded: true,
        showsAttention: true,
        lastCaptureAtEpochMs: DateTime(2026, 11, 1).millisecondsSinceEpoch,
      );
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      expect(cubit.state.isSupported, isTrue);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.permissionGranted, isTrue);
      expect(cubit.state.enabledCount, 1);
      expect(cubit.state.showsAttention, isTrue);
      expect(cubit.state.degraded, isTrue);
      expect(cubit.state.lastCaptureAt, DateTime(2026, 11, 1));
      expect(cubit.state.failure, isNull);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'refresh re-reads instead of trusting the previous snapshot',
    setUp: () {
      stubHealth(degraded: true, showsAttention: true);
      when(issuerApps.call).thenAnswer(
        (_) async => Right(<IssuerApp>[_issuer('nu', enabled: true)]),
      );
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) async {
      await cubit.start();
      // The user granted the battery exemption and a capture arrived while
      // the app was in the background.
      stubHealth(
        batteryOptimizationExempt: true,
        lastCaptureAtEpochMs: DateTime(2026, 11, 9).millisecondsSinceEpoch,
      );
      await cubit.refresh();
    },
    verify: (CaptureBackgroundCubit cubit) {
      verify(health.call).called(2);
      expect(cubit.state.showsAttention, isFalse);
      expect(cubit.state.batteryOptimizationExempt, isTrue);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'a revoked permission wins over a stale degraded native diagnostic',
    setUp: () {
      when(granted.call).thenAnswer((_) async => const Right(false));
      stubHealth(degraded: true, showsAttention: true);
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      expect(cubit.state.permissionGranted, isFalse);
      expect(cubit.state.enabledCount, 0);
      expect(cubit.state.showsAttention, isFalse);
      // Nothing else is asked: the permission state has its own surface.
      verifyNever(issuerApps.call);
      verifyNever(health.call);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'zero enabled issuers wins over a stale degraded native diagnostic',
    setUp: () {
      when(issuerApps.call).thenAnswer(
        (_) async => Right(<IssuerApp>[_issuer('nu', enabled: false)]),
      );
      stubHealth(degraded: true, showsAttention: true);
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      expect(cubit.state.permissionGranted, isTrue);
      expect(cubit.state.enabledCount, 0);
      expect(cubit.state.showsAttention, isFalse);
      verifyNever(health.call);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'a failed health probe fails closed, keeps the failure and never invents '
    'attention',
    setUp: () {
      when(health.call).thenAnswer(
        (_) async => const Left(UnexpectedFailure('channel down')),
      );
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.showsAttention, isFalse);
      expect(cubit.state.permissionGranted, isTrue);
      expect(cubit.state.enabledCount, 1);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'a failed issuer read also fails closed instead of showing the card',
    setUp: () {
      when(issuerApps.call).thenAnswer(
        (_) async => const Left(UnexpectedFailure('channel down')),
      );
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.showsAttention, isFalse);
      verifyNever(health.call);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'on an unsupported platform nothing is read and nothing is shown',
    setUp: () => when(supported.call).thenReturn(false),
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      expect(cubit.state.isSupported, isFalse);
      expect(cubit.state.isLoading, isFalse);
      expect(cubit.state.showsAttention, isFalse);
      verifyNever(granted.call);
      verifyNever(health.call);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'snooze writes the fourteen-day silence and re-reads the state',
    setUp: () => stubHealth(degraded: true, showsAttention: true),
    build: build,
    act: (CaptureBackgroundCubit cubit) async {
      await cubit.start();
      stubHealth(
        degraded: true,
        snoozedUntil: DateTime(2026, 11, 24),
        showsAttention: false,
      );
      await cubit.snooze();
    },
    verify: (CaptureBackgroundCubit cubit) {
      verify(snooze.call).called(1);
      verify(health.call).called(2);
      expect(cubit.state.showsAttention, isFalse);
      // The truth underneath is unchanged: the capture is still degraded, it
      // is only silenced until the stored date.
      expect(cubit.state.degraded, isTrue);
      expect(cubit.state.snoozedUntil, DateTime(2026, 11, 24));
      expect(cubit.state.isSnoozed, isTrue);
      expect(cubit.state.failure, isNull);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'a failed snooze write leaves the card exactly where it was',
    setUp: () {
      stubHealth(degraded: true, showsAttention: true);
      when(snooze.call).thenAnswer(
        (_) async => const Left(UnexpectedFailure('prefs down')),
      );
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) async {
      await cubit.start();
      await cubit.snooze();
    },
    verify: (CaptureBackgroundCubit cubit) {
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.showsAttention, isTrue);
    },
  );

  test('confirmActivated answers true only when the battery is really exempt',
      () async {
    final cubit = build();
    addTearDown(cubit.close);
    stubHealth(degraded: true, showsAttention: true);
    await cubit.start();
    expect(await cubit.confirmActivated(), isFalse);

    // The user returns from Android Settings with the exemption granted.
    stubHealth(
      degraded: true,
      showsAttention: true,
      batteryOptimizationExempt: true,
    );
    expect(await cubit.confirmActivated(), isTrue);
    expect(cubit.state.batteryOptimizationExempt, isTrue);
    // Granting the exemption does not clear the degradation by itself: the
    // card only disappears when the formula says so (e.g. a capture arrives).
    expect(cubit.state.showsAttention, isTrue);
  });

  test('confirmActivated answers false when the probe cannot be read',
      () async {
    final cubit = build();
    addTearDown(cubit.close);
    await cubit.start();
    when(health.call).thenAnswer(
      (_) async => const Left(UnexpectedFailure('channel down')),
    );

    expect(await cubit.confirmActivated(), isFalse);
    expect(cubit.state.failure, isNotNull);
  });

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'requestBatteryExemption opens the screen and re-reads, never assuming '
    'the exemption was granted',
    setUp: () => stubHealth(degraded: true, showsAttention: true),
    build: build,
    act: (CaptureBackgroundCubit cubit) async {
      await cubit.start();
      await cubit.requestBatteryExemption();
    },
    verify: (CaptureBackgroundCubit cubit) {
      verify(requestBattery.call).called(1);
      verify(health.call).called(2);
      expect(cubit.state.batteryOptimizationExempt, isFalse);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'openAutostart goes through its own use case and surfaces a channel '
    'failure without hiding the card',
    setUp: () {
      stubHealth(degraded: true, showsAttention: true);
      when(openAutostart.call).thenAnswer(
        (_) async => const Left(UnexpectedFailure('no activity found')),
      );
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) async {
      await cubit.start();
      await cubit.openAutostart();
    },
    verify: (CaptureBackgroundCubit cubit) {
      verify(openAutostart.call).called(1);
      expect(cubit.state.failure, isNotNull);
      expect(cubit.state.showsAttention, isTrue);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'start backfills the configuration date for an install that predates the '
    'HU-09 mark, so the degraded rule stops reading "never configured"',
    setUp: stubHealth,
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      verify(markConfigured.call).called(1);
      // The mark is idempotent; the health read is not skipped because of it.
      verify(health.call).called(1);
    },
  );

  blocTest<CaptureBackgroundCubit, CaptureBackgroundState>(
    'no configuration backfill is attempted while capture is not set up',
    setUp: () {
      when(issuerApps.call).thenAnswer(
        (_) async => Right(<IssuerApp>[_issuer('nu', enabled: false)]),
      );
    },
    build: build,
    act: (CaptureBackgroundCubit cubit) => cubit.start(),
    verify: (CaptureBackgroundCubit cubit) {
      verifyNever(markConfigured.call);
      verifyNever(health.call);
    },
  );

  test('a live capture doorbell re-reads the health so the card can clear',
      () async {
    final StreamController<void> doorbell = StreamController<void>.broadcast();
    addTearDown(doorbell.close);
    when(watchIncoming.call).thenAnswer((_) => doorbell.stream);

    final cubit = build();
    addTearDown(cubit.close);
    await cubit.start();

    doorbell.add(null);
    await pumpEventQueue();

    // `verify` consumes invocations in mocktail, so the count is only read once
    // at the end: one read from `start()` plus one from the doorbell refresh.
    verify(health.call).called(2);
  });
}

IssuerApp _issuer(String id, {required bool enabled}) => IssuerApp(
      issuerId: id,
      displayName: id,
      packageName: 'com.$id',
      installed: true,
      enabled: enabled,
    );
