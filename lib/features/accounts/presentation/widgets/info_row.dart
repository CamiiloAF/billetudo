import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Info Row` component (`myfAc`): label above, value below.
class InfoRow extends StatelessWidget {
  const InfoRow({required this.label, required this.value, super.key});

  /// Both already localized: this widget renders, it does not translate.
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
