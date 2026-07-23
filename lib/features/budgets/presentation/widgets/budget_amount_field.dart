import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/money_input_formatter.dart';
import '../../../../core/widgets/keyboard_done_toolbar.dart';

/// The amount input of the budget form (`a3gGPM/k9OW4h`): a 52pt box holding
/// the figure at 22/800 and, anchored inside it, the currency pill
/// (`EA3R5` — `$muted`, radius 10, the ISO code at 13/700 plus a
/// `chevron-down`) that opens the currency picker.
///
/// The typed figure carries the currency's own decimals (COP has none), so a
/// prefilled amount never reads `4.500.000,00`, and it is always prefixed by
/// the currency symbol — `KP13F` reads `$0` empty and must read `$4.500.000`
/// filled, never a bare `4.500.000`.
///
/// [MoneyInputFormatter] keeps the figure grouped while the user types
/// (`4500000` → `4.500.000`) without moving the caret, so what is being typed
/// reads like money from the first keystroke and not only after an external
/// rebuild.
///
/// The symbol is a **fixed prefix outside the editable text**, not part of the
/// value: the field's input formatter only lets digits and separators through,
/// so a `$` baked into the text would be stripped on the first keystroke.
/// Painting it separately also keeps the caret arithmetic untouched.
///
/// It owns a [TextEditingController] rather than an `initialValue` so that
/// switching currency **with a figure already typed** re-renders it: an
/// `initialValue` is read once, and the field kept showing `1.234,56` under a
/// COP that has no cents. The cubit has already rounded the stored amount by
/// then ([MoneyFormatter.roundToCurrencyPrecision]), so this only adopts it —
/// and only when the currency truly changed, never on every rebuild, which
/// would drag the caret mid-word.
class BudgetAmountField extends StatefulWidget {
  const BudgetAmountField({
    required this.amountMinor,
    required this.currency,
    required this.onChanged,
    required this.onCurrencyTap,
    this.errorText,
    super.key,
  });

  final int? amountMinor;
  final String currency;
  final ValueChanged<int?> onChanged;
  final VoidCallback onCurrencyTap;

  /// Set when the amount failed validation (HU-01: a budget needs a positive
  /// amount). Switches the box border to `$expense` and shows a message below.
  final String? errorText;

  @override
  State<BudgetAmountField> createState() => _BudgetAmountFieldState();
}

class _BudgetAmountFieldState extends State<BudgetAmountField> {
  static const MoneyFormatter _money = MoneyFormatter();

  late final TextEditingController _controller = TextEditingController(
      text: _textFor(widget.amountMinor, widget.currency));

  static String _textFor(int? amountMinor, String currency) =>
      amountMinor == null
          ? ''
          : _money.formatAmount(
              amountMinor,
              decimalDigits: MoneyFormatter.currencyDecimals(currency),
            );

  @override
  void didUpdateWidget(BudgetAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currency == oldWidget.currency) {
      return;
    }
    final text = _textFor(widget.amountMinor, widget.currency);
    if (text == _controller.text) {
      return;
    }
    // Caret to the end: the old offset counted characters of a figure that no
    // longer exists (`1.234,56` → `1.235`) and could land out of range.
    _controller.value = TextEditingValue(
      text: text,
      selection: TextSelection.collapsed(offset: text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final decimals = MoneyFormatter.currencyDecimals(widget.currency);
    final amountMinor = widget.amountMinor;
    final errorText = widget.errorText;
    const style = TextStyle(
      fontFamily: AppTheme.fontFamily,
      fontSize: 22,
      fontWeight: FontWeight.w800,
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
          child: Row(
            children: [
              Text(
                MoneyFormatter.currencySymbol,
                style: style.copyWith(
                  color: amountMinor == null
                      ? colors.textSecondary
                      : colors.textPrimary,
                ),
              ),
              Expanded(
                child: KeyboardDoneToolbar(
                  child: TextFormField(
                    controller: _controller,
                    onChanged: (value) =>
                        widget.onChanged(MoneyFormatter.parseMinor(value)),
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    inputFormatters: [MoneyInputFormatter(decimals: decimals)],
                    style: style.copyWith(color: colors.textPrimary),
                    decoration: InputDecoration(
                      isCollapsed: true,
                      filled: false,
                      contentPadding: EdgeInsets.zero,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      hintText: _money.formatAmount(0, decimalDigits: decimals),
                      hintStyle: style.copyWith(color: colors.textSecondary),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              BudgetCurrencyPill(
                code: widget.currency,
                onTap: widget.onCurrencyTap,
              ),
            ],
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

/// The currency pill inside [BudgetAmountField] (`a3gGPM/EA3R5`).
class BudgetCurrencyPill extends StatelessWidget {
  const BudgetCurrencyPill({
    required this.code,
    required this.onTap,
    super.key,
  });

  final String code;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    return Material(
      color: colors.muted,
      borderRadius: BorderRadius.circular(10),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                code,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(width: 4),
              Icon(
                LucideIcons.chevronDown,
                size: 14,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
