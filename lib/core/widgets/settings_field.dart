import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import '../theme/app_theme.dart';

/// `Appearance Field` (`R8PlN`): icon + label (+ optional sublabel) + chevron
/// row, reused across Ajustes for every navigable setting and by the
/// diagnostics rows of "Estado de sincronización".
///
/// The icon pair is overridable because it is not decoration: Ajustes uses the
/// brand pair, while the sync screen uses `$muted`/`$text-secondary` so the
/// diagnostics rows read as tools and the violet stays reserved for "the
/// cloud".
class SettingsField extends StatelessWidget {
  const SettingsField({
    required this.icon,
    required this.label,
    required this.onTap,
    this.sublabel,
    this.iconColor,
    this.iconBackground,
    this.badge,
    this.showChevron = true,
    super.key,
  });

  final IconData icon;
  final String label;
  final String? sublabel;
  final VoidCallback onTap;

  /// Defaults to the component's `$primary-on-soft` glyph.
  final Color? iconColor;

  /// Defaults to the component's `$primary-soft` wrap.
  final Color? iconBackground;

  /// Rendered right after the label (`U2Ssn`), e.g. the "Próximamente" pill.
  final Widget? badge;

  /// `false` for a row that announces something instead of navigating
  /// (`y16jpI` disabled), like "Exportar a Excel · Próximamente".
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: iconBackground ?? colors.primarySoft,
                    borderRadius: BorderRadius.circular(AppTheme.radiusMedium),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: iconColor ?? colors.primaryOnSoft,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // `Settings Row`'s `Label` (`grTTH`) is 15/600.
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              label,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: theme.textTheme.titleSmall
                                  ?.copyWith(fontWeight: FontWeight.w600),
                            ),
                          ),
                          if (badge case final badge?) ...[
                            const SizedBox(width: 8),
                            badge,
                          ],
                        ],
                      ),
                      if (sublabel != null) ...[
                        const SizedBox(height: 2),
                        // Deliberately unbounded: the sublabel is the
                        // descriptive line and is expected to wrap. Clamping it
                        // to one line truncated Settings' own "Moneda" row
                        // ("Elige la moneda con la que registras tu…") when this
                        // widget moved to `core/` — a regression the sync row,
                        // whose sublabel is short, would never have surfaced.
                        // The label above does clamp, because it shares a Row
                        // with the optional badge and would overflow it.
                        Text(
                          sublabel!,
                          style: theme.textTheme.bodySmall
                              ?.copyWith(color: colors.textSecondary),
                        ),
                      ],
                    ],
                  ),
                ),
                if (showChevron)
                  Icon(LucideIcons.chevronRight, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
