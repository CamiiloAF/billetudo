import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/widgets/keyboard_done_toolbar.dart';

/// The `Form Field` component (`wOlOA`): a 13/600 `$text-secondary` label over
/// an input box (optional leading icon), plus an optional error line.
///
/// Two shapes, one component:
///  * [DebtFormField.text] — the user types.
///  * [DebtFormField.selector] — the user taps and a sheet/picker answers
///    (vencimiento), so it shows a value + chevron instead of a cursor.
class DebtFormField extends StatelessWidget {
  const DebtFormField.text({
    required this.label,
    this.icon,
    this.hint,
    this.initialValue,
    this.errorText,
    this.keyboardType,
    this.inputFormatters,
    this.maxLength,
    this.textCapitalization = TextCapitalization.none,
    this.trailingText,
    this.onChanged,
    super.key,
  })  : onTap = null,
        value = null,
        onClear = null;

  const DebtFormField.selector({
    required this.label,
    required this.value,
    required this.onTap,
    this.icon,
    this.hint,
    this.errorText,
    this.onClear,
    super.key,
  })  : initialValue = null,
        keyboardType = null,
        inputFormatters = null,
        maxLength = null,
        textCapitalization = TextCapitalization.none,
        trailingText = null,
        onChanged = null;

  final String label;
  final IconData? icon;
  final String? hint;
  final String? initialValue;
  final String? errorText;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final int? maxLength;
  final TextCapitalization textCapitalization;

  /// A fixed trailing suffix inside the box (the "%" of the interest field).
  final String? trailingText;

  final ValueChanged<String>? onChanged;
  final VoidCallback? onTap;
  final String? value;

  /// A selector-only affordance to clear the current [value] (item 1e): the
  /// "×" only shows when there is a value to clear.
  final VoidCallback? onClear;

  bool get _isSelector => onTap != null;

  bool get _usesSystemNumberKeyboard {
    final type = keyboardType;
    return type == TextInputType.number ||
        type == const TextInputType.numberWithOptions(decimal: true);
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final icon = this.icon;

    final Widget input = TextFormField(
      initialValue: initialValue,
      onChanged: onChanged,
      keyboardType: keyboardType,
      inputFormatters: inputFormatters,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      style: theme.textTheme.bodyLarge,
      decoration: InputDecoration(
        hintText: hint,
        counterText: '',
        errorText: errorText,
        prefixIcon:
            icon == null ? null : Icon(icon, color: colors.textSecondary),
        suffixIcon: trailingText == null
            ? null
            : Padding(
                padding: const EdgeInsets.only(right: 16),
                child: Text(
                  trailingText!,
                  style: theme.textTheme.bodyLarge?.copyWith(
                    color: colors.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
        suffixIconConstraints: const BoxConstraints(),
      ),
    );

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
        const SizedBox(height: 6),
        if (_isSelector)
          DebtFormSelectorBox(
            icon: icon,
            value: value,
            hint: hint,
            hasError: errorText != null,
            onTap: onTap!,
            onClear: value == null ? null : onClear,
          )
        else if (_usesSystemNumberKeyboard)
          KeyboardDoneToolbar(child: input)
        else
          input,
        if (_isSelector && errorText != null) ...[
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
class DebtFormSelectorBox extends StatelessWidget {
  const DebtFormSelectorBox({
    required this.value,
    required this.hint,
    required this.hasError,
    required this.onTap,
    this.icon,
    this.onClear,
    super.key,
  });

  final String? value;
  final String? hint;
  final bool hasError;
  final VoidCallback onTap;
  final IconData? icon;

  /// When set, a trailing "×" clears the value (item 1e) instead of opening the
  /// picker; shown only when there is a value.
  final VoidCallback? onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final icon = this.icon;
    final value = this.value;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTheme.radiusField),
      child: Container(
        height: 50,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radiusField),
          border: Border.all(color: hasError ? colors.expense : colors.border),
        ),
        child: Row(
          children: [
            if (icon != null) ...[
              Icon(icon, color: colors.textSecondary, size: 18),
              const SizedBox(width: 8),
            ],
            Expanded(
              child: Text(
                value ?? hint ?? '',
                style: theme.textTheme.bodyMedium?.copyWith(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color:
                      value == null ? colors.textSecondary : colors.textPrimary,
                ),
              ),
            ),
            if (onClear case final onClear?)
              DebtSelectorClearButton(onClear: onClear)
            else
              Icon(
                LucideIcons.chevronDown,
                color: colors.textSecondary,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }
}

/// The "×" that clears a selector's value (item 1e): a `$primary-soft` circle
/// with a 44x44 tap target (the visible circle stays 30x30, matching `B1f66`).
class DebtSelectorClearButton extends StatelessWidget {
  const DebtSelectorClearButton({required this.onClear, super.key});

  final VoidCallback onClear;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final l10n = AppLocalizations.of(context);
    return Semantics(
      button: true,
      label: l10n.commonClear,
      child: InkResponse(
        onTap: onClear,
        radius: 22,
        child: SizedBox(
          width: 44,
          height: 44,
          child: Center(
            child: Container(
              width: 30,
              height: 30,
              decoration: BoxDecoration(
                color: colors.primarySoft,
                shape: BoxShape.circle,
              ),
              child: Icon(
                LucideIcons.x,
                color: colors.textSecondary,
                size: 16,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
