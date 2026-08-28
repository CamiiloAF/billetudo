import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import 'account_avatar.dart';

/// The avatar's `Status Badge` (`UILBZ`): a 20×20 circle with a 2px
/// `$background` ring and a 12px glyph, one per [AccountAvatarBadge] other
/// than [AccountAvatarBadge.synced] (which never renders one at all).
class StatusBadge extends StatelessWidget {
  const StatusBadge({required this.badge, super.key});

  final AccountAvatarBadge badge;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    final (fill, iconColor, icon, label) = switch (badge) {
      AccountAvatarBadge.synced => (
          colors.surface,
          colors.textSecondary,
          LucideIcons.cloudCheck,
          l10n.homeSyncSynced,
        ),
      AccountAvatarBadge.syncing => (
          colors.primarySoft,
          colors.primaryOnSoft,
          LucideIcons.refreshCw,
          l10n.homeSyncSyncing,
        ),
      AccountAvatarBadge.noAccount => (
          colors.surface,
          colors.primaryOnSoft,
          LucideIcons.cloudUpload,
          l10n.homeAccountAvatarNoAccount,
        ),
      // The badge icon on `$amber` is per-theme, not a single fixed value:
      // white clears 4.21:1 on light `$amber` (dark enough), but light
      // `$amber` dark is bright yellow, where white falls to 1.36:1 — fixed
      // `$text-primary`'s light value (`#1C1B29`) is used instead, same
      // constant regardless of theme (MASTER.md § Paleta).
      AccountAvatarBadge.attention => (
          colors.amber,
          Theme.of(context).brightness == Brightness.dark
              ? AppColors.light.textPrimary
              : colors.onPrimary,
          LucideIcons.cloudOff,
          l10n.homeSyncAttention,
        ),
    };

    return Semantics(
      label: label,
      child: Container(
        width: 20,
        height: 20,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: fill,
          shape: BoxShape.circle,
          border: Border.all(color: colors.background, width: 2),
        ),
        child: Icon(icon, size: 12, color: iconColor),
      ),
    );
  }
}
