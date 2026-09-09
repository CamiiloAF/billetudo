// Patrol e2e for the bank-notification capture inbox (Fase 2: `Bk8zW` Avisos
// centre, the Movimientos ghost row, the dispatch to the ordinary
// transaction form, and the permission/issuer activation screens). Runs the
// real app — real DI graph, real on-device Drift database, real go_router
// navigation. No repository is mocked; the one exception is documented
// below.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak state
// into each other even though they share one app process.
//
// Nothing in Patrol can fire a real Android notification (that is
// `BilletudoNotificationListenerService`'s job, native code on another
// branch) — every scenario below seeds `PendingCaptures` rows directly
// against the same real on-device Drift database the app itself reads from,
// same pattern `categories_patrol_test.dart`/`debts_patrol_test.dart` already
// use for `Transactions`. A capture never appears without at least one
// issuer switched ON in real use, so every scenario also flips that
// preference through `SetIssuerEnabled` (a domain use case, not a mock) right
// after seeding — this is a legitimate precondition, not a workaround.
//
// The one exception: the permission-activation scenario (HU-02, "activación
// del permiso") needs the *system* notification-listener permission granted,
// which nothing in Patrol can toggle (it lives outside the app, in Android
// Settings, and requires a human tap). `CaptureMethodChannelDatasource` talks
// to the native side through a single named `MethodChannel`
// (`com.billetudo.app/capture`), and — same technique Flutter's own plugin
// tests use for a platform channel with no fake in place — a
// `TestDefaultBinaryMessengerBinding.setMockMethodCallHandler` on that exact
// channel name intercepts the call on the Dart side before it ever reaches
// the (real, but not-yet-granted) native implementation. This only exercises
// the Flutter-side wiring of HU-02/HU-09, never the native permission dialog
// itself — a real device run of that dialog is a manual QA item, not a
// Patrol one (see the "Verificaciones manuales" note in this file's report).
// This mock only reflects Android's own answer (`isSupported` on non-Android
// is hardcoded `false` in the datasource), so this one scenario only proves
// something running on an Android device/emulator.
import 'dart:async';

import 'package:billetudo/core/database/app_database.dart';
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/utils/money_formatter.dart';
import 'package:billetudo/features/capture/data/datasources/capture_method_channel_datasource.dart';
import 'package:billetudo/features/capture/domain/usecases/set_issuer_enabled.dart';
import 'package:billetudo/features/transactions/presentation/pages/transaction_form_page.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

const _money = MoneyFormatter();

String _formatted(int amountMinor) =>
    _money.formatSymbol(amountMinor, currencyCode: 'COP');

/// Seeds one cash account directly against the real Drift database.
Future<Account> _seedAccount(AppDatabase db, String name) =>
    db.into(db.accounts).insertReturning(
          AccountsCompanion.insert(
            name: name,
            type: AccountType.cash,
            currency: 'COP',
          ),
        );

Future<Category> _seedCategory(AppDatabase db, String name) =>
    db.into(db.categories).insertReturning(
          CategoriesCompanion.insert(name: name, kind: CategoryKind.expense),
        );

/// Seeds one `PendingCaptures` row — the deterministic stand-in for a real
/// bank notification (see file header). `sourcePackage` defaults to Nu's,
/// the same one `_enableNu` below switches on.
Future<PendingCapture> _seedCapture(
  AppDatabase db, {
  required int amountMinor,
  String? merchant,
  String sourcePackage = 'com.nu.production',
  EntryType entryType = EntryType.expense,
  DateTime? postedAt,
  String? suggestedAccountId,
  String? suggestedCategoryId,
}) =>
    db.into(db.pendingCaptures).insertReturning(
          PendingCapturesCompanion.insert(
            source: TxSource.notification,
            sourcePackage: sourcePackage,
            postedAt: postedAt ?? DateTime.now(),
            amountMinor: amountMinor,
            currency: 'COP',
            entryType: entryType,
            merchantRaw: Value(merchant),
            suggestedAccountId: Value(suggestedAccountId),
            suggestedCategoryId: Value(suggestedCategoryId),
          ),
        );

/// Switches Nu's preference-side listening flag ON (`IssuerSettingsRepository`,
/// no method channel involved) — the real precondition for a capture to be
/// legible in the Avisos centre, per `NoticesState.hasEnabledIssuers`. Every
/// scenario that seeds a capture calls this first so the empty state reads
/// "Todo al día" once the inbox empties, not "sin emisores".
Future<void> _enableNu() =>
    getIt<SetIssuerEnabled>()(packageName: 'com.nu.production', enabled: true);

