// Patrol e2e for the home-screen widget's pure shortcuts
// (`docs/requirements/fase-2/20-widget-captura-rapida.md`, HU-01/HU-02).
// Runs the real app — real DI graph, real on-device Drift database, real
// go_router navigation, the real `CaptureShortcutCubit`/
// `CaptureShortcutListener` pair — with a single deliberate exception: the
// platform-channel boundary itself
// (`com.billetudo.app/capture_shortcuts`, `CaptureShortcutChannelDatasource`)
// is answered by a mock handler instead of a real Android/iOS home-screen
// widget tap.
//
// That boundary is the correct place to stand in this suite: nothing this
// side of it — `QuickCaptureWidgetBridge.kt`'s Kotlin, `MainActivity.kt`'s
// `configureFlutterEngine`/`onNewIntent`, the equivalent Swift side — is
// Dart, so no Patrol scenario running against the Flutter engine could ever
// exercise it; only a real on-device widget tap can, which is exactly the
// manual verification called out at the end of this file's suite in the
// QA report. What *is* Dart, and therefore what this suite owns, is
// everything from `CaptureShortcutChannelDatasource.initialShortcutId()`/
// `shortcutIds` onward: does a cold-start shortcut actually open the right
// form before the user sees Home, does a hot tap push on top of whatever is
// already showing, and does an id this build doesn't recognise degrade to
// "nothing happens" instead of crashing. The same mocking technique is
// already used one layer down in
// `test/features/capture/data/capture_shortcut_repository_impl_test.dart`
// (unit, no engine) and one layer up in `import_export_patrol_test.dart`'s
// `_mockFilePicker`/`_mockShareChannel` (this same kind of full-app Patrol
// suite, a different plugin boundary) — this file is the same idea applied
// to `capture`'s own channel.
//
// Every scenario seeds one cash account directly through `AppDatabase`
// before the first frame (via `startApp`'s `beforeFirstFrame` hook, added by
// this suite in `support/patrol_app.dart`): the home-screen widget's
// destinations are all `AccountGatedRoute`-wrapped
// (`docs/requirements/fase-1/15-gate-cuenta.md`), and on a fresh install
// with no accounts a shortcut would land on `AccountGateBridgeSheet`
// instead of the movement form, which is `gate_cuenta_patrol_test.dart`'s
// own scope, not this one's. Seeding has to happen before the first pump,
// not after `startApp` returns: `CaptureShortcutCubit.start()` runs as part
// of `BilletudoApp`'s very first build, so a cold-start shortcut is already
// consumed by the time a post-`startApp` seed would run.
import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Mirrors `QuickCaptureWidgetBridge.kt`'s channel name and
/// `CaptureShortcutChannelDatasource`'s `@Named('captureShortcutChannel')`
/// registration (`register_module.dart`'s own doc comment: "Named so tests
/// can swap it for a channel backed by a fake handler").
const String _channelName = 'com.billetudo.app/capture_shortcuts';
const MethodChannel _shortcutChannel = MethodChannel(_channelName);

/// Stands in for the native side answering Dart's outbound
/// `getInitialShortcut` call — the cold-start half of the contract.
/// `shortcutId` is `null` for what a normal launcher-icon launch reports.
///
/// Must be installed before `startApp` pumps the widget tree:
/// `CaptureShortcutCubit.start()` asks for the initial shortcut as part of
/// `BilletudoApp`'s first build, so setting this up any later would miss it
/// — same ordering constraint documented on `startApp`'s
/// `beforeFirstFrame` parameter.
void _mockInitialShortcut(String? shortcutId) {
  TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .setMockMethodCallHandler(_shortcutChannel, (call) async {
    if (call.method == 'getInitialShortcut') {
      return shortcutId;
    }
    return null;
  });
}

