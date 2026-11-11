import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/data/datasources/capture_method_channel_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/notification_capture_repository_impl.dart';
import 'package:billetudo/features/capture/domain/entities/capture_diagnostics.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_app.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_notification.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const MethodChannel channel =
      MethodChannel(CaptureMethodChannelDatasource.channelName);
  final List<MethodCall> calls = <MethodCall>[];
  late Object? Function(MethodCall call) handler;

  setUp(() {
    calls.clear();
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, (MethodCall call) async {
      calls.add(call);
      return handler(call);
    });
  });

  tearDown(() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(channel, null);
  });

  NotificationCaptureRepositoryImpl buildRepository() =>
      const NotificationCaptureRepositoryImpl(
        CaptureMethodChannelDatasource(),
      );

  test('drainPendingCaptures maps the native payload into entities', () async {
    handler = (MethodCall call) => <Object?>[
          <Object?, Object?>{
            'issuerId': 'google_wallet',
            'packageName': 'com.google.android.apps.walletnfcrel',
            'ruleId': 'google_wallet.tap_payment',
            'amountMinor': 3800000,
            'currency': 'COP',
            'entryType': 'expense',
            'postedAtEpochMs': 1789000000000,
            'merchantRaw': 'DROGUERIA LAS 24',
            'accountHint': '5615',
            'cardNetwork': 'Visa',
          },
          // Malformed entries are dropped instead of producing a capture with
          // an invented amount.
          <Object?, Object?>{'issuerId': 'nu', 'amountMinor': 0},
        ];

    final Result<List<ParsedNotification>> result =
        await buildRepository().drainPendingCaptures();

    final List<ParsedNotification> captures =
        result.getOrElse((Failure f) => throw StateError(f.message));
    expect(captures, hasLength(1));
    expect(captures.single.amountMinor, 3800000);
    expect(captures.single.entryType, TransactionType.expense);
    expect(captures.single.merchantRaw, 'DROGUERIA LAS 24');
    expect(captures.single.accountHint, '5615');
    expect(captures.single.cardNetwork, 'Visa');
    expect(calls.single.method, 'drainPendingCaptures');
  });

  test('getInstalledIssuerApps maps the catalog crossing', () async {
    handler = (MethodCall call) => <Object?>[
          <Object?, Object?>{
            'issuerId': 'nequi',
            'displayName': 'Nequi',
            'packageName': 'com.nequi.MobileApp',
            'installed': true,
            'enabled': false,
          },
        ];

    final Result<List<IssuerApp>> result =
        await buildRepository().getInstalledIssuerApps();

    final List<IssuerApp> apps =
        result.getOrElse((Failure f) => throw StateError(f.message));
    expect(apps.single.issuerId, 'nequi');
    // Off by default: a granted permission alone captures nothing.
    expect(apps.single.enabled, isFalse);
  });

  test('setEnabledIssuers forwards the ids', () async {
    handler = (MethodCall call) => null;

    await buildRepository().setEnabledIssuers(<String>{'nu', 'nequi'});

    expect(calls.single.method, 'setEnabledIssuers');
    expect(
      (calls.single.arguments as Map<Object?, Object?>)['issuerIds'],
      containsAll(<String>['nu', 'nequi']),
    );
  });

  test('a platform error becomes a Failure, never a crash', () async {
    handler = (MethodCall call) => throw PlatformException(code: 'boom');

    final Result<bool> result = await buildRepository().isPermissionGranted();

    expect(result.isLeft(), isTrue);
  });

  group('getDiagnostics', () {
    CaptureDiagnostics diagnosticsFrom(Result<CaptureDiagnostics> result) =>
        result.getOrElse((Failure f) => throw StateError(f.message));

    test('maps the complete native payload', () async {
      handler = (MethodCall call) => <Object?, Object?>{
            'lastCaptureAtEpochMs': 1789000000000,
            'lastListenerConnectedAtEpochMs': 1789000000500,
            'listenerConnectedNow': true,
            'batteryOptimizationExempt': true,
            'manufacturer': 'Xiaomi',
            'autostartAvailable': true,
          };

      final CaptureDiagnostics diagnostics =
          diagnosticsFrom(await buildRepository().getDiagnostics());

      expect(diagnostics.lastCaptureAtEpochMs, 1789000000000);
      expect(
        diagnostics.lastListenerConnectedAt,
        DateTime.fromMillisecondsSinceEpoch(1789000000500),
      );
      expect(diagnostics.listenerConnectedNow, isTrue);
      expect(diagnostics.batteryOptimizationExempt, isTrue);
      expect(diagnostics.manufacturer, 'Xiaomi');
      expect(diagnostics.autostartAvailable, isTrue);
      expect(diagnostics.hasCaptureHistory, isTrue);
      expect(calls.single.method, 'getDiagnostics');
    });

    test('tolerates a partial payload', () async {
      handler = (MethodCall call) => <Object?, Object?>{
            'manufacturer': 'samsung',
          };

      final CaptureDiagnostics diagnostics =
          diagnosticsFrom(await buildRepository().getDiagnostics());

      expect(diagnostics.lastCaptureAtEpochMs, isNull);
      expect(diagnostics.lastListenerConnectedAt, isNull);
      expect(diagnostics.listenerConnectedNow, isFalse);
      expect(diagnostics.batteryOptimizationExempt, isFalse);
      expect(diagnostics.manufacturer, 'samsung');
      expect(diagnostics.autostartAvailable, isFalse);
    });

    test('tolerates an empty answer', () async {
      handler = (MethodCall call) => null;

      final CaptureDiagnostics diagnostics =
          diagnosticsFrom(await buildRepository().getDiagnostics());

      expect(diagnostics.lastCaptureAtEpochMs, isNull);
      expect(diagnostics.lastListenerConnectedAt, isNull);
      expect(diagnostics.listenerConnectedNow, isFalse);
      expect(diagnostics.batteryOptimizationExempt, isFalse);
      expect(diagnostics.manufacturer, isEmpty);
      expect(diagnostics.autostartAvailable, isFalse);
    });

    test('maps an explicit null listener timestamp as never connected',
        () async {
      handler = (MethodCall call) => <Object?, Object?>{
            // What a rejected bind looks like: the native side has no value.
            'lastListenerConnectedAtEpochMs': null,
            'listenerConnectedNow': false,
          };

      final CaptureDiagnostics diagnostics =
          diagnosticsFrom(await buildRepository().getDiagnostics());

      expect(diagnostics.lastListenerConnectedAt, isNull);
      expect(diagnostics.listenerConnectedNow, isFalse);
    });

    test('treats a non-positive listener timestamp as never connected',
        () async {
      handler = (MethodCall call) => <Object?, Object?>{
            'lastListenerConnectedAtEpochMs': 0,
          };

      final CaptureDiagnostics diagnostics =
          diagnosticsFrom(await buildRepository().getDiagnostics());

      expect(diagnostics.lastListenerConnectedAt, isNull);
    });

    test('never throws on unexpected value types', () async {
      handler = (MethodCall call) => <Object?, Object?>{
            // A native/Flutter version skew: the timestamp arrives as a
            // string and the booleans as textual/numeric flags.
            'lastCaptureAtEpochMs': '1789000000000',
            'lastListenerConnectedAtEpochMs': <String, Object?>{},
            'listenerConnectedNow': 1,
            'batteryOptimizationExempt': 'true',
            'manufacturer': 42,
            'autostartAvailable': 1,
          };

      final CaptureDiagnostics diagnostics =
          diagnosticsFrom(await buildRepository().getDiagnostics());

      expect(diagnostics.lastCaptureAtEpochMs, 1789000000000);
      expect(diagnostics.lastListenerConnectedAt, isNull);
      // A numeric 1 must not claim the listener is bound right now.
      expect(diagnostics.listenerConnectedNow, isFalse);
      expect(diagnostics.batteryOptimizationExempt, isTrue);
      expect(diagnostics.manufacturer, isEmpty);
      // Only `true` counts: a numeric 1 must not claim the exemption.
      expect(diagnostics.autostartAvailable, isFalse);
    });

    test('accepts a numeric string for the listener timestamp', () async {
      handler = (MethodCall call) => <Object?, Object?>{
            'lastListenerConnectedAtEpochMs': '1789000000500',
          };

      final CaptureDiagnostics diagnostics =
          diagnosticsFrom(await buildRepository().getDiagnostics());

      expect(
        diagnostics.lastListenerConnectedAt,
        DateTime.fromMillisecondsSinceEpoch(1789000000500),
      );
    });

    test('a platform error becomes a Failure', () async {
      handler = (MethodCall call) => throw PlatformException(code: 'boom');

      final Result<CaptureDiagnostics> result =
          await buildRepository().getDiagnostics();

      expect(result.isLeft(), isTrue);
    });
  });

  group('system actions', () {
    test('requestIgnoreBatteryOptimizations forwards the call', () async {
      handler = (MethodCall call) => null;

      final Result<Unit> result =
          await buildRepository().requestIgnoreBatteryOptimizations();

      expect(result.isRight(), isTrue);
      expect(calls.single.method, 'requestIgnoreBatteryOptimizations');
    });

    test('openAutostartSettings forwards the call', () async {
      handler = (MethodCall call) => null;

      final Result<Unit> result =
          await buildRepository().openAutostartSettings();

      expect(result.isRight(), isTrue);
      expect(calls.single.method, 'openAutostartSettings');
    });

    test('a rejected system action becomes a Failure, never a crash', () async {
      handler = (MethodCall call) => throw PlatformException(
            code: 'no_activity',
            message: 'No system screen accepted the request',
          );

      final Result<Unit> battery =
          await buildRepository().requestIgnoreBatteryOptimizations();
      final Result<Unit> autostart =
          await buildRepository().openAutostartSettings();

      expect(battery.isLeft(), isTrue);
      expect(autostart.isLeft(), isTrue);
    });
  });

  group('off Android', () {
    // The feature does not exist outside Android, and that must be true at the
    // channel boundary: a probe on iOS must answer the "off" value WITHOUT
    // reaching the method channel, or a build with no native side would throw
    // instead of simply hiding the surfaces.
    setUp(() => debugDefaultTargetPlatformOverride = TargetPlatform.iOS);
    tearDown(() => debugDefaultTargetPlatformOverride = null);

    test('getDiagnostics answers empty diagnostics without calling the channel',
        () async {
      handler = (MethodCall call) => throw StateError(
            'the capture channel must not be invoked off Android',
          );

      final Result<CaptureDiagnostics> result =
          await buildRepository().getDiagnostics();

      final CaptureDiagnostics diagnostics =
          result.getOrElse((Failure f) => throw StateError(f.message));
      expect(diagnostics, const CaptureDiagnostics.empty());
      expect(diagnostics.lastCaptureAtEpochMs, isNull);
      expect(diagnostics.hasCaptureHistory, isFalse);
      expect(calls, isEmpty);
    });

    test('every capture call answers the "off" value with no channel traffic',
        () async {
      handler = (MethodCall call) => throw StateError(
            'the capture channel must not be invoked off Android',
          );
      final NotificationCaptureRepositoryImpl repository = buildRepository();

      expect(repository.isSupported, isFalse);
      expect(
        (await repository.isPermissionGranted()).getRight().toNullable(),
        isFalse,
      );
      expect(
        (await repository.getEnabledIssuers()).getRight().toNullable(),
        isEmpty,
      );
      expect(
        (await repository.getInstalledIssuerApps()).getRight().toNullable(),
        isEmpty,
      );
      expect(
        (await repository.drainPendingCaptures()).getRight().toNullable(),
        isEmpty,
      );
      expect((await repository.requestIgnoreBatteryOptimizations()).isRight(),
          isTrue);
      expect((await repository.openAutostartSettings()).isRight(), isTrue);

      expect(calls, isEmpty);
    });
  });
}
