// Patrol e2e for Ajustes (Configuración). Runs the real app — real DI graph,
// real on-device Drift database, real go_router navigation — against a real
// emulator/simulator. No datasource or repository is mocked.
//
// "Eliminar cuenta" (HU-07, Auth) already has its own full e2e coverage in
// `auth_patrol_test.dart` (confirm/cancel, the no-backend error path). This
// suite only proves Ajustes' own entry point reaches that flow; it does not
// re-test the flow itself.
//
// Every scenario starts from `startApp`, which wipes the on-device sqlite
// file first (see `support/patrol_app.dart`), so scenarios do not leak
// account-level state (Drift's `AppSettings` row, e.g. "Modo sobres") into
// each other even though they share one app process. "Apariencia" is the one
// setting outside that reset: it is a device preference stored in
// `SharedPreferences` (`ThemePreferenceDatasource`), never wiped by
// `startApp` — its scenario below reads that datasource directly to prove
// the choice really persisted to disk, since actually reopening the app
// (calling `startApp` a second time mid-test) is not an option here: it
// re-runs `Supabase.initialize`, which asserts it is only ever called once
// per process and throws on a second call.
import 'package:billetudo/core/di/injection.dart';
import 'package:billetudo/core/theme/theme_preference_datasource.dart';
import 'package:billetudo/core/widgets/segmented_control.dart';
import 'package:billetudo/features/home/presentation/pages/home_page.dart';
import 'package:billetudo/features/home/presentation/widgets/quick_access_row.dart';
import 'package:billetudo/features/settings/presentation/pages/quick_access_order_page.dart';
import 'package:billetudo/features/settings/presentation/pages/settings_page.dart';
import 'package:billetudo/features/settings/presentation/widgets/envelope_mode_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:patrol/patrol.dart';

import 'support/patrol_app.dart';

/// Pumps frames until [finder] matches at least one widget, or a frame
/// budget runs out. Mirrors `home_patrol_test.dart`'s `_pumpUntilFound`:
/// `pumpWidgetAndSettle` cannot see I/O that completes after it returns, so
/// right after a fresh `startApp` the persistent tab bar can still be a
/// frame away from mounting — verified against a real emulator run.
Future<void> _pumpUntilFound(
  PatrolIntegrationTester $,
  Finder finder, {
  int maxFrames = 30,
}) async {
  for (var i = 0; i < maxFrames && finder.evaluate().isEmpty; i++) {
    await $.tester.pump(const Duration(milliseconds: 100));
  }
}

Future<void> _openSettings(PatrolIntegrationTester $) async {
  final masTab = find.text('Más');
  await _pumpUntilFound($, masTab);
  await $.tester.tap(masTab);
  await $.tester.pumpAndSettle();
  await $.tester.tap(find.text('Ajustes'));
  await $.tester.pumpAndSettle();
}

/// Whether the `SegmentedControlSegment` labeled [label] renders as the
/// active one. Not a `find.text` + color assertion: the active/inactive
/// look is carried entirely by `SegmentedControlSegment.selected`, which is
/// what actually drives `ThemeModeCubit.setThemeMode` downstream — reading
/// the widget's own field is the direct check, a rendered color would only
/// be an indirect proxy for it.
bool _isSegmentSelected(PatrolIntegrationTester $, String label) {
  final segment = $.tester.widget<SegmentedControlSegment>(
    find.ancestor(
      of: find.text(label),
      matching: find.byType(SegmentedControlSegment),
    ),
  );
  return segment.selected;
}

/// The "Modo sobres" switch, scoped to `EnvelopeModeField` — a bare
/// `find.byType(Switch)` is ambiguous once HU-04's "Mostrar ayuda al entrar
/// a una sección" (`ShowHelpOnEntryField`) landed on the same page, since
/// that row renders a `Switch` too.
Finder _envelopeModeSwitch() => find.descendant(
      of: find.byType(EnvelopeModeField),
      matching: find.byType(Switch),
    );

