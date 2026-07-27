import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/home/presentation/pages/home_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

/// [HomeShellPage] wraps a real `StatefulNavigationShell`, which go_router
/// builds internally via a private constructor and internal route-matching
/// state — it can't be constructed directly nor mocked with mocktail (it's a
/// concrete `StatefulWidget` whose `currentIndex` and `goBranch` depend on
/// live `ShellRouteContext`/`GoRouter` internals). Extracting the "show
/// dialog vs. goBranch(0)" decision into a pure function would need a change
/// under `lib/`, which is out of scope for this test file.
///
/// Instead this builds a minimal real `GoRouter` with a two-branch
/// `StatefulShellRoute.indexedStack` — the same pattern the app's own
/// `app_router.dart` uses — so `navigationShell` here is the genuine object
/// `HomeShellPage` receives in production. Rather than trying to simulate an
/// OS back gesture (fragile: depends on `handlePopRoute`/platform channel
/// wiring across Flutter versions), the test grabs the `PopScope` that
/// `HomeShellPage` builds and invokes its registered
/// `onPopInvokedWithResult` callback directly — that closure is exactly
/// `_handleBack`, the unit under test.
void main() {
  Future<GoRouter> pumpShell(
    WidgetTester tester, {
    String initialLocation = '/',
  }) async {
    final router = GoRouter(
      initialLocation: initialLocation,
      routes: [
        StatefulShellRoute.indexedStack(
          builder: (context, state, navigationShell) =>
              HomeShellPage(navigationShell: navigationShell),
          branches: [
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/',
                  builder: (context, state) => const Text('Inicio branch'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/other',
                  builder: (context, state) => const Text('Other branch'),
                ),
              ],
            ),
          ],
        ),
      ],
    );
    addTearDown(router.dispose);

    await tester.pumpWidget(
      MaterialApp.router(
        routerConfig: router,
        theme: AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    return router;
  }

  void invokeBackGesture(WidgetTester tester) {
    // `PopScope` is generic (`PopScope<T>`); the concrete instance
    // `HomeShellPage` builds infers `T` from its callback, so
    // `find.byType(PopScope)` (which matches exact `runtimeType`) finds
    // nothing — a predicate that checks `is PopScope` is required instead.
    final finder = find.byWidgetPredicate((widget) => widget is PopScope);
    final popScope = tester.widget(finder) as PopScope;
    popScope.onPopInvokedWithResult!(false, null);
  }

  testWidgets(
      'gesto atrás desde Inicio (índice 0) muestra el diálogo de confirmación',
      (tester) async {
    await pumpShell(tester);
    expect(find.text('Inicio branch'), findsOneWidget);

    invokeBackGesture(tester);
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de Billetudo?'), findsOneWidget);
  });

  testWidgets(
      'gesto atrás desde otra pestaña navega a Inicio sin mostrar el diálogo',
      (tester) async {
    await pumpShell(tester, initialLocation: '/other');
    expect(find.text('Other branch'), findsOneWidget);

    invokeBackGesture(tester);
    await tester.pumpAndSettle();

    expect(find.text('¿Salir de Billetudo?'), findsNothing);
    expect(find.text('Inicio branch'), findsOneWidget);
  });
}
