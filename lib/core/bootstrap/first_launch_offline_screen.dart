import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../l10n/gen/app_localizations.dart';
import '../theme/app_colors.dart';
import 'first_launch_offline_cubit.dart';
import 'first_launch_offline_state.dart';

/// "Primer arranque — sin conexión" (`KSkpO` light / `zeAfp` dark): blocks
/// the very first launch when the device has no connectivity to download the
/// seed category catalog (decisión #12,
/// `docs/requirements/05-auth-sync.md`). An extended `Empty State` instance
/// (icon + title + optional subtitle) plus a full-width "Reintentar" button
/// as a sibling, per `design-system/billetudo/pages/primer-arranque.md`.
///
/// Copy is deliberately agnostic — no mention of categories, sync or the
/// server — framed as "finish setting up your account" (product decision,
/// not missing detail).
///
/// Assumes a [FirstLaunchOfflineCubit] is already provided above it (see
/// `FirstLaunchOfflineGate`).
class FirstLaunchOfflineScreen extends StatelessWidget {
  const FirstLaunchOfflineScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;

    return Scaffold(
      backgroundColor: colors.background,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        width: 88,
                        height: 88,
                        decoration: BoxDecoration(
                          color: colors.primarySoft,
                          borderRadius: BorderRadius.circular(44),
                        ),
                        child: Icon(
                          LucideIcons.wifiOff,
                          size: 40,
                          color: colors.primaryOnSoft,
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        l10n.firstLaunchOfflineTitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        l10n.firstLaunchOfflineSubtitle,
                        textAlign: TextAlign.center,
                        style: Theme.of(context)
                            .textTheme
                            .bodyMedium
                            ?.copyWith(color: colors.textSecondary),
                      ),
                    ],
                  ),
                ),
              ),
              BlocBuilder<FirstLaunchOfflineCubit, FirstLaunchOfflineState>(
                builder: (context, state) {
                  final isRetrying =
                      state.status == FirstLaunchOfflineStatus.retrying;
                  return SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: FilledButton.icon(
                      onPressed: isRetrying
                          ? null
                          : () => context.read<FirstLaunchOfflineCubit>().retry(),
                      icon: isRetrying
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(LucideIcons.refreshCw, size: 18),
                      label: Text(
                        isRetrying
                            ? l10n.firstLaunchOfflineRetrying
                            : l10n.commonRetry,
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
