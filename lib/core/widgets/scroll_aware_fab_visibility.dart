import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import 'scroll_aware_fab.dart';

/// Shared scroll-direction-based FAB visibility: the FAB hides on scroll
/// down and comes back on scroll up (HU-02). Mix this into any `State` that
/// owns the page's scrollable body — home and movimientos both need it, and
/// the plain scroll-listener boilerplate is identical for both, so it lives
/// here once instead of being copy-pasted per screen.
///
/// The mixing `State` must attach [fabScrollController] to whichever
/// scrollable (`CustomScrollView`, `ListView`, ...) drives the page, and use
/// [fabVisible] to drive a [ScrollAwareFab] (or equivalent) around its FAB.
mixin ScrollAwareFabVisibility<T extends StatefulWidget> on State<T> {
  /// Attach this to the page's own scrollable body.
  final ScrollController fabScrollController = ScrollController();

  bool _fabVisible = true;

  /// Whether the FAB should currently be shown.
  bool get fabVisible => _fabVisible;

  @override
  void initState() {
    super.initState();
    fabScrollController.addListener(_onFabScroll);
  }

  void _onFabScroll() {
    final direction = fabScrollController.position.userScrollDirection;
    if (direction == ScrollDirection.reverse && _fabVisible) {
      setState(() => _fabVisible = false);
    } else if (direction == ScrollDirection.forward && !_fabVisible) {
      setState(() => _fabVisible = true);
    }
  }

  @override
  void dispose() {
    fabScrollController.dispose();
    super.dispose();
  }
}
