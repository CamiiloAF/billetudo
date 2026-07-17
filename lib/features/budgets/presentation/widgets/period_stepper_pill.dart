import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/budget_period_window.dart';
import '../utils/budget_format.dart';

/// The floating period stepper (`‹ 1–31 jul · vigente ›`) anchored at the bottom
/// of the detail (HU-05). A centered pill, NOT a full-width bar (so it never
/// reads as the tab bar). Chevrons disable at the budget's bounds.
///
/// The elevation shadow is resolved per theme: a dark-tinted navy shadow does
/// not lift over the dark `$background`, so dark uses a stronger black alpha.
class PeriodStepperPill extends StatelessWidget {
  const PeriodStepperPill({
    required this.window,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final BudgetPeriodWindow window;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Center(
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? const Color(0x66000000)
                  : const Color(0x1A1C1B29),
              blurRadius: isDark ? 28 : 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            IconButton(
              onPressed: window.hasPrevious ? onPrevious : null,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.chevronLeft),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: Text(
                BudgetFormat.periodStepperLabel(l10n, window),
                style: theme.textTheme.labelLarge,
              ),
            ),
            IconButton(
              onPressed: window.hasNext ? onNext : null,
              iconSize: 20,
              visualDensity: VisualDensity.compact,
              icon: const Icon(LucideIcons.chevronRight),
            ),
          ],
        ),
      ),
    );
  }
}
