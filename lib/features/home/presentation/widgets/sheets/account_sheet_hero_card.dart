import 'package:flutter/material.dart';

import '../../../../../core/l10n/gen/app_localizations.dart';
import '../../../../../core/theme/app_colors.dart';
import '../../../../auth/domain/entities/auth_user.dart';
import '../account_avatar.dart';

/// `AccountSheet`'s signed-in `Hero Card` (`D0WrY` offline / `ZgRMl` synced,
/// `design-system/billetudo/pages/inicio.md` § "Hoja de cuenta"): `$primary
/// -soft` fill, a horizontal row — avatar on the left, name stacked above a
/// status row (email · a sync status pill) on the right.
///
/// The avatar's own status badge tracks [synced]: in the offline/attention
/// state Pencil shows it (default `fPMzQ` state, amber `cloud-off`) since
/// it is what justifies the "Sin conexión" pill next to it; only the synced
/// instance switches it off explicitly
/// (`descendants:{"UILBZ":{"enabled":false}}`) so a healthy avatar doesn't
/// contradict the mint pill sitting right next to it.
class AccountSheetHeroCard extends StatelessWidget {
  const AccountSheetHeroCard({
    required this.user,
    required this.synced,
    super.key,
  });

  final AuthUser user;

  /// `true` renders the mint "Sincronizado" pill, `false` the amber "Sin
  /// conexión" one — the only two states this sheet's signed-in variant
  /// covers (`HomeSyncStatus.synced`/`.attention`).
  final bool synced;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final name = user.displayName;
    final email = user.email;
    final initial = name.trim().isEmpty ? null : name.trim()[0].toUpperCase();
    final pillColor = synced ? colors.mintSoft : colors.amberSoft;
    final pillTextColor = synced ? colors.mintText : colors.amberText;
    final pillLabel = synced
        ? l10n.homeAccountSheetSyncedPill
        : l10n.homeAccountSheetOfflinePill;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          AccountAvatar(
            badge: synced
                ? AccountAvatarBadge.synced
                : AccountAvatarBadge.attention,
            initial: initial,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 17,
                    fontWeight: FontWeight.w700,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (email != null) ...[
                      Flexible(
                        child: Text(
                          email,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: colors.textSecondary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Text(
                        '·',
                        style: theme.textTheme.bodySmall
                            ?.copyWith(color: colors.textSecondary),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: pillColor,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        pillLabel,
                        style: theme.textTheme.labelSmall?.copyWith(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: pillTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
