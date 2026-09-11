import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// The `Permission Fact Row` component (`OVVPQ`): a 36x36 `$primary-soft`
/// icon square, a short 14/700 title and one plain-language 13/500 line.
///
/// Explanatory text, **not** a control: no chevron, no ripple and no 44pt tap
/// target, exactly as the component's own note says. It exists so every
/// in-context permission explainer (microphone today, bank notifications
/// later) states its facts in the same shape instead of each one inventing
/// its own list.
class PermissionFactRow extends StatelessWidget {
  const PermissionFactRow({
    required this.icon,
    required this.title,
    required this.body,
    super.key,
  });

  final IconData icon;

  /// Already localized.
  final String title;

  /// Already localized.
  final String body;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 36,
          height: 36,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: colors.primarySoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 18, color: colors.primaryOnSoft),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: theme.textTheme.titleSmall?.copyWith(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  height: 1.3,
                  color: colors.textPrimary,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                body,
                style: theme.textTheme.bodySmall?.copyWith(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.4,
                  color: colors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// The vertical stack of [PermissionFactRow]s the explainer sheets share,
/// with the component's own 14pt gap (`rusW1` in `tN3NS`).
class PermissionFactList extends StatelessWidget {
  const PermissionFactList({required this.facts, super.key});

  final List<PermissionFactRow> facts;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: [
        for (var i = 0; i < facts.length; i++) ...[
          if (i > 0) const SizedBox(height: 14),
          facts[i],
        ],
      ],
    );
  }
}
