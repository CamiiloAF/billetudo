import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../auth/domain/entities/auth_user.dart';
import '../cubit/home_state.dart';
import 'account_avatar.dart';

// `AccountAvatar` moved to its own file (one public widget per file); this
// re-export keeps `home_header.dart` a valid import for it.
export 'account_avatar.dart';

/// The Home header (`Home Header · Avatar de cuenta`, `v8CGbF`,
/// `design-system/billetudo/pages/inicio.md` § "Header"): a tappable avatar
/// carrying the sync/backup status, a one-line greeting, and two identically
/// shaped 44×44 circular buttons (saldos, notificaciones).
///
/// Three moves from the older header: the standalone sync icon is gone
/// (absorbed by [AccountAvatar]'s status badge, which only lights up when it
/// has something to say); the greeting compresses from two lines to one
/// ("Hola, {nombre}"); and the avatar itself becomes tappable, opening "Tu
/// cuenta" instead of sitting decorative.
class HomeHeader extends StatelessWidget {
  const HomeHeader({
    required this.syncStatus,
    required this.onBellTap,
    required this.onAvatarTap,
    required this.onWalletTap,
    this.user,
    super.key,
  });

  final HomeSyncStatus syncStatus;
  final VoidCallback onBellTap;

  /// Opens "Tu cuenta" (`AccountSheet`) — the avatar's only affordance now
  /// that the sync icon moved onto its badge.
  final VoidCallback onAvatarTap;

  /// Opens "Tu dinero" (`BalancesSheet`) — the only path left to the balances
  /// sheet now that the "Mis cuentas" strip is gone from Home.
  final VoidCallback onWalletTap;

  /// The signed-in user, or null when local-first with no session (HU-07).
  final AuthUser? user;

  /// The uppercase initial of the display name, or null when it can't be
  /// derived (no session, or a blank name) — then the avatar falls back to
  /// the person icon.
  String? get _initial {
    final name = user?.displayName.trim() ?? '';
    return name.isEmpty ? null : name.characters.first.toUpperCase();
  }

  AccountAvatarBadge get _badge {
    if (user == null) {
      return AccountAvatarBadge.noAccount;
    }
    return switch (syncStatus) {
      HomeSyncStatus.syncing => AccountAvatarBadge.syncing,
      HomeSyncStatus.attention => AccountAvatarBadge.attention,
      HomeSyncStatus.synced ||
      HomeSyncStatus.offline =>
        AccountAvatarBadge.synced,
    };
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    final greeting = user != null
        ? l10n.homeGreetingNamed(user!.displayName.split(' ').first)
        : l10n.homeGreeting;

    return Row(
      children: [
        InkResponse(
          onTap: onAvatarTap,
          radius: 28,
          child: AccountAvatar(badge: _badge, initial: _initial),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            greeting,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.w700),
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onWalletTap,
          tooltip: l10n.homeWalletTooltip,
          style: IconButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.textPrimary,
          ),
          icon: const Icon(LucideIcons.wallet),
        ),
        const SizedBox(width: 8),
        IconButton(
          onPressed: onBellTap,
          tooltip: l10n.homeNotificationsTooltip,
          style: IconButton.styleFrom(
            backgroundColor: colors.surface,
            foregroundColor: colors.textPrimary,
          ),
          icon: const Icon(LucideIcons.bell),
        ),
      ],
    );
  }
}
