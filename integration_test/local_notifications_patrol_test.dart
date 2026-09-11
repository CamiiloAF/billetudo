// Patrol e2e for the "Notificaciones" screen under Ajustes ▸ Preferencias
// (HU-08, `design-system/billetudo/pages/notificaciones.md`). Runs the real
// app — real DI graph, real go_router navigation — against a real
// emulator/simulator. No cubit or datasource is mocked.
//
// The reminder-configuration scenarios of HU-08 (setting a lead time on a
// scheduled-payment template, switching it back to "Sin recordatorio", and
// the reminder getting cancelled when its template is deleted) live in
// `scheduled_payments_patrol_test.dart` instead of here: they reuse that
// suite's existing form-filling helpers (`_createCashAccount`,
// `_enterAmount`, `_pickAccountField`, `_pickFutureDate`, ...) end to end,
// and none of them touch this screen. This file covers what is unique to the
// "Notificaciones" *settings* screen itself: the 4 per-kind switches, their
// persistence, and the permission-denied variant.
//
// Every scenario starts from `startApp`, which wipes the on-device Drift
// sqlite file first (see `support/patrol_app.dart`) so `AppSettings`/
// `ScheduledPayments` state does not leak between scenarios. The per-kind
// notification preferences this screen reads are **not** stored in Drift,
// though (`SharedPreferencesNotificationPreferences`) — same exception
// `settings_patrol_test.dart`'s own file comment documents for "Apariencia"
// (`ThemePreferenceDatasource`): a device-level `SharedPreferences` value
// `startApp` does not wipe.
//
// The **notification permission itself is also not reset by `startApp`**:
// it is a real OS-level, per-package grant (Android 13+'s
// `POST_NOTIFICATIONS`), not app state. A fresh emulator/install starts with
// it **denied** — confirmed running this very suite: `Notificaciones` opened
// on a clean API 36 emulator rendered `NotificationPermissionDeniedNotice`
// and every `ToggleField` inert, exactly like `notification_settings_
// section.dart`'s own doc comment describes, and a first attempt at a
// straight "tap to flip, expect it flipped" scenario failed for that exact
// reason (an inert row's `onTap` is `null` — see `ToggleField`). This is
// **not** a bug: `ReadNotificationPermission`/`ScheduledPaymentFormCubit.
// reminderChanged`'s own doc comment are explicit that the OS permission is
// only ever requested in context — configuring a reminder on a scheduled
// payment, never at startup or from Ajustes. So this suite now covers both
// real states instead of assuming "granted":
//  - `Notificaciones: con el permiso del sistema denegado...` exercises the
//    fresh-install default directly, no mock involved (what the brief's
//    scenario 5 asked for, achieved for real instead of via a
//    `permission_handler` channel stub — the plugin's own wire format is not
//    documented/stable enough to hardcode, unlike `file_picker`/`share_plus`
//    in `import_export_patrol_test.dart`).
//  - `Notificaciones: conceder el permiso...` grants it through the same
//    in-context path the real app uses (Pagos programados' reminder field),
//    via Patrol's own native permission-dialog automator
//    (`$.platformAutomator.mobile.grantPermissionWhenInUse`), then exercises the toggle
//    persistence scenario the brief's scenario 4 asked for.
//
// Ordering matters: the OS grant from the second scenario is **irreversible
// from inside this suite** (no in-app "revoke" action exists) and survives
// for the rest of this same install, so the denied-state scenario must run
// before it, not after. Both scenarios read the screen's actual current
// state before asserting instead of hardcoding "denied"/"granted", so a
// rerun on a device that already has the permission granted (e.g. a second
// pass without reinstalling) degrades gracefully instead of failing on a
// precondition this suite does not control.
import 'dart:async';

