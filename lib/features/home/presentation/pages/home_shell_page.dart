import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

import '../widgets/exit_app_confirm_dialog.dart';
import '../widgets/home_tab_bar.dart';

/// The navigation shell (HU-01): hosts the five tab branches in an
/// `IndexedStack` and renders the persistent bottom tab bar. Reselecting the
/// active tab pops it to its root, the standard tab behavior.
///
/// Each branch's subscreens are pushed on the root navigator
/// (`parentNavigatorKey: _rootNavigatorKey` in `app_router.dart`), so this
/// `PopScope` only fires when the shell route itself sits at the top of the
/// root stack — i.e. when the active tab is at its own root with nothing
/// pushed above it. A back gesture from a pushed subscreen keeps popping
/// that subscreen normally, untouched by this scope.
class HomeShellPage extends StatelessWidget {
  const HomeShellPage({
    required this.navigationShell,
    this.onSelectBranch,
    this.onInterceptBranchBack,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  /// Optional hook fired with the tapped index right before the branch
  /// switch itself. Lets the composition root (the router) run cross-feature
  /// side effects tied to reaching a specific tab through the ordinary
  /// bottom tab bar — e.g. clearing Gráficas' "volver a Gráficas" flag on
  /// Movimientos when the user lands there this way instead of through the
  /// categories drill-down (`app_router.dart`'s `_movimientosBranch`).
  final void Function(int index)? onSelectBranch;

  /// Queried on every system-back press, before the default "jump to Inicio"
  /// behaviour: lets the composition root override the back gesture for the
  /// *current* branch's root screen. Returns a callback to run instead of
  /// the default, or `null` to fall through to it.
  ///
  /// This exists because `StatefulShellRoute.indexedStack`'s branches each
  /// get their own nested `Navigator`, but go_router's Android system-back
  /// dispatch (`GoRouterDelegate.popRoute` → `_rootNavigatorKey.currentState
  /// ?.maybePop()`) only ever asks the *root* `Navigator` — the one this
  /// `PopScope` sits on, since the whole `StatefulShellRoute` is a single
  /// page on it. A branch route's own `PopScope` (e.g. `TransactionsPage`'s,
  /// for Gráficas' "volver a Gráficas" flow) lives on a *nested* Navigator
  /// that system back never reaches, so without this hook every
  /// system-back press at a branch's root unconditionally falls to
  /// `goBranch(0)` — stealing Movimientos' "volver a Gráficas" back target
  /// and silently landing on Inicio instead (bugfix: system back from the
  /// categories drill-down).
  final VoidCallback? Function(int currentIndex)? onInterceptBranchBack;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleBack(context, didPop),
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: HomeTabBar(
          currentIndex: navigationShell.currentIndex,
          onSelect: (index) {
            onSelectBranch?.call(index);
            navigationShell.goBranch(
              index,
              initialLocation: index == navigationShell.currentIndex,
            );
          },
        ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context, bool didPop) async {
    if (didPop) {
      return;
    }
    final intercept = onInterceptBranchBack?.call(navigationShell.currentIndex);
    if (intercept != null) {
      intercept();
      return;
    }
    if (navigationShell.currentIndex != 0) {
      navigationShell.goBranch(0);
      return;
    }
    final confirmed = await ExitAppConfirmDialog.show(context);
    if (confirmed ?? false) {
      await SystemNavigator.pop();
    }
  }
}
