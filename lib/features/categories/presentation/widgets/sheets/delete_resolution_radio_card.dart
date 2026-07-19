import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// A tappable radio-card option, used by the delete-with-transactions sheet
/// to pick between reassigning or clearing a category (`snXFk` in
/// `billetudo.pen`). Selected state reads `stroke:$primary` 1.5px +
/// `fill:$primary-soft`; unselected reads `stroke:$border` + `fill:$surface`.
class DeleteResolutionRadioCard extends StatelessWidget {
  const DeleteResolutionRadioCard({
    required this.selected,
    required this.label,
    required this.onTap,
    super.key,
  });

  final bool selected;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: selected ? colors.primarySoft : colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: selected ? colors.primary : colors.border,
            width: selected ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Icon(
              selected ? LucideIcons.circleDot : LucideIcons.circle,
              color: selected ? colors.primary : colors.textSecondary,
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color: colors.textPrimary,
                  fontWeight: selected ? FontWeight.w600 : FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
