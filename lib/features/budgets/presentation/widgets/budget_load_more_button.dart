import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The activity's "Ver más" affordance (`NloPT/oadHE`): a full-width `$muted`
/// pill with the label and a `chevron-down`, NOT a bare text button. It expands
/// the list in place (HU-04) — it never navigates away, which is why it points
/// down instead of forward.
class BudgetLoadMoreButton extends StatelessWidget {
  const BudgetLoadMoreButton({required this.onPressed, super.key});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);

    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                l10n.budgetLoadMore,
                style: theme.textTheme.labelLarge?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: colors.primaryOnSoftStrong,
                ),
              ),
              const SizedBox(width: 6),
              Icon(
                LucideIcons.chevronDown,
                size: 16,
                color: colors.primaryOnSoftStrong,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
