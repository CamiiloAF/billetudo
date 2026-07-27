import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../di/injection.dart';
import '../l10n/gen/app_localizations.dart';
import '../theme/app_theme.dart';
import 'first_launch_offline_cubit.dart';
import 'first_launch_offline_screen.dart';
import 'first_launch_offline_state.dart';

/// Runs instead of the real app's `builder()` when `bootstrap()` detects the
/// first-launch seeding call failed with a `NetworkFailure` (decisión #12,
/// `docs/requirements/05-auth-sync.md`): shows the blocking
/// [FirstLaunchOfflineScreen] in its own minimal `MaterialApp` (only
/// theme/l10n, no router — the real app's shell hasn't been reached yet)
/// until a retry succeeds, then swaps in [builder] for the rest of the
/// process lifetime.
///
/// A plain `setState` swap (not a route push) is intentional: nothing of the
/// real app's navigation stack exists yet at this point, so there is nothing
/// to push onto.
class FirstLaunchOfflineGate extends StatefulWidget {
  const FirstLaunchOfflineGate({required this.builder, super.key});

  final Widget Function() builder;

  @override
  State<FirstLaunchOfflineGate> createState() => _FirstLaunchOfflineGateState();
}

class _FirstLaunchOfflineGateState extends State<FirstLaunchOfflineGate> {
  bool _ready = false;

  @override
  Widget build(BuildContext context) {
    if (_ready) {
      return widget.builder();
    }

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      home: BlocProvider(
        create: (_) => getIt<FirstLaunchOfflineCubit>(),
        child: BlocListener<FirstLaunchOfflineCubit, FirstLaunchOfflineState>(
          listenWhen: (previous, current) =>
              current.status == FirstLaunchOfflineStatus.success,
          listener: (context, state) => setState(() => _ready = true),
          child: const FirstLaunchOfflineScreen(),
        ),
      ),
    );
  }
}
