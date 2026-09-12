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
        // Flexible + ellipsis, not a bare Text: a real account or debt name
        // ("Crédito hipotecario Bancolombia") overflows this row at any font
        // scale, and Pencil renders no ellipsis, so the frame cannot show it.
        // Nothing moves while the value fits.
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}