import 'package:billetudo/core/router/app_router.dart';
import 'package:billetudo/core/widgets/app_switch.dart';
import 'package:billetudo/core/widgets/toggle_field.dart';
import 'package:billetudo/features/scheduled_payments/presentation/widgets/scheduled_payment_reminder_field.dart';
import 'package:billetudo/features/settings/presentation/pages/notification_settings_page.dart';
import 'package:billetudo/features/settings/presentation/pages/settings_page.dart';
import 'package:billetudo/features/settings/presentation/widgets/notification_permission_denied_notice.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Same as `settings_patrol_test.dart`'s own `_openSettings`: "Más" ▸
/// "Ajustes", scrolled into view first since `MorePage`'s sliver discards
/// rows outside its cache extent.
Future<void> _openSettings(PatrolIntegrationTester $) async {
  final masTab = find.text('Más');
  for (var i = 0; i < 30 && masTab.evaluate().isEmpty; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
  }
  await $.tester.tap(masTab);
  await $.tester.pumpAndSettle();
  await $.tester.dragUntilVisible(
    find.text('Ajustes'),
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Ajustes'));
  await $.tester.pumpAndSettle();
}

Future<void> _openNotificationSettings(PatrolIntegrationTester $) async {
  await _openSettings($);
  await $.tester.dragUntilVisible(
    find.text('Notificaciones'),
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Notificaciones'));
  await $.tester.pumpAndSettle();
}

/// Reads the current [AppSwitch] rendered inside the `ToggleField` labeled
/// [label] — mirrors `settings_patrol_test.dart`'s `_envelopeModeSwitch`,
/// scoped by ancestor type since a bare `find.byType(AppSwitch)` is
/// ambiguous the moment more than one row is on screen (all 4 rows of this
/// screen are, at once, no scrolling needed on a real phone height).
AppSwitch _toggleFor(PatrolIntegrationTester $, String label) {
  final field = find.ancestor(
    of: find.text(label),
    matching: find.byType(ToggleField),
  );
  final switchFinder = find.descendant(
    of: field,
    matching: find.byType(AppSwitch),
  );
  return $.tester.widget<AppSwitch>(switchFinder);
}

/// Creates one cash account named [name] from `/cuentas` — mirrors
/// `scheduled_payments_patrol_test.dart`'s own `_createCashAccount`. A fresh
/// install has none, and `AccountGatedRoute` (`AccountGateSurface.
/// scheduledPayment`) sends a zero-account visit to Pagos programados to a
/// bridge sheet instead of the list — `_grantNotificationPermissionViaReminder
/// Flow` needs the real list/form, so it must clear that gate first.
Future<void> _createCashAccount(PatrolIntegrationTester $, String name) async {
  final context = $.tester.element(find.byType(Scaffold).first);
  GoRouter.of(context).go(AppRoutes.accounts);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Agregar cuenta'));
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Efectivo'));
  await $.tester.pumpAndSettle();
  await $.tester.enterText(find.byType(TextFormField).first, name);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.byTooltip('Guardar'));
  await $.tester.pumpAndSettle();
}

/// Grants the OS notification permission through the app's **only** real
/// in-context trigger (see file comment): pushes Pagos programados, opens a
/// fresh template form and picks a real reminder option — which is exactly
/// what `ScheduledPaymentFormCubit.reminderChanged` gates the permission
/// request behind. The form is abandoned without saving: this helper only
/// needs the OS grant, not a persisted template.
Future<void> _grantNotificationPermissionViaReminderFlow(
  PatrolIntegrationTester $,
) async {
  await _createCashAccount($, 'Efectivo');

  final context = $.tester.element(find.byType(Scaffold).first);
  unawaited(GoRouter.of(context).push(AppRoutes.scheduledPayments));
  await $.tester.pumpAndSettle();
  await dismissAutoTutorialIfShown($);

  await $.tester.tap(find.byTooltip('Nuevo pago programado'));
  await $.tester.pumpAndSettle();

  final reminderField = find.byWidgetPredicate(
    (widget) => widget is ScheduledPaymentReminderField,
  );
  await $.tester.dragUntilVisible(
    reminderField,
    find.byType(Scrollable).first,
    const Offset(0, -250),
  );
  await $.tester.pumpAndSettle();
  await $.tester.tap(reminderField);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('El día del pago'));
  await $.tester.pumpAndSettle();

  // The OS permission dialog is native UI, outside the Flutter tree — Patrol
  // drives it through its own automator, same pattern the package documents
  // for any runtime-permission prompt (location, camera, ...), not just the
  // ones it names explicitly.
  if (await $.platformAutomator.mobile.isPermissionDialogVisible()) {
    await $.platformAutomator.mobile.grantPermissionWhenInUse();
    await $.tester.pumpAndSettle();
  }

  // Abandon the form: this helper only needed the OS grant, not a saved
  // template. `_createCashAccount` above landed on `/cuentas` via `go()`
  // (replacing the stack, same as `scheduled_payments_patrol_test.dart`'s own
  // `_createCashAccount`), and this helper then *pushed* Pagos programados
  // and its form on top of that — so popping the form and the list back
  // (`ScheduledPaymentFormPage._handleClose`'s plain pop, no discard-changes
  // prompt; then the list's own "Atrás") would only land back on `/cuentas`,
  // a stacked page with no bottom tab bar of its own, not the shell's
  // "Más" tab `_openSettings` needs next. `go(AppRoutes.home)` resets to
  // that known state directly regardless of how deep the stack got.
  GoRouter.of(context).go(AppRoutes.home);
  await $.tester.pumpAndSettle();
}

