import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Section label used above a goal movement field (fecha, nota) in
/// `GoalContributionSheet`.
class GoalMovementFieldLabel extends StatelessWidget {
  const GoalMovementFieldLabel({required this.text, super.key});

  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Text(
      text,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
    );
  }
}
