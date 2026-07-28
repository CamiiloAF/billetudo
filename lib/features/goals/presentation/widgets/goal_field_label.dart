import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// Section label used above a goal form field (name, account, target date).
class GoalFieldLabel extends StatelessWidget {
  const GoalFieldLabel(this.text, {super.key});

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
