import 'package:flutter/material.dart';

import '../../../../../core/theme/app_colors.dart';

/// The `Card Empty` component (`S27V2`): a compact empty state used *inside*
/// a `ReportCard`, distinct from the full-screen `EmptyState` (`jmQO5`).
class ReportCardEmpty extends StatelessWidget {
  const ReportCardEmpty({
    required this.icon,
    required this.message,
    required this.cta,
    super.key,
  });

  final IconData icon;
  final String message;

  /// The CTA button, already styled `FilledButton`/`OutlinedButton` by the
  /// caller — per "Un solo CTA primario por pantalla" (`design-system/
  /// billetudo/pages/graficas.md`, nota `FR1Gz`), Presupuestos' empty is
  /// Primary and Metas' is Secondary.
  final Widget cta;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: colors.primarySoft,
              borderRadius: BorderRadius.circular(32),
            ),
            child: Icon(icon, size: 28, color: colors.primaryOnSoft),
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              height: 1.4,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(width: 240, child: cta),
        ],
      ),
    );
  }
}
