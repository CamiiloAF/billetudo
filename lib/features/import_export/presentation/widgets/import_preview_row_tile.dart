import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Import Preview Row` component (`zAusB`, HU-06/HU-07): a checkbox row
/// in the final preview.
///
/// Named `ImportPreviewRowTile` (not `ImportPreviewRow`) to avoid colliding
/// with the domain entity of the same conceptual role
/// (`domain/entities/import_preview_row.dart`).
///
/// Duplicates and invalid rows never share treatment: [selectable] `false`
/// swaps the checkbox for a non-interactive `circle-x` in `$expense-text` —
/// never leave the checkbox on a row that cannot actually be included.
class ImportPreviewRowTile extends StatelessWidget {
  const ImportPreviewRowTile({
    required this.title,
    required this.selectable,
    this.checked = false,
    this.onChanged,
    this.note,
    this.reason,
    this.reasonColor,
    super.key,
  });

  /// Already formatted ("15/03/2024 · $45.000 · Bancolombia").
  final String title;

  /// `false` for invalid rows — not selectable at all.
  final bool selectable;
  final bool checked;
  final ValueChanged<bool>? onChanged;

  /// The imported row's own note/description (`zJKYH` in `zAusB`). `null`
  /// hides the line entirely — mirrors Pencil's `enabled:false` for rows
  /// without a note, rather than showing an empty line.
  final String? note;

  /// Already localized reason line. `null` hides it (a clean valid row).
  final String? reason;

  /// `$amber-text` for a probable duplicate, `$expense-text` for invalid,
  /// `$text-secondary` for a neutral note.
  final Color? reasonColor;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (selectable)
            GestureDetector(
              onTap: onChanged == null ? null : () => onChanged!(!checked),
              child: Container(
                width: 24,
                height: 24,
                margin: const EdgeInsets.only(top: 2),
                decoration: BoxDecoration(
                  color: checked ? colors.textPrimary : colors.surface,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                    color: checked ? colors.textPrimary : colors.textSecondary,
                    width: 2,
                  ),
                ),
                child: checked
                    ? Icon(LucideIcons.check, size: 16, color: colors.background)
                    : null,
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Icon(
                LucideIcons.circleX,
                size: 24,
                color: colors.expenseText,
              ),
            ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (note case final note?) ...[
                  const SizedBox(height: 3),
                  Text(
                    note,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: colors.textSecondary,
                    ),
                  ),
                ],
                if (reason case final reason?) ...[
                  const SizedBox(height: 3),
                  Text(
                    reason,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: theme.textTheme.bodySmall?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: reasonColor ?? colors.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}
