import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// One of the two "Modo" radio-cards on the template form (both always
/// visible at once, unlike the retired `SwitchListTile` this replaces, which
/// hid "manual" as an "off" state). Matches the real `rVgOE` "Modo Block
/// (radio)" component: a fixed per-mode icon in a 40x40 wrap, the
/// title/subtitle, and a filled-check radio at the trailing edge — not a
/// left-aligned `circle`/`circleDot` icon.
class ScheduledPaymentModeRadioCard extends StatelessWidget {
  const ScheduledPaymentModeRadioCard({
    required this.selected,
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    super.key,
  });

  final bool selected;

  /// The mode's own icon (e.g. `zap` for "Automático", `bell` for "Manual")
  /// — fixed per mode, not derived from [selected].
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: selected ? colors.primarySoft : colors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: selected ? colors.surface : colors.primarySoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                size: 20,
                color: selected ? colors.primary : colors.textSecondary,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: theme.textTheme.bodyMedium?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
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
            Container(
              width: 22,
              height: 22,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: selected ? colors.primary : Colors.transparent,
                border: selected
                    ? null
                    : Border.all(color: colors.border, width: 1.5),
              ),
              child: selected
                  ? Icon(LucideIcons.check, size: 14, color: colors.onPrimary)
                  : null,
            ),
          ],
        ),
      ),
    );
  }
}
