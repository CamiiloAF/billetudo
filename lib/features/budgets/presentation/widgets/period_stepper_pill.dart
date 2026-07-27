import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header_circle_button.dart';
import '../../domain/entities/budget.dart';
import '../../domain/entities/budget_period_window.dart';
import '../utils/budget_format.dart';

/// The floating period stepper (`‹ 1–31 jul · vigente ›`) anchored at the bottom
/// of the detail (HU-05, `NloPT/MZrD8`). A nearly full-width pill with the two
/// halves of the label pushed apart from the 44pt `$muted` chevron circles —
/// NOT a full-width bar (so it never reads as the tab bar). Chevrons dim to
/// 40% at the budget's bounds (`QLn6w/KVIaU`).
///
/// The elevation shadow is resolved per theme: a dark-tinted navy shadow does
/// not lift over the dark `$background`, so dark uses a stronger black alpha.
class PeriodStepperPill extends StatelessWidget {
  const PeriodStepperPill({
    required this.budget,
    required this.window,
    required this.onPrevious,
    required this.onNext,
    super.key,
  });

  final Budget budget;
  final BudgetPeriodWindow window;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final locale = Localizations.localeOf(context).toString();
    final colors = context.colors;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(27),
          border: Border.all(color: colors.border),
          boxShadow: [
            BoxShadow(
              color: isDark ? const Color(0x66000000) : const Color(0x221C1B29),
              blurRadius: isDark ? 28 : 20,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Row(
          children: [
            PeriodStepperChevron(
              icon: LucideIcons.chevronLeft,
              tooltip: l10n.budgetPeriodPreviousTooltip,
              onPressed: window.hasPrevious ? onPrevious : null,
            ),
            Expanded(
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Flexible(
                    child: Text(
                      BudgetFormat.stepperRange(l10n, budget, window, locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: colors.textPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 5),
                  Flexible(
                    child: Text(
                      BudgetFormat.stepperState(l10n, budget, window, locale),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: colors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            PeriodStepperChevron(
              icon: LucideIcons.chevronRight,
              tooltip: l10n.budgetPeriodNextTooltip,
              onPressed: window.hasNext ? onNext : null,
            ),
          ],
        ),
      ),
    );
  }
}

/// One chevron of the stepper: the shared 44pt `$muted` circle, faded to 40%
/// when there is no window to step to (`QLn6w/KVIaU`).
class PeriodStepperChevron extends StatelessWidget {
  const PeriodStepperChevron({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;

  /// Null disables (and dims) the chevron.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Opacity(
      opacity: onPressed == null ? 0.4 : 1,
      child: PageHeaderCircleButton(
        icon: icon,
        background: colors.muted,
        foreground: colors.textPrimary,
        tooltip: tooltip,
        onPressed: onPressed,
      ),
    );
  }
}
