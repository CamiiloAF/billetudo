import 'dart:async';

import 'package:flutter/material.dart';

import '../../features/splash/presentation/pages/splash_page.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';

/// Runs immediately as the very first thing `runApp` mounts, so the user sees
/// [SplashPage] instead of a blank frame while `bootstrap()` opens Drift,
/// initializes Supabase/PowerSync, wires up dependency injection and seeds
/// default categories in the background.
///
/// [init] does that work and resolves to the real app's builder (normally
/// the one `bootstrap()` was called with, but possibly wrapped in
/// `FirstLaunchOfflineGate` if seeding hit a `NetworkFailure` on the very
/// first launch) — [AppBootstrapGate] then swaps it in for the rest of the
/// process lifetime.
///
/// A plain `setState` swap (not a route push) is intentional, same as
/// `FirstLaunchOfflineGate`: nothing of the real app's navigation stack
/// exists yet, so there is nothing to push onto.
class AppBootstrapGate extends StatefulWidget {
  const AppBootstrapGate({required this.init, super.key});

  final Future<Widget Function()> Function() init;

  @override
  State<AppBootstrapGate> createState() => _AppBootstrapGateState();
}

class _AppBootstrapGateState extends State<AppBootstrapGate> {
  Widget Function()? _builder;

  @override
  void initState() {
    super.initState();
    unawaited(_run());
  }

  Future<void> _run() async {
    final builder = await widget.init();
    if (!mounted) return;
    setState(() => _builder = builder);
  }

  @override
  Widget build(BuildContext context) {
    final builder = _builder;
    if (builder != null) {
      return builder();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: const SplashPage(),
    );
  }
}
