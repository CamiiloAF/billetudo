import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// One tappable row inside `AiMessageCopyMenu` (`jYlTh`/`k4pWxl` in
/// `billetudo.pen`'s `Cbssw`): icon + label, 18px icon, 10px gap, `[13,12]`
/// padding — the tap target the menu item's own 44px `height` already
/// provides.
class AiMessageMenuRow extends StatelessWidget {
  const AiMessageMenuRow({required this.icon, required this.label, super.key});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 12),
      child: Row(
        children: [
          Icon(icon, size: 18, color: colors.textSecondary),
          const SizedBox(width: 10),
          Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: colors.textPrimary,
                ),
          ),
        ],
      ),
    );
  }
}
