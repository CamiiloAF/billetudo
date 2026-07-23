import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';

/// The `Form Field` pattern of the transaction form (`wOlOA`): a top label
/// (outside the box) over a tappable box that shows the picked value (or a
/// muted placeholder). Used for Cuenta and Fecha so both read as one
/// consistent control.
///
/// The box always carries a trailing `chevron-down` (16px, `$text-secondary`),
/// confirmed on every real `wOlOA` instance in Pencil (`SckMF` Cuenta,
/// `IiCkU`/`aLwJo` Fecha). It also supports an optional leading [inlineIcon]
/// (no wrap, 18px), shown whenever the field has a clear visual identity —
/// Cuenta uses `wallet`, Fecha uses `calendar`/`infinity`.
///
/// When [onCleared] is set (Pagos Programados' optional `endDate`), the
/// trailing chevron is swapped for a small tappable `x` that clears the
/// field without opening the picker — not part of the base `wOlOA` pattern,
/// but a control this field needs (undoing "Sin fecha de fin") that the
/// component can carry without breaking the other call sites.
class TransactionFormFieldButton extends StatelessWidget {
  const TransactionFormFieldButton({
    required this.label,
    required this.value,
    required this.onTap,
    this.inlineIcon,
    this.hasValue = true,
    this.errorText,
    this.onCleared,
    super.key,
  });

  final String label;

  /// The picked value, or the placeholder text when nothing is selected yet.
  final String value;

  /// Whether [value] is a real selection (`$text-primary`) or a placeholder
  /// (`$text-secondary`).
  final bool hasValue;

  /// Optional inline icon shown to the left of the value, without a wrap
  /// (18px, `$text-secondary`) — e.g. `wallet` for Cuenta, `calendar` for
  /// Fecha.
  final IconData? inlineIcon;

  /// When set, the box border and a message below it switch to the error
  /// state — same pattern as `AccountFormField` (`$expense` border/text).
  final String? errorText;

  /// When set and [hasValue] is `true`, shows a small `x` in place of the
  /// chevron to clear the field in one tap, without opening the picker.
  final VoidCallback? onCleared;

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final errorText = this.errorText;
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
              constraints: const BoxConstraints(minHeight: 50),
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(AppTheme.radiusField),
                border: Border.all(
                  color: errorText != null ? colors.expense : colors.border,
                ),
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
                  const SizedBox(width: 10),
                  if (hasValue && onCleared != null)
                    InkWell(
                      onTap: onCleared,
                      borderRadius:
                          BorderRadius.circular(AppTheme.radiusMedium),
                      child: Padding(
                        padding: const EdgeInsets.all(4),
                        child: Icon(
                          LucideIcons.x,
                          size: 16,
                          color: colors.textSecondary,
                        ),
                      ),
                    )
                  else
                    Icon(
                      LucideIcons.chevronDown,
                      size: 16,
                      color: colors.textSecondary,
                    ),
                ],
              ),
            ),
          ),
        ),
        if (errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.expense),
          ),
        ],
      ],
    );
  }
}
