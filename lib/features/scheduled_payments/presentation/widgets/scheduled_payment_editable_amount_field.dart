import 'package:flutter/material.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/l10n/gen/app_localizations.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/money_formatter.dart';
import '../../../transactions/presentation/cubit/transaction_form_state.dart'
    show CalcOperator;
import '../../../transactions/presentation/widgets/numeric_keypad.dart';
import '../utils/calculator_amount_buffer.dart';

/// The editable amount row shared by the template form's own "Zona Fija"
/// (`ScheduledPaymentAmountFixedZone`) and the confirmation sheet (criterion
/// 8): tapping it expands the same calculator [NumericKeypad] Transacciones
/// uses (Pencil `irJZw`), in-situ — never an `AlertDialog` on top of it.
///
/// Mirrors `TransactionAmountFixedZone`'s expanded/collapsed structure
/// exactly (header label + 44x44 chevron button, then the big centered
/// value at 40px/800 when expanded; a centered label + value at 20px/700
/// with matching 44x44 chevron buttons on both sides when collapsed) so the
/// two features' keyboard zones read as the same control. The arithmetic
/// lives in [CalculatorAmountBuffer], a presentation-only port of
/// `TransactionFormCubit`'s calculator so this widget never touches the
/// Transactions feature's cubit/state beyond the shared `CalcOperator` enum
/// and the [NumericKeypad] widget itself.
class ScheduledPaymentEditableAmountField extends StatefulWidget {
  const ScheduledPaymentEditableAmountField({
    required this.amountMinor,
    required this.currency,
    required this.onChanged,
    this.label,
    this.valueColor,
    this.amountPrefix = '',
    this.confirmEnabled = true,
    super.key,
  });

  final int amountMinor;
  final String currency;
  final ValueChanged<int> onChanged;

  /// Shows the keypad's own Confirm key (which collapses this field). The
  /// confirmation sheet passes `false`: it carries its own Confirmar button,
  /// so the keypad's `=` spans the full width there instead.
  final bool confirmEnabled;

  /// Already localized. `null` falls back to the form's generic "Monto"; the
  /// confirmation sheet passes "Monto a registrar"/"Monto a transferir".
  final String? label;

  /// The collapsed value's colour. `null` keeps the brand `primary` the
  /// template form uses; the confirmation sheet passes the type's own tone
  /// (`text-primary` for a gasto, `income-text` for an ingreso).
  final Color? valueColor;

  /// Prepended to the formatted amount — `'+'` for an ingreso, empty
  /// otherwise (an expense is never shown with a minus sign here: the sheet
  /// already says what it is registering).
  final String amountPrefix;

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
  void didUpdateWidget(
      covariant ScheduledPaymentEditableAmountField oldWidget) {
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

  void _expand() => setState(() => _expanded = true);

  void _collapse() => setState(() => _expanded = false);

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: AppTheme.motionDuration,
      curve: AppTheme.motionCurve,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: AppTheme.motionDuration,
        switchInCurve: AppTheme.motionCurve,
        switchOutCurve: AppTheme.motionCurve,
        child: _expanded
            ? ScheduledPaymentAmountExpanded(
                key: const ValueKey('expanded'),
                amountMinor: _buffer.amountMinor,
                currency: widget.currency,
                entryFractionDigits: _buffer.entryFractionDigits,
                label: widget.label,
                valueColor: widget.valueColor,
                amountPrefix: widget.amountPrefix,
                confirmEnabled: widget.confirmEnabled,
                onCollapse: _collapse,
                onDigit: (digit) => _apply(
                    _buffer.digitPressed(digit, currency: widget.currency)),
                onDecimal: () =>
                    _apply(_buffer.decimalPressed(currency: widget.currency)),
                onOperator: (operator) =>
                    _apply(_buffer.operatorPressed(operator)),
                onEquals: () => _apply(_buffer.equalsPressed()),
                onBackspace: () => _apply(_buffer.backspacePressed()),
                onBackspaceLongPress: () => _apply(_buffer.cleared()),
              )
            : ScheduledPaymentAmountCollapsed(
                key: const ValueKey('collapsed'),
                amountMinor: _buffer.amountMinor,
                currency: widget.currency,
                label: widget.label,
                valueColor: widget.valueColor,
                amountPrefix: widget.amountPrefix,
                onExpand: _expand,
              ),
      ),
    );
  }
}