/// Stands in for a warm tap on the widget — the `onNewIntent`/`singleTop`
/// half of the contract. Delivers the id directly to whatever handler
/// `CaptureShortcutChannelDatasource`'s constructor installed on the real
/// channel (`_channel.setMethodCallHandler`), exactly like
/// `QuickCaptureWidgetBridge.deliver` invoking `channel.invokeMethod` from
/// the native side would once the engine (and therefore Dart's listener) is
/// already up.
Future<void> _simulateHotShortcutTap(
  PatrolIntegrationTester $,
  String shortcutId,
) async {
  final data = _shortcutChannel.codec.encodeMethodCall(
    MethodCall('onShortcut', shortcutId),
  );
  await TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
      .handlePlatformMessage(_channelName, data, (_) {});
  await $.tester.pumpAndSettle();
}

/// One cash account, straight through the real `AppDatabase` — same
/// convention as `reports_patrol_test.dart`'s `_seedOneMonthOfData`. Only
/// there to clear `AccountGatedRoute`'s requirement; this suite never reads
/// the account back.
Future<void> _seedCashAccount() async {
  final db = getIt<AppDatabase>();
  await db.into(db.accounts).insert(
        AccountsCompanion.insert(
          name: 'Cuenta seed',
          type: AccountType.cash,
          currency: 'COP',
        ),
      );
}

void main() {
  patrolTest(
    'HU-01: a cold start with the widget\'s "Gasto" shortcut already '
    'pending opens the expense form directly, without Home ever appearing',
    ($) async {
      _mockInitialShortcut('expense');
      addTearDown(() => _mockInitialShortcut(null));

      await startApp($, beforeFirstFrame: _seedCashAccount);

      // The router's own initial location is still Home
      // (`BilletudoApp`'s default), but `CaptureShortcutListener` pushes the
      // form on top before the very first settle — same assertion style as
      // `gate_cuenta_patrol_test.dart`'s HU-01 scenario for "no bounce back
      // to Home".
      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text('Nuevo gasto'), findsOneWidget);
    },
  );

  patrolTest(
    'HU-02: a cold start with the widget\'s "Ingreso" shortcut opens the '
    'income form directly',
    ($) async {
      _mockInitialShortcut('income');
      addTearDown(() => _mockInitialShortcut(null));

      await startApp($, beforeFirstFrame: _seedCashAccount);

      expect(find.byType(HomePage), findsNothing);
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text('Nuevo ingreso'), findsOneWidget);
    },
  );

  patrolTest(
    // No literal "/" in this name: AndroidTestOrchestrator uses the test's
    // display name to build an output filename, and a "/" is read as a path
    // separator — it crashes the orchestrator process outright (not just
    // this test), taking every scenario after it down with it.
    'HU-01 and HU-02: a shortcut tapped while the app is already running '
    '(onNewIntent, singleTop) pushes the right capture form on top of Home',
    ($) async {
      // A normal launch: nothing pending at cold start.
      _mockInitialShortcut(null);
      addTearDown(() => _mockInitialShortcut(null));

      await startApp($, beforeFirstFrame: _seedCashAccount);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TransactionFormPage), findsNothing);

      await _simulateHotShortcutTap($, 'income');

      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text('Nuevo ingreso'), findsOneWidget);
    },
  );

  patrolTest(
    'a shortcut id this build does not recognise (older app, newer widget) '
    'never navigates and never crashes, cold or hot',
    ($) async {
      // Cold start: an id outside `CaptureShortcut.values`
      // (`CaptureShortcut.fromId` returns `null` for it, same fixture id
      // used by `capture_shortcut_repository_impl_test.dart`'s "an unknown
      // id is dropped instead of failing").
      _mockInitialShortcut('receipt_photo');
      addTearDown(() => _mockInitialShortcut(null));

      await startApp($, beforeFirstFrame: _seedCashAccount);

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TransactionFormPage), findsNothing);

      // Hot tap with the same kind of unrecognised id: still nothing to
      // navigate to, still on Home.
      await _simulateHotShortcutTap($, 'receipt_photo');

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(TransactionFormPage), findsNothing);
    },
  );
}
