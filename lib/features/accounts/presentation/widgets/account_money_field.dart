import 'package:flutter/material.dart';

import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/money_input_formatter.dart';
import 'account_form_field.dart';

/// A money [AccountFormField.text] that survives a currency change.
///
/// Why it is stateful while every other field of the form is not: an
/// `initialValue` is read once, so a field already holding `1.234,56` kept
/// showing its cents after the user switched to COP, which has none. Owning a
/// [TextEditingController] is what lets the text be re-rendered later.
///
/// The text is only rewritten when [currency] actually changed — the cubit has
/// already re-cut its precision by then
/// ([MoneyFormatter.roundToCurrencyPrecision]), so this just adopts what the
/// state now holds. Rewriting on every rebuild would drag the caret on each
/// keystroke, which is the bug the grouping formatter was built to avoid.
class AccountMoneyField extends StatefulWidget {
  const AccountMoneyField({
    required this.label,
    required this.currency,
    required this.text,
    required this.onChanged,
    this.icon,
    this.hint,
    this.errorText,
    this.allowNegative = false,
    super.key,
  });

  /// Already localized.
  final String label;
  final IconData? icon;
  final String? hint;

  /// ISO code driving how many decimals the figure takes.
  final String currency;

  /// What the cubit holds, in the grouped notation the field types in.
  final String text;

  final String? errorText;
  final bool allowNegative;
  final ValueChanged<String> onChanged;

  @override
  State<AccountMoneyField> createState() => _AccountMoneyFieldState();
}

class _AccountMoneyFieldState extends State<AccountMoneyField> {
  late final TextEditingController _controller =
      TextEditingController(text: widget.text);

  @override
  void didUpdateWidget(AccountMoneyField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currency == oldWidget.currency ||
        widget.text == _controller.text) {
      return;
    }
    // Caret to the end: the old offset counted characters of a figure that no
    // longer exists (`1.234,56` → `1.235`) and could land out of range.
    _controller.value = TextEditingValue(
      text: widget.text,
      selection: TextSelection.collapsed(offset: widget.text.length),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AccountFormField.text(
      label: widget.label,
      icon: widget.icon,
      hint: widget.hint,
      controller: _controller,
      errorText: widget.errorText,
      keyboardType: TextInputType.numberWithOptions(
        decimal: true,
        signed: widget.allowNegative,
      ),
      inputFormatters: [
        MoneyInputFormatter(
          decimals: MoneyFormatter.currencyDecimals(widget.currency),
          allowNegative: widget.allowNegative,
        ),
      ],
      onChanged: widget.onChanged,
    );
  }
}
