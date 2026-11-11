import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// One system setting inside the background-capture sheet (`TPLPN` / `bN2YZ`,
/// HU-09).
///
/// Two states:
///  - **actionable** — 64pt tall, `$surface` with a `$border` at radius 14,
///    the caller's icon tone (amber for battery still pending, primary for
///    autostart) and a decorative chevron;
///  - **fulfilled** — same chassis in `$mint-soft`/`$mint` with a check and no
///    tap target, used when the battery exemption is already granted. A row
///    that can no longer do anything must not invite a tap.
///
/// The chevron is decorative: the accessible label is the title plus the
/// subtitle, exposed as one node so a screen reader does not read every row
/// twice or announce the arrow.
class CaptureBackgroundActionRow extends StatelessWidget {
  const CaptureBackgroundActionRow({
    required this.icon,
    required this.iconColor,
    required this.iconBackground,
    required this.title,
    required this.subtitle,
    this.onTap,
    super.key,
  });

  /// The row's glyph while actionable (`battery-charging`, `rotate-cw`).
  final IconData icon;

  /// Icon tone while actionable. Fulfilled rows always use `$mint`.
  final Color iconColor;

  /// Icon-wrap fill while actionable. Fulfilled rows always use `$mint-soft`.
  final Color iconBackground;

  /// Already localized.
  final String title;

  /// Already localized. The caller switches it to the "Permitido" copy when
  /// the row is fulfilled.
  final String subtitle;

  /// `null` renders the fulfilled row: check instead of chevron, no ink, no
  /// tap target.
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final AppColors colors = context.colors;
    final ThemeData theme = Theme.of(context);
    final BorderRadius radius = BorderRadius.circular(AppTheme.radiusField);
    final bool fulfilled = onTap == null;

    final Widget content = Container(
      height: 64,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        borderRadius: radius,
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 44,
            height: 44,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: fulfilled ? colors.mintSoft : iconBackground,
              shape: BoxShape.circle,
            ),
            child: Icon(
              fulfilled ? LucideIcons.check : icon,
              size: 20,
              color: fulfilled ? colors.mint : iconColor,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: colors.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: colors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          // Decorative: the row's own label already says what it does. The
          // fulfilled check is part of the state, not the action.
          if (!fulfilled)
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.textSecondary,
            ),
        ],
      ),
    );

    // One accessible label per row, title + subtitle. `ExcludeSemantics` keeps
    // the two visual lines and the arrow from becoming separate nodes.
    final AppLocalizations l10n = AppLocalizations.of(context);
    final Widget labelled = Semantics(
      label: l10n.captureBackgroundActionRowSemantics(title, subtitle),
      button: !fulfilled,
      enabled: !fulfilled,
      child: ExcludeSemantics(child: content),
    );

    return Material(
      color: colors.surface,
      borderRadius: radius,
      child: fulfilled
          ? labelled
          : InkWell(onTap: onTap, borderRadius: radius, child: labelled),
    );
  }
}
