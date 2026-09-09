import 'package:billetudo/core/error/result.dart';
import 'package:billetudo/features/capture/data/datasources/capture_method_channel_datasource.dart';
import 'package:billetudo/features/capture/data/repositories/notification_capture_repository_impl.dart';
import 'package:billetudo/features/capture/domain/entities/issuer_app.dart';
import 'package:billetudo/features/capture/domain/entities/parsed_notification.dart';
import 'package:billetudo/features/transactions/domain/entities/transaction.dart';
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
}
