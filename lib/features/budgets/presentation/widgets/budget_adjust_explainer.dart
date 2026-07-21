import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Hint Explica` tira (`gFPkL`) inside the "Ajustar monto — solo el
/// próximo período" sheet: `$primary-soft`, `repeat-1`, the whole "fork de 3
/// partes" mechanic spelled out in one sentence, so nothing is left implicit.
class BudgetAdjustExplainer extends StatelessWidget {
  const BudgetAdjustExplainer({required this.text, super.key});

  /// Already localized: "A partir del `fecha` tu presupuesto será de $X.
  /// Desde `fecha` vuelve automáticamente a $Y — no tienes que hacer nada."
  final String text;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: colors.primarySoft,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(LucideIcons.repeat1, size: 18, color: colors.primary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: colors.primaryDeep,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