/// Taps Home's bell (`captureBellTooltip`, "Avisos") to open the Avisos
/// centre. Assumes Home is already on screen — true right after `startApp`,
/// whose default location is Home.
Future<void> _openNotices(PatrolIntegrationTester $) async {
  await $.tester.tap(find.byTooltip('Avisos'));
  await $.tester.pumpAndSettle();
}

/// Pumps frames until [finder] matches at least one widget, or a frame budget
/// runs out — needed for content behind an async Drift stream, same pattern
/// `home_patrol_test.dart`'s own `_pumpUntilFound` documents.
Future<void> _pumpUntilFound(
  PatrolIntegrationTester $,
  Finder finder, {
  int maxFrames = 30,
}) async {
  for (var i = 0; i < maxFrames && finder.evaluate().isEmpty; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
  }
  if (finder.evaluate().isEmpty) {
    throw TestFailure(
      'Timed out after ${maxFrames * 100}ms waiting for $finder',
    );
  }
}

/// Waits (bounded, small increments) for [text] to appear — never
/// `pumpAndSettle()` on a `SnackBar`: its own auto-dismiss timer keeps it
/// "animating" until it fires, so `pumpAndSettle()` would fast-forward
/// through its entire visible window first. Same reasoning/pattern as
/// `scheduled_payments_patrol_test.dart`'s `_expectSnackbar`.
Future<void> _expectSnackbar(PatrolIntegrationTester $, String text) async {
  final finder = find.text(text);
  for (var attempt = 0; attempt < 15 && finder.evaluate().isEmpty; attempt++) {
    await $.tester.pump(const Duration(milliseconds: 200));
  }
  expect(finder, findsOneWidget);
}

/// Fakes `com.billetudo.app/capture` (see file header) for the one scenario
/// that needs the system permission "granted" to reach the issuer switches.
/// `installed` seeds what `getInstalledIssuerApps` answers; `enabled` tracks
/// what `setEnabledIssuers` writes, exactly like the real native side would.
class _FakeCaptureChannel {
  _FakeCaptureChannel();

  static const _channel =
      MethodChannel(CaptureMethodChannelDatasource.channelName);

  final List<Map<String, Object?>> installed = [
    {
      'issuerId': 'nu',
      'displayName': 'Nu',
      'packageName': 'com.nu.production',
      'installed': true,
    },
    {
      'issuerId': 'nequi',
      'displayName': 'Nequi',
      'packageName': 'com.nequi.MobileApp',
      'installed': true,
    },
  ];

  final Set<String> enabled = <String>{};

  void install() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, _handle);
  }

  void uninstall() {
    TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger
        .setMockMethodCallHandler(_channel, null);
  }

  Future<Object?> _handle(MethodCall call) async {
    switch (call.method) {
      case 'isPermissionGranted':
        return true;
      case 'getInstalledIssuerApps':
        return [
          for (final app in installed)
            {...app, 'enabled': enabled.contains(app['issuerId'])},
        ];
      case 'getEnabledIssuers':
        return enabled.toList();
      case 'setEnabledIssuers':
        final args = call.arguments as Map<Object?, Object?>;
        final ids = (args['issuerIds'] as List<Object?>).cast<String>();
        enabled
          ..clear()
          ..addAll(ids);
        return null;
      case 'drainPendingCaptures':
        return <Object?>[];
      case 'openPermissionSettings':
        return null;
      default:
        return null;
    }
  }
}

