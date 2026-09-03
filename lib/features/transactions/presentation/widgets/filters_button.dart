import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Issue #7: opens the unified filters sheet (Presupuesto → Fecha → Tipo →
/// Categoría → Etiqueta). [activeCount] is `TransactionFilter.activeFilterCount`
/// — every dimension with an active filter, cuenta included (its chips live
/// in `AccountFilterChipRow`, but still count toward this badge per the
/// acceptance criteria) — a badge only renders while it is `> 0`, same
/// "no badge for zero" rule as `QuickAccessChipWithBadge`.
class FiltersButton extends StatelessWidget {
  const FiltersButton({
    required this.activeCount,
    required this.onTap,
    super.key,
  });

  final int activeCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final active = activeCount > 0;
    final foreground = active ? colors.primaryOnSoftStrong : colors.textSecondary;

    return Material(
      color: active ? colors.primarySoft : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: active ? colors.primary : colors.border),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          alignment: Alignment.center,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(LucideIcons.slidersHorizontal, size: 14, color: foreground),
              const SizedBox(width: 6),
              Text(
                l10n.transactionsFiltersButtonLabel,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: active ? 13 : 12,
                  fontWeight: FontWeight.w700,
                  color: foreground,
                ),
              ),
              if (active) ...[
                const SizedBox(width: 6),
                Container(
                  height: 18,
                  constraints: const BoxConstraints(minWidth: 18),
                  padding: const EdgeInsets.symmetric(horizontal: 5),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Text(
                    '$activeCount',
                    style: theme.textTheme.labelSmall?.copyWith(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: colors.onPrimary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
