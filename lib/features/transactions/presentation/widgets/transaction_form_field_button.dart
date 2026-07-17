import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The `Form Field` pattern of the transaction form (`wOlOA`): a top label
/// (outside the box) over a tappable box that shows the picked value (or a muted
/// placeholder). Used for Cuenta and Fecha so both read as one consistent
/// control.
///
/// The box carries no leading icon-wrap nor a trailing chevron — those were
/// dropped from the design. An optional [inlineIcon] (no wrap) is supported only
/// for the transfer's account fields, which prefix the value with the account's
/// type icon.
class TransactionFormFieldButton extends StatelessWidget {
  const TransactionFormFieldButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.inlineIcon,
    this.hasValue = true,
    super.key,
  });

  final String label;

  /// The picked value, or the placeholder text when nothing is selected yet.
  final String value;

  /// Whether [value] is a real selection (`$text-primary`) or a placeholder
  /// (`$text-secondary`).
  final bool hasValue;

  /// Optional inline icon shown to the left of the value, without a wrap
  /// (18px, `$text-secondary`). Only the transfer account fields use it.
  final IconData? inlineIcon;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        Material(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            child: Container(
              height: 50,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusField),
                border: Border.all(color: colors.border),
              ),
              child: Row(
                children: [
                  if (inlineIcon != null) ...[
                    Icon(inlineIcon, size: 18, color: colors.textSecondary),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      value,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.titleMedium?.copyWith(
                        color: hasValue
                            ? colors.textPrimary
                            : colors.textSecondary,
                        fontSize: 15,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
