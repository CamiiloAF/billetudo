import 'package:flutter/material.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../cubit/home_state.dart';

/// The Home header (HU-07/HU-10): avatar + greeting, a passive sync indicator
/// and the notifications bell.
///
/// Local-first: with no account the greeting is generic and never blocks or
/// nags. The sync indicator is informative only (not a tap target).
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.syncStatus,
    required this.onBellTap,
    super.key,
  });

  final HomeSyncStatus syncStatus;
  final VoidCallback onBellTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [colors.primary, colors.primaryDeep],
            ),
            shape: BoxShape.circle,
          ),
          child: Icon(Icons.person_outline, color: colors.onPrimary, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            l10n.homeGreeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        SyncIndicator(status: syncStatus),
        const SizedBox(width: 4),
        IconButton(
          onPressed: onBellTap,
          tooltip: l10n.homeNotificationsTooltip,
          style: IconButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.textPrimary,
          ),
          icon: const Icon(Icons.notifications_none),
        ),
      ],
    );
  }
}

/// The discreet sync-status icon (HU-10). Passive: it carries a semantics
/// label but is not interactive.
class SyncIndicator extends StatelessWidget {
  const SyncIndicator({required this.status, super.key});

  final HomeSyncStatus status;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final (icon, label) = switch (status) {
      HomeSyncStatus.synced => (Icons.cloud_done_outlined, l10n.homeSyncSynced),
      HomeSyncStatus.syncing => (Icons.sync, l10n.homeSyncSyncing),
      HomeSyncStatus.offline => (Icons.cloud_off_outlined, l10n.homeSyncOffline),
    };
    return Semantics(
      label: label,
      child: Icon(icon, size: 20, color: colors.textSecondary),
    );
  }
}
