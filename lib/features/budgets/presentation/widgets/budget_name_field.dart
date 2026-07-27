import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../domain/entities/budget_draft.dart';

/// The name input of the budget form (`a3gGPM/CS8I0`): a bare 52pt box with
/// no label of its own — the section above it is labelled "Ícono y nombre"
/// for the icon and the name together.
class BudgetNameField extends StatelessWidget {
  const BudgetNameField({
    required this.initialValue,
    required this.hint,
    required this.onChanged,
    this.errorText,
    this.focusNode,
    this.textInputAction,
    this.onSubmitted,
    super.key,
  });

  final String initialValue;

  /// Already localized placeholder.
  final String hint;

  final ValueChanged<String> onChanged;

  /// Set when the name failed validation (HU-01: a budget needs a name).
  /// Switches the box border to `$expense` and shows a message below it —
  /// same pattern as `AccountFormField`.
  final String? errorText;

  /// The field's own focus node, so the form can chain focus from here to the
  /// next text input. `null` keeps Flutter's default.
  final FocusNode? focusNode;

  /// The keyboard action button ("siguiente" / "listo"). `null` keeps the
  /// default so any other usage is unchanged.
  final TextInputAction? textInputAction;

  /// Fired when the keyboard action is confirmed (used to move focus to the
  /// next text field, or to dismiss the keyboard on the last one).
  final VoidCallback? onSubmitted;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final errorText = this.errorText;
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          height: 52,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(AppTheme.radiusField),
            border: Border.all(
              color: errorText != null ? colors.expense : colors.border,
            ),
          ),
          alignment: Alignment.center,
          child: TextFormField(
            initialValue: initialValue,
            focusNode: focusNode,
            onChanged: onChanged,
            textInputAction: textInputAction,
            onFieldSubmitted:
                onSubmitted == null ? null : (_) => onSubmitted!.call(),
            maxLength: BudgetDraft.maxNameLength,
            textCapitalization: TextCapitalization.sentences,
            style: textStyle?.copyWith(color: colors.textPrimary),
            decoration: InputDecoration(
              isCollapsed: true,
              filled: false,
              counterText: '',
              contentPadding: EdgeInsets.zero,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              hintText: hint,
              hintStyle: textStyle?.copyWith(color: colors.textSecondary),
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
