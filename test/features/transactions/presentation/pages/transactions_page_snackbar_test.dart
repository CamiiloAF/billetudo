import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

/// Root-cause reproduction for bug-fixes.md #7: "Movimiento eliminado.
/// Deshacer" (and every other undo/retry `SnackBar` in the app) never
/// auto-dismisses, only a manual swipe closes it.
///
/// CONFIRMED ROOT CAUSE (Flutter SDK, not app logic): as of Flutter 3.38.5,
/// `SnackBar`'s `persist` field defaults to `action != null`
/// (`packages/flutter/lib/src/material/snack_bar.dart:303`), and
/// `ScaffoldMessengerState`'s auto-dismiss timer is a documented no-op
/// whenever `snackBar.persist` is true
/// (`packages/flutter/lib/src/material/scaffold.dart:616-625`:
/// `if (snackBar.persist) { return; }` inside the `Timer` callback — the
/// timer still fires, it just declines to hide). In other words: **any**
/// `SnackBar` that has a `SnackBarAction` never times out unless the call
/// site explicitly passes `persist: false`.
///
/// Every "Deshacer"/retry `SnackBar` in this app sets `action:` and none set
/// `persist: false`:
///   - lib/features/transactions/presentation/pages/transactions_page.dart:70-76
///     ("Movimiento eliminado." / Deshacer — the one in the bug report)
///   - lib/features/auth/presentation/pages/login_page.dart:56-65 (retry)
///   - lib/features/scheduled_payments/presentation/pages/pending_occurrences_page.dart:36-45
///   - lib/features/scheduled_payments/presentation/pages/scheduled_payment_detail_page.dart:52-59
///     (already had `duration: Duration(seconds: 5)`, which is *also*
///     defeated by the same `persist` default — the explicit duration is
///     dead configuration until `persist: false` is added too)
///   - lib/features/scheduled_payments/presentation/widgets/pending_occurrences_section.dart:35-44
/// So the bug is global to every undo/retry snackbar, not specific to
/// Movimientos — matching what the report asked to verify.
///
/// `lib/features/accounts/presentation/pages/account_detail_page.dart:240-242`
/// ("copiado el número de cuenta") has no `action` and is unaffected — that
/// snackbar already auto-dismisses correctly, which is consistent with this
/// diagnosis (only action-bearing snackbars are broken).
///
/// This file reproduces the mechanism directly with `SnackBar`/
/// `ScaffoldMessenger` rather than through `TransactionsPage` itself: that
/// page transitively imports `lib/core/di/injection.dart` (via its filter
/// sheets), and the generated `lib/core/di/injection.config.dart` is
/// currently stale against `TransactionFormCubit`'s constructor — a
/// pre-existing, unrelated baseline break (uncommitted on this branch; not
/// caused by this investigation) that fails compilation for every test
/// importing it, and that `dart run build_runner build` cannot currently fix
/// either (`Failed to compile build script`). See the report for details;
/// `flutter-dev` needs to resolve that separately before any widget test can
/// import `TransactionsPage` again.
void main() {
  Widget appWith(Widget child) => MaterialApp(
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Scaffold(body: child),
      );

  /// Advances real time in small increments matching the Flutter framework's
  /// own `SnackBar` auto-dismiss tests
  /// (`packages/flutter/test/material/snack_bar_test.dart`): a single big
  /// `tester.pump(Duration(seconds: 5))` jump does not let
  /// `ScaffoldMessengerState` rebuild mid-jump to arm its dismiss `Timer`,
  /// so it would silently mask a working timer as broken.
  Future<void> pumpPastDefaultDuration(WidgetTester tester) async {
    for (var i = 0; i < 8; i++) {
      await tester.pump(const Duration(milliseconds: 750)); // 8 * 0.75s = 6s
    }
    await tester.pump(); // begin exit animation, if any
    await tester.pump(const Duration(seconds: 1)); // finish exit animation
  }

  testWidgets(
    'control: un SnackBar SIN action se autodescarta pasados los 4s por defecto',
    (tester) async {
      await tester.pumpWidget(
        appWith(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                  .showSnackBar(const SnackBar(content: Text('sin accion'))),
              child: const Text('mostrar'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('mostrar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('sin accion'), findsOneWidget);

      await pumpPastDefaultDuration(tester);

      expect(find.text('sin accion'), findsNothing);
    },
  );

  testWidgets(
    'reproduccion exacta del call site de transactions_page.dart (accion sin '
    'persist:false): el SnackBar NO se autodescarta ni tras 40s simulados '
    '— coincide con el bug reportado',
    (tester) async {
      await tester.pumpWidget(
        appWith(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Movimiento eliminado.'),
                    action: SnackBarAction(
                      label: 'Deshacer',
                      onPressed: () {},
                    ),
                  ),
                ),
              child: const Text('borrar'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('borrar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Movimiento eliminado.'), findsOneWidget);

      // Far past the 4s default, in the same small-increment style — even
      // 40 simulated seconds are not enough, because the framework's timer
      // callback is a no-op here (`persist` defaults to true).
      for (var i = 0; i < 40; i++) {
        await tester.pump(const Duration(seconds: 1));
      }

      expect(
        find.text('Movimiento eliminado.'),
        findsOneWidget,
        reason:
            'Root cause confirmado: SnackBar.persist por defecto es '
            '"action != null" (snack_bar.dart:303) y el timer de '
            'ScaffoldMessengerState no hace nada cuando persist es true '
            '(scaffold.dart:616-625). Con un action y sin persist:false, '
            'jamas se autodescarta.',
      );
    },
  );

  testWidgets(
    'el fix esperado: el mismo SnackBar con accion + persist:false SI se '
    'autodescarta pasados los 4s',
    (tester) async {
      await tester.pumpWidget(
        appWith(
          Builder(
            builder: (context) => ElevatedButton(
              onPressed: () => ScaffoldMessenger.of(context)
                ..hideCurrentSnackBar()
                ..showSnackBar(
                  SnackBar(
                    content: const Text('Movimiento eliminado.'),
                    action: SnackBarAction(
                      label: 'Deshacer',
                      onPressed: () {},
                    ),
                    persist: false,
                  ),
                ),
              child: const Text('borrar'),
            ),
          ),
        ),
      );

      await tester.tap(find.text('borrar'));
      await tester.pump();
      await tester.pump();
      expect(find.text('Movimiento eliminado.'), findsOneWidget);

      await pumpPastDefaultDuration(tester);

      expect(
        find.text('Movimiento eliminado.'),
        findsNothing,
        reason:
            'persist: false es el fix minimo: hace que el mismo Timer que '
            'ya se arma correctamente si llame a hideCurrentSnackBar().',
      );
    },
  );
}
