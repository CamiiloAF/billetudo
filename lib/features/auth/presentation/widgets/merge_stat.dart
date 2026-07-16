import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

class MergeStat extends StatelessWidget {
  const MergeStat(
      {required this.value, required this.label, this.style, super.key});

  final String value;
  final String label;
  final TextStyle? style;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Expanded(
      child: Column(
        children: [
          Text(value, style: style),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context)
                .textTheme
                .bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
        ],
      ),
    );
  }
}
