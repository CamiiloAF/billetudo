import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/widgets/keyboard_done_toolbar.dart';

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
    this.controller,
    this.errorText,
    this.helperText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.obscureText = false,
    this.textCapitalization = TextCapitalization.none,
    this.trailing,
    this.onChanged,
    super.key,
  })  : onTap = null,
        value = null,
        assert(
          initialValue == null || controller == null,
          'a field is driven either by initialValue or by a controller',
        );

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
        controller = null,
        keyboardType = null,
        inputFormatters = null,
        maxLength = null,
        obscureText = false,
        textCapitalization = TextCapitalization.none,
        trailing = null,
        onChanged = null;

  /// Already localized.
  final String label;
  final IconData? icon;
  final String? hint;
  final String? initialValue;

  /// Drives the text when the field's content can change from the outside
  /// after the first build (a money field re-rendered on a currency change).
  /// Mutually exclusive with [initialValue]; its owner disposes it.
  final TextEditingController? controller;

  final String? errorText;
  final String? helperText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final bool obscureText;

  /// How the keyboard auto-capitalizes typed text. Defaults to
  /// [TextCapitalization.none]; name/institution fields opt into `.words`.
  final TextCapitalization textCapitalization;

  /// Extra action inside the box (e.g. the reveal eye of the number field).
  final Widget? trailing;

  final ValueChanged<String>? onChanged;

  /// Non-null only on a selector field.
  final VoidCallback? onTap;

  /// What a selector currently holds; null renders the hint.
  final String? value;

  bool get isSelector => onTap != null;

  /// Whether this field opens the system number keyboard, which on iOS lacks a
  /// return key — the case that needs a "Listo" accessory to dismiss.
  bool get _usesSystemNumberKeyboard {
    final type = keyboardType;
    return type == TextInputType.number ||
        type == TextInputType.phone ||
        type == const TextInputType.numberWithOptions(decimal: true) ||
        type == const TextInputType.numberWithOptions(signed: true) ||
        type ==
            const TextInputType.numberWithOptions(decimal: true, signed: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final icon = this.icon;

    final Widget input = TextFormField(
      initialValue: initialValue,
      controller: controller,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      obscureText: obscureText,
      textCapitalization: textCapitalization,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        errorText: errorText,
        prefixIcon:
            icon == null ? null : Icon(icon, color: colors.textSecondary),
        suffixIcon: trailing,
      ),
    );

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
        else if (_usesSystemNumberKeyboard)
          KeyboardDoneToolbar(child: input)
        else
          input,
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
        constraints: const BoxConstraints(minHeight: 52),
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
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: theme.textTheme.bodyLarge?.copyWith(
                  color:
                      value == null ? colors.textSecondary : colors.textPrimary,
                ),
              ),
            ),
            Icon(LucideIcons.chevronDown,
                color: colors.textSecondary, size: 20),
          ],
        ),
      ),
    );
  }
}
