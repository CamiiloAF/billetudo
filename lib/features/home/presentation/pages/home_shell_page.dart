import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../widgets/home_tab_bar.dart';

/// The navigation shell (HU-01): hosts the five tab branches in an
/// `IndexedStack` and renders the persistent bottom tab bar. Reselecting the
/// active tab pops it to its root, the standard tab behavior.
class HomeShellPage extends StatelessWidget {
  const HomeShellPage({required this.navigationShell, super.key});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: HomeTabBar(
        currentIndex: navigationShell.currentIndex,
        onSelect: (index) => navigationShell.goBranch(
          index,
          initialLocation: index == navigationShell.currentIndex,
        ),
      ),
    );
  }
}
