import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// One row of the "Formato detectado" section (HU-05): a `Form Field`-style
/// readout (`wOlOA`). Tappable in Manual mode (opens the matching format
/// sheet); `onTap == null` renders it inert, used by the Automático summary
/// where the fields are informational only.
class ImportFormatField extends StatelessWidget {
  const ImportFormatField({
    required this.icon,
    required this.label,
    required this.value,
    this.onTap,
    super.key,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onTap;

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
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: colors.textSecondary,
          ),
        ),
        const SizedBox(height: 6),
        InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: Container(
            width: double.infinity,
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: colors.border),
            ),
            child: Row(
              children: [
                Icon(icon, size: 18, color: colors.textSecondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodyMedium
                        ?.copyWith(fontSize: 15, fontWeight: FontWeight.w500),
                  ),
                ),
                if (onTap != null)
                  Icon(LucideIcons.chevronRight, size: 16, color: colors.textSecondary),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
