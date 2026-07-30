import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';
import 'cashflow_net_hero.dart' show CashflowNetHero;

/// One of the two neutral stats (`Ingresos`/`Gastos`) under
/// [CashflowNetHero]'s headline figure. Deliberately `$text-primary`, never
/// tinted by income/expense semantics — see "Stats Row va neutro" in
/// `design-system/billetudo/pages/graficas.md`.
class CashflowHeroStat extends StatelessWidget {
  const CashflowHeroStat({required this.label, required this.value, super.key});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          value,
          style: theme.textTheme.titleSmall?.copyWith(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: colors.textPrimary,
          ),
        ),
      ],
    );
  }
}
