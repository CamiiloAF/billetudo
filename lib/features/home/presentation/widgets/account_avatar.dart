import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import 'status_badge.dart';

/// The 4 states `AccountAvatar`'s status badge resolves to
/// (`design-system/billetudo/pages/inicio.md` § "Header", `fPMzQ`).
enum AccountAvatarBadge {
  /// Everything is backed up: the badge stays off — a healthy avatar draws
  /// nothing extra.
  synced,

  /// Mid-sync: `$primary-soft` fill, `refresh-cw` glyph.
  syncing,

  /// No session at all: `$surface` fill, `cloud-upload` glyph — a
  /// conversion point, not an error.
  noAccount,

  /// Something needs the user's attention (offline with pending changes, or
  /// a stale sync): `$amber` fill, `cloud-off` glyph.
  attention,
}

/// `Account Avatar` (`fPMzQ`): the Home header's avatar, now tappable
/// (44×44, opens "Tu cuenta") and the carrier of the sync/backup status that
/// used to live in the header's standalone cloud icon
/// (`design-system/billetudo/pages/inicio.md` § "Header").
///
/// The badge is never a bare dot: color alone cannot carry the meaning
/// (WCAG 1.4.1), and a plain dot over an avatar reads as "you have messages"
/// in the universal UI convention — here it means something else entirely.
/// A 2px `$background` ring separates it from the avatar's gradient without
/// introducing a new color.
class AccountAvatar extends StatelessWidget {
  const AccountAvatar({required this.badge, this.initial, super.key});

  /// The uppercase initial of the signed-in user's display name, or `null`
  /// when there is no session (or a blank name) — then the avatar falls back
  /// to the neutral `user` glyph (`Fallback Icon`).
  final String? initial;

  final AccountAvatarBadge badge;

  static const double size = 44;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final initial = this.initial;

    return SizedBox(
      width: size,
      height: size,
      child: Stack(
        children: [
          Container(
            width: size,
            height: size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [colors.primary, colors.primaryDeep],
              ),
              shape: BoxShape.circle,
            ),
            child: initial != null
                ? Text(
                    initial,
                    style: theme.textTheme.titleMedium?.copyWith(
                      color: colors.onPrimary,
                      fontWeight: FontWeight.w700,
                    ),
                  )
                : Icon(LucideIcons.user, color: colors.onPrimary, size: 22),
          ),
          if (badge != AccountAvatarBadge.synced)
            Positioned(
              right: -4,
              bottom: -4,
              child: StatusBadge(badge: badge),
            ),
        ],
      ),
    );
  }
}
