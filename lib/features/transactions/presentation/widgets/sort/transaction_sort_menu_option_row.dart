import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// One selectable row of the `Sort Menu` popover (`xXWi0`/`dbTXb`, e.g.
/// "Más recientes primero"): a label plus a fixed 24x24 check slot that only
/// renders its icon for the currently-active option, keeping every row the
/// same height whether or not it is selected.
class TransactionSortMenuOptionRow extends StatelessWidget {
  const TransactionSortMenuOptionRow({
    required this.label,
    required this.selected,
    super.key,
  });

  final String label;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: colors.textPrimary,
            ),
          ),
          SizedBox(
            width: 24,
            height: 24,
            child: selected
                ? Icon(
                    LucideIcons.check,
                    size: 20,
                    color: colors.primaryOnSoft,
                  )
                : null,
          ),
        ],
      ),
    );
  }
}