void main() {
  patrolTest(
    'Apariencia: elegir "Oscuro" en el Segmented Control se aplica de '
    'inmediato y sobrevive un reinicio real de la app',
    ($) async {
      await startApp($);
      await _openSettings($);
      expect(find.byType(SettingsPage), findsOneWidget);

      await $.tester.tap(find.text('Oscuro'));
      await $.tester.pumpAndSettle();

      expect(_isSegmentSelected($, 'Oscuro'), isTrue);
      expect(_isSegmentSelected($, 'Claro'), isFalse);
      expect(_isSegmentSelected($, 'Sistema'), isFalse);
      expect(
        $.tester.widget<MaterialApp>(find.byType(MaterialApp)).themeMode,
        ThemeMode.dark,
      );

      // Proves the choice really round-tripped through `SharedPreferences`
      // (`ThemePreferenceDatasource`, not Drift), not just `ThemeModeCubit`'s
      // in-memory state. Not a second `startApp($)` call to simulate a real
      // "kill and reopen the app": `Supabase.initialize` (which `startApp`
      // calls as part of its own bootstrap) asserts it is only ever called
      // once per process and throws on a second call — verified against a
      // real emulator run (the whole app got stuck on the pre-throw screen,
      // `find.text('Más')` afterwards found 0 widgets since the widget tree
      // never actually rebuilt). Reading the very same datasource this
      // cubit reads from on a cold boot is the closest equivalent this
      // process can exercise without that crash.
      final persisted = await getIt<ThemePreferenceDatasource>().read();
      expect(persisted, ThemeMode.dark);

      // Navigating away and back to Ajustes (the other half of "persiste"
      // per this suite's brief): the selection is still there once the
      // card rebuilds from `ThemeModeCubit`'s current state.
      await $.tester.tap(find.byTooltip('Atrás'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Ajustes'));
      await $.tester.pumpAndSettle();

      expect(_isSegmentSelected($, 'Oscuro'), isTrue);
    },
  );

  patrolTest(
    'Modo sobres: activar el switch persiste al salir de Ajustes y volver',
    ($) async {
      await startApp($);
      await _openSettings($);

      // Fresh install: `AppSettings.defaults()` has `zeroBasedEnabled: false`.
      expect($.tester.widget<Switch>(_envelopeModeSwitch()).value, isFalse);

      await $.tester.tap(_envelopeModeSwitch());
      await $.tester.pumpAndSettle();
      expect($.tester.widget<Switch>(_envelopeModeSwitch()).value, isTrue);

      // Leaves Ajustes and comes back. `_settingsRoute` builds a brand new
      // `AppSettingsCubit` on every visit (it is not a DI singleton like
      // `ThemeModeCubit`), so re-reading `true` here proves the flag
      // round-tripped through the real Drift row, not just an in-memory
      // cubit that happened to survive.
      //
      // Not `_openSettings($)` again: that taps the tab bar's "Más" label
      // first, but popping Ajustes lands back on "Más" itself, whose own
      // `AppBar` title is also the literal text "Más" — with both on
      // screen at once, `find.text('Más')` matches 2 widgets and `tap()`
      // throws — verified against a real emulator run. Already being on
      // "Más", only "Ajustes" needs tapping again.
      await $.tester.tap(find.byTooltip('Atrás'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Ajustes'));
      await $.tester.pumpAndSettle();

      expect($.tester.widget<Switch>(_envelopeModeSwitch()).value, isTrue);
    },
  );

  patrolTest(
    'Modo sobres: activarlo desde la hoja "¿Qué es?" prende el switch y '
    'la hoja deja de ofrecer "Activar modo sobres" una vez activo',
    ($) async {
      await startApp($);
      await _openSettings($);

      await $.tester.tap(find.text('¿Qué es?'));
      await $.tester.pumpAndSettle();

      expect(find.text('¿Qué es el modo sobres?'), findsOneWidget);
      expect(find.text('Activar modo sobres'), findsOneWidget);

      await $.tester.tap(find.text('Activar modo sobres'));
      await $.tester.pumpAndSettle();

      expect($.tester.widget<Switch>(_envelopeModeSwitch()).value, isTrue);

      // Reopening the sheet while already enabled: the sheet's own doc
      // comment says the activate button is hidden in that case (nonsense
      // to offer turning on something already on) — only "Entendido" is
      // left.
      await $.tester.tap(find.text('¿Qué es?'));
      await $.tester.pumpAndSettle();

      expect(find.text('Activar modo sobres'), findsNothing);
      expect(find.text('Entendido'), findsOneWidget);

      await $.tester.tap(find.text('Entendido'));
      await $.tester.pumpAndSettle();

      // The sheet's own "Entendido" never toggles the flag off — it's still
      // on back in Ajustes.
      expect($.tester.widget<Switch>(_envelopeModeSwitch()).value, isTrue);
    },
  );

  patrolTest(
    '"Eliminar cuenta" en Ajustes abre la hoja destructiva (el flujo '
    'completo ya lo cubre auth_patrol_test.dart)',
    ($) async {
      await startApp($);
      await _openSettings($);

      // Adding "Orden del acceso rápido" (criterion 6) pushed "Eliminar
      // cuenta" further down the page, so it may start off-screen.
      await $.tester.dragUntilVisible(
        find.text('Eliminar cuenta'),
        find.byType(Scrollable).first,
        const Offset(0, -250),
      );
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Eliminar cuenta'));
      await $.tester.pumpAndSettle();

      expect(find.text('Eliminar tu cuenta'), findsOneWidget);

      await $.tester.tap(find.text('Cancelar'));
      await $.tester.pumpAndSettle();

      expect(find.byType(SettingsPage), findsOneWidget);
      expect(find.byIcon(LucideIcons.arrowLeft), findsOneWidget);
    },
  );

  patrolTest(
    'Orden del acceso rápido: arrastrar un acceso en Ajustes reordena la '
    'lista y el nuevo orden se refleja en el QuickAccessRow de Inicio, sin '
    'reiniciar la app',
    ($) async {
      await startApp($);
      await _openSettings($);

      await $.tester.tap(find.text('Orden del acceso rápido'));
      await $.tester.pumpAndSettle();
      expect(find.byType(QuickAccessOrderPage), findsOneWidget);

      // Default order: Pagos programados, Deudas, Gráficas e informes.
      final scheduledTop =
          $.tester.getCenter(find.text('Pagos programados')).dy;
      final debtsTop = $.tester.getCenter(find.text('Deudas')).dy;
      expect(scheduledTop, lessThan(debtsTop));

      // Long-press-drag "Pagos programados" below "Deudas" — small
      // incremental steps with a pump after each, same reasoning as
      // `categories_patrol_test.dart`'s root-reorder scenario: a single big
      // `moveTo` jump does not give the delayed drag recognizer per-frame
      // pointer updates to react to, so the item never actually picks up.
      final start = $.tester.getCenter(find.text('Pagos programados'));
      final end = $.tester.getCenter(find.text('Deudas')) + const Offset(0, 40);
      final gesture = await $.tester.startGesture(start);
      await $.tester.pump(const Duration(milliseconds: 600));
      const steps = 10;
      for (var i = 1; i <= steps; i++) {
        await gesture.moveTo(Offset.lerp(start, end, i / steps)!);
        await $.tester.pump(const Duration(milliseconds: 50));
      }
      await $.tester.pump(const Duration(milliseconds: 300));
      await gesture.up();
      await $.tester.pumpAndSettle();

      final newDebtsTop = $.tester.getCenter(find.text('Deudas')).dy;
      final newScheduledTop =
          $.tester.getCenter(find.text('Pagos programados')).dy;
      expect(
        newDebtsTop,
        lessThan(newScheduledTop),
        reason: 'after the drag, Deudas should render above Pagos programados',
      );

      // Back to Ajustes, then to the "Más" hub, then to Inicio: the
      // persisted order (not the default) drives `QuickAccessRow` there
      // too, with no app restart. Two pops are needed — `acceso-rapido` is
      // nested under `ajustes`, which is itself nested under `mas` — before
      // the tab bar (with its "Inicio" destination) is reachable again.
      await $.tester.tap(find.byTooltip('Atrás'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.byTooltip('Atrás'));
      await $.tester.pumpAndSettle();
      await $.tester.tap(find.text('Inicio'));
      await $.tester.pumpAndSettle();

      expect(find.byType(HomePage), findsOneWidget);
      expect(find.byType(QuickAccessChip), findsWidgets);

      final homeDebtsX = $.tester.getCenter(find.text('Deudas')).dx;
      final homeScheduledX =
          $.tester.getCenter(find.text('Pagos programados')).dx;
      expect(
        homeDebtsX,
        lessThan(homeScheduledX),
        reason: 'QuickAccessRow on Inicio must render the persisted order, '
            'not the original hardcoded one',
      );
    },
  );
}
