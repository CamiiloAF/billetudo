import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../../core/theme/app_colors.dart';

/// The `Form Field` component: label + input box (optional icon) + optional
/// error text.
///
/// The error is the same field with its error node on, never a separate
/// variant.
///
/// Two shapes, one component:
/// * [AccountFormField.text] — the user types.
/// * [AccountFormField.selector] — the user taps and a sheet answers (currency,
///   day of month), so it shows a value and a chevron instead of a cursor.
class AccountFormField extends StatelessWidget {
  const AccountFormField.text({
    required this.label,
    this.icon,
    this.hint,
    this.initialValue,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.obscureText = false,
    this.trailing,
    this.onChanged,
    super.key,
  })  : onTap = null,
        value = null;

  const AccountFormField.selector({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.hint,
    this.errorText,
    this.helperText,
    super.key,
  })  : initialValue = null,
        keyboardType = null,
        inputFormatters = null,
        maxLength = null,
        obscureText = false,
        trailing = null,
        onChanged = null;

  /// Already localized.
  final String label;
  final IconData? icon;
  final String? hint;
  final String? initialValue;
  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool obscureText;

  /// Extra action inside the box (e.g. the reveal eye of the number field).
  final Widget? trailing;

  final ValueChanged<String>? onChanged;

  /// Non-null only on a selector field.
  final VoidCallback? onTap;

  /// What a selector currently holds; null renders the hint.
  final String? value;

  bool get isSelector => onTap != null;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final icon = this.icon;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 8),
        if (isSelector)
          AccountFormSelectorBox(
            icon: icon,
            value: value,
            hint: hint,
            hasError: errorText != null,
            onTap: onTap!,
          )
        else
          TextFormField(
            initialValue: initialValue,
            onChanged: onChanged,
            keyboardType: keyboardType,
            inputFormatters: inputFormatters,
            maxLength: maxLength,
            obscureText: obscureText,
            style: theme.textTheme.bodyLarge,
            decoration: InputDecoration(
              hintText: hint,
              counterText: '',
              errorText: errorText,
              prefixIcon:
                  icon == null ? null : Icon(icon, color: colors.textSecondary),
              suffixIcon: trailing,
            ),
          ),
        if (helperText != null) ...[
          const SizedBox(height: 6),
          Text(
            helperText!,
            style: theme.textTheme.bodySmall
                ?.copyWith(color: colors.textSecondary),
          ),
        ],
        if (isSelector && errorText != null) ...[
          const SizedBox(height: 6),
          Text(
            errorText!,
            style: theme.textTheme.bodySmall?.copyWith(color: colors.expense),
          ),
        ],
      ],
    );
  }
}

/// The tappable box of a selector field: value (or hint) plus a chevron that
/// says a picker will open.
class AccountFormSelectorBox extends StatelessWidget {
  const AccountFormSelectorBox({
    required this.value,
    required this.hint,
    required this.hasError,
    required this.onTap,
    this.icon,
    super.key,
  });

  final String? value;
  final String? hint;
  final bool hasError;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final icon = this.icon;
    final value = this.value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 52,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: hasError ? colors.expense : colors.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: colors.textSecondary, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                value ?? hint ?? '',
                style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      value == null ? colors.textSecondary : colors.textPrimary,
                ),
              ),
            ),
            Icon(Icons.expand_more, color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
