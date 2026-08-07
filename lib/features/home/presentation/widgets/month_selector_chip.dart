import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The hero's month-navigation chip (HU-04, `A9v7s` `HC Month`): shown only
/// when no budget is featured — with a featured budget, `HeroPeriodStepper`
/// takes over the same spot to navigate the budget's own period window
/// instead of a calendar month. Opens `MonthPickerSheet` on tap.
///
/// Fixed `$on-primary` text/icon over a translucent `$month-chip-bg` fill:
/// it always sits on the hero's gradient, never a themed surface, so its
/// colors do not change with light/dark.
class MonthSelectorChip extends StatelessWidget {
  const MonthSelectorChip({
    required this.label,
    required this.onTap,
    super.key,
  });

  /// Already localized month name (e.g. "Julio").
  final String label;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.homeMonthChipTooltip,
      child: Material(
        color: colors.monthChipBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          child: Tooltip(
            message: l10n.homeMonthChipTooltip,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 12),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: colors.onPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Icon(
                    LucideIcons.chevronDown,
                    size: 13,
                    color: colors.onPrimary,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
