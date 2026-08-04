import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import 'chart_tabs.dart' show ChartTabs;

/// A single pill of [ChartTabs] (`I1Jgk`): extracted to its own public
/// widget per this project's `avoid_private_widgets` convention.
class ChartTabItem extends StatelessWidget {
  const ChartTabItem({
    required this.label,
    required this.selected,
    required this.onTap,
    super.key,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Semantics(
      button: true,
      selected: selected,
      label: label,
      child: Material(
        color: selected ? colors.surface : Colors.transparent,
        borderRadius: BorderRadius.circular(11),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(11),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 6),
            child: Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: selected ? colors.textPrimary : colors.segmentInactiveText,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
