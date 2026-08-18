import 'dart:async';

import 'package:flutter/material.dart';

import '../utils/show_account_gate_if_needed.dart';
import 'account_gate_copy.dart';

/// HU-04 of `docs/requirements/fase-1/15-gate-cuenta.md`: reaching a route that
/// needs an account directly — a deep link, a restored deep route, typing
/// the path by hand — must get the same bridge a FAB tap gets, not a
/// half-built form. Wrap the `GoRoute`'s `builder` result in this widget
/// instead of returning it directly; it never mounts [builder]'s page until
/// [surface]'s requirement is met.
///
/// Not a `GoRouter` `redirect`: showing the bridge sheet and, if the user
/// accepts, the full account-creation page and awaiting its result is an
/// inherently interactive sub-flow that a `redirect` (which only computes a
/// new location before the very first build) cannot express. This instead
/// reuses [showAccountGateIfNeeded] — the same helper every other call site
/// uses — from a widget that pops itself when the user cancels, and mounts
/// [builder] the instant the requirement is met.
class AccountGatedRoute extends StatefulWidget {
  const AccountGatedRoute({
    required this.surface,
    required this.builder,
    super.key,
  });

  final AccountGateSurface surface;
  final WidgetBuilder builder;

  @override
  State<AccountGatedRoute> createState() => _AccountGatedRouteState();
}

class _AccountGatedRouteState extends State<AccountGatedRoute> {
  bool _ready = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => unawaited(_check()));
  }

  Future<void> _check() async {
    final canProceed = await showAccountGateIfNeeded(context, widget.surface);
    if (!mounted) {
      return;
    }
    if (canProceed) {
      setState(() => _ready = true);
    } else {
      // Cancelled the bridge: there is nothing to show at this route, so
      // back out to wherever the user came from (HU-01's "deja al usuario
      // exactamente donde estaba").
      unawaited(Navigator.of(context).maybePop());
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.builder(context);
    }
    // Between mounting and the gate's first answer (and while the bridge
    // sheet or the account form are open above this route) there is nothing
    // meaningful to paint here yet.
    return const SizedBox.shrink();
  }
}
