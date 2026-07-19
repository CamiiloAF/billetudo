import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/theme/app_colors.dart';

/// One editable row of the confirmation sheet (`r0F8r`): a boxless row with
/// the label on the left (13/500 `text-secondary`), the value pushed to the
/// right (15/600 `text-primary`) and a trailing `chevron-right`.
///
/// The chevron is the feature's icon vocabulary, not decoration:
/// `chevron-right` means "opens a selector" (Fecha/Cuenta), while
/// `chevron-down` on the amount means "expands here". It is drawn whenever
/// [showChevron] is set, which is not the same as being tappable: `woFWS`
/// gives both account rows a chevron so the values stay in one column, even
/// though a transfer's destination account has no selector (HU-03 only edits
/// `date`/`accountId`/`amountMinor`).
class ConfirmationSheetFieldRow extends StatelessWidget {
  const ConfirmationSheetFieldRow({
    required this.label,
    required this.value,
    this.onTap,
    this.showChevron = true,
    super.key,
  });

  final String label;
  final String value;

  /// `null` renders the row as read-only (it still keeps its chevron unless
  /// [showChevron] says otherwise).
  final VoidCallback? onTap;

  /// Whether the trailing `chevron-right` is drawn.
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final row = SizedBox(
      height: 44,
      child: Row(
        children: [
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: colors.textSecondary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              value,
              textAlign: TextAlign.right,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: colors.textPrimary,
              ),
            ),
          ),
          if (showChevron) ...[
            const SizedBox(width: 4),
            Icon(
              LucideIcons.chevronRight,
              size: 18,
              color: colors.textSecondary,
            ),
          ],
        ],
      ),
    );
    if (onTap == null) {
      return row;
    }
    return InkWell(onTap: onTap, child: row);
  }
}
