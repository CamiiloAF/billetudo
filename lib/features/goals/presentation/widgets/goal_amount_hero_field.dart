import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../../core/utils/money_input_formatter.dart';
import '../../../../core/widgets/keyboard_done_toolbar.dart';

/// The amount héroe shared by the crear/editar meta form (saldo objetivo /
/// avance inicial) and the aportar/retirar sheets: a centered label, the big
/// editable amount at 38px/800. Same pattern as Deudas' `DebtAmountHeroField`.
class GoalAmountHeroField extends StatefulWidget {
  const GoalAmountHeroField({
    required this.label,
    required this.currency,
    required this.initialAmountMinor,
    required this.onChanged,
    this.boxed = false,
    this.autofocus = false,
    this.fieldKey,
    this.errorText,
    super.key,
  });

  final String label;
  final String currency;
  final int initialAmountMinor;
  final ValueChanged<int> onChanged;
  final bool boxed;
  final bool autofocus;
  final Key? fieldKey;
  final String? errorText;

  @override
  State<GoalAmountHeroField> createState() => _GoalAmountHeroFieldState();
}

class _GoalAmountHeroFieldState extends State<GoalAmountHeroField> {
  static const MoneyFormatter _money = MoneyFormatter();

  late final TextEditingController _controller = TextEditingController(
    text: _seed(widget.initialAmountMinor, widget.currency),
  );

  static String _seed(int amountMinor, String currency) {
    if (amountMinor <= 0) {
      return '';
    }
    return _money.formatAmount(
      amountMinor,
      decimalDigits: MoneyFormatter.displayDecimals(amountMinor, currency),
    );
  }

  @override
  void didUpdateWidget(GoalAmountHeroField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.currency != oldWidget.currency) {
      final minor = MoneyFormatter.parseMinor(_controller.text) ?? 0;
      final text = _seed(minor, widget.currency);
      _controller.value = TextEditingValue(
        text: text,
        selection: TextSelection.collapsed(offset: text.length),
      );
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onChanged(String text) =>
      widget.onChanged(MoneyFormatter.parseMinor(text) ?? 0);

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);

    final content = Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          widget.label,
          style: theme.textTheme.labelLarge?.copyWith(
            color: colors.textSecondary,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 6),
        KeyboardDoneToolbar(
          child: TextField(
            key: widget.fieldKey,
            controller: _controller,
            autofocus: widget.autofocus,
            textAlign: TextAlign.center,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            enableInteractiveSelection: false,
            inputFormatters: [
              MoneyInputFormatter(
                decimals: MoneyFormatter.inputDecimals(widget.currency),
              ),
            ],
            onChanged: _onChanged,
            cursorColor: colors.primary,
            style: theme.textTheme.displaySmall?.copyWith(
              color: colors.textPrimary,
              fontSize: 38,
              fontWeight: FontWeight.w800,
            ),
            decoration: InputDecoration(
              isDense: true,
              border: InputBorder.none,
              enabledBorder: InputBorder.none,
              focusedBorder: InputBorder.none,
              contentPadding: EdgeInsets.zero,
              prefixText: MoneyFormatter.currencySymbol,
              prefixStyle: theme.textTheme.displaySmall?.copyWith(
                color: colors.textPrimary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
              hintText: '0',
              hintStyle: theme.textTheme.displaySmall?.copyWith(
                color: colors.textSecondary,
                fontSize: 38,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
      ],
    );

    final error = widget.errorText;
    final Widget hero = !widget.boxed
        ? content
        : Container(
            width: double.infinity,
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radiusLarge),
              border: Border.all(
                color: error == null ? colors.border : colors.expense,
              ),
            ),
            padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
            child: content,
          );

    if (error == null) {
      return hero;
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        hero,
        const SizedBox(height: 6),
        Text(
          error,
          style: theme.textTheme.bodySmall?.copyWith(color: colors.expenseText),
        ),
      ],
    );
  }
}
