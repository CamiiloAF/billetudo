import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/presentation/widgets/numeric_keypad.dart';
import '../utils/calculator_amount_buffer.dart';

/// The confirmation sheet's editable amount row (criterion 8): tapping it
/// expands the same calculator [NumericKeypad] Transacciones uses (Pencil
/// `irJZw`), in-situ inside the sheet — never an `AlertDialog` on top of it.
///
/// A reduced, local version of Transacciones' "Zona Fija": only the
/// expand/collapse of the keypad itself, not the anchored header/collapsed
/// bar mechanism (out of scope here, see confirmation sheet spec). The
/// arithmetic lives in [CalculatorAmountBuffer], a presentation-only port of
/// `TransactionFormCubit`'s calculator so this widget never touches the
/// Transactions feature's cubit/state beyond the shared `CalcOperator` enum
/// and the [NumericKeypad] widget itself.
class ScheduledPaymentEditableAmountField extends StatefulWidget {
  const ScheduledPaymentEditableAmountField({
    required this.amountMinor,
    required this.currency,
    required this.onChanged,
    super.key,
  });

  final int amountMinor;
  final String currency;
  final ValueChanged<int> onChanged;

  @override
  State<ScheduledPaymentEditableAmountField> createState() =>
      _ScheduledPaymentEditableAmountFieldState();
}

class _ScheduledPaymentEditableAmountFieldState
    extends State<ScheduledPaymentEditableAmountField> {
  bool _expanded = false;
  late CalculatorAmountBuffer _buffer =
      CalculatorAmountBuffer(amountMinor: widget.amountMinor);

  /// The last value this widget itself reported via `widget.onChanged`, so an
  /// incoming `widget.amountMinor` that merely echoes back a local edit is
  /// not mistaken for an external reset (e.g. the guided review moving on to
  /// the next occurrence, which genuinely needs a fresh buffer).
  int? _lastEmitted;

  @override
  void didUpdateWidget(covariant ScheduledPaymentEditableAmountField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.amountMinor != oldWidget.amountMinor &&
        widget.amountMinor != _lastEmitted) {
      setState(() {
        _buffer = CalculatorAmountBuffer(amountMinor: widget.amountMinor);
        _expanded = false;
      });
    }
  }

  void _apply(CalculatorAmountBuffer next) {
    setState(() => _buffer = next);
    _lastEmitted = next.amountMinor;
    widget.onChanged(next.amountMinor);
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context);
    final colors = context.colors;
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        InkWell(
          onTap: () => setState(() => _expanded = !_expanded),
          child: Row(
            children: [
              Text(
                l10n.transactionFormAmountLabel,
                style:
                    theme.textTheme.bodySmall?.copyWith(color: colors.textSecondary),
              ),
              const Spacer(),
              Text(
                const MoneyFormatter().format(
                  _buffer.amountMinor,
                  currencyCode: widget.currency,
                ),
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700, color: colors.primary),
              ),
              const SizedBox(width: 4),
              Icon(
                _expanded ? LucideIcons.chevronUp : LucideIcons.chevronDown,
                size: 16,
                color: colors.textSecondary,
              ),
            ],
          ),
        ),
        AnimatedSize(
          duration: AppTheme.motionDuration,
          curve: AppTheme.motionCurve,
          alignment: Alignment.topCenter,
          child: _expanded
              ? Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: NumericKeypad(
                    onDigit: (digit) => _apply(
                      _buffer.digitPressed(digit, currency: widget.currency),
                    ),
                    onDecimal: () => _apply(
                      _buffer.decimalPressed(currency: widget.currency),
                    ),
                    onOperator: (operator) =>
                        _apply(_buffer.operatorPressed(operator)),
                    onEquals: () => _apply(_buffer.equalsPressed()),
                    onBackspace: () => _apply(_buffer.backspacePressed()),
                  ),
                )
              : const SizedBox.shrink(),
        ),
      ],
    );
  }
}
