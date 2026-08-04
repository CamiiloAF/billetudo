import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Report Card` component (`dflhE`, `reusable:true`): a `$surface`
/// container, 16pt padding, with a title/subtitle header and a content slot
/// — the shared chrome of every chart card in Gráficas e informes.
class ReportCard extends StatelessWidget {
  const ReportCard({
    required this.title,
    required this.subtitle,
    required this.child,
    this.boundaryKey,
    super.key,
  });

  final String title;
  final String subtitle;
  final Widget child;

  /// When set, wraps the card in a `RepaintBoundary` under this key — how
  /// `ChartExport` (HU-05) captures **only** the active chart's card,
  /// excluding tabs/header/export icon (criterion 15).
  final GlobalKey? boundaryKey;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final card = Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: colors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
    final boundaryKey = this.boundaryKey;
    if (boundaryKey == null) {
      return card;
    }
    return RepaintBoundary(key: boundaryKey, child: card);
  }
}
