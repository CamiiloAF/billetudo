import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One dot of `Onboarding Top Bar`'s progress indicator (Pencil `s6LXJ`,
/// descendants `Dot0`..`Dot3`): wide and `$primary` for the current step,
/// narrow and `$primary` for a step already passed, narrow and `$border` for
/// a step not reached yet.
class OnboardingProgressDot extends StatelessWidget {
  const OnboardingProgressDot({
    required this.active,
    required this.current,
    super.key,
  });

  /// Whether this step is the current one or already passed.
  final bool active;

  /// Whether this is the step currently shown — drawn wide instead of narrow.
  final bool current;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      width: current ? 22 : 8,
      height: 8,
      decoration: BoxDecoration(
        color: active ? colors.primary : colors.border,
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
