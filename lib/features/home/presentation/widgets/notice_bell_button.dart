import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// `r1eRC` — Home's bell with a counter of everything waiting in the Avisos
/// centre.
///
/// The **number** is what carries the meaning: when there is nothing pending
/// the badge is absent, never a bare dot, so the affordance never relies on
/// colour alone. The `$background` ring separates the pill from the bell's
/// own `$surface` circle. [count] follows the same convention as
/// `QuickAccessChipWithBadge`: capped at "9+", and never rendered at zero.
///
/// The 44x44 tap target is the circle; the badge neither enlarges nor clips
/// it, which is why it is painted in an unclipped [Stack] instead of being
/// laid out beside the icon.
class NoticeBellButton extends StatelessWidget {
  const NoticeBellButton({
    required this.count,
    required this.onPressed,
    super.key,
  });

  final int count;
  final VoidCallback onPressed;

  String get _badgeLabel => count > 9 ? '9+' : '$count';

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return SizedBox(
      width: 44,
      height: 44,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          IconButton(
            onPressed: onPressed,
            tooltip: l10n.captureBellTooltip,
            style: IconButton.styleFrom(
              backgroundColor: colors.surface,
              foregroundColor: colors.textPrimary,
              fixedSize: const Size.square(44),
            ),
            icon: const Icon(LucideIcons.bell),
          ),
          if (count > 0)
            Positioned(
              left: 22,
              top: 2,
              child: Container(
                height: 20,
                constraints: const BoxConstraints(minWidth: 20),
                padding: const EdgeInsets.symmetric(horizontal: 6),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: colors.primary,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: colors.background, width: 2),
                ),
                child: Text(
                  _badgeLabel,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimary,
                      ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
