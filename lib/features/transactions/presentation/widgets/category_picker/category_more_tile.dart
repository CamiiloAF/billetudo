import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// The trailing "Ver más"/"Otra" tile of the `Category Quick Picker`
/// (`EIoVx`)/`mK8oI`: an outline treatment distinct from `CategoryPickerChip`
/// since it has no category behind it — `$surface` fill (not `$muted`), a
/// visible `$border` stroke (unlike an unselected chip, which has none), and
/// a neutral `ellipsis` icon. Opens `CategorySelectSheet` on tap.
class CategoryMoreTile extends StatelessWidget {
  const CategoryMoreTile({
    required this.label,
    required this.onTap,
    super.key,
  });

  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: 72,
        child: Column(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: colors.border, width: 2),
              ),
              child: Icon(
                LucideIcons.ellipsis,
                size: 20,
                color: colors.textSecondary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: theme.textTheme.labelLarge?.copyWith(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: colors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