/// The expanded state: a header row (label + 44x44 collapse chevron), the
/// big centered amount (40px/800), then the anchored keypad — same structure
/// as `TransactionAmountExpandedZone`.
class ScheduledPaymentAmountExpanded extends StatelessWidget {
  const ScheduledPaymentAmountExpanded({
    required this.amountMinor,
    required this.currency,
    required this.onCollapse,
    required this.onDigit,
    required this.onDecimal,
    required this.onOperator,
    required this.onEquals,
    required this.onBackspace,
    required this.onBackspaceLongPress,
    this.entryFractionDigits = -1,
    this.label,
    this.valueColor,
    this.amountPrefix = '',
    this.confirmEnabled = true,
    super.key,
  });

  final int amountMinor;
  final String currency;

  /// The active buffer's `entryFractionDigits`: `0` renders the pending decimal
  /// separator so the comma shows the instant it is pressed (item 20).
  final int entryFractionDigits;
  final String? label;

  /// The value's colour, kept identical to the collapsed state so the amount
  /// never changes tone when expanded. `null` falls back to the brand
  /// `primary`.
  final Color? valueColor;

  final String amountPrefix;

  /// Forwarded to [NumericKeypad.confirmEnabled].
  final bool confirmEnabled;

  final VoidCallback onCollapse;
  final ValueChanged<int> onDigit;
  final VoidCallback onDecimal;
  final ValueChanged<CalcOperator> onOperator;
  final VoidCallback onEquals;
  final VoidCallback onBackspace;

  /// Long-pressing backspace clears the whole amount (item 5).
  final VoidCallback onBackspaceLongPress;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                label ?? l10n.transactionFormAmountLabel,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: colors.textSecondary,
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            IconButton(
              onPressed: onCollapse,
              tooltip: l10n.transactionFormCollapseAmount,
              iconSize: 20,
              color: colors.textSecondary,
              constraints: const BoxConstraints.tightFor(width: 44, height: 44),
              icon: const Icon(LucideIcons.chevronDown),
            ),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text(
            '$amountPrefix${money.formatSymbolEntry(amountMinor, currencyCode: currency, entryFractionDigits: entryFractionDigits)}',
            textAlign: TextAlign.center,
            style: theme.textTheme.displaySmall?.copyWith(
              color: valueColor ?? colors.primary,
              fontSize: 40,
              fontWeight: FontWeight.w800,
            ),
          ),
        ),
        NumericKeypad(
          onDigit: onDigit,
          onDecimal: onDecimal,
          onOperator: onOperator,
          onEquals: onEquals,
          onBackspace: onBackspace,
          onBackspaceLongPress: onBackspaceLongPress,
          // Confirm commits the amount by collapsing this field, mirroring the
          // header chevron.
          onConfirm: onCollapse,
          confirmEnabled: confirmEnabled,
        ),
      ],
    );
  }
}

/// The collapsed state: a centered label + value (20px/700), flanked by a
/// left spacer and a 44x44 expand chevron on the right so the amount block
/// stays truly centered — same structure as `TransactionAmountCollapsedBar`.
class ScheduledPaymentAmountCollapsed extends StatelessWidget {
  const ScheduledPaymentAmountCollapsed({
    required this.amountMinor,
    required this.currency,
    required this.onExpand,
    this.label,
    this.valueColor,
    this.amountPrefix = '',
    super.key,
  });

  final int amountMinor;
  final String currency;
  final String? label;
  final Color? valueColor;
  final String amountPrefix;
  final VoidCallback onExpand;

  @override
  Widget build(BuildContext context) {
    final colors = context.colors;
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context);
    const money = MoneyFormatter();
    return InkWell(
      onTap: onExpand,
      child: Row(
        children: [
          const SizedBox(width: 44, height: 44),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label ?? l10n.transactionFormAmountLabel,
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: colors.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$amountPrefix${money.formatSymbol(amountMinor, currencyCode: currency)}',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: valueColor ?? colors.primary,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            onPressed: onExpand,
            tooltip: l10n.transactionFormExpandAmount,
            iconSize: 20,
            color: colors.textSecondary,
            constraints: const BoxConstraints.tightFor(width: 44, height: 44),
            icon: const Icon(LucideIcons.chevronUp),
          ),
        ],
      ),
    );
  }
}
