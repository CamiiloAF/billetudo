import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// One 44×44 chevron of `PeriodStepper`'s `Stepper Row` (`vBgce/Xroj5`,
/// `design-system/billetudo/MASTER.md` § "Period Stepper"): a `$muted`
/// circle with an 18px `$text-primary` icon, dimmed to `opacity:0.4` and
/// inert when [onPressed] is null — there is no period to navigate to past
/// that edge.
class PeriodStepperChevron extends StatelessWidget {
  const PeriodStepperChevron({
    required this.icon,
    required this.label,
    required this.onPressed,
    super.key,
  });

  final IconData icon;

  /// Used as both the accessible [Semantics] label and the [Tooltip]
  /// message.
  final String label;

  /// Null disables (and dims) the chevron.
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final enabled = onPressed != null;

    return Opacity(
      opacity: enabled ? 1 : 0.4,
      child: Semantics(
        label: label,
        button: true,
        enabled: enabled,
        child: Tooltip(
          message: label,
          child: Material(
            color: colors.muted,
            shape: const CircleBorder(),
            child: InkWell(
              onTap: onPressed,
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: 44,
                height: 44,
                child: Icon(icon, size: 18, color: colors.textPrimary),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
