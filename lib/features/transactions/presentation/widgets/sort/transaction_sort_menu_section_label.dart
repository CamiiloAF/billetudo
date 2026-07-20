import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// One non-tappable section header of the `Sort Menu` popover
/// (`xXWi0`/`dbTXb`), e.g. "FECHA"/"MONTO".
class TransactionSortMenuSectionLabel extends StatelessWidget {
  const TransactionSortMenuSectionLabel({
    required this.label,
    required this.topPadding,
    super.key,
  });

  final String label;

  /// The `FECHA` label sits right below the popover's own 4px padding
  /// (`10`), while `MONTO` sits below the `Divider` with extra breathing
  /// room (`14`) — both per the popover's design.
  final double topPadding;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, topPadding, 16, 6),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.5,
          color: colors.textSecondary,
        ),
      ),
    );
  }
}