void main() {
  patrolTest(
    'Flujo de despacho feliz: tocar una captura pendiente abre el '
    'formulario pre-llenado; confirmarla la retira de la bandeja y deja el '
    'movimiento en Movimientos con source=notification',
    ($) async {
      await startApp($);
      await _enableNu();
      final db = getIt<AppDatabase>();
      final account = await _seedAccount(db, 'Nu');
      final category = await _seedCategory(db, 'Mercado');
      final capture = await _seedCapture(
        db,
        amountMinor: 50000, // $500 COP
        merchant: 'Exito Poblado',
        suggestedAccountId: account.id,
        suggestedCategoryId: category.id,
      );

      await _openNotices($);
      await _pumpUntilFound($, find.text('Exito Poblado'));
      expect(find.text('Exito Poblado'), findsOneWidget);

      await $.tester.tap(find.text('Exito Poblado'));
      await $.tester.pumpAndSettle();

      // The ordinary transaction form, pre-filled from the capture (HU-05) —
      // never a parallel confirmation surface of its own.
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text(_formatted(50000)), findsOneWidget);

      await $.tester.tap(find.byTooltip('Guardar'));
      await $.tester.pumpAndSettle();

      // Back on the Avisos centre: the form popped and the capture is gone
      // from the inbox — with Nu on and nothing else pending, the empty
      // state reads "Todo al día", not "sin emisores".
      expect(find.byType(TransactionFormPage), findsNothing);
      await _pumpUntilFound($, find.text('Todo al día'));
      expect(find.text('Exito Poblado'), findsNothing);

      // The capture became a real `Transactions` row (`source=notification`)
      // and the capture itself is now `confirmed`, pointing at it — never a
      // second capture confirmed twice on a double tap.
      final rows = await db.select(db.transactions).get();
      expect(rows, hasLength(1));
      expect(rows.single.source, TxSource.notification);
      expect(rows.single.amountMinor, 50000);
      expect(rows.single.accountId, account.id);
      expect(rows.single.categoryId, category.id);

      final refreshed = await (db.select(db.pendingCaptures)
            ..where((t) => t.id.equals(capture.id)))
          .getSingle();
      expect(refreshed.status, CaptureStatus.confirmed);
      expect(refreshed.transactionId, rows.single.id);
    },
  );

  patrolTest(
    'Fila fantasma en Movimientos: una captura pendiente aparece fijada '
    'arriba del listado y tocarla abre el mismo flujo de despacho',
    ($) async {
      await startApp($);
      await _enableNu();
      final db = getIt<AppDatabase>();
      final account = await _seedAccount(db, 'Nu');
      await _seedCapture(
        db,
        amountMinor: 32000,
        merchant: 'Rappi',
        suggestedAccountId: account.id,
      );

      // `push`, not `go`: `go` on a `StatefulShellRoute` branch route can
      // trip a `Navigator.dispose`/`!_debugLocked` assertion (verified on a
      // real emulator, see `transactions_patrol_test.dart`'s own
      // `_goToTransactions` doc comment) — `push` does not.
      final context = $.tester.element(find.byType(Scaffold).first);
      unawaited(GoRouter.of(context).push(AppRoutes.transactions));
      await $.tester.pumpAndSettle();

      // The ghost block (`vNjim`): its own title, count and the capture's
      // card, all above the (empty, here) day-grouped list — nothing else on
      // this fresh install could produce a "Rappi" row otherwise.
      //
      // Generous 15s budget (vs. the 3s default): this route builds
      // `PendingCapturesCubit`, `TransactionsListCubit` and
      // `BalanceCarouselCubit` together right after a cold `push` into the
      // Movimientos branch, and `PendingCapturesCubit` alone combines three
      // freshly-constructed Drift streams — slow on a software emulator.
      await _pumpUntilFound($, find.text('Rappi'), maxFrames: 150);
      expect(find.text('Pendientes de confirmar'), findsOneWidget);
      expect(find.text('Rappi'), findsOneWidget);

      await $.tester.tap(find.text('Rappi'));
      await $.tester.pumpAndSettle();

      // Same dispatch destination as the Avisos centre's own card — the
      // ordinary, pre-filled transaction form, never a parallel surface.
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text(_formatted(32000)), findsOneWidget);
    },
  );

  patrolTest(
    'Estado vacío: sin capturas ni avisos, el Centro de avisos muestra '
    '"Todo al día" sin CTA de acción',
    ($) async {
      await startApp($);
      await _enableNu();

      await _openNotices($);
      await _pumpUntilFound($, find.text('Todo al día'));

      expect(find.text('Todo al día'), findsOneWidget);
      // No action CTA on this branch of the empty state — only the "sin
      // emisores" branch offers one (`captureNoIssuersCta`, "Elegir apps").
      expect(find.text('Elegir apps'), findsNothing);
    },
  );

  patrolTest(
    'Descartar con deshacer: tocar "Es la misma" descarta la captura y '
    'deshacer desde el snackbar la deja de nuevo en la bandeja',
    ($) async {
      await startApp($);
      await _enableNu();
      final db = getIt<AppDatabase>();
      final account = await _seedAccount(db, 'Nu');
      final now = DateTime.now();

      // A transaction the user already typed by hand, same amount/currency/
      // type and inside the ±48h "posible duplicado" window
      // (`FindDuplicateCandidates.transactionWindow`) — the only path today
      // that reaches a discard action (see file header: `PendingCaptureCard`
      // itself carries no discard affordance, only `DuplicateCompareCard`
      // does).
      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: account.id,
              amountMinor: 27000,
              currency: 'COP',
              type: EntryType.expense,
              date: now,
              countsInBudget: const Value(false),
            ),
          );
      await _seedCapture(
        db,
        amountMinor: 27000,
        merchant: 'Rappi',
        postedAt: now,
        suggestedAccountId: account.id,
      );

      await _openNotices($);
      await _pumpUntilFound($, find.text('Posible duplicado'));
      expect(find.text('Es la misma'), findsOneWidget);

      await $.tester.tap(find.text('Es la misma'));
      await $.tester.pumpAndSettle();

      await _expectSnackbar($, 'Captura descartada');
      // The card is gone from the inbox the moment it is discarded, before
      // the undo is even tapped.
      expect(find.text('Rappi'), findsNothing);

      await $.tester.tap(find.text('Deshacer'));
      await $.tester.pump(const Duration(milliseconds: 300));
      await $.tester.pumpAndSettle();

      // Restored: back in the inbox as an ordinary pending capture, still
      // flagged as a possible duplicate against the same transaction.
      await _pumpUntilFound($, find.text('Rappi'));
      expect(find.text('Rappi'), findsOneWidget);
      expect(find.text('Posible duplicado'), findsOneWidget);
    },
  );

  patrolTest(
    'Duplicado — la rama "Es otra compra" continúa al formulario pre-llenado '
    'sin descartar la captura',
    ($) async {
      await startApp($);
      await _enableNu();
      final db = getIt<AppDatabase>();
      final account = await _seedAccount(db, 'Nu');
      final now = DateTime.now();

      await db.into(db.transactions).insert(
            TransactionsCompanion.insert(
              accountId: account.id,
              amountMinor: 19000,
              currency: 'COP',
              type: EntryType.expense,
              date: now,
              countsInBudget: const Value(false),
            ),
          );
      await _seedCapture(
        db,
        amountMinor: 19000,
        merchant: 'Panaderia San Jose',
        postedAt: now,
        suggestedAccountId: account.id,
      );

      await _openNotices($);
      await _pumpUntilFound($, find.text('Posible duplicado'));
      expect(find.text('Es otra compra'), findsOneWidget);

      await $.tester.tap(find.text('Es otra compra'));
      await $.tester.pumpAndSettle();

      // Continues to the ordinary pre-filled form — exactly the happy-path
      // destination — and nothing was discarded: the capture stays
      // `pending` in the database (confirming it is this scenario's own job,
      // not asserted twice here).
      expect(find.byType(TransactionFormPage), findsOneWidget);
      expect(find.text(_formatted(19000)), findsOneWidget);

      final stillPending = await db.select(db.pendingCaptures).get();
      expect(stillPending, hasLength(1));
      expect(stillPending.single.status, CaptureStatus.pending);
    },
  );

  patrolTest(
    'Activación del permiso: desde el estado sin emisores activos, el CTA '
    'lleva al catálogo de apps y activar un switch cambia el conteo visible',
    ($) async {
      // See file header: fakes the system permission as already granted
      // (Patrol cannot drive Android's own consent screen), so the catalog
      // itself — HU-02's actual subject — is reachable deterministically.
      final channel = _FakeCaptureChannel()..install();
      addTearDown(channel.uninstall);

      await startApp($);
      // No `_enableNu()` here on purpose: this scenario starts from the
      // "sin emisores" branch of the empty state, which only shows when
      // nothing is switched on yet.

      await _openNotices($);
      await _pumpUntilFound($, find.text('Elegir apps'));
      expect(find.text('Todavía no escuchamos ninguna app'), findsOneWidget);

      await $.tester.tap(find.text('Elegir apps'));
      await $.tester.pumpAndSettle();

      // The permission reads granted (faked), so this lands directly on the
      // issuer catalog (`qrDFE`), not the explainer.
      await _pumpUntilFound($, find.text('Ninguna activa todavía'));
      expect(find.text('Nu'), findsOneWidget);
      expect(find.text('Nequi'), findsOneWidget);

      await $.tester.tap(find.text('Nu'));
      await $.tester.pumpAndSettle();

      // The count updates from the re-read the cubit does after every
      // toggle (`CaptureIssuersCubit.setEnabled`), never an optimistic
      // patch — real round trip through the fake channel.
      expect(find.text('1 de 2 activas'), findsOneWidget);
      expect(find.text('Ninguna activa todavía'), findsNothing);
    },
  );
}
