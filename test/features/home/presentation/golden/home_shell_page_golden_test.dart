import 'package:billetudo/core/l10n/gen/app_localizations.dart';
import 'package:billetudo/core/theme/app_theme.dart';
import 'package:billetudo/features/home/presentation/pages/home_shell_page.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';

import '../../../../support/golden_helpers.dart';

/// [HomeShellPage] wraps a real `StatefulNavigationShell`, which go_router
/// builds internally and can't be constructed directly nor mocked (see
/// `home_shell_page_test.dart`'s doc comment). This golden mirrors that
/// test's approach: a minimal real `GoRouter` with a five-branch
/// `StatefulShellRoute.indexedStack`, one flat-color placeholder per branch
/// so the only thing under test — the persistent bottom tab bar's chrome —
/// is what actually varies between goldens.
void main() {
  setUpAll(() async {
    disableGoogleFontsRuntimeFetching();
    await loadMaterialIconsFont();
  });

  Widget branchBody(String label) => Center(child: Text(label));

  Future<void> golden(
    WidgetTester tester,
    String initialLocation,
    String name, {
    required Brightness brightness,
  }) async {
    setGoldenViewport(tester);
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
                  builder: (context, state) => branchBody('Inicio'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/movimientos',
                  builder: (context, state) => branchBody('Movimientos'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/presupuestos',
                  builder: (context, state) => branchBody('Presupuestos'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/metas',
                  builder: (context, state) => branchBody('Metas'),
                ),
              ],
            ),
            StatefulShellBranch(
              routes: [
                GoRoute(
                  path: '/mas',
                  builder: (context, state) => branchBody('Más'),
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
        theme:
            brightness == Brightness.dark ? AppTheme.dark() : AppTheme.light(),
        locale: const Locale('es'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
      ),
    );
    await tester.pumpAndSettle();
    await expectLater(
      find.byType(MaterialApp),
      matchesGoldenFile('goldens/home_shell_page_$name.png'),
    );
  }

  for (final brightness in Brightness.values) {
    final suffix = brightness == Brightness.light ? 'light' : 'dark';

    testWidgets('Inicio active (índice 0) ($suffix)', (tester) async {
      await golden(tester, '/', 'inicio_active_$suffix',
          brightness: brightness);
    });

    testWidgets('Más active (índice 4) ($suffix)', (tester) async {
      await golden(tester, '/mas', 'mas_active_$suffix',
          brightness: brightness);
    });
  }
}
