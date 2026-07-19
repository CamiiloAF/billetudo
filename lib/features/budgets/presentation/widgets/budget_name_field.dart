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
    super.key,
  });

  final String initialValue;

  /// Already localized placeholder.
  final String hint;

  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final textStyle = theme.textTheme.titleMedium?.copyWith(
      fontSize: 15,
      fontWeight: FontWeight.w500,
    );

    return Container(
      height: 52,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusField),
        border: Border.all(color: colors.border),
      ),
      alignment: Alignment.center,
      child: TextFormField(
        initialValue: initialValue,
        onChanged: onChanged,
        maxLength: BudgetDraft.maxNameLength,
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
    );
  }
}
