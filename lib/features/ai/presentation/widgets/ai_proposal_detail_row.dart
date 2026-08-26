import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One label/value line of an `AiProposalCard`'s Body Slot (`billetudo.pen`
/// `MO6zZ`, "Fila — Monto"), e.g. "Monto" / "$850.000".
class AiProposalDetailRow extends StatelessWidget {
  const AiProposalDetailRow(
      {required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: colors.textSecondary,
          ),
        ),
        Text(
          value,
          textAlign: TextAlign.right,
          style: theme.textTheme.bodyMedium?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
