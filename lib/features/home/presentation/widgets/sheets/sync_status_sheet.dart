import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/sync/presentation/utils/sync_freshness.dart';
import '../../../../../core/sync/presentation/utils/sync_relative_time.dart';
import '../../../../../core/sync/presentation/widgets/sync_time_row.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../../../../core/widgets/sheet_buttons_row.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';

/// The sync-status sheet the Home opens when the cloud icon is tapped
/// (`DUSmQ` / `uYVmf` / `n1qFs` / `MEcVH` / `W4oGp` in `billetudo.pen`).
///
/// It is deliberately *reactive*: one sheet whose icon, title and message
/// track the live [HomeState] via a [BlocBuilder]. If the user opens it
/// mid-sync and the upload finishes, the content swaps in place.
///
/// **The "última sincronización" row shows in all five states**, healthy
/// included: if the datum only appeared on failure the user would have nothing
/// to compare against, which is the literal lesson of the incident behind
/// HU-08. Past 24 h it turns `$amber-text` and the copy switches to "está
/// tardando" — "syncing" and "syncing for three days" must not read the same.
///
/// Offline is never framed as an error (local-first, HU-10). The signed-out
/// offline case never reaches this sheet — the Home routes it to login.
class SyncStatusSheet extends StatelessWidget {
  const SyncStatusSheet({this.onOpenDetails, super.key});

  /// Opens "Estado de sincronización". `null` keeps the single-button layout
  /// (the sheet never navigates on its own).
  final VoidCallback? onOpenDetails;

  /// Opens the reactive sheet, wiring the shared [HomeCubit] so the content
  /// keeps updating while it stays open.
  static Future<void> show(
    BuildContext context,
    HomeCubit cubit, {
    VoidCallback? onOpenDetails,
  }) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider<HomeCubit>.value(
          value: cubit,
          child: SyncStatusSheet(onOpenDetails: onOpenDetails),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.syncStatus != current.syncStatus ||
          previous.syncSnapshot != current.syncSnapshot,
      builder: (context, state) {
        final snapshot = state.syncSnapshot;
        final now = DateTime.now();
        final lastSyncedAt = snapshot.lastSyncedAt;
        final isStale = SyncFreshness.isStale(lastSyncedAt, now: now);
        final relative = lastSyncedAt == null
            ? null
            : SyncRelativeTime.since(l10n, lastSyncedAt, now: now);
        final isAttention = state.syncStatus == HomeSyncStatus.attention;
        // Held-back writes outrank a stale clock: both are amber, but only one
        // of them has something the user can act on, item by item.
        final isStalled = snapshot.hasQuarantinedOperations;

        final (icon, title, message) = switch (state.syncStatus) {
          HomeSyncStatus.attention when isStalled => (
              LucideIcons.cloudAlert,
              l10n.homeSyncSheetStalledTitle(snapshot.quarantinedCount),
              l10n.homeSyncSheetStalledMessage,
            ),
          HomeSyncStatus.attention => (
              LucideIcons.hourglass,
              l10n.homeSyncSheetTooLongTitle,
              l10n.homeSyncSheetTooLongMessage(
                lastSyncedAt == null
                    ? l10n.syncDurationMoment
                    : SyncRelativeTime.elapsed(
                        l10n,
                        now.difference(lastSyncedAt),
                      ),
              ),
            ),
          HomeSyncStatus.synced => (
              LucideIcons.cloudCheck,
              l10n.homeSyncSheetSyncedTitle,
              l10n.homeSyncSheetSyncedMessage,
            ),
          HomeSyncStatus.syncing => (
              LucideIcons.refreshCw,
              l10n.homeSyncSheetSyncingTitle,
              l10n.homeSyncSheetSyncingMessage,
            ),
          HomeSyncStatus.offline => (
              LucideIcons.cloudOff,
              l10n.homeSyncSheetOfflineTitle,
              l10n.homeSyncSheetOfflineMessage,
            ),
        };

        final timeLabel = switch (relative) {
          null => l10n.syncNeverSyncedLabel,
          final relative when isAttention && !isStalled =>
            l10n.syncLastSuccessfulSyncLabel(relative),
          final relative => l10n.syncLastSyncLabel(relative),
        };
        final onOpenDetails = this.onOpenDetails;

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: isAttention ? colors.amberSoft : colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                icon,
                color: isAttention ? colors.amber : colors.primaryOnSoft,
                size: 28,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleLarge
                  ?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 8),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(color: colors.textSecondary),
            ),
            const SizedBox(height: 18),
            SyncTimeRow(
              label: timeLabel,
              color: isStale || isAttention
                  ? colors.amberText
                  : colors.textPrimary,
            ),
            const SizedBox(height: 18),
            if (isAttention && onOpenDetails != null)
              SheetButtonsRow(
                left: OutlinedButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.homeSyncSheetDismiss),
                ),
                right: FilledButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onOpenDetails();
                  },
                  icon: const Icon(LucideIcons.arrowRight, size: 18),
                  label: Text(l10n.homeSyncSheetDetails),
                ),
              )
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(l10n.homeSyncSheetDismiss),
                ),
              ),
          ],
        );
      },
    );
  }
}
