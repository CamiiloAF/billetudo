import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Disclosure Row` component (`GhK9z`): an expandable secondary block
/// for invalid/warning rows in the import preview — collapsed by default.
class DisclosureRow extends StatelessWidget {
  const DisclosureRow({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.expanded,
    required this.onToggle,
    required this.children,
    super.key,
  });

  final IconData icon;
  final Color iconColor;

  /// Already localized ("Ver 3 filas con error").
  final String label;
  final bool expanded;
  final VoidCallback onToggle;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          InkWell(
            onTap: onToggle,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(icon, size: 18, color: iconColor),
                    const SizedBox(width: 8),
                    Text(
                      label,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
                Icon(
                  expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                  size: 16,
                  color: colors.textSecondary,
                ),
              ],
            ),
          ),
          if (expanded && children.isNotEmpty) ...[
            const SizedBox(height: 10),
            Column(
              children: [
                for (var i = 0; i < children.length; i++) ...[
                  if (i > 0) const SizedBox(height: 8),
                  children[i],
                ],
              ],
            ),
          ],
        ],
      ),
    );
  }
}
