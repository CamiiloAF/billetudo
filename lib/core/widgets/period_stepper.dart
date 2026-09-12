import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../theme/app_colors.dart';
import 'period_stepper_chevron.dart';

/// `Period Stepper` (`vBgce`, `design-system/billetudo/MASTER.md` §
/// "Period Stepper"): the shared inline pill that navigates a period/cycle
/// (month, custom range, budget window). Unified 2026-09-11 — replaces the
/// two previously-duplicated widgets, both now deleted: `PeriodNavBar`
/// (Movimientos, square `cornerRadius:16` card) and `PeriodStepperPill`
/// (Presupuestos, pill floating at the screen's bottom). This pill is
/// **inline**, never floating — the caller places it in the normal content
/// flow.
///
/// The center accepts exactly one of two shapes, matching `vBgce`'s
/// `Center` node:
/// - [label]: a single-line period label (Movimientos, e.g. "Julio 2026").
/// - [rangeLabel] + [stateLabel]: a two-fragment range + status line
///   (Presupuestos, e.g. "25 ago – 25 sep" + "· vigente" — see
///   `BudgetFormat.stepperRange`/`stepperState`).
///
/// [contextIcon] + [contextLabel] draw the optional `Context Row` above the
/// period line (the "Budget Context Tag" case, e.g. "🍴 Comida del mes") —
/// omit both to hide it, matching `Context Row`'s `enabled:false` default.
class PeriodStepper extends StatelessWidget {
  const PeriodStepper({
    required this.previousLabel,
    required this.nextLabel,
    required this.onPrevious,
    required this.onNext,
    this.label,
    this.rangeLabel,
    this.stateLabel,
    this.contextIcon,
    this.contextLabel,
    super.key,
  }) : assert(
          (label != null) ^ (rangeLabel != null && stateLabel != null),
          'Provide either label, or both rangeLabel and stateLabel — never '
          'both shapes, never neither.',
        );

  /// Accessible label/tooltip for the left chevron (`Chev L`).
  final String previousLabel;

  /// Accessible label/tooltip for the right chevron (`Chev R`).
  final String nextLabel;

  /// Null disables (and dims to 40%) the left chevron — no previous period.
  final VoidCallback? onPrevious;

  /// Null disables (and dims to 40%) the right chevron — no next period.
  final VoidCallback? onNext;

  /// Single-line period label (Movimientos case), e.g. "Julio 2026".
  final String? label;

  /// First, primary fragment of the two-part center (Presupuestos case),
  /// e.g. "25 ago – 25 sep".
  final String? rangeLabel;

  /// Second, secondary fragment of the two-part center, e.g. "· vigente".
  final String? stateLabel;

  /// Optional `Context Row` icon, shown above the period line — null hides
  /// the row entirely (must be supplied together with [contextLabel]).
  final IconData? contextIcon;

  /// Optional `Context Row` label alongside [contextIcon].
  final String? contextLabel;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final showContextRow = contextIcon != null && contextLabel != null;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 5),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(27),
        border: Border.all(color: colors.border),
        boxShadow: const [
          BoxShadow(
            color: Color(0x141C1B29),
            blurRadius: 10,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          PeriodStepperChevron(
            icon: LucideIcons.chevronLeft,
            label: previousLabel,
            onPressed: onPrevious,
          ),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (showContextRow) ...[
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        contextIcon,
                        size: 12,
                        color: colors.primaryOnSoftStrong,
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          contextLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: colors.primaryOnSoftStrong,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                ],
                if (label case final label?)
                  Text(
                    label,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: colors.textPrimary,
                    ),
                  )
                else
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Flexible(
                        child: Text(
                          rangeLabel!,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: colors.textPrimary,
                          ),
                        ),
                      ),
                      const SizedBox(width: 5),
                      Flexible(
                        child: Text(
                          stateLabel!,
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
              ],
            ),
          ),
          PeriodStepperChevron(
            icon: LucideIcons.chevronRight,
            label: nextLabel,
            onPressed: onNext,
          ),
        ],
      ),
    );
  }
}
