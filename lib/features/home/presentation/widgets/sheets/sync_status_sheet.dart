import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../../core/widgets/bottom_sheet_base.dart';
import '../../cubit/home_cubit.dart';
import '../../cubit/home_state.dart';

/// The sync-status sheet (bugfix item 6): the reassurance panel the Home opens
/// when the user taps the cloud icon with a session (`CaLYm` / `WAW55` /
/// `nzxqu` in `billetudo.pen`).
///
/// It is deliberately *reactive*: a single sheet whose icon, title and message
/// track the live [HomeSyncStatus] via a [BlocBuilder] over the [HomeCubit].
/// If the user opens it mid-sync ("Sincronizando…") and the upload finishes,
/// the content swaps to "Todo a salvo" in place, without closing or reopening.
///
/// Offline is never framed as an error here (local-first, HU-10): the copy
/// reassures that the data is safe on-device and will sync when the connection
/// returns. The signed-out offline case never reaches this sheet — the Home
/// routes it to login instead.
class SyncStatusSheet extends StatelessWidget {
  const SyncStatusSheet({super.key});

  /// Opens the reactive sheet, wiring the shared [HomeCubit] so the content
  /// keeps updating while it stays open.
  static Future<void> show(BuildContext context, HomeCubit cubit) =>
      BottomSheetBase.show<void>(
        context,
        builder: (context) => BlocProvider<HomeCubit>.value(
          value: cubit,
          child: const SyncStatusSheet(),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);

    return BlocBuilder<HomeCubit, HomeState>(
      buildWhen: (previous, current) =>
          previous.syncStatus != current.syncStatus,
      builder: (context, state) {
        final (icon, title, message) = switch (state.syncStatus) {
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

        return Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: colors.primaryOnSoft, size: 28),
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
            const SizedBox(height: 24),
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
