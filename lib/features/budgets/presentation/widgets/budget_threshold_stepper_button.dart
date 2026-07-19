import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/page_header_circle_button.dart';

/// One of the `−` / `+` controls of the custom-threshold sheet.
///
/// Reuses the system's stepper affordance — the same 44pt `$muted` circle the
/// period pill's chevrons use (`PeriodStepperChevron`, `QLn6w/KVIaU`), dimmed
/// to 40% at the bounds — instead of a bare Material icon button.
class BudgetThresholdStepperButton extends StatelessWidget {
  const BudgetThresholdStepperButton({
    required this.icon,
    required this.tooltip,
    required this.onPressed,
    super.key,
  });

  final IconData icon;
  final String tooltip;

  /// Null disables (and dims) the control.
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
