import 'package:clock/clock.dart';
import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/sync/presentation/utils/sync_relative_time.dart';
import '../../../../../core/sync/presentation/widgets/sync_hero.dart';
import '../../../../../core/sync/presentation/widgets/sync_time_row.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../cubit/home_state.dart';

/// The compact sync block: `SyncHero` parametrized (`compact: true`), never a
/// parallel component. Only two states here — synced and attention (the
/// "sin conexión" wording), matching the two documented `AccountSheet`
/// variants.
class AccountSyncBlock extends StatelessWidget {
  const AccountSyncBlock({required this.state, super.key});

  final HomeState state;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final isAttention = state.syncStatus == HomeSyncStatus.attention;
    final lastSyncedAt = state.syncSnapshot.lastSyncedAt;
    final relative = lastSyncedAt == null
        ? null
        : SyncRelativeTime.since(l10n, lastSyncedAt, now: clock.now());
    final timeLabel =
        relative == null ? l10n.syncNeverSyncedLabel : l10n.syncLastSyncLabel(relative);

    return SyncHero(
      compact: true,
      trailingChevron: true,
      attention: isAttention,
      icon: isAttention ? LucideIcons.cloudOff : LucideIcons.cloudCheck,
      iconColor: isAttention ? colors.amber : colors.mint,
      iconBackground: isAttention ? colors.amberSoft : colors.mintSoft,
      title: isAttention
          ? l10n.homeAccountSheetOfflineTitle
          : l10n.homeAccountSheetSyncedTitle,
      kicker: isAttention
          ? l10n.homeAccountSheetOfflineKicker
          : l10n.homeAccountSheetSyncedKicker,
      body: isAttention
          ? l10n.homeAccountSheetOfflineBody
          : l10n.homeAccountSheetSyncedBody,
      timeRow: SyncTimeRow(
        label: timeLabel,
        color: isAttention ? colors.amberText : colors.textPrimary,
      ),
    );
  }
}
