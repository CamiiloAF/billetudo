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
  const HomeShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) => _handleBack(context, didPop),
      child: Scaffold(
        body: navigationShell,
        bottomNavigationBar: HomeTabBar(
          currentIndex: navigationShell.currentIndex,
          onSelect: (index) => navigationShell.goBranch(
            index,
            initialLocation: index == navigationShell.currentIndex,
          ),
        ),
      ),
    );
  }

  Future<void> _handleBack(BuildContext context, bool didPop) async {
    if (didPop) {
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