void main() {
  patrolTest(
    'Notificaciones: las 4 filas de aviso están presentes',
    ($) async {
      await startApp($);
      await _openNotificationSettings($);

      expect(find.byType(NotificationSettingsPage), findsOneWidget);
      expect(find.text('Recordatorios de pago'), findsOneWidget);
      expect(find.text('Cobros próximos'), findsOneWidget);
      expect(find.text('Pagos por confirmar'), findsOneWidget);
      expect(find.text('Hitos de metas'), findsOneWidget);
      expect(find.byType(ToggleField), findsNWidgets(4));
    },
  );

  patrolTest(
    'Notificaciones: con el permiso del sistema denegado (estado real de '
    'una instalación nueva), la nota de aviso aparece y las filas quedan '
    'inertes — tocarlas no cambia nada',
    ($) async {
      await startApp($);
      await _openNotificationSettings($);

      // A fresh install really does start with the OS permission denied on
      // modern Android (confirmed running this suite, see file comment) —
      // but this suite does not control that precondition across reruns on
      // the same device (once granted below, it stays granted). Assert the
      // real state instead of assuming it, and skip gracefully if a prior
      // run already granted it here.
      final deniedNoticeVisible =
          find.byType(NotificationPermissionDeniedNotice).evaluate().isNotEmpty;
      if (!deniedNoticeVisible) {
        return;
      }

      expect(
        find.text('Tu teléfono tiene las notificaciones apagadas'),
        findsOneWidget,
      );

      const label = 'Hitos de metas';
      final before = _toggleFor($, label);
      expect(before.inert, isTrue);

      // Tapping an inert row must be a true no-op — `ToggleField`'s own
      // `onTap` is `null` while inert, never a tap that silently discards
      // the change.
      await $.tester.tap(find.text(label));
      await $.tester.pumpAndSettle();
      expect(_toggleFor($, label).value, before.value);
      expect(_toggleFor($, label).inert, isTrue);
    },
  );

  patrolTest(
    'Notificaciones: conceder el permiso (vía el flujo real de Pagos '
    'programados) deja las filas activas, y apagar una persiste al salir '
    'de la pantalla y volver a entrar',
    ($) async {
      await startApp($);
      await _grantNotificationPermissionViaReminderFlow($);
      await _openNotificationSettings($);

      expect(find.byType(NotificationPermissionDeniedNotice), findsNothing);

      const label = 'Hitos de metas';
      // Read whatever this run's real, on-device `SharedPreferences` value
      // is instead of assuming the fresh-install "on" default — this
      // suite's own scenarios above may have already run in this same
      // process and shared_preferences is not reset by `startApp`.
      final initial = _toggleFor($, label).value;
      expect(_toggleFor($, label).inert, isFalse);

      await $.tester.tap(find.text(label));
      await $.tester.pumpAndSettle();
      expect(_toggleFor($, label).value, !initial);

      // Leaves Notificaciones (back to Ajustes), then back into it: proves
      // the flip round-tripped through the real `SharedPreferences` write —
      // `NotificationSettingsCubit.start()` re-reads it from scratch on
      // every fresh visit to this route, it does not carry in-memory state
      // across pushes.
      await $.tester.tap(find.byTooltip('Atrás'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Notificaciones'));
      await $.tester.pumpAndSettle();

      expect(_toggleFor($, label).value, !initial);

      // Leaves the toggle back exactly as this scenario found it, so a
      // rerun of this same suite (same device, same shared_preferences
      // file) starts this scenario from the same state again.
      await $.tester.tap(find.text(label));
      await $.tester.pumpAndSettle();
      expect(_toggleFor($, label).value, initial);
    },
  );

  patrolTest(
    'Notificaciones se alcanza desde Ajustes ▸ Preferencias',
    ($) async {
      await startApp($);
      await _openSettings($);
      expect(find.byType(SettingsPage), findsOneWidget);

      await $.tester.dragUntilVisible(
        find.text('Notificaciones'),
        find.byType(Scrollable).first,
        const Offset(0, -250),
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Notificaciones'));
      await $.tester.pumpAndSettle();

      expect(find.byType(NotificationSettingsPage), findsOneWidget);
      await $.tester.tap(find.byTooltip('Atrás'));
      await $.tester.pumpAndSettle();
      expect(find.byType(SettingsPage), findsOneWidget);
    },
  );
}
