import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';

/// Issue #7: opens the unified filters sheet (Presupuesto → Fecha → Tipo →
/// Categoría → Etiqueta). Icon-only square button (`WTT9S` in `nMKtn`), same
/// 44×48/`cornerRadius:16` treatment as `TransactionsSortButton`, living in
/// the search row rather than a text pill of its own. [activeCount] is
/// `TransactionFilter.activeFilterCount` — every dimension with an active
/// filter, cuenta included (its chips live in `AccountFilterChipRow`, but
/// still count toward this badge per the acceptance criteria) — a small
/// circular badge pinned to the button's top-right corner only renders while
/// it is `> 0`, same "no badge for zero" rule as `QuickAccessChipWithBadge`.
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
    final foreground =
        active ? colors.primaryOnSoftStrong : colors.textSecondary;

    return Tooltip(
      message: l10n.transactionsFiltersButtonLabel,
      child: Semantics(
        label: l10n.transactionsFiltersButtonLabel,
        button: true,
        child: SizedBox(
          width: 44,
          height: 48,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Material(
                color: active ? colors.primarySoft : colors.surface,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                  side: BorderSide(
                    color: active ? colors.primary : colors.border,
                  ),
                ),
                child: InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(16),
                  child: Center(
                    child: Icon(
                      LucideIcons.slidersHorizontal,
                      size: 20,
                      color: foreground,
                    ),
                  ),
                ),
              ),
              if (active)
                Positioned(
                  top: -2,
                  right: -6,
                  child: Container(
                    width: 16,
                    height: 16,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: colors.primary,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$activeCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: colors.onPrimary,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
