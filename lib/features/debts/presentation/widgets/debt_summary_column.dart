import 'package:flutter/material.dart';

/// One side of the summary card (`weSea`/`mWzRJ`): a small directional icon +
/// label over the outstanding total for that direction. Public so the card can
/// compose both sides without a private widget.
class DebtSummaryColumn extends StatelessWidget {
  const DebtSummaryColumn({
    required this.icon,
    required this.label,
    required this.amount,
    required this.labelColor,
    required this.amountColor,
    super.key,
  });

  final IconData icon;
  final String label;
  final String amount;
  final Color labelColor;
  final Color amountColor;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: labelColor),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.labelMedium?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: labelColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          amount,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleLarge?.copyWith(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: amountColor,
          ),
        ),
      ],
    );
  }
}
